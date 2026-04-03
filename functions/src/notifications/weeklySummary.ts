import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import { getCompanionMessage } from "./messageTemplates";
import { sendPushNotification } from "./sendNotification";

/**
 * Scheduled Cloud Function that runs every Sunday at 20:00 UTC.
 * Sends a weekly reading summary notification to all users with an FCM token.
 *
 * The notification includes:
 *   - Pages read this week (pagesReadThisWeek)
 *   - Total reading minutes this week (readingMinutesThisWeek)
 *   - Current streak days
 *
 * These stats are sent in the data payload so the Flutter app can
 * display a rich summary in the inbox.
 */
export const weeklySummary = onSchedule(
  {
    schedule: "0 20 * * 0", // every Sunday at 20:00 UTC
    timeZone: "UTC",
    retryCount: 1,
    memory: "256MiB",
  },
  async () => {
    logger.info("Weekly summary running — Sunday 20:00 UTC");

    const db = admin.firestore();

    let sentCount = 0;
    let skippedCount = 0;

    try {
      // Get all users with FCM tokens
      const snapshot = await db
        .collection("users")
        .get();

      logger.info(`Processing ${snapshot.docs.length} users for weekly summary`);

      const promises = snapshot.docs.map(async (doc) => {
        const user = doc.data();

        try {
          if (!user.fcmToken) {
            skippedCount++;
            return;
          }

          const breed = user.companionBreed || "golden_retriever";
          const companionName = user.companionName || "Buddy";
          const pagesThisWeek = user.pagesReadThisWeek || 0;
          const minutesThisWeek = user.readingMinutesThisWeek || 0;
          const streakDays = user.streakDays || 0;
          const booksRead = user.booksRead || 0;

          // Skip if user had zero activity this week
          if (pagesThisWeek === 0 && minutesThisWeek === 0) {
            skippedCount++;
            return;
          }

          const hours = Math.floor(minutesThisWeek / 60);
          const mins = minutesThisWeek % 60;
          const timeStr = hours > 0
            ? `${hours}h ${mins}m`
            : `${mins}m`;

          const message = getCompanionMessage(breed, companionName, "weekly_summary");

          // Override body with actual stats
          const summaryBody =
            `This week: ${pagesThisWeek} pages, ${timeStr} reading time` +
            (streakDays > 0 ? `, ${streakDays} day streak` : "") +
            `. Total books: ${booksRead}. Keep going!`;

          await sendPushNotification(user.fcmToken, message.title, summaryBody, {
            type: "weekly_summary",
            companionBreed: breed,
            companionName: companionName,
            pagesThisWeek: pagesThisWeek.toString(),
            minutesThisWeek: minutesThisWeek.toString(),
            streakDays: streakDays.toString(),
          });

          sentCount++;
        } catch (error) {
          logger.error(`Failed to send weekly summary to ${doc.id}:`, error);
        }
      });

      await Promise.all(promises);
    } catch (error) {
      logger.error("Error in weekly summary:", error);
    }

    logger.info(
      `Weekly summary complete: ${sentCount} sent, ${skippedCount} skipped`
    );
  }
);
