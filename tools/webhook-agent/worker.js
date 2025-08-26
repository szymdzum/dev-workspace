// Cloudflare Worker webhook agent - Deploy anywhere, no server needed
// Much better than polling every 20 seconds like a maniac

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url)

    // Route requests
    if (url.pathname === '/fix-maybe' && request.method === 'POST') {
      return handleWebhook(request, env)
    }

    if (url.pathname === '/health') {
      return new Response(
        JSON.stringify({
          status: 'healthy',
          service: 'webhook-fix-agent-worker',
          timestamp: new Date().toISOString(),
        }),
        {
          headers: { 'Content-Type': 'application/json' },
        }
      )
    }

    // Default response
    return new Response(
      JSON.stringify({
        service: 'Webhook Fix Agent (Cloudflare Worker)',
        description: "React to events, don't poll like a maniac",
        endpoints: {
          '/fix-maybe': 'POST - GitHub webhook receiver',
          '/health': 'GET - Health check',
        },
      }),
      {
        headers: { 'Content-Type': 'application/json' },
      }
    )
  },
}

async function handleWebhook(request, env) {
  try {
    const payload = await request.json()
    const event = request.headers.get('X-GitHub-Event')

    console.log(`📡 Webhook: ${event} from ${payload.repository?.name}`)

    // Smart decision: should we fix?
    const reasons = shouldFix(event, payload)

    if (reasons.length === 0) {
      return new Response(
        JSON.stringify({
          message: 'No action needed',
          reasons: [],
        }),
        {
          headers: { 'Content-Type': 'application/json' },
        }
      )
    }

    // Trigger GitHub Action to do the actual fixes
    // (Workers can't git clone/push, but they can trigger actions)
    const triggerResult = await triggerFixAction(payload, reasons, env)

    return new Response(
      JSON.stringify({
        message: 'Fix triggered',
        reasons,
        action: triggerResult,
      }),
      {
        headers: { 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    console.error('Webhook error:', error)
    return new Response(
      JSON.stringify({
        error: 'Webhook processing failed',
        message: error.message,
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    )
  }
}

function shouldFix(event, payload) {
  const reasons = []

  if (event === 'push') {
    // Only fix main branch pushes
    if (payload.ref === 'refs/heads/main') {
      reasons.push('main branch updated')
    }

    // Fix if commit suggests issues
    const commitMessage = payload.head_commit?.message || ''
    if (
      commitMessage.toLowerCase().includes('fix') ||
      commitMessage.toLowerCase().includes('wip') ||
      commitMessage.toLowerCase().includes('broke')
    ) {
      reasons.push('commit suggests fixes needed')
    }

    // Fix if many files changed
    const filesChanged = payload.head_commit?.modified?.length || 0
    if (filesChanged > 10) {
      reasons.push(`large changeset (${filesChanged} files)`)
    }
  }

  if (event === 'pull_request') {
    if (
      (payload.action === 'opened' || payload.action === 'synchronize') &&
      !payload.pull_request.draft
    ) {
      reasons.push('PR ready for review')
    }
  }

  // Skip if commit already looks like a fix
  const commitMessage = payload.head_commit?.message || payload.pull_request?.title || ''
  if (commitMessage.startsWith('fix:') || commitMessage.includes('automated')) {
    return [] // Don't fix fixes
  }

  return reasons
}

async function triggerFixAction(payload, reasons, env) {
  // Trigger GitHub Action workflow_dispatch to do the actual fixing
  const [owner, repo] = payload.repository.full_name.split('/')

  const actionPayload = {
    ref: payload.ref || 'main',
    inputs: {
      reason: reasons.join(', '),
      commit_sha: payload.head_commit?.id || payload.pull_request?.head?.sha,
      triggered_by: 'webhook',
    },
  }

  try {
    const response = await fetch(
      `https://api.github.com/repos/${owner}/${repo}/actions/workflows/smart-fix.yml/dispatches`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${env.GITHUB_TOKEN}`,
          Accept: 'application/vnd.github.v3+json',
          'User-Agent': 'webhook-fix-agent',
        },
        body: JSON.stringify(actionPayload),
      }
    )

    if (response.ok) {
      return { success: true, message: 'GitHub Action triggered' }
    } else {
      const error = await response.text()
      return { success: false, error }
    }
  } catch (error) {
    return { success: false, error: error.message }
  }
}
