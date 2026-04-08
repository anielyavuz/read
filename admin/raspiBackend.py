#!/usr/bin/env python3
"""
Bookpulse Raspberry Pi Backend Service
=======================================
Runs as a persistent systemd service on Raspberry Pi.
Handles scheduled challenge notifications via FCM and periodic Firestore jobs.

See infoRaspiBackend.md for setup, architecture, and extension guide.
"""

import os
import sys
import time
import signal
import logging
import schedule
from datetime import datetime, timedelta, timezone

import firebase_admin
from firebase_admin import credentials, firestore, messaging

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

CREDENTIAL_FILE = os.environ.get(
    "BOOKPULSE_FIREBASE_CRED",
    os.path.join(os.path.dirname(__file__),
                 "bookpulseapp-firebase-adminsdk-fbsvc-6c8ae79c7c.json"),
)

LOG_LEVEL = os.environ.get("BOOKPULSE_LOG_LEVEL", "INFO").upper()

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

logging.basicConfig(
    level=getattr(logging, LOG_LEVEL, logging.INFO),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger("bookpulse-backend")

# ---------------------------------------------------------------------------
# Firebase Init
# ---------------------------------------------------------------------------

if not firebase_admin._apps:
    cred = credentials.Certificate(CREDENTIAL_FILE)
    firebase_admin.initialize_app(cred)

db = firestore.client()

# ---------------------------------------------------------------------------
# Graceful Shutdown
# ---------------------------------------------------------------------------

_running = True


def _shutdown(signum, frame):
    global _running
    logger.info("Received signal %s, shutting down gracefully...", signum)
    _running = False


signal.signal(signal.SIGTERM, _shutdown)
signal.signal(signal.SIGINT, _shutdown)

# ---------------------------------------------------------------------------
# Helper: FCM Send
# ---------------------------------------------------------------------------


def send_fcm(token: str, title: str, body: str, data: dict | None = None):
    """Send a data-only FCM message (Flutter onMessage always fires)."""
    payload = {"title": title, "body": body, "type": "push"}
    if data:
        payload.update(data)

    message = messaging.Message(
        data=payload,
        android=messaging.AndroidConfig(priority="high"),
        apns=messaging.APNSConfig(
            headers={"apns-priority": "10"},
            payload=messaging.APNSPayload(
                aps=messaging.Aps(content_available=True),
            ),
        ),
        token=token,
    )
    try:
        response = messaging.send(message)
        logger.debug("FCM sent to ...%s -> %s", token[-8:], response)
        return response
    except messaging.UnregisteredError:
        logger.warning("Token unregistered: ...%s", token[-8:])
        return None
    except Exception as e:
        logger.error("FCM send failed: %s", e)
        return None


# ---------------------------------------------------------------------------
# Job: Challenge Last-Day Reminders
# ---------------------------------------------------------------------------


def job_challenge_last_day_reminders():
    """
    Finds challenges ending tomorrow and sends FCM to participants
    who have challenge notifications enabled.
    Runs daily at 10:00.
    """
    logger.info("Running: challenge_last_day_reminders")
    now = datetime.now(timezone.utc)
    tomorrow_start = (now + timedelta(days=1)).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    tomorrow_end = tomorrow_start + timedelta(days=1)

    try:
        challenges_ref = db.collection("challenges")
        ending_soon = (
            challenges_ref
            .where("endDate", ">=", tomorrow_start)
            .where("endDate", "<", tomorrow_end)
            .stream()
        )

        sent_count = 0
        for cdoc in ending_soon:
            challenge = cdoc.to_dict()
            challenge_id = cdoc.id
            title = challenge.get("title", "Challenge")
            c_type = challenge.get("type", "sprint")

            # Get participants
            participants = (
                db.collection("challenges")
                .document(challenge_id)
                .collection("participants")
                .stream()
            )

            for pdoc in participants:
                uid = pdoc.id
                user_doc = db.collection("users").document(uid).get()
                if not user_doc.exists:
                    continue

                user_data = user_doc.to_dict()
                token = user_data.get("fcmToken")
                if not token:
                    continue

                # Check notification preferences
                prefs = user_data.get("notificationPrefs", {})
                if not prefs.get("enabled", True):
                    continue
                if not prefs.get("challengeNotifications", True):
                    continue

                # Build body based on challenge type
                body = _build_last_day_body(c_type, title, challenge)

                send_fcm(
                    token=token,
                    title="Challenge ends tomorrow!",
                    body=body,
                    data={"challengeId": challenge_id},
                )
                sent_count += 1

        logger.info("challenge_last_day_reminders: sent %d notifications", sent_count)

    except Exception as e:
        logger.error("challenge_last_day_reminders failed: %s", e)


def _build_last_day_body(c_type: str, title: str, challenge: dict) -> str:
    """Build notification body based on challenge type."""
    if c_type in ("pages", "readAlong"):
        target = challenge.get("targetPages", 0)
        return f'"{title}" ends tomorrow. Push for your page goal ({target} pages)!'
    elif c_type == "sprint":
        return f'"{title}" ends tomorrow. Every minute counts — start a focus session!'
    elif c_type == "genre":
        return f'"{title}" ends tomorrow. Finish a book to climb the ranks!'
    return f'"{title}" ends tomorrow. Give it your all!'


# ---------------------------------------------------------------------------
# Job: Challenge Mid-Point Reminders
# ---------------------------------------------------------------------------


def job_challenge_midpoint_reminders():
    """
    Finds challenges at their mid-point today and sends FCM to participants.
    Only for challenges longer than 7 days.
    Runs daily at 10:00.
    """
    logger.info("Running: challenge_midpoint_reminders")
    now = datetime.now(timezone.utc)
    today = now.replace(hour=0, minute=0, second=0, microsecond=0)

    try:
        # Get all active challenges
        challenges_ref = db.collection("challenges")
        active = (
            challenges_ref
            .where("endDate", ">", now)
            .stream()
        )

        sent_count = 0
        for cdoc in active:
            challenge = cdoc.to_dict()
            challenge_id = cdoc.id

            start_date = challenge.get("startDate")
            end_date = challenge.get("endDate")
            if not start_date or not end_date:
                continue

            # Convert Firestore timestamps to datetime
            if hasattr(start_date, 'timestamp'):
                start_dt = start_date.replace(tzinfo=timezone.utc) if start_date.tzinfo is None else start_date
            else:
                continue
            if hasattr(end_date, 'timestamp'):
                end_dt = end_date.replace(tzinfo=timezone.utc) if end_date.tzinfo is None else end_date
            else:
                continue

            total_days = (end_dt - start_dt).days
            if total_days <= 7:
                continue

            mid_date = start_dt + timedelta(days=total_days // 2)
            mid_day = mid_date.replace(hour=0, minute=0, second=0, microsecond=0)

            if mid_day.date() != today.date():
                continue

            title = challenge.get("title", "Challenge")
            c_type = challenge.get("type", "sprint")

            # Get participants
            participants = (
                db.collection("challenges")
                .document(challenge_id)
                .collection("participants")
                .stream()
            )

            for pdoc in participants:
                uid = pdoc.id
                user_doc = db.collection("users").document(uid).get()
                if not user_doc.exists:
                    continue

                user_data = user_doc.to_dict()
                token = user_data.get("fcmToken")
                if not token:
                    continue

                prefs = user_data.get("notificationPrefs", {})
                if not prefs.get("enabled", True):
                    continue
                if not prefs.get("challengeNotifications", True):
                    continue

                body = _build_midpoint_body(c_type, title, challenge)
                send_fcm(
                    token=token,
                    title="Halfway there!",
                    body=body,
                    data={"challengeId": challenge_id},
                )
                sent_count += 1

        logger.info("challenge_midpoint_reminders: sent %d notifications", sent_count)

    except Exception as e:
        logger.error("challenge_midpoint_reminders failed: %s", e)


def _build_midpoint_body(c_type: str, title: str, challenge: dict) -> str:
    """Build mid-point notification body based on challenge type."""
    if c_type in ("pages", "readAlong"):
        target = challenge.get("targetPages", 0)
        return f'You\'re halfway through "{title}"! Target: {target} pages.'
    elif c_type == "sprint":
        target = challenge.get("targetMinutes", 0)
        return f'Halfway through "{title}"! Target: {target} minutes.'
    elif c_type == "genre":
        target = challenge.get("targetBooks", 0)
        return f'Halfway through "{title}"! Target: {target} books.'
    return f'You\'re halfway through "{title}"! Keep going!'


# ---------------------------------------------------------------------------
# Job: Streak Risk Reminders (20:00 UTC)
# ---------------------------------------------------------------------------


def job_streak_risk_reminders():
    """
    Finds users who haven't read today and have an active streak.
    Sends FCM to warn them their streak is at risk.
    Runs daily at 20:00.
    """
    logger.info("Running: streak_risk_reminders")
    now = datetime.now(timezone.utc)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)

    try:
        users_ref = db.collection("users")
        # Get users with active streaks
        users_with_streak = (
            users_ref
            .where("streakDays", ">", 0)
            .stream()
        )

        sent_count = 0
        for udoc in users_with_streak:
            user_data = udoc.to_dict()
            uid = udoc.id

            # Check if they already read today
            last_read = user_data.get("lastReadDate")
            if last_read:
                if hasattr(last_read, 'timestamp'):
                    last_read_dt = last_read
                else:
                    continue
                if last_read_dt >= today_start:
                    continue  # Already read today, skip

            token = user_data.get("fcmToken")
            if not token:
                continue

            prefs = user_data.get("notificationPrefs", {})
            if not prefs.get("enabled", True):
                continue
            if not prefs.get("streakReminder", True):
                continue

            streak = user_data.get("streakDays", 0)
            send_fcm(
                token=token,
                title="Your streak is at risk!",
                body=f"Your {streak}-day streak is on the line! Just 5 minutes of reading keeps it alive.",
            )
            sent_count += 1

        logger.info("streak_risk_reminders: sent %d notifications", sent_count)

    except Exception as e:
        logger.error("streak_risk_reminders failed: %s", e)


# ---------------------------------------------------------------------------
# Job: Health Check Log
# ---------------------------------------------------------------------------


def job_health_check():
    """Simple heartbeat log for monitoring."""
    logger.info("Health check OK — service running. Time: %s", datetime.now())


# ---------------------------------------------------------------------------
# Schedule Setup
# ---------------------------------------------------------------------------


def setup_schedule():
    """Configure all scheduled jobs."""
    # Challenge notifications at 10:00 UTC
    schedule.every().day.at("10:00").do(job_challenge_last_day_reminders)
    schedule.every().day.at("10:00").do(job_challenge_midpoint_reminders)

    # Streak risk at 20:00 UTC
    schedule.every().day.at("20:00").do(job_streak_risk_reminders)

    # Health check every 6 hours
    schedule.every(6).hours.do(job_health_check)

    logger.info("Schedule configured: %d jobs", len(schedule.get_jobs()))
    for job in schedule.get_jobs():
        logger.info("  -> %s", job)


# ---------------------------------------------------------------------------
# Main Loop
# ---------------------------------------------------------------------------


def main():
    logger.info("=" * 50)
    logger.info("Bookpulse Backend Service starting...")
    logger.info("Firebase credential: %s", CREDENTIAL_FILE)
    logger.info("Log level: %s", LOG_LEVEL)
    logger.info("=" * 50)

    setup_schedule()

    # Run initial health check
    job_health_check()

    while _running:
        schedule.run_pending()
        time.sleep(30)

    logger.info("Service stopped.")


if __name__ == "__main__":
    main()
