/**
 * Comprehensive logging system for Claude Code hooks
 * Provides structured logging, analytics, and security monitoring
 */

import { writeFile, mkdir, readFile, appendFile, access, constants } from 'fs/promises';
import { resolve, dirname } from 'path';

export interface HookEvent {
  timestamp: string;
  sessionId: string;
  hookName: string;
  toolName: string;
  duration: number;
  result: 'allow' | 'deny' | 'error';
  filePath?: string;
  fileExtension?: string;
  errors?: string[];
  metadata?: Record<string, any>;
}

export interface SecurityEvent {
  timestamp: string;
  sessionId: string;
  type: 'hardcoded_secret' | 'path_traversal' | 'sensitive_file_access' | 'dangerous_command' | 'input_validation_failure';
  severity: 'low' | 'medium' | 'high' | 'critical';
  message: string;
  details: string[];
  filePath?: string;
  blocked: boolean;
}

export interface PerformanceEvent {
  timestamp: string;
  sessionId: string;
  hookName: string;
  duration: number;
  memoryUsage: NodeJS.MemoryUsage;
  cpuUsage: NodeJS.CpuUsage;
}

export interface SessionStats {
  sessionId: string;
  startTime: string;
  endTime?: string;
  duration?: number;
  totalEvents: number;
  hookExecutions: number;
  securityViolations: number;
  blockedOperations: number;
  avgHookDuration: number;
  toolsUsed: string[];
  filesModified: number;
}

export interface Analytics {
  sessionStats: SessionStats;
  hookPerformance: {
    [hookName: string]: {
      executions: number;
      avgDuration: number;
      successRate: number;
      errors: string[];
    };
  };
  securityMetrics: {
    totalViolations: number;
    violationsByType: Record<string, number>;
    blockedOperations: number;
    sensitiveFileAccesses: number;
  };
  toolUsage: {
    [toolName: string]: {
      uses: number;
      successRate: number;
      avgDuration: number;
    };
  };
  recommendations: string[];
}

/**
 * Structured logger for Claude Code hooks with analytics capabilities
 */
export class HookLogger {
  private readonly sessionId: string;
  private readonly logDir: string;
  private readonly eventsFile: string;
  private readonly securityFile: string;
  private readonly performanceFile: string;
  private readonly sessionFile: string;
  private startTime: Date;

  constructor(sessionId?: string) {
    this.sessionId = sessionId || this.generateSessionId();
    this.logDir = resolve(process.env['CLAUDE_PROJECT_DIR'] || process.cwd(), '.claude/runtime/logs');
    this.eventsFile = resolve(this.logDir, `events-${this.getDateString()}.jsonl`);
    this.securityFile = resolve(this.logDir, `security-${this.getDateString()}.jsonl`);
    this.performanceFile = resolve(this.logDir, `performance-${this.getDateString()}.jsonl`);
    this.sessionFile = resolve(this.logDir, `session-${this.sessionId}.json`);
    this.startTime = new Date();
    
    // Initialize logging directory
    this.ensureLogDirectory().catch(console.error);
  }

  /**
   * Log a hook execution event
   */
  async logEvent(event: Omit<HookEvent, 'timestamp' | 'sessionId'>): Promise<void> {
    const logEvent: HookEvent = {
      timestamp: new Date().toISOString(),
      sessionId: this.sessionId,
      ...event
    };

    await this.appendToFile(this.eventsFile, JSON.stringify(logEvent));
  }

  /**
   * Log a security violation or check
   */
  async logSecurity(event: Omit<SecurityEvent, 'timestamp' | 'sessionId'>): Promise<void> {
    const securityEvent: SecurityEvent = {
      timestamp: new Date().toISOString(),
      sessionId: this.sessionId,
      ...event
    };

    await this.appendToFile(this.securityFile, JSON.stringify(securityEvent));
    
    // Also log to main events for analytics
    await this.logEvent({
      hookName: 'security-check',
      toolName: 'security',
      duration: 0,
      result: event.blocked ? 'deny' : 'allow',
      metadata: {
        securityType: event.type,
        severity: event.severity
      }
    });
  }

  /**
   * Log performance metrics
   */
  async logPerformance(event: Omit<PerformanceEvent, 'timestamp' | 'sessionId'>): Promise<void> {
    const perfEvent: PerformanceEvent = {
      timestamp: new Date().toISOString(),
      sessionId: this.sessionId,
      ...event
    };

    await this.appendToFile(this.performanceFile, JSON.stringify(perfEvent));
  }

  /**
   * Log an error with context
   */
  async logError(error: Error, context?: Record<string, any>): Promise<void> {
    await this.logEvent({
      hookName: context?.['hookName'] || 'unknown',
      toolName: context?.['toolName'] || 'unknown',
      duration: context?.['duration'] || 0,
      result: 'error',
      errors: [error.message, ...(error.stack ? [error.stack] : [])],
      metadata: context
    });
  }

  /**
   * Update session information
   */
  async updateSession(updates: Partial<SessionStats>): Promise<void> {
    try {
      let currentSession: SessionStats;
      
      try {
        const existing = await readFile(this.sessionFile, 'utf8');
        currentSession = JSON.parse(existing);
      } catch {
        currentSession = {
          sessionId: this.sessionId,
          startTime: this.startTime.toISOString(),
          totalEvents: 0,
          hookExecutions: 0,
          securityViolations: 0,
          blockedOperations: 0,
          avgHookDuration: 0,
          toolsUsed: [],
          filesModified: 0
        };
      }

      const updatedSession = { ...currentSession, ...updates };
      
      if (!updates.endTime) {
        updatedSession.endTime = new Date().toISOString();
        updatedSession.duration = Date.now() - new Date(currentSession.startTime).getTime();
      }

      await this.writeToFile(this.sessionFile, JSON.stringify(updatedSession, null, 2));
    } catch (error) {
      console.error('Failed to update session:', error);
    }
  }

  /**
   * Generate analytics from logged data
   */
  async generateAnalytics(days = 1): Promise<Analytics> {
    try {
      const events = await this.readEvents(days);
      const securityEvents = await this.readSecurityEvents(days);
      const session = await this.readSession();

      return {
        sessionStats: session || {
          sessionId: this.sessionId,
          startTime: this.startTime.toISOString(),
          totalEvents: events.length,
          hookExecutions: events.filter(e => e.result !== 'error').length,
          securityViolations: securityEvents.filter(e => e.blocked).length,
          blockedOperations: events.filter(e => e.result === 'deny').length,
          avgHookDuration: this.calculateAverageDuration(events),
          toolsUsed: [...new Set(events.map(e => e.toolName))],
          filesModified: events.filter(e => e.filePath).length
        },
        hookPerformance: this.analyzeHookPerformance(events),
        securityMetrics: this.analyzeSecurityMetrics(securityEvents),
        toolUsage: this.analyzeToolUsage(events),
        recommendations: this.generateRecommendations(events, securityEvents)
      };
    } catch (error) {
      console.error('Failed to generate analytics:', error);
      throw error;
    }
  }

