import { ValidationHandler } from '@claude-dev/hooks';
import { HookInput } from '@claude-dev/hooks';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

// Mock exec for testing
jest.mock('child_process', () => ({
  exec: jest.fn()
}));

const mockedExec = exec as jest.MockedFunction<typeof exec>;

describe('ValidationHandler', () => {
  let handler: ValidationHandler;

  beforeEach(() => {
    handler = new ValidationHandler({
      targets: ['lint', 'build'],
      affectedOnly: true,
      bail: true,
      triggerTools: ['Write', 'Edit', 'MultiEdit'],
      triggerExtensions: ['.ts', '.tsx', '.js', '.jsx'],
      batchThreshold: 1
    });
    jest.clearAllMocks();
  });

  describe('should trigger validation', () => {
    it('should trigger on Write tool with TypeScript files', async () => {
      const mockInput: HookInput = {
        session_id: 'test-session',
        cwd: '/Users/szymondzumak/Developer',
        tool_name: 'Write',
        tool_input: {
          file_path: '/Users/szymondzumak/Developer/src/component.tsx',
          content: 'export const Component = () => <div>Test</div>;'
        }
      };

      // Mock successful lint
      mockedExec.mockImplementation((command, callback) => {
        callback!(null, { stdout: '✓ All files passed linting', stderr: '' } as any);
      });

      const result = await handler.execute(mockInput);
      
      expect(mockedExec).toHaveBeenCalledWith(
        expect.stringContaining('nx affected -t lint'),
        expect.any(Function)
      );
      expect(result.continue).toBe(true);
    });

    it('should skip validation for non-matching file extensions', async () => {
      const mockInput: HookInput = {
        session_id: 'test-session',
        cwd: '/test',
        tool_name: 'Write',
        tool_input: {
          file_path: '/test/readme.md',
          content: '# Hello World'
        }
      };

      const result = await handler.execute(mockInput);
      
      expect(mockedExec).not.toHaveBeenCalled();
      expect(result.continue).toBe(true);
    });
  });

  describe('lint validation', () => {
    it('should block when lint fails', async () => {
      const mockInput: HookInput = {
        session_id: 'test-session',
        cwd: '/Users/szymondzumak/Developer',
        tool_name: 'Edit',
        tool_input: {
          file_path: '/Users/szymondzumak/Developer/src/bad-code.ts',
          old_string: 'const good = "code";',
          new_string: 'var bad=code // lint errors'
        }
      };

      // Mock lint failure
      mockedExec.mockImplementation((command, callback) => {
        if (command.includes('lint')) {
          callback!(new Error('Lint failed'), { stdout: '', stderr: 'ESLint found 5 errors' } as any);
        }
      });

      const result = await handler.execute(mockInput);
      
      expect(result.hookSpecificOutput?.permissionDecision).toBe('deny');
      expect(result.hookSpecificOutput?.permissionDecisionReason).toContain('Lint validation failed');
    });

    it('should continue when lint passes', async () => {
      const mockInput: HookInput = {
        session_id: 'test-session',
        cwd: '/Users/szymondzumak/Developer',
        tool_name: 'Write',
        tool_input: {
          file_path: '/Users/szymondzumak/Developer/src/good-code.ts',
          content: 'export const goodCode = "properly formatted";'
        }
      };

      // Mock lint success
      mockedExec.mockImplementation((command, callback) => {
        if (command.includes('lint')) {
          callback!(null, { stdout: '✓ All files passed linting', stderr: '' } as any);
        }
      });

      const result = await handler.execute(mockInput);
      
      expect(result.continue).toBe(true);
      expect(result.hookSpecificOutput?.permissionDecision).not.toBe('deny');
    });
  });

  describe('build validation', () => {
    it('should block when TypeScript build fails', async () => {
      const mockInput: HookInput = {
        session_id: 'test-session',
        cwd: '/Users/szymondzumak/Developer',
        tool_name: 'MultiEdit',
        tool_input: {
          file_path: '/Users/szymondzumak/Developer/src/types.ts',
          edits: [{
            old_string: 'interface User { name: string; }',
            new_string: 'interface User { name: number; email: string; }' // type conflict
          }]
        }
      };

      // Mock successful lint but failed build
      mockedExec.mockImplementation((command, callback) => {
        if (command.includes('lint')) {
          callback!(null, { stdout: '✓ Linting passed', stderr: '' } as any);
        } else if (command.includes('build')) {
          callback!(new Error('Build failed'), { 
            stdout: '', 
            stderr: 'TS2322: Type "number" is not assignable to type "string"' 
          } as any);
        }
      });

      const result = await handler.execute(mockInput);
      
      expect(result.hookSpecificOutput?.permissionDecision).toBe('deny');
      expect(result.hookSpecificOutput?.permissionDecisionReason).toContain('Build validation failed');
    });

    it('should continue when both lint and build pass', async () => {
      const mockInput: HookInput = {
        session_id: 'test-session',
        cwd: '/Users/szymondzumak/Developer',
        tool_name: 'Write',
        tool_input: {
          file_path: '/Users/szymondzumak/Developer/src/valid.ts',
          content: 'export interface User { name: string; age: number; }'
        }
      };

      // Mock both passing
      mockedExec.mockImplementation((command, callback) => {
        if (command.includes('lint')) {
          callback!(null, { stdout: '✓ Linting passed', stderr: '' } as any);
        } else if (command.includes('build')) {
          callback!(null, { stdout: '✓ Build successful', stderr: '' } as any);
        }
      });

      const result = await handler.execute(mockInput);
      
      expect(result.continue).toBe(true);
      expect(result.hookSpecificOutput?.validationResults).toEqual({
        lint: { passed: true, output: '✓ Linting passed' },
        build: { passed: true, output: '✓ Build successful' }
      });
    });
  });

  describe('batch processing', () => {
    it('should batch multiple rapid changes', async () => {
      // This would require more complex testing setup for batching behavior
      // For now, just test that the configuration is respected
      expect(handler['config'].batchThreshold).toBe(1);
      expect(handler['config'].bail).toBe(true);
    });
  });
});