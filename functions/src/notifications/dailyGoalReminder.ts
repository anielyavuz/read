import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import { getCompanionMessage } from "./messageTemplates";
import { sendPushNotification } from "./sendNotification";

/**
 * Scheduled Cloud Function that runs daily at 21:00 UTC.
 * Checks for users who haven't reached their daily page goal today
 * and sends a gentle reminder from their companion.
 *
 * Conditions to send:
 *   - User has an FCM token
 *   - User has a dailyPageGoal set
 *   - User's pagesReadToday < dailyPageGoal
 *   - User's pagesReadTodayDate matches today (otherwise 0 pages read)
 */
export const dailyGoalReminder = onSchedule(
  {
    schedule: "0 21 * * *", // daily at 21:00 UTC
    timeZone: "UTC",
    retryCount: 1,
    memory: "256MiB",
  },
  async () => {
    logger.info("Daily goal reminder running at 21:00 UTC");

    const db = admin.firestore();
    const now = new Date();
    const todayStr =
      `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, "0")}-${String(now.getUTCDate()).padStart(2, "0")}`;

    let sentCount = 0;
    let skippedCount = 0;

    try {
      // Query all users who have a daily page goal
      const snapshot = await db
        .collection("users")
        .where("dailyPageGoal", ">", 0)
        .get();

      logger.info(`Found ${snapshot.docs.length} users with daily goals`);

      const promises = snapshot.docs.map(async (doc) => {
        const user = doc.data();

        try {
          if (!user.fcmToken) {
            skippedCount++;
            return;
          }

          const goal = user.dailyPageGoal || 20;
          const pagesDate = user.pagesReadTodayDate || "";
          const pagesRead = pagesDate === todayStr ? (user.pagesReadToday || 0) : 0;

          // Skip if goal already met
          if (pagesRead >= goal) {
            skippedCount++;
            return;
          }

          const breed = user.companionBreed || "golden_retriever";
          const companionName = user.companionName || "Buddy";
          const remaining = goal - pagesRead;

          const message = getCompanionMessage(breed, companionName, "daily_goal");

          await sendPushNotification(user.fcmToken, message.title, message.body, {
            type: "daily_goal",
            companionBreed: breed,
            companionName: companionName,
            pagesRemaining: remaining.toString(),
            dailyGoal: goal.toString(),
          });

          sentCount++;
        } catch (error) {
          logger.error(`Failed to send daily goal reminder to ${doc.id}:`, error);
        }
      });

      await Promise.all(promises);
    } catch (error) {
      logger.error("Error in daily goal reminder:", error);
    }

    logger.info(
      `Daily goal reminder complete: ${sentCount} sent, ${skippedCount} skipped`
    );
  }
);
