import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import { getCompanionMessage } from "./messageTemplates";
import { sendPushNotification } from "./sendNotification";

/**
 * Maps readingTime preference to the hour (UTC) at which the reminder
 * should be sent. The notification fires 10 minutes BEFORE the actual
 * reading time, so the function triggers at the START of the hour that
 * contains the "10 minutes before" moment.
 *
 * Reading times (assumed UTC):
 *   morning   = 08:00  -> reminder at 07:50 -> run in hour 7
 *   afternoon = 13:00  -> reminder at 12:50 -> run in hour 12
 *   evening   = 18:00  -> reminder at 17:50 -> run in hour 17
 *   night     = 21:00  -> reminder at 20:50 -> run in hour 20
 *   custom    = parsed from customReadingTime field
 */
const READING_TIME_TO_REMINDER_HOUR: Record<string, number> = {
  morning: 7,    // remind at 07:50 for 08:00 reading
  afternoon: 12, // remind at 12:50 for 13:00 reading
  evening: 17,   // remind at 17:50 for 18:00 reading
  night: 20,     // remind at 20:50 for 21:00 reading
};

/**
 * Checks whether the user's lastReadDate is today (UTC).
 */
function hasReadToday(lastReadDate: admin.firestore.Timestamp | null | undefined): boolean {
  if (!lastReadDate) return false;

  const now = new Date();
  const lastRead = lastReadDate.toDate();

  return (
    lastRead.getUTCFullYear() === now.getUTCFullYear() &&
    lastRead.getUTCMonth() === now.getUTCMonth() &&
    lastRead.getUTCDate() === now.getUTCDate()
  );
}

/**
 * Parses a "HH:MM" string and returns the hour at which the reminder
 * should fire (one hour before the reading time to catch the 10-min-before window).
 * Returns null if the format is invalid.
 */
function parseCustomReadingHour(customTime: string | undefined | null): number | null {
  if (!customTime) return null;

  const parts = customTime.split(":");
  if (parts.length !== 2) return null;

  const hour = parseInt(parts[0], 10);
  const minute = parseInt(parts[1], 10);

  if (isNaN(hour) || isNaN(minute) || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return null;
  }

  // If reading time is at HH:MM, the reminder is at HH:MM - 10 min.
  // We need the function to run in the hour that contains that reminder time.
  // If minute >= 10, the reminder falls in the same hour -> return hour.
  // If minute < 10, the reminder falls in the previous hour -> return hour - 1.
  if (minute >= 10) {
    return hour;
  } else {
    return hour === 0 ? 23 : hour - 1;
  }
}

/**
 * Scheduled Cloud Function that runs every hour.
 * Sends daily reading reminders to users whose reading time matches the current hour.
 */
export const dailyReadingReminder = onSchedule(
  {
    schedule: "0 * * * *", // every hour at minute 0
    timeZone: "UTC",
    retryCount: 1,
    memory: "256MiB",
  },
  async () => {
    const currentHourUTC = new Date().getUTCHours();
    logger.info(`Daily reminder check running for UTC hour: ${currentHourUTC}`);

    const db = admin.firestore();

    // 1. Find users with preset reading times that match this hour
    const matchingPresets: string[] = [];
    for (const [preset, reminderHour] of Object.entries(READING_TIME_TO_REMINDER_HOUR)) {
      if (reminderHour === currentHourUTC) {
        matchingPresets.push(preset);
      }
    }

    const usersToNotify: admin.firestore.DocumentData[] = [];

    // Query users with matching preset reading times
    if (matchingPresets.length > 0) {
      for (const preset of matchingPresets) {
        try {
          const snapshot = await db
            .collection("users")
            .where("readingTime", "==", preset)
            .get();

          snapshot.docs.forEach((doc) => {
            usersToNotify.push({ id: doc.id, ...doc.data() });
          });
        } catch (error) {
          logger.error(`Error querying users with readingTime=${preset}:`, error);
        }
      }
    }

    // 2. Query users with custom reading time
    try {
      const customSnapshot = await db
        .collection("users")
        .where("readingTime", "==", "custom")
        .get();

      customSnapshot.docs.forEach((doc) => {
        const data = doc.data();
        const reminderHour = parseCustomReadingHour(data.customReadingTime);
        if (reminderHour === currentHourUTC) {
          usersToNotify.push({ id: doc.id, ...data });
        }
      });
    } catch (error) {
      logger.error("Error querying custom readingTime users:", error);
    }

    logger.info(`Found ${usersToNotify.length} users to notify for hour ${currentHourUTC}`);

    // 3. Send notifications
    let sentCount = 0;
    let skippedCount = 0;

    const notificationPromises = usersToNotify.map(async (user) => {
      try {
        // Skip if no FCM token
        if (!user.fcmToken) {
          skippedCount++;
          return;
        }

        // Skip if user already read today
        if (hasReadToday(user.lastReadDate)) {
          skippedCount++;
          return;
        }

        const breed = user.companionBreed || "golden_retriever";
        const companionName = user.companionName || "Buddy";

        const message = getCompanionMessage(breed, companionName, "daily_reminder");

        await sendPushNotification(user.fcmToken, message.title, message.body, {
          type: "daily_reminder",
          companionBreed: breed,
          companionName: companionName,
        });

        sentCount++;
      } catch (error) {
        logger.error(`Failed to send reminder to user ${user.id}:`, error);
      }
    });

    await Promise.all(notificationPromises);

    logger.info(
      `Daily reminder complete: ${sentCount} sent, ${skippedCount} skipped, ` +
      `${usersToNotify.length - sentCount - skippedCount} failed`
    );
  }
);
