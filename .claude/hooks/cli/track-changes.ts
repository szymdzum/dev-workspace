/**
 * Change tracking CLI for Claude Code hooks
 * Tracks and logs all file modifications for analytics
 */

import { SecureHookBase, HookLogger, runSecureHook, HookResult } from '@claude-dev/hooks';
import { extname } from 'path';

interface FileChange {
  timestamp: string;
  sessionId: string;
  filePath: string;
  fileExtension: string;
  operation: string;
  toolName: string;
  changeSize?: number;
  metadata?: Record<string, any>;
}

class TrackChangesCLI extends SecureHookBase {
  private logger: HookLogger;

  constructor() {
    super();
    this.logger = new HookLogger();
  }

  async main(): Promise<HookResult> {
    const startTime = Date.now();
    
    try {
      // Read and sanitize input from stdin
      const input = await this.readAndSanitizeStdin();
      
      // Extract relevant data
      const { tool_name, tool_input, session_id } = input;
      const filePath = this.getFilePathFromInput(tool_input);

      // Skip if no file path (e.g., Bash commands)
      if (!filePath) {
        await this.logger.logEvent({
          hookName: 'track-changes',
          toolName: tool_name || 'unknown',
          duration: Date.now() - startTime,
          result: 'allow',
          metadata: { reason: 'no_file_to_track' }
        });
        
        return this.allow();
      }

      // Sanitize file path
      let safePath: string;
      try {
        safePath = this.sanitizePath(filePath);
      } catch (error) {
        // Don't block on path issues for tracking - just log
        await this.logger.logSecurity({
          type: 'path_traversal',
          severity: 'medium',
          message: 'Change tracking path issue',
          details: [error instanceof Error ? error.message : 'Unknown path error'],
          filePath,
          blocked: false
        });
        
        return this.allow();
      }

      // Skip sensitive files from tracking
      if (this.isSensitivePath(safePath)) {
        await this.logger.logSecurity({
          type: 'sensitive_file_access',
          severity: 'low',
          message: 'Sensitive file change not tracked',
          details: [`File: ${safePath}`],
          filePath: safePath,
          blocked: false
        });
        
        return this.allow();
      }

      // Track the change
      const change = await this.createChangeRecord(safePath, tool_name || 'unknown', tool_input, session_id);
      
      // Log the change for analytics
      await this.logChange(change);

      // Log performance data
      await this.logger.logEvent({
        hookName: 'track-changes',
        toolName: tool_name || 'unknown',
        duration: Date.now() - startTime,
        result: 'allow',
        filePath: safePath,
        fileExtension: change.fileExtension,
        metadata: {
          operation: change.operation,
          changeSize: change.changeSize
        }
      });

      return this.allow();

    } catch (error) {
      await this.logger.logError(error as Error, {
        hookName: 'track-changes',
        toolName: input?.tool_name,
        duration: Date.now() - startTime
      });

      // Don't block operations due to tracking failures
      return this.allow();
    }
  }

  /**
   * Extract file path from tool input
   */
  private getFilePathFromInput(toolInput: any): string | null {
    if (!toolInput) return null;
    return toolInput.file_path || toolInput.notebook_path || null;
  }

  /**
   * Create a detailed change record
   */
  private async createChangeRecord(
    filePath: string, 
    toolName: string, 
    toolInput: any, 
    sessionId?: string
  ): Promise<FileChange> {
    const fileExtension = extname(filePath).toLowerCase();
    const operation = this.determineOperation(toolName, toolInput);
    
    const change: FileChange = {
      timestamp: new Date().toISOString(),
      sessionId: sessionId || 'unknown',
      filePath,
      fileExtension,
      operation,
      toolName,
      metadata: {}
    };

    // Calculate change size and add specific metadata based on operation
    switch (toolName) {
      case 'Write':
        change.changeSize = toolInput.content?.length || 0;
        change.metadata = {
          isNewFile: true,
          contentLength: change.changeSize
        };
        break;

      case 'Edit':
        const oldLength = toolInput.old_string?.length || 0;
        const newLength = toolInput.new_string?.length || 0;
        change.changeSize = Math.abs(newLength - oldLength);
        change.metadata = {
          oldLength,
          newLength,
          delta: newLength - oldLength,
          replaceAll: toolInput.replace_all || false
        };
        break;

      case 'MultiEdit':
        if (toolInput.edits && Array.isArray(toolInput.edits)) {
          const totalDelta = toolInput.edits.reduce((sum: number, edit: any) => {
            const oldLen = edit.old_string?.length || 0;
            const newLen = edit.new_string?.length || 0;
            return sum + Math.abs(newLen - oldLen);
          }, 0);
          
          change.changeSize = totalDelta;
          change.metadata = {
            editCount: toolInput.edits.length,
            totalDelta,
            edits: toolInput.edits.map((edit: any) => ({
              oldLength: edit.old_string?.length || 0,
              newLength: edit.new_string?.length || 0,
              replaceAll: edit.replace_all || false
            }))
          };
        }
        break;

      case 'NotebookEdit':
        change.metadata = {
          cellType: toolInput.cell_type,
          editMode: toolInput.edit_mode || 'replace',
          cellId: toolInput.cell_id
        };
        change.changeSize = toolInput.new_source?.length || 0;
        break;
    }

    return change;
  }

