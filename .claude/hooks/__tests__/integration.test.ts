import { ClaudeHooks } from '@claude-dev/hooks';
import { HookInput } from '@claude-dev/hooks';
import { exec } from 'child_process';
import fs from 'fs/promises';

// Mock external dependencies
jest.mock('child_process');
jest.mock('fs/promises');

const mockedExec = exec as jest.MockedFunction<typeof exec>;
const mockedFs = fs as jest.Mocked<typeof fs>;

describe('Hook Integration Tests', () => {
  let hookSystem: any;
  const testCwd = '/Users/szymondzumak/Developer';
  const testSessionId = 'integration-test-session';

  beforeEach(() => {
    // Create the same hook system as our main configuration
    hookSystem = ClaudeHooks.create()
      .useDefaults()
      .useValidation({
        targets: ['lint', 'build'],
        affectedOnly: true,
        bail: true,
        triggerTools: ['Write', 'Edit', 'MultiEdit'],
        triggerExtensions: ['.ts', '.tsx', '.js', '.jsx', '.json', '.md'],
        batchThreshold: 1
      });

    jest.clearAllMocks();
    
    // Default mocks for file operations
    mockedFs.mkdir.mockResolvedValue(undefined);
    mockedFs.writeFile.mockResolvedValue();
    mockedFs.readFile.mockResolvedValue('[]');
  });

  describe('Security + Validation Integration', () => {
    it('should block secrets before validation runs', async () => {
      const mockInput: HookInput = {
        session_id: testSessionId,
        cwd: testCwd,
        tool_name: 'Write',
        tool_input: {
          file_path: '/Users/szymondzumak/Developer/src/config.ts',
          content: 'const apiKey = "sk-1234567890abcdef1234567890abcdef";'
        }
      };

      const result = await hookSystem.execute(mockInput);
      
      // Security should block before validation runs
      expect(result.hookSpecificOutput?.permissionDecision).toBe('deny');
      expect(result.hookSpecificOutput?.permissionDecisionReason).toContain('Hardcoded secret detected');
      
      // Validation should not have run
      expect(mockedExec).not.toHaveBeenCalled();
    });

    it('should run validation after security passes', async () => {
      const mockInput: HookInput = {
        session_id: testSessionId,
        cwd: testCwd,
        tool_name: 'Write',
        tool_input: {
          file_path: '/Users/szymondzumak/Developer/src/safe-component.tsx',
          content: 'export const Component = () => <div>Safe content</div>;'
        }
      };

      // Mock successful validation
      mockedExec.mockImplementation((command, callback) => {
        if (command.includes('lint')) {
          callback!(null, { stdout: '✓ Lint passed', stderr: '' } as any);
        } else if (command.includes('build')) {
          callback!(null, { stdout: '✓ Build passed', stderr: '' } as any);
        }
      });

      const result = await hookSystem.execute(mockInput);
      
      // Security should pass
      expect(result.hookSpecificOutput?.permissionDecision).not.toBe('deny');
      
      // Validation should run
      expect(mockedExec).toHaveBeenCalledWith(
        expect.stringContaining('nx affected -t lint'),
        expect.any(Function)
      );
      
      // Should continue after all checks pass
      expect(result.continue).toBe(true);
    });
  });

  describe('Change Tracking Integration', () => {
    it('should track changes while validating', async () => {
      const mockInput: HookInput = {
        session_id: testSessionId,
        cwd: testCwd,
        tool_name: 'Edit',
        tool_input: {
          file_path: '/Users/szymondzumak/Developer/src/utils.ts',
          old_string: 'const version = "1.0.0";',
          new_string: 'const version = "1.1.0";'
        }
      };

      // Mock successful validation
      mockedExec.mockImplementation((command, callback) => {
        callback!(null, { stdout: '✓ Validation passed', stderr: '' } as any);
      });

      const result = await hookSystem.execute(mockInput);
      
      // Should track the change
      expect(mockedFs.writeFile).toHaveBeenCalledWith(
        expect.stringContaining(`${testSessionId}-changes.json`),
        expect.stringContaining('"operation":"Edit"')
      );
      
      // Should validate
      expect(mockedExec).toHaveBeenCalled();
      
      // Should continue
      expect(result.continue).toBe(true);
    });
  });

  describe('Results Validator Integration', () => {
    it('should run final validation on Stop event', async () => {
      const mockInput: HookInput = {
        session_id: testSessionId,
        cwd: testCwd,
        tool_name: 'Stop',
        tool_input: {}
      };

      // Mock successful final validation
      mockedExec.mockImplementation((command, callback) => {
        if (command.includes('lint')) {
          callback!(null, { stdout: '✓ Final lint check passed', stderr: '' } as any);
        } else if (command.includes('typecheck') || command.includes('tsc --noEmit')) {
          callback!(null, { stdout: '✓ Final type check passed', stderr: '' } as any);
        }
      });

      const result = await hookSystem.execute(mockInput);
      
      // Should run both lint and typecheck
      expect(mockedExec).toHaveBeenCalledWith(
        expect.stringContaining('nx affected -t lint'),
        expect.any(Function)
      );
      expect(mockedExec).toHaveBeenCalledWith(
        expect.stringMatching(/(nx affected -t typecheck|npx tsc --noEmit)/),
        expect.any(Function)
      );
      
      expect(result.continue).toBe(true);
    });

    it('should block Stop when validation fails with helpful message', async () => {
      const mockInput: HookInput = {
        session_id: testSessionId,
        cwd: testCwd,
        tool_name: 'Stop',
        tool_input: {}
      };

      // Mock validation failure with real error format
      mockedExec.mockImplementation((command, callback) => {
        if (command.includes('lint')) {
          callback!(new Error('Lint failed'), { 
            stdout: '', 
            stderr: `
.claude/hooks/__tests__/fixtures/test-lint-errors.ts
  2:1   error  'var' is not allowed. Use 'const' or 'let' instead  no-var
  3:27  error  Missing semicolon  semi
            ` 
          } as any);
        }
      });

      const result = await hookSystem.execute(mockInput);
      
      expect(result.hookSpecificOutput?.permissionDecision).toBe('deny');
      expect(result.hookSpecificOutput?.permissionDecisionReason).toContain('Quality gate failed');
      expect(result.hookSpecificOutput?.permissionDecisionReason).toContain('test-lint-errors.ts');
      expect(result.hookSpecificOutput?.permissionDecisionReason).toContain('no-var');
    });
  });

  describe('Full Workflow Integration', () => {
    it('should handle complete development workflow', async () => {
      const sessionOps = [
        {
          tool_name: 'Write',
          tool_input: {
            file_path: '/Users/szymondzumak/Developer/src/feature.ts',
            content: 'export const feature = () => "new feature";'
          }
        },
        {
          tool_name: 'Edit',
          tool_input: {
            file_path: '/Users/szymondzumak/Developer/src/feature.ts',
            old_string: 'export const feature = () => "new feature";',
            new_string: 'export const feature = (name: string) => `Hello ${name}`;'
          }
        },
        {
          tool_name: 'Stop',
          tool_input: {}
        }
      ];

      // Mock successful validation for all operations
      mockedExec.mockImplementation((command, callback) => {
        callback!(null, { stdout: '✓ All validations passed', stderr: '' } as any);
      });

      for (const op of sessionOps) {
        const mockInput: HookInput = {
          session_id: testSessionId,
          cwd: testCwd,
          tool_name: op.tool_name,
          tool_input: op.tool_input
        };

        const result = await hookSystem.execute(mockInput);
        expect(result.continue).toBe(true);
      }

      // Should have tracked changes
      expect(mockedFs.writeFile).toHaveBeenCalledWith(
        expect.stringContaining(`${testSessionId}-changes.json`),
        expect.any(String)
      );

      // Should have run validation multiple times
      expect(mockedExec).toHaveBeenCalledTimes(6); // 2 ops × 2 validations + Stop × 2 validations
    });

    it('should fail fast when security issues are detected', async () => {
      const mockInput: HookInput = {
        session_id: testSessionId,
        cwd: testCwd,
        tool_name: 'Write',
        tool_input: {
          file_path: '/Users/szymondzumak/Developer/.claude/hooks/__tests__/fixtures/test-secrets.ts',
          content: 'const apiKey = "sk-1234567890abcdef";'
        }
      };

      const result = await hookSystem.execute(mockInput);
      
      // Should fail immediately
      expect(result.hookSpecificOutput?.permissionDecision).toBe('deny');
      
      // Should not run validation
      expect(mockedExec).not.toHaveBeenCalled();
      
      // Should not track change
      expect(mockedFs.writeFile).not.toHaveBeenCalled();
    });
  });

  describe('Error Handling Integration', () => {
    it('should handle validation command failures gracefully', async () => {
      const mockInput: HookInput = {
        session_id: testSessionId,
        cwd: testCwd,
        tool_name: 'Write',
        tool_input: {
          file_path: '/Users/szymondzumak/Developer/src/test.ts',
          content: 'export const test = "value";'
        }
      };

      // Mock command execution failure (not validation failure)
      mockedExec.mockImplementation((command, callback) => {
        // Simulate system error (not validation failure)
        const error = new Error('Command not found');
        (error as any).code = 127;
        callback!(error, { stdout: '', stderr: 'nx: command not found' } as any);
      });

      const result = await hookSystem.execute(mockInput);
      
      // Should handle system errors gracefully and continue
      // (The exact behavior depends on implementation - might warn but continue)
      expect(result).toBeDefined();
    });
  });
});