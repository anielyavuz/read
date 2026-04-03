const admin = require("firebase-admin");
const { getWeeklyReportMessage } = require("./messageTemplates");
const { sendPushNotification } = require("./sendNotification");

function log(message) {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] [weeklyReport] ${message}`);
}

/**
 * Estimates pages read from XP earned this week.
 * Based on the XP system: +10 XP per page read.
 * This is an approximation since XP also comes from other sources
 * (daily goals, quizzes, streaks, etc.), so we apply a conservative factor.
 *
 * @param {number} xp - XP earned this week
 * @returns {number} Estimated pages read
 */
function estimatePagesFromXP(xp) {
  if (!xp || xp <= 0) return 0;
  // Assume roughly 60% of XP comes from page reading (+10 XP/page)
  return Math.round((xp * 0.6) / 10);
}

/**
 * Runs the weekly report notification job.
 *
 * - Runs every Sunday at 19:00 (server local time)
 * - Queries users where notificationPrefs.enabled == true AND notificationPrefs.weeklyReport == true
 * - For each user, gathers stats: xpThisWeek, streakDays, estimated pages
 * - Sends FCM with weekly summary message
 *
 * NOTE: xpThisWeek reset to 0 should be handled by a separate scheduled job
 * (e.g., a Cloud Function or another cron task running at Monday 00:00).
 * This job only reads and reports the data.
 *
 * All times are local to the server (Raspberry Pi).
 */
async function runWeeklyReport() {
  log("Running weekly report — Sunday 19:00");

  const db = admin.firestore();

  let sentCount = 0;
  let skippedCount = 0;
  let totalUsers = 0;

  try {
    // Query users with notifications enabled and weekly report on
    const snapshot = await db
      .collection("users")
      .where("notificationPrefs.enabled", "==", true)
      .where("notificationPrefs.weeklyReport", "==", true)
      .get();

    totalUsers = snapshot.size;
    log(`Found ${totalUsers} users with weekly report enabled`);

    const notificationPromises = snapshot.docs.map(async (doc) => {
      const user = doc.data();
      const userId = doc.id;

      try {
        // Skip if no FCM token
        if (!user.fcmToken) {
          skippedCount++;
          return;
        }

        const displayName = user.displayName || "Reader";
        const xpThisWeek = user.xpThisWeek || 0;
        const streakDays = user.streakDays || 0;
        const estimatedPages = estimatePagesFromXP(xpThisWeek);

        // Skip if user had zero activity this week
        if (xpThisWeek === 0 && streakDays === 0) {
          skippedCount++;
          log(`Skipping user ${userId} — no activity this week`);
          return;
        }

        const message = getWeeklyReportMessage(displayName, xpThisWeek, streakDays, estimatedPages);

        await sendPushNotification(user.fcmToken, message.title, message.body, {
          type: "weekly_report",
          xpThisWeek: xpThisWeek.toString(),
          streakDays: streakDays.toString(),
          estimatedPages: estimatedPages.toString(),
        });

        sentCount++;
      } catch (error) {
        log(`Failed to send weekly report to user ${userId}: ${error.message}`);
      }
    });

    await Promise.all(notificationPromises);
  } catch (error) {
    log(`Error in weekly report: ${error.message}`);
  }

  log(
    `Complete: ${totalUsers} eligible, ${sentCount} sent, ` +
    `${skippedCount} skipped, ${totalUsers - sentCount - skippedCount} failed`
  );
}

module.exports = { runWeeklyReport };
