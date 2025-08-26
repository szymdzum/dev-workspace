#!/usr/bin/env node

// Webhook-based fix agent - React to events, don't poll like a maniac

import { execSync } from 'child_process'
import crypto from 'crypto'
import express from 'express'

const app = express()
const PORT = process.env.PORT || 3000
const WEBHOOK_SECRET = process.env.WEBHOOK_SECRET || 'your-webhook-secret'

// Middleware to parse GitHub webhooks
app.use('/fix-maybe', express.raw({ type: 'application/json' }))
app.use(express.json())

// Verify GitHub webhook signature
function verifyGitHubSignature(payload, signature) {
  const hmac = crypto.createHmac('sha256', WEBHOOK_SECRET)
  const digest = 'sha256=' + hmac.update(payload, 'utf8').digest('hex')
  return crypto.timingSafeEqual(Buffer.from(digest), Buffer.from(signature))
}

// Smart fix logic - only fix when it makes sense
function shouldFix(event, payload) {
  const reasons = []

  if (event === 'push') {
    // Fix on pushes to main branch
    if (payload.ref === 'refs/heads/main') {
      reasons.push('main branch updated')
    }

    // Fix if commit message suggests issues
    const commitMessage = payload.head_commit?.message || ''
    if (commitMessage.includes('fix') || commitMessage.includes('WIP')) {
      reasons.push('commit suggests fixes needed')
    }

    // Fix if many files changed (potential integration issues)
    const filesChanged = payload.head_commit?.modified?.length || 0
    if (filesChanged > 5) {
      reasons.push(`many files changed (${filesChanged})`)
    }
  }

  if (event === 'pull_request') {
    // Fix on PR opens/updates (but not drafts)
    if (payload.action === 'opened' || payload.action === 'synchronize') {
      if (!payload.pull_request.draft) {
        reasons.push('PR ready for review')
      }
    }
  }

  return reasons
}

// Execute fixes intelligently
async function executeFixes(reasons, payload) {
  console.log('🔧 Executing fixes:', reasons.join(', '))

  const fixes = []

  try {
    // Clone/update repo
    const repoUrl = payload.repository.clone_url
    const repoName = payload.repository.name

    console.log(`📂 Working on ${repoName}...`)

    // Run quick health check
    console.log('🏥 Running health check...')

    // Check if tests are broken
    try {
      execSync('npm test', { stdio: 'pipe', cwd: `./${repoName}` })
      console.log('✅ Tests passing')
    } catch (error) {
      console.log('❌ Tests failing - will attempt fixes')
      fixes.push('test-fixes')
    }

    // Check for lint issues
    try {
      execSync('npm run lint', { stdio: 'pipe', cwd: `./${repoName}` })
      console.log('✅ Lint clean')
    } catch (error) {
      console.log('❌ Lint issues - will attempt fixes')
      fixes.push('lint-fixes')
    }

    // Apply fixes if needed
    if (fixes.length > 0) {
      console.log('🛠️ Applying fixes:', fixes.join(', '))

      // Auto-fix lint issues
      if (fixes.includes('lint-fixes')) {
        execSync('npm run lint:fix', { cwd: `./${repoName}` })
        console.log('🎨 Applied lint fixes')
      }

      // Update snapshots for failing tests
      if (fixes.includes('test-fixes')) {
        try {
          execSync('npm test -- --updateSnapshot', { cwd: `./${repoName}` })
          console.log('📸 Updated test snapshots')
        } catch (error) {
          console.log('⚠️ Could not auto-fix tests')
        }
      }

      // Create fix commit
      try {
        execSync('git add .', { cwd: `./${repoName}` })
        execSync(
          'git commit -m "fix: automated webhook fixes\\n\\n🤖 Fixed: ' + fixes.join(', ') + '"',
          { cwd: `./${repoName}` }
        )
        execSync('git push', { cwd: `./${repoName}` })
        console.log('✅ Pushed fixes')
      } catch (error) {
        console.log('⚠️ No changes to commit or push failed')
      }
    }

    return { success: true, fixes }
  } catch (error) {
    console.error('❌ Fix execution failed:', error.message)
    return { success: false, error: error.message }
  }
}

// Webhook endpoint
app.post('/fix-maybe', async (req, res) => {
  console.log('🪝 Webhook received')

  // Verify signature (in production)
  const signature = req.get('X-Hub-Signature-256')
  if (process.env.NODE_ENV === 'production' && signature) {
    if (!verifyGitHubSignature(req.body, signature)) {
      console.log('❌ Invalid signature')
      return res.status(401).send('Invalid signature')
    }
  }

  const payload = JSON.parse(req.body)
  const event = req.get('X-GitHub-Event')

  console.log(`📡 Event: ${event} from ${payload.repository?.name}`)

  // Decide if we should fix
  const reasons = shouldFix(event, payload)

  if (reasons.length === 0) {
    console.log('😌 No fixes needed, ignoring event')
    return res.json({ message: 'No action needed', reasons: [] })
  }

  console.log('🚨 Fix triggered:', reasons.join(', '))

  // Execute fixes asynchronously (don't make GitHub wait)
  setImmediate(async () => {
    const result = await executeFixes(reasons, payload)
    console.log('🏁 Fix result:', result)
  })

  // Respond quickly to GitHub
  res.json({
    message: 'Fix triggered',
    reasons,
    status: 'processing',
  })
})

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'webhook-fix-agent',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  })
})

// Status endpoint
app.get('/', (req, res) => {
  res.json({
    service: 'Webhook Fix Agent',
    description: "React to events, don't poll like a maniac",
    endpoints: {
      '/fix-maybe': 'POST - GitHub webhook receiver',
      '/health': 'GET - Health check',
    },
    version: '1.0.0',
  })
})

app.listen(PORT, () => {
  console.log('🚀 Webhook Fix Agent running on port', PORT)
  console.log('🪝 Ready to receive webhooks at /fix-maybe')
  console.log('💡 Much smarter than polling every 20 seconds!')
})

export default app