  /**
   * Create a formatted analytics report
   */
  async generateReport(): Promise<string> {
    const analytics = await this.generateAnalytics();
    const { sessionStats, hookPerformance, securityMetrics, toolUsage } = analytics;

    return `
📊 Claude Code Hook Analytics Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 Session Overview
Session ID:      ${sessionStats.sessionId}
Duration:        ${sessionStats.duration ? Math.round(sessionStats.duration / 1000 / 60) : 0} minutes
Total Events:    ${sessionStats.totalEvents}
Hook Executions: ${sessionStats.hookExecutions}
Files Modified:  ${sessionStats.filesModified}
Tools Used:      ${sessionStats.toolsUsed.join(', ')}

🔒 Security Metrics
Total Violations:    ${securityMetrics.totalViolations}
Blocked Operations:  ${securityMetrics.blockedOperations}
Sensitive Accesses:  ${securityMetrics.sensitiveFileAccesses}

Top Violation Types:
${Object.entries(securityMetrics.violationsByType)
  .sort(([,a], [,b]) => b - a)
  .slice(0, 5)
  .map(([type, count]) => `  • ${type}: ${count}`)
  .join('\n')}

⚡ Performance
Avg Hook Duration:   ${sessionStats.avgHookDuration}ms

Top Hook Performance:
${Object.entries(hookPerformance)
  .sort(([,a], [,b]) => b.executions - a.executions)
  .slice(0, 5)
  .map(([name, perf]) => `  • ${name}: ${perf.executions} runs, ${perf.avgDuration}ms avg, ${Math.round(perf.successRate * 100)}% success`)
  .join('\n')}

🛠️ Tool Usage
${Object.entries(toolUsage)
  .sort(([,a], [,b]) => b.uses - a.uses)
  .slice(0, 5)
  .map(([name, usage]) => `  • ${name}: ${usage.uses} uses, ${Math.round(usage.successRate * 100)}% success`)
  .join('\n')}

💡 Recommendations
${analytics.recommendations.map(rec => `  • ${rec}`).join('\n')}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Generated: ${new Date().toISOString()}
    `.trim();
  }

  // Private helper methods

