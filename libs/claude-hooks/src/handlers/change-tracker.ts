/**
 * Change Tracker Handler - Session-wide File Change Monitoring
 * 
 * Tracks all file changes during a Claude session to enable
 * targeted validation and cleanup.
 */

import { UniversalHandler } from './base';
import { HookInput, PostToolUseInput } from '../types/claude-code';
import { HookResponse } from '../types/responses';
import { ResultsValidatorHandler } from './results-validator';

/**
 * Tracks file changes throughout the session
 */
export class ChangeTrackerHandler extends UniversalHandler {
  
  async handle(input: HookInput): Promise<HookResponse<any>> {
    // Track changes on PostToolUse events
    if (input.hook_event_name === 'PostToolUse') {
      this.trackFileChanges(input as PostToolUseInput);
    }
    
    // Clear tracking on new sessions
    if (input.hook_event_name === 'SessionStart') {
      this.debug('New session started, clearing change tracking');
      ResultsValidatorHandler.clearTrackedChanges();
    }
    
    return { continue: true };
  }
  
  /**
   * Track file changes from tool operations
   */
  private trackFileChanges(input: PostToolUseInput): void {
    const filePath = this.extractFilePath(input);
    
    if (filePath && this.shouldTrackFile(filePath)) {
      this.debug(`Tracking change: ${filePath}`, true);
      ResultsValidatorHandler.trackChange(filePath);
    }
  }
  
  /**
   * Extract file path from various tool inputs
   */
  private extractFilePath(input: PostToolUseInput): string | null {
    const toolInput = input.tool_input as any;
    
    switch (input.tool_name) {
      case 'Write':
      case 'Edit':
      case 'MultiEdit':
        return toolInput?.file_path || null;
        
      case 'Read':
        // Don't track reads, only modifications
        return null;
        
      default:
        return null;
    }
  }
  
  /**
   * Determine if a file should be tracked for changes
   */
  private shouldTrackFile(filePath: string): boolean {
    // Skip tracking for certain file types/locations
    const skipPatterns = [
      /node_modules/,
      /\.git\//,
      /dist\//,
      /coverage\//,
      /\.log$/,
      /\.tmp$/,
      /\.cache/,
      /\.next/,
      /\.nuxt/,
      /\.vscode/
    ];
    
    return !skipPatterns.some(pattern => pattern.test(filePath));
  }
  
  /**
   * Get summary of tracked changes for debugging
   */
  getChangesSummary(): string {
    const changes = ResultsValidatorHandler.getTrackedChanges();
    
    if (changes.length === 0) {
      return 'No files changed in this session';
    }
    
    const summary = changes
      .slice(0, 5)
      .map(file => `  • ${file}`)
      .join('\n');
    
    const remaining = changes.length - 5;
    const suffix = remaining > 0 ? `\n  ... and ${remaining} more` : '';
    
    return `Files changed in session (${changes.length}):\n${summary}${suffix}`;
  }
}