  /**
   * Determine the high-level operation type
   */
  private determineOperation(toolName: string, toolInput: any): string {
    switch (toolName) {
      case 'Write':
        return 'create';
      case 'Edit':
        return 'modify';
      case 'MultiEdit':
        return 'batch_modify';
      case 'NotebookEdit':
        const mode = toolInput.edit_mode || 'replace';
        return mode === 'insert' ? 'notebook_insert' : 
               mode === 'delete' ? 'notebook_delete' : 'notebook_modify';
      default:
        return 'unknown';
    }
  }

  /**
   * Log change to structured analytics
   */
  private async logChange(change: FileChange): Promise<void> {
    try {
      // Write to changes log
      const logEntry = {
        type: 'file_change',
        timestamp: change.timestamp,
        sessionId: change.sessionId,
        data: change
      };

      // Use the logger's structured logging
      await this.writeChangeToAnalytics(logEntry);

      // Update session statistics
      await this.updateSessionStats(change);

    } catch (error) {
      console.error('Failed to log change:', error);
    }
  }

  /**
   * Write change to analytics files
   */
  private async writeChangeToAnalytics(logEntry: any): Promise<void> {
    try {
      const analyticsDir = `${this.PROJECT_DIR}/.claude/runtime/analytics`;
      const changesFile = `${analyticsDir}/changes-${this.getDateString()}.jsonl`;
      
      await this.executeSecurely('mkdir', ['-p', analyticsDir]);
      await this.executeSecurely('sh', ['-c', `echo '${JSON.stringify(logEntry)}' >> "${changesFile}"`]);
      
    } catch (error) {
      console.error('Failed to write analytics:', error);
    }
  }

  /**
   * Update session statistics with change data
   */
  private async updateSessionStats(change: FileChange): Promise<void> {
    try {
      const sessionDir = `${this.PROJECT_DIR}/.claude/runtime/sessions`;
      const sessionFile = `${sessionDir}/${change.sessionId}.json`;
      
      // Ensure directory exists
      await this.executeSecurely('mkdir', ['-p', sessionDir]);

      // Read existing session data
      let sessionData: any = {
        sessionId: change.sessionId,
        startTime: change.timestamp,
        changes: [],
        fileStats: {},
        toolStats: {}
      };

      try {
        const readResult = await this.executeSecurely('cat', [sessionFile]);
        if (readResult.success && readResult.stdout) {
          sessionData = JSON.parse(readResult.stdout);
        }
      } catch {
        // New session file
      }

      // Update statistics
      sessionData.changes.push(change);
      sessionData.lastActivity = change.timestamp;
      
      // Update file statistics
      if (!sessionData.fileStats[change.fileExtension]) {
        sessionData.fileStats[change.fileExtension] = {
          files: new Set(),
          operations: 0,
          totalSize: 0
        };
      }
      
      const fileStats = sessionData.fileStats[change.fileExtension];
      fileStats.files.add(change.filePath);
      fileStats.operations++;
      fileStats.totalSize += change.changeSize || 0;
      
      // Convert Set to Array for JSON serialization
      fileStats.files = Array.from(fileStats.files);

      // Update tool statistics
      if (!sessionData.toolStats[change.toolName]) {
        sessionData.toolStats[change.toolName] = {
          uses: 0,
          totalSize: 0
        };
      }
      
      sessionData.toolStats[change.toolName].uses++;
      sessionData.toolStats[change.toolName].totalSize += change.changeSize || 0;

      // Write updated session data
      const sessionJson = JSON.stringify(sessionData, null, 2);
      await this.executeSecurely('sh', ['-c', `echo '${sessionJson.replace(/'/g, "'\\''")}' > "${sessionFile}"`]);

    } catch (error) {
      console.error('Failed to update session stats:', error);
    }
  }

  /**
   * Get current date string for file naming
   */
  private getDateString(): string {
    return new Date().toISOString().split('T')[0];
  }
}

// Run the CLI if called directly
if (require.main === module) {
  runSecureHook(TrackChangesCLI);
}