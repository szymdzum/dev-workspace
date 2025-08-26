# Webhook Fix Agent

**Use webhooks, not polling** - React to events intelligently instead of checking every 20 seconds like a maniac.

## Setup

### 1. Create GitHub Webhook

```bash
# Run the setup script
./scripts/setup-webhook.sh

# Or manually via API
gh api repos/:owner/:repo/hooks --method POST --input webhook-payload.json
```

### 2. Deploy Agent

**Option A: Cloudflare Worker (Recommended)**
```bash
cd tools/webhook-agent
wrangler deploy worker.js --name webhook-fix-agent
```

**Option B: Node.js Server**
```bash
cd tools/webhook-agent
npm install
npm start
```

### 3. Configure Secrets

```bash
# For Cloudflare Worker
wrangler secret put GITHUB_TOKEN

# For local development
export WEBHOOK_SECRET=your-webhook-secret
export GITHUB_TOKEN=your-github-token
```

## How It Works

### Smart Triggering
Only fixes when it actually makes sense:

- ✅ Push to main branch
- ✅ Large changesets (>10 files)
- ✅ Commits with "fix" or "WIP" in message
- ✅ Non-draft PRs opened/updated
- ❌ Already fixed commits
- ❌ Draft PRs
- ❌ Feature branches (unless specified)

### Intelligent Fixes
1. **Health Check**: Tests, lint, types
2. **Auto-Fix**: Safe lint issues, snapshots
3. **Single Commit**: One clean fix commit
4. **GitHub Action**: Triggers existing smart-fix workflow

### Benefits vs Polling

| Polling Every 20s | Webhook Approach |
|---|---|
| 4,320 checks/day | ~10 events/day |
| Always running | Event-driven |
| Wastes resources | Efficient |
| Fixes random stuff | Fixes actual issues |
| Spam commits | Contextual fixes |

## Endpoints

- `POST /fix-maybe` - GitHub webhook receiver
- `GET /health` - Health check
- `GET /` - Service info

## Configuration

**Environment Variables:**
- `WEBHOOK_SECRET` - GitHub webhook secret
- `GITHUB_TOKEN` - Token for triggering actions
- `PORT` - Server port (default: 3000)

**Smart Fix Triggers:**
```javascript
// Examples of what triggers fixes
{
  "push to main": "Always check main branch",
  "large changeset": ">10 files modified", 
  "commit keywords": "fix, WIP, broke in message",
  "PR events": "opened, synchronize (non-draft)"
}
```

## Deployment

### Cloudflare Worker
```bash
wrangler deploy
# Set your webhook URL to: https://your-worker.workers.dev/fix-maybe
```

### Railway/Render/Vercel
```bash
# Deploy to any platform that supports Node.js
# Set webhook URL to: https://your-app.com/fix-maybe
```

## Monitoring

Check webhook deliveries in GitHub:
```
Settings → Webhooks → Recent Deliveries
```

View agent logs:
```bash
wrangler tail  # For Cloudflare
pm2 logs       # For Node.js
```

---

🎯 **Result**: Intelligent, event-driven fixes instead of manic polling every 20 seconds!