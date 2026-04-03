const admin = require("firebase-admin");
const cron = require("node-cron");
const path = require("path");

const { runDailyReminder } = require("./notifications/dailyReminder");
const { runStreakRiskCheck } = require("./notifications/streakCheck");
const { runWeeklyReport } = require("./notifications/weeklyReport");

// Initialize Firebase Admin with service account
const serviceAccount = require(path.join(__dirname, "serviceAccountKey.json"));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

function log(message) {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${message}`);
}

log("BookPulse Backend Automation started");
log("Firebase Admin initialized successfully");

// ---------------------------------------------------------------------------
// Schedule: Daily reading reminder — every hour from 06:00 to 22:00
// Checks each user's weekday/weekend reading time and sends pre-reminders
// Quiet hours (23:00-07:00) are also enforced inside the job itself
// ---------------------------------------------------------------------------
cron.schedule("0 6-22 * * *", async () => {
  log("CRON: Running daily reading reminder check...");
  try {
    await runDailyReminder();
    log("CRON: Daily reading reminder check completed");
  } catch (error) {
    log(`CRON ERROR: Daily reading reminder failed: ${error.message}`);
    console.error(error);
  }
});

// ---------------------------------------------------------------------------
// Schedule: Streak risk check — daily at 20:00 (server local time)
// Notifies users with active streaks who haven't read today
// ---------------------------------------------------------------------------
cron.schedule("0 20 * * *", async () => {
  log("CRON: Running streak risk check...");
  try {
    await runStreakRiskCheck();
    log("CRON: Streak risk check completed");
  } catch (error) {
    log(`CRON ERROR: Streak risk check failed: ${error.message}`);
    console.error(error);
  }
});

// ---------------------------------------------------------------------------
// Schedule: Weekly report — every Sunday at 19:00 (server local time)
// Sends weekly summary with XP, streak, and estimated pages
// ---------------------------------------------------------------------------
cron.schedule("0 19 * * 0", async () => {
  log("CRON: Running weekly report...");
  try {
    await runWeeklyReport();
    log("CRON: Weekly report completed");
  } catch (error) {
    log(`CRON ERROR: Weekly report failed: ${error.message}`);
    console.error(error);
  }
});

log("Cron jobs scheduled:");
log("  - Daily reading reminder: every hour from 06:00 to 22:00 (0 6-22 * * *)");
log("  - Streak risk check: daily at 20:00 (0 20 * * *)");
log("  - Weekly report: Sunday at 19:00 (0 19 * * 0)");
log("All times are local to the server (Raspberry Pi).");
log("Waiting for scheduled tasks...");
