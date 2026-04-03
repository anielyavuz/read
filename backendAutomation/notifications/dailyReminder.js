const admin = require("firebase-admin");
const { getCompanionMessage, getReadingReminderMessage } = require("./messageTemplates");
const { sendPushNotification } = require("./sendNotification");

function log(message) {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] [dailyReminder] ${message}`);
}

/**
 * Quiet hours: notifications are NOT sent between 23:00 and 07:00 (server local time).
 * Returns true if the current hour is within quiet hours.
 */
function isQuietHours() {
  const currentHour = new Date().getHours();
  return currentHour >= 23 || currentHour < 7;
}

/**
 * Checks whether today is a weekend day (Saturday or Sunday).
 */
function isWeekend() {
  const day = new Date().getDay();
  return day === 0 || day === 6;
}

/**
 * Parses a "HH:MM" time string and returns { hour, minute }.
 * Returns null if format is invalid.
 */
function parseTime(timeStr) {
  if (!timeStr || typeof timeStr !== "string") return null;

  const parts = timeStr.split(":");
  if (parts.length !== 2) return null;

  const hour = parseInt(parts[0], 10);
  const minute = parseInt(parts[1], 10);

  if (isNaN(hour) || isNaN(minute) || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return null;
  }

  return { hour, minute };
}

/**
 * Determines if the current hour is the right time to send a pre-reminder
 * for a given reading time. The reminder should be sent 10 minutes before
 * the scheduled reading time.
 *
 * Since the cron runs every hour on the hour (06:00-22:00), we check if the
 * reminder window (readingTime - 10 min) falls within the current hour.
 *
 * Example: reading time 21:00 -> reminder at 20:50 -> fires during hour 20
 * Example: reading time 21:05 -> reminder at 20:55 -> fires during hour 20
 * Example: reading time 08:00 -> reminder at 07:50 -> fires during hour 7
 */
function shouldSendThisHour(timeStr) {
  const parsed = parseTime(timeStr);
  if (!parsed) return false;

  const currentHour = new Date().getHours();

  // Calculate the reminder time (10 minutes before reading time)
  let reminderHour = parsed.hour;
  let reminderMinute = parsed.minute - 10;

  if (reminderMinute < 0) {
    reminderMinute += 60;
    reminderHour = reminderHour === 0 ? 23 : reminderHour - 1;
  }

  return currentHour === reminderHour;
}

/**
 * Checks whether the user's lastReadDate is today (server local time).
 */
function hasReadToday(lastReadDate) {
  if (!lastReadDate) return false;

  const now = new Date();
  const lastRead = lastReadDate.toDate ? lastReadDate.toDate() : new Date(lastReadDate);

  return (
    lastRead.getFullYear() === now.getFullYear() &&
    lastRead.getMonth() === now.getMonth() &&
    lastRead.getDate() === now.getDate()
  );
}

/**
 * Runs the daily reading reminder check.
 *
 * - Enforces quiet hours (23:00 - 07:00 — no notifications sent)
 * - Queries users where notificationPrefs.enabled == true
 * - Determines weekday vs weekend and picks the appropriate time
 * - Checks if current hour matches the user's reminder time (minus 10 min)
 * - Sends FCM notification with companion-personality message
 *
 * Cron schedule: runs every hour from 06:00 to 22:00 (0 6-22 * * *)
 * All times are local to the server (Raspberry Pi).
 */
async function runDailyReminder() {
  const currentHour = new Date().getHours();
  log(`Running for local hour: ${currentHour}`);

  // Enforce quiet hours
  if (isQuietHours()) {
    log("Quiet hours active (23:00-07:00). Skipping.");
    return;
  }

  const db = admin.firestore();
  const weekend = isWeekend();
  log(`Day type: ${weekend ? "weekend" : "weekday"}`);

  let usersToNotify = [];

  try {
    // Query all users with notifications enabled
    const snapshot = await db
      .collection("users")
      .where("notificationPrefs.enabled", "==", true)
      .get();

    log(`Found ${snapshot.size} users with notifications enabled`);

    // Filter users whose reading time matches the current hour
    snapshot.docs.forEach((doc) => {
      const data = doc.data();
      const prefs = data.notificationPrefs || {};

      // Pick the correct time based on weekday vs weekend
      const readingTime = weekend ? prefs.weekendTime : prefs.weekdayTime;

      if (readingTime && shouldSendThisHour(readingTime)) {
        usersToNotify.push({ id: doc.id, ...data, _readingTime: readingTime });
      }
    });
  } catch (error) {
    log(`Error querying users: ${error.message}`);
    return;
  }

  log(`${usersToNotify.length} users matched for this hour`);

  // Send notifications
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
        log(`Skipping user ${user.id} — already read today`);
        return;
      }

      // Get reading duration goal for the message
      const duration = (user.notificationPrefs && user.notificationPrefs.readingDurationGoal) || 30;

      // Use companion-personality message if breed info is available,
      // otherwise fall back to the generic reading reminder template
      const breed = user.companionBreed || "golden_retriever";
      const companionName = user.companionName || "Buddy";
      const displayName = user.displayName || "Reader";

      // Try companion message first, fall back to generic template
      let message;
      if (user.companionBreed) {
        message = getCompanionMessage(breed, companionName, "daily_reminder");
      } else {
        message = getReadingReminderMessage(displayName, duration);
      }

      await sendPushNotification(user.fcmToken, message.title, message.body, {
        type: "daily_reminder",
        companionBreed: breed,
        companionName: companionName,
        readingDuration: duration.toString(),
      });

      sentCount++;
    } catch (error) {
      log(`Failed to send reminder to user ${user.id}: ${error.message}`);
    }
  });

  await Promise.all(notificationPromises);

  log(
    `Complete: ${sentCount} sent, ${skippedCount} skipped, ` +
    `${usersToNotify.length - sentCount - skippedCount} failed`
  );
}

module.exports = { runDailyReminder };
