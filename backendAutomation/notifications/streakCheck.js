const admin = require("firebase-admin");
const { getCompanionMessage, getStreakRiskMessage } = require("./messageTemplates");
const { sendPushNotification } = require("./sendNotification");

function log(message) {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] [streakCheck] ${message}`);
}

/**
 * Returns the start of today (server local time) as a Date object — midnight 00:00:00.000.
 */
function getTodayStart() {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);
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
 * Runs the streak risk check.
 *
 * - Runs daily at 20:00 (server local time)
 * - Queries users where notificationPrefs.enabled == true AND notificationPrefs.streakReminder == true
 * - For each user with streakDays > 0, checks lastReadDate
 * - If the user has NOT read today, sends a streak risk notification
 * - Includes the current streak count in the message
 *
 * All times are local to the server (Raspberry Pi).
 */
async function runStreakRiskCheck() {
  log("Running streak risk check at 20:00");

  const db = admin.firestore();

  let sentCount = 0;
  let skippedCount = 0;
  let totalAtRisk = 0;

  try {
    // Query users with notifications enabled and streak reminders on
    const snapshot = await db
      .collection("users")
      .where("notificationPrefs.enabled", "==", true)
      .where("notificationPrefs.streakReminder", "==", true)
      .get();

    log(`Found ${snapshot.size} users with streak reminders enabled`);

    // Filter to users with active streaks who haven't read today
    const atRiskUsers = snapshot.docs.filter((doc) => {
      const data = doc.data();

      // Only check users with active streaks
      if (!data.streakDays || data.streakDays <= 0) return false;

      // Skip users who already read today
      if (hasReadToday(data.lastReadDate)) return false;

      return true;
    });

    totalAtRisk = atRiskUsers.length;
    log(`Found ${totalAtRisk} users at risk of losing their streak`);

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
        const displayName = user.displayName || "Reader";
        const streakDays = user.streakDays || 1;

        // Use companion-personality message if breed info is available,
        // otherwise fall back to generic streak risk template
        let message;
        if (user.companionBreed) {
          message = getCompanionMessage(breed, companionName, "streak_risk", streakDays);
        } else {
          message = getStreakRiskMessage(displayName, streakDays);
        }

        await sendPushNotification(user.fcmToken, message.title, message.body, {
          type: "streak_risk",
          companionBreed: breed,
          companionName: companionName,
          streakDays: streakDays.toString(),
        });

        sentCount++;
      } catch (error) {
        log(`Failed to send streak risk notification to user ${userId}: ${error.message}`);
      }
    });

    await Promise.all(notificationPromises);
  } catch (error) {
    log(`Error in streak risk check: ${error.message}`);
  }

  log(
    `Complete: ${totalAtRisk} at risk, ${sentCount} notified, ` +
    `${skippedCount} skipped (no token), ${totalAtRisk - sentCount - skippedCount} failed`
  );
}

module.exports = { runStreakRiskCheck };
