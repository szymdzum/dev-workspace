// .claude/agents/rate-limiter.ts - Deploy this NOW
// Emergency brake for when Context Beast gets too excited

interface AgentLimits {
  maxPRsPerHour: number
  maxStackDepth: number
  maxFilesPerPR: number
  cooldownPeriod: number
  emergencyBrake: boolean
}

interface PRActivity {
  timestamp: number
  prCount: number
  stackDepth: number
  filesChanged: number
  author: 'human' | 'beast' | 'unknown'
}

export const agentGovernor: AgentLimits = {
  maxPRsPerHour: 5, // Not 500, FIVE. Your GitHub notifications thank you
  maxStackDepth: 3, // Graphite can handle more, your sanity can't
  maxFilesPerPR: 10, // Beyond this lies madness
  cooldownPeriod: 15, // Minutes of forced contemplation
  emergencyBrake: true, // Kill switch for when AI achieves consciousness
}

class AgentRateLimiter {
  private activityLog: PRActivity[] = []
  private lastEmergencyBrake = 0
  private panicMode = false

  constructor(private limits: AgentLimits = agentGovernor) {}

  // The wisdom gate - ask before you leap
  requiresApproval(changes: {
    files: number
    lines: number
    complexity?: 'low' | 'medium' | 'high'
  }): boolean {
    const reasons = []

    // File count check
    if (changes.files > this.limits.maxFilesPerPR) {
      reasons.push(`Too many files (${changes.files} > ${this.limits.maxFilesPerPR})`)
    }

    // Line count sanity check
    if (changes.lines > 500) {
      reasons.push(`Too many lines (${changes.lines} - nobody will review this)`)
    }

    // Complexity gate
    if (changes.complexity === 'high') {
      reasons.push('High complexity changes need human oversight')
    }

    // Current activity check
    if (this.isRateLimited()) {
      reasons.push('Rate limit exceeded - slow down there, speedy')
    }

    // Panic mode override
    if (this.panicMode) {
      reasons.push('PANIC MODE ACTIVE - all changes require approval')
    }

    if (reasons.length > 0) {
      console.warn('🚨 Agent approval required:', reasons.join(', '))
      return true
    }

    return false
  }

  // The guardian - checks if we're going too fast
  isRateLimited(): boolean {
    this.cleanOldActivity()

    const recentActivity = this.getRecentActivity()
    const prCount = recentActivity.reduce((sum, activity) => sum + activity.prCount, 0)
    const maxStackDepth = Math.max(...recentActivity.map(a => a.stackDepth), 0)

    // PR per hour check
    if (prCount >= this.limits.maxPRsPerHour) {
      this.triggerCooldown(`PR rate limit exceeded: ${prCount}/${this.limits.maxPRsPerHour}`)
      return true
    }

    // Stack depth check
    if (maxStackDepth >= this.limits.maxStackDepth) {
      this.triggerCooldown(`Stack too deep: ${maxStackDepth}/${this.limits.maxStackDepth}`)
      return true
    }

    return false
  }

  // Record activity (call this on every PR creation)
  recordActivity(activity: Omit<PRActivity, 'timestamp'>) {
    this.activityLog.push({
      ...activity,
      timestamp: Date.now(),
    })

    // Auto-panic if things get crazy
    if (activity.prCount > 10 || activity.stackDepth > 5) {
      this.activatePanicMode('Suspicious activity detected')
    }
  }

  // Emergency brake - stops everything
  activatePanicMode(reason: string) {
    this.panicMode = true
    this.lastEmergencyBrake = Date.now()

    console.error('🚨 PANIC MODE ACTIVATED:', reason)
    console.error('All agent activity suspended. Human intervention required.')

    // Write panic state to file for persistence
    require('fs').writeFileSync(
      '.claude/agents/PANIC_MODE.json',
      JSON.stringify(
        {
          activated: new Date().toISOString(),
          reason,
          message: 'Run `deactivatePanicMode()` when ready to resume',
        },
        null,
        2
      )
    )
  }

