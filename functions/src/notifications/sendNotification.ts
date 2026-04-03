import * as admin from "firebase-admin";
import { logger } from "firebase-functions/v2";

/**
 * Sends a data-only push notification via Firebase Cloud Messaging.
 * Data-only messages always reach Flutter's onMessage handler in foreground,
 * unlike notification payloads which Android handles natively.
 *
 * @param token - FCM device token
 * @param title - Notification title (sent in data payload)
 * @param body - Notification body text (sent in data payload)
 * @param data - Optional extra key-value data payload
 */
export async function sendPushNotification(
  token: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<void> {
  if (!token) {
    logger.warn("sendPushNotification called with empty token, skipping.");
    return;
  }

  const message: admin.messaging.Message = {
    token,
    data: {
      title,
      body,
      ...(data ?? {}),
    },
    android: {
      priority: "high",
    },
    apns: {
      payload: {
        aps: {
          "content-available": 1,
          sound: "default",
          badge: 1,
          alert: {
            title,
            body,
          },
        },
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);
    logger.info(`Notification sent successfully: ${response}`);
  } catch (error: unknown) {
    if (
      error instanceof Error &&
      "code" in error &&
      ((error as { code: string }).code === "messaging/invalid-registration-token" ||
        (error as { code: string }).code === "messaging/registration-token-not-registered")
    ) {
      logger.warn(`Invalid or expired FCM token: ${token}. Consider removing from Firestore.`);
    } else {
      logger.error("Error sending notification:", error);
    }
    throw error;
  }
}
