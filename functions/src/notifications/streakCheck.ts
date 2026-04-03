import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import { getCompanionMessage } from "./messageTemplates";
import { sendPushNotification } from "./sendNotification";

/**
 * Returns the start of today (UTC) as a Date object — midnight 00:00:00.000.
 */
function getTodayStartUTC(): Date {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 0, 0, 0, 0));
}

/**
 * Determines streak urgency tier based on streak length.
 * Higher streaks = more dramatic/urgent messages.
 */
function getStreakUrgencyContext(streakDays: number): "streak_risk" | "streak_risk" {
  // All use streak_risk context but the message templates use streakDays
  // to vary intensity internally. The breed personality handles the drama level.
  return "streak_risk";
}

/**
 * Scheduled Cloud Function that runs daily at 20:00 UTC.
 * Checks for users with active streaks who haven't read today,
 * and sends urgent streak-risk notifications from their companion.
 */
export const streakRiskCheck = onSchedule(
  {
    schedule: "0 20 * * *", // daily at 20:00 UTC
    timeZone: "UTC",
    retryCount: 1,
    memory: "256MiB",
  },
  async () => {
    logger.info("Streak risk check running at 20:00 UTC");

    const db = admin.firestore();
    const todayStart = getTodayStartUTC();
    const todayTimestamp = admin.firestore.Timestamp.fromDate(todayStart);

    let sentCount = 0;
    let skippedCount = 0;
    let totalAtRisk = 0;

    try {
      // Query users with active streaks (streakDays > 0)
      // who last read BEFORE today (meaning they haven't read today yet)
      const snapshot = await db
        .collection("users")
        .where("streakDays", ">", 0)
        .get();

      const atRiskUsers = snapshot.docs.filter((doc) => {
        const data = doc.data();
        const lastReadDate = data.lastReadDate as admin.firestore.Timestamp | null | undefined;

        // If no lastReadDate, they're at risk
        if (!lastReadDate) return true;

        // If lastReadDate is before today, they haven't read today
        return lastReadDate.toMillis() < todayTimestamp.toMillis();
      });

      totalAtRisk = atRiskUsers.length;
      logger.info(`Found ${totalAtRisk} users at risk of losing their streak`);

      const notificationPromises = atRiskUsers.map(async (doc) => {
        const user = doc.data();
        const userId = doc.id;

        try {
          // Skip if no FCM token
          if (!user.fcmToken) {
            skippedCount++;
            return;
          }

          const breed = user.companionBreed || "golden_retriever";
          const companionName = user.companionName || "Buddy";
          const streakDays = user.streakDays || 1;
          const context = getStreakUrgencyContext(streakDays);

          const message = getCompanionMessage(breed, companionName, context, streakDays);

          await sendPushNotification(user.fcmToken, message.title, message.body, {
            type: "streak_risk",
            companionBreed: breed,
            companionName: companionName,
            streakDays: streakDays.toString(),
          });

          sentCount++;
        } catch (error) {
          logger.error(`Failed to send streak risk notification to user ${userId}:`, error);
        }
      });

      await Promise.all(notificationPromises);
    } catch (error) {
      logger.error("Error in streak risk check:", error);
    }

    logger.info(
      `Streak risk check complete: ${totalAtRisk} at risk, ${sentCount} notified, ` +
      `${skippedCount} skipped (no token), ${totalAtRisk - sentCount - skippedCount} failed`
    );
  }
);