  // Release the emergency brake
  deactivatePanicMode() {
    this.panicMode = false

    try {
      require('fs').unlinkSync('.claude/agents/PANIC_MODE.json')
    } catch (e) {
      // File doesn't exist, that's fine
    }

    console.log('✅ Panic mode deactivated. Agents may resume (carefully).')
  }

  // Cooling down period after rate limit hit
  private triggerCooldown(reason: string) {
    const cooldownEnd = Date.now() + this.limits.cooldownPeriod * 60 * 1000

    console.warn(`⏰ Cooldown triggered: ${reason}`)
    console.warn(`Next action allowed at: ${new Date(cooldownEnd).toLocaleTimeString()}`)

    // Store cooldown state
    require('fs').writeFileSync(
      '.claude/agents/cooldown.json',
      JSON.stringify(
        {
          reason,
          endsAt: cooldownEnd,
          message: 'Agent is in cooldown. Please wait.',
        },
        null,
        2
      )
    )
  }

  // Clean up old activity (older than 1 hour)
  private cleanOldActivity() {
    const oneHourAgo = Date.now() - 60 * 60 * 1000
    this.activityLog = this.activityLog.filter(activity => activity.timestamp > oneHourAgo)
  }

  // Get activity from the last hour
  private getRecentActivity(): PRActivity[] {
    const oneHourAgo = Date.now() - 60 * 60 * 1000
    return this.activityLog.filter(activity => activity.timestamp > oneHourAgo)
  }

  // Status check - are we currently limited?
  getStatus(): {
    rateLimited: boolean
    panicMode: boolean
    recentPRs: number
    maxStackDepth: number
    cooldownRemaining: number
  } {
    this.cleanOldActivity()
    const recentActivity = this.getRecentActivity()

    // Check cooldown
    let cooldownRemaining = 0
    try {
      const cooldownData = JSON.parse(
        require('fs').readFileSync('.claude/agents/cooldown.json', 'utf8')
      )
      cooldownRemaining = Math.max(0, cooldownData.endsAt - Date.now())
    } catch (e) {
      // No cooldown file
    }

    return {
      rateLimited: this.isRateLimited() || cooldownRemaining > 0,
      panicMode: this.panicMode,
      recentPRs: recentActivity.reduce((sum, a) => sum + a.prCount, 0),
      maxStackDepth: Math.max(...recentActivity.map(a => a.stackDepth), 0),
      cooldownRemaining: Math.ceil(cooldownRemaining / 1000 / 60), // minutes
    }
  }
}

// Global instance - import this in your agents
export const rateLimiter = new AgentRateLimiter()

// Convenience functions for quick checks
export const canCreatePR = (changes: {
  files: number
  lines: number
  complexity?: 'low' | 'medium' | 'high'
}) => {
  return !rateLimiter.requiresApproval(changes) && !rateLimiter.isRateLimited()
}

export const recordPRCreation = (
  files: number,
  stackDepth: number,
  author: 'human' | 'beast' = 'beast'
) => {
  rateLimiter.recordActivity({
    prCount: 1,
    stackDepth,
    filesChanged: files,
    author,
  })
}

// Emergency utilities
export const emergencyBrake = (reason: string) => rateLimiter.activatePanicMode(reason)
export const resume = () => rateLimiter.deactivatePanicMode()

// Status check alias
export const agentStatus = () => {
  const status = rateLimiter.getStatus()
  console.log('🤖 Agent Status:', status)

  if (status.panicMode) {
    console.log('🚨 PANIC MODE ACTIVE - All activity suspended')
  } else if (status.rateLimited) {
    console.log(`⏰ Rate limited - cooldown: ${status.cooldownRemaining}m`)
  } else {
    console.log('✅ All systems operational')
  }

  console.log(
    `📊 Activity: ${status.recentPRs}/5 PRs this hour, max stack: ${status.maxStackDepth}/3`
  )

  return status
}

// Auto-check panic mode on import
try {
  if (require('fs').existsSync('.claude/agents/PANIC_MODE.json')) {
    rateLimiter.activatePanicMode('Panic mode was previously activated')
  }
} catch (e) {
  // Ignore filesystem errors on import
}

export default agentGovernor
