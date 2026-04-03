import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Export notification functions
export { dailyReadingReminder } from "./notifications/dailyReminder";
export { streakRiskCheck } from "./notifications/streakCheck";
export { dailyGoalReminder } from "./notifications/dailyGoalReminder";
export { weeklySummary } from "./notifications/weeklySummary";
