const admin = require("firebase-admin");

function log(message) {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${message}`);
}

/**
 * Sends a push notification via Firebase Cloud Messaging.
 *
 * @param {string} token - FCM device token
 * @param {string} title - Notification title
 * @param {string} body - Notification body text
 * @param {Object} data - Optional key-value data payload
 */
async function sendPushNotification(token, title, body, data) {
  if (!token) {
    log("sendPushNotification called with empty token, skipping.");
    return;
  }

  const message = {
    token,
    notification: {
      title,
      body,
    },
    data: data || {},
    android: {
      priority: "high",
      notification: {
        channelId: "bookpulse_companion",
        sound: "default",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);
    log(`Notification sent successfully: ${response}`);
  } catch (error) {
    if (
      error.code === "messaging/invalid-registration-token" ||
      error.code === "messaging/registration-token-not-registered"
    ) {
      log(`Invalid or expired FCM token: ${token}. Consider removing from Firestore.`);
    } else {
      log(`Error sending notification: ${error.message}`);
    }
    throw error;
  }
}

module.exports = { sendPushNotification };