  private generateSessionId(): string {
    return `${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
  }

  private getDateString(): string {
    return new Date().toISOString().split('T')[0];
  }

  private async ensureLogDirectory(): Promise<void> {
    try {
      await mkdir(this.logDir, { recursive: true });
    } catch (error) {
      console.error('Failed to create log directory:', error);
    }
  }

  private async appendToFile(filePath: string, content: string): Promise<void> {
    try {
      await mkdir(dirname(filePath), { recursive: true });
      await appendFile(filePath, content + '\n');
    } catch (error) {
      console.error(`Failed to append to ${filePath}:`, error);
    }
  }

  private async writeToFile(filePath: string, content: string): Promise<void> {
    try {
      await mkdir(dirname(filePath), { recursive: true });
      await writeFile(filePath, content);
    } catch (error) {
      console.error(`Failed to write to ${filePath}:`, error);
    }
  }

  private async readEvents(days: number): Promise<HookEvent[]> {
    const events: HookEvent[] = [];
    
    for (let i = 0; i < days; i++) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dateString = date.toISOString().split('T')[0];
      const filePath = resolve(this.logDir, `events-${dateString}.jsonl`);
      
      try {
        const content = await readFile(filePath, 'utf8');
        const lines = content.trim().split('\n').filter(line => line.trim());
        
        for (const line of lines) {
          try {
            events.push(JSON.parse(line));
          } catch {
            // Skip invalid JSON lines
          }
        }
      } catch {
        // File doesn't exist, skip
      }
    }
    
    return events;
  }

  private async readSecurityEvents(days: number): Promise<SecurityEvent[]> {
    const events: SecurityEvent[] = [];
    
    for (let i = 0; i < days; i++) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dateString = date.toISOString().split('T')[0];
      const filePath = resolve(this.logDir, `security-${dateString}.jsonl`);
      
      try {
        const content = await readFile(filePath, 'utf8');
        const lines = content.trim().split('\n').filter(line => line.trim());
        
        for (const line of lines) {
          try {
            events.push(JSON.parse(line));
          } catch {
            // Skip invalid JSON lines
          }
        }
      } catch {
        // File doesn't exist, skip
      }
    }
    
    return events;
  }

  private async readSession(): Promise<SessionStats | null> {
    try {
      const content = await readFile(this.sessionFile, 'utf8');
      return JSON.parse(content);
    } catch {
      return null;
    }
  }

  private calculateAverageDuration(events: HookEvent[]): number {
    if (events.length === 0) return 0;
    const total = events.reduce((sum, event) => sum + event.duration, 0);
    return Math.round(total / events.length);
  }

  private analyzeHookPerformance(events: HookEvent[]): Analytics['hookPerformance'] {
    const performance: Analytics['hookPerformance'] = {};
    
    for (const event of events) {
      if (!performance[event.hookName]) {
        performance[event.hookName] = {
          executions: 0,
          avgDuration: 0,
          successRate: 0,
          errors: []
        };
      }
      
      const perf = performance[event.hookName];
      perf.executions++;
      
      if (event.errors && event.errors.length > 0) {
        perf.errors.push(...event.errors);
      }
    }
    
    for (const [hookName, perf] of Object.entries(performance)) {
      const hookEvents = events.filter(e => e.hookName === hookName);
      const successful = hookEvents.filter(e => e.result === 'allow').length;
      
      perf.avgDuration = this.calculateAverageDuration(hookEvents);
      perf.successRate = perf.executions > 0 ? successful / perf.executions : 0;
      perf.errors = [...new Set(perf.errors)]; // Remove duplicates
    }
    
    return performance;
  }

  private analyzeSecurityMetrics(events: SecurityEvent[]): Analytics['securityMetrics'] {
    const violationsByType: Record<string, number> = {};
    
    for (const event of events) {
      violationsByType[event.type] = (violationsByType[event.type] || 0) + 1;
    }
    
    return {
      totalViolations: events.length,
      violationsByType,
      blockedOperations: events.filter(e => e.blocked).length,
      sensitiveFileAccesses: events.filter(e => e.type === 'sensitive_file_access').length
    };
  }

  private analyzeToolUsage(events: HookEvent[]): Analytics['toolUsage'] {
    const usage: Analytics['toolUsage'] = {};
    
    for (const event of events) {
      if (!usage[event.toolName]) {
        usage[event.toolName] = {
          uses: 0,
          successRate: 0,
          avgDuration: 0
        };
      }
      
      usage[event.toolName].uses++;
    }
    
    for (const [toolName, toolUsage] of Object.entries(usage)) {
      const toolEvents = events.filter(e => e.toolName === toolName);
      const successful = toolEvents.filter(e => e.result === 'allow').length;
      
      toolUsage.successRate = toolUsage.uses > 0 ? successful / toolUsage.uses : 0;
      toolUsage.avgDuration = this.calculateAverageDuration(toolEvents);
    }
    
    return usage;
  }

  private generateRecommendations(events: HookEvent[], securityEvents: SecurityEvent[]): string[] {
    const recommendations: string[] = [];
    
    // Performance recommendations
    const slowHooks = Object.entries(this.analyzeHookPerformance(events))
      .filter(([, perf]) => perf.avgDuration > 1000)
      .sort(([, a], [, b]) => b.avgDuration - a.avgDuration);
    
    if (slowHooks.length > 0) {
      recommendations.push(`Optimize slow hooks: ${slowHooks[0][0]} (${slowHooks[0][1].avgDuration}ms avg)`);
    }
    
    // Security recommendations
    const criticalSecurity = securityEvents.filter(e => e.severity === 'critical');
    if (criticalSecurity.length > 0) {
      recommendations.push(`Address ${criticalSecurity.length} critical security issues`);
    }
    
    // Error rate recommendations
    const errorEvents = events.filter(e => e.result === 'error');
    if (errorEvents.length > events.length * 0.1) {
      recommendations.push('High error rate detected - review hook configurations');
    }
    
    // Tool usage recommendations
    const toolUsage = this.analyzeToolUsage(events);
    const failingTools = Object.entries(toolUsage)
      .filter(([, usage]) => usage.successRate < 0.8)
      .sort(([, a], [, b]) => a.successRate - b.successRate);
    
    if (failingTools.length > 0) {
      recommendations.push(`Improve ${failingTools[0][0]} tool success rate (${Math.round(failingTools[0][1].successRate * 100)}%)`);
    }
    
    if (recommendations.length === 0) {
      recommendations.push('All systems running optimally!');
    }
    
    return recommendations;
  }
}