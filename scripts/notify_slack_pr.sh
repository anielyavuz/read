#!/bin/bash
# Bookpulse — Slack PR Notification Script
# Usage: ./scripts/notify_slack_pr.sh <pr_url> <branch_name> <pr_title> <summary>
#
# Slack webhook URL is read from .slack_webhook file (gitignored)
# or passed via SLACK_WEBHOOK_URL env var.

set -euo pipefail

PR_URL="${1:-}"
BRANCH="${2:-}"
PR_TITLE="${3:-}"
SUMMARY="${4:-}"

if [ -z "$PR_URL" ] || [ -z "$PR_TITLE" ]; then
  echo "Usage: $0 <pr_url> <branch_name> <pr_title> <summary>"
  exit 1
fi

# Read webhook URL
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WEBHOOK_FILE="$PROJECT_DIR/.slack_webhook"

if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
  WEBHOOK="$SLACK_WEBHOOK_URL"
elif [ -f "$WEBHOOK_FILE" ]; then
  WEBHOOK="$(cat "$WEBHOOK_FILE" | tr -d '[:space:]')"
else
  echo "Error: No Slack webhook URL found."
  echo "Create .slack_webhook file or set SLACK_WEBHOOK_URL env var."
  exit 1
fi

# Build Slack message payload
PAYLOAD=$(cat <<ENDJSON
{
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "📱 New PR from Mobile Claude Code",
        "emoji": true
      }
    },
    {
      "type": "section",
      "fields": [
        {
          "type": "mrkdwn",
          "text": "*Branch:*\n\`${BRANCH}\`"
        },
        {
          "type": "mrkdwn",
          "text": "*PR:*\n<${PR_URL}|${PR_TITLE}>"
        }
      ]
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Summary:*\n${SUMMARY}"
      }
    },
    {
      "type": "divider"
    },
    {
      "type": "context",
      "elements": [
        {
          "type": "mrkdwn",
          "text": "📖 Bookpulse | Review & merge from PC"
        }
      ]
    }
  ]
}
ENDJSON
)

# Send to Slack
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  "$WEBHOOK")

if [ "$HTTP_STATUS" = "200" ]; then
  echo "Slack notification sent successfully."
else
  echo "Slack notification failed (HTTP $HTTP_STATUS)."
  exit 1
fi
