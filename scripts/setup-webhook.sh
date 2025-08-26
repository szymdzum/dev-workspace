#!/bin/bash
# Use webhooks, not polling
# Setup GitHub webhook for intelligent fix triggering

echo "🪝 Setting up GitHub webhook for smart fixes..."

# Create webhook payload
WEBHOOK_PAYLOAD='{
  "name": "web",
  "active": true,
  "events": ["push", "pull_request"],
  "config": {
    "url": "https://your-agent.com/fix-maybe",
    "content_type": "json",
    "insecure_ssl": "0"
  }
}'

# Create the webhook
echo "Creating webhook..."
gh api repos/:owner/:repo/hooks \
  --method POST \
  --input - <<< "$WEBHOOK_PAYLOAD"

echo "✅ Webhook created!"
echo "📍 URL: https://your-agent.com/fix-maybe"
echo "📡 Events: push, pull_request"

# List existing webhooks to verify
echo ""
echo "🔍 Current webhooks:"
gh api repos/:owner/:repo/hooks --jq '.[] | {id: .id, url: .config.url, events: .events}'