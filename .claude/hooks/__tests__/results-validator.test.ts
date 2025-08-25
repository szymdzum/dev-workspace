import { ResultsValidator } from '@claude-dev/hooks';
import { HookInput } from '@claude-dev/hooks';
import { exec } from 'child_process';
import path from 'path';

// Mock exec for testing
jest.mock('child_process', () => ({
  exec: jest.fn()
}));

const mockedExec = exec as jest.MockedFunction<typeof exec>;

describe('ResultsValidator', () => {
  let validator: ResultsValidator;
  const testCwd = '/Users/szymondzumak/Developer';

  beforeEach(() => {
    validator = ResultsValidator.standard();
    jest.clearAllMocks();
    
    // Mock the working directory to match our test setup
    process.chdir = jest.fn().mockReturnValue(testCwd);
  });

  describe('Stop event validation', () => {
    it('should run lint and typecheck before allowing Stop', async () => {
      const mockInput: HookInput = {
        session_id: 'test-session',
        cwd: testCwd,
        tool_name: 'Stop',
        tool_input: {}
      };

      // Mock successful validation
      mockedExec.mockImplementation((command, callback) => {
        if (command.includes('nx affected -t lint')) {
          callback!(null, { stdout: '✓ All lint checks passed', stderr: '' } as any);
        } else if (command.includes('nx affected -t typecheck') || command.includes('npx tsc --noEmit')) {
          callback!(null, { stdout: '✓ Type checking passed', stderr: '' } as any);
        }
      });

      const result = await validator.execute(mockInput);
      
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

    it('should block Stop when lint fails', async () => {
      const mockInput: HookInput = {
        session_id: 'test-session',
        cwd: testCwd,
        tool_name: 'Stop',
        tool_input: {}
      };

      // Mock lint failure
      mockedExec.mockImplementation((command, callback) => {
        if (command.includes('lint')) {
          callback!(new Error('Lint failed'), { 
            stdout: '', 
            stderr: `
/Users/szymondzumak/Developer/src/bad-file.ts
  1:1  error  'var' is not allowed. Use 'const' or 'let' instead  no-var
  2:9  error  Missing semicolon  semi
            ` 
          } as any);
        }
      });

      const result = await validator.execute(mockInput);
      
      expect(result.hookSpecificOutput?.permissionDecision).toBe('deny');
      expect(result.hookSpecificOutput?.permissionDecisionReason).toContain('Quality gate failed');
      expect(result.hookSpecificOutput?.permissionDecisionReason).toContain('Lint errors found');
    });

    it('should block Stop when typecheck fails', async () => {
      const mockInput: HookInput = {
        session_id: 'test-session',
        cwd: testCwd,
        tool_name: 'Stop',
        tool_input: {}
      };

      // Mock lint success but typecheck failure
      mockedExec.mockImplementation((command, callback) => {
        if (command.includes('lint')) {
          callback!(null, { stdout: '✓ Lint checks passed', stderr: '' } as any);
        } else if (command.includes('typecheck') || command.includes('tsc --noEmit')) {
          callback!(new Error('Type check failed'), { 
            stdout: '', 
            stderr: `
src/bad-types.ts(5,12): error TS2322: Type 'string' is not assignable to type 'number'.
src/bad-types.ts(8,5): error TS2339: Property 'nonExistent' does not exist on type 'User'.
            ` 
          } as any);
        }
      });

      const result = await validator.execute(mockInput);
      
      expect(result.hookSpecificOutput?.permissionDecision).toBe('deny');
      expect(result.hookSpecificOutput?.permissionDecisionReason).toContain('Type check failed');
    });

    it('should provide helpful error messages with file locations', async () => {
      const mockInput: HookInput = {
        session_id: 'test-session',
        cwd: testCwd,
        tool_name: 'Stop',
        tool_input: {}
      };

      const lintError = `
/Users/szymondzumak/Developer/.claude/hooks/__tests__/fixtures/test-lint-errors.ts
  2:1   error  'var' is not allowed. Use 'const' or 'let' instead  no-var
  3:27  error  Missing semicolon  semi
  8:7   error  'x' is assigned a value but never used  @typescript-eslint/no-unused-vars
      `;

      mockedExec.mockImplementation((command, callback) => {
        if (command.includes('lint')) {
          callback!(new Error('Lint failed'), { 
            stdout: '', 
            stderr: lintError
          } as any);
        }
      });

      const result = await validator.execute(mockInput);
      
      expect(result.hookSpecificOutput?.permissionDecisionReason).toContain('test-lint-errors.ts');
      expect(result.hookSpecificOutput?.permissionDecisionReason).toContain('no-var');
      expect(result.hookSpecificOutput?.permissionDecisionReason).toContain('Missing semicolon');
    });
  });

  describe('validation with test fixtures', () => {
    it('should detect errors in test-lint-errors.ts fixture', async () => {
      const mockInput: HookInput = {
        session_id: 'test-session',
        cwd: testCwd,
        tool_name: 'Stop',
        tool_input: {}
      };

      // Simulate real lint output for our test fixture
      const realLintError = `
.claude/hooks/__tests__/fixtures/test-lint-errors.ts
  2:1   error  'var' is not allowed. Use 'const' or 'let' instead  no-var
  3:27  error  Missing semicolon  semi
  6:9   error  There should be no space before ')'  space-before-function-paren
  9:5   error  Expected indentation of 2 spaces but found 0  indent
      `;

      mockedExec.mockImplementation((command, callback) => {
        if (command.includes('lint')) {
          callback!(new Error('Lint failed'), { 
            stdout: '', 
            stderr: realLintError
          } as any);
        }
      });

      const result = await validator.execute(mockInput);
      
      expect(result.hookSpecificOutput?.permissionDecision).toBe('deny');
      expect(result.hookSpecificOutput?.permissionDecisionReason).toContain('test-lint-errors.ts');
    });

    it('should detect type errors in test-type-errors.ts fixture', async () => {
      const mockInput: HookInput = {
        session_id: 'test-session',
        cwd: testCwd,
        tool_name: 'Stop',
        tool_input: {}
      };

      // Simulate TypeScript errors for our fixture
      const typeErrors = `
.claude/hooks/__tests__/fixtures/test-type-errors.ts(8,10): error TS2339: Property 'email' does not exist on type 'BadInterface'.
.claude/hooks/__tests__/fixtures/test-type-errors.ts(13,10): error TS2322: Type 'string' is not assignable to type 'number'.
.claude/hooks/__tests__/fixtures/test-type-errors.ts(22,15): error TS2322: Type 'number' is not assignable to type 'string'.
      `;

      mockedExec.mockImplementation((command, callback) => {
        if (command.includes('lint')) {
          callback!(null, { stdout: '✓ Lint passed', stderr: '' } as any);
        } else if (command.includes('typecheck') || command.includes('tsc')) {
          callback!(new Error('Type check failed'), { 
            stdout: '', 
            stderr: typeErrors
          } as any);
        }
      });

      const result = await validator.execute(mockInput);
      
      expect(result.hookSpecificOutput?.permissionDecision).toBe('deny');
      expect(result.hookSpecificOutput?.permissionDecisionReason).toContain('test-type-errors.ts');
      expect(result.hookSpecificOutput?.permissionDecisionReason).toContain("Property 'email' does not exist");
    });
  });

  describe('non-Stop events', () => {
    it('should not validate on other tool events', async () => {
      const mockInput: HookInput = {
        session_id: 'test-session',
        cwd: testCwd,
        tool_name: 'Write',
        tool_input: {
          file_path: '/test/file.ts',
          content: 'const test = "hello";'
        }
      };

      const result = await validator.execute(mockInput);
      
      expect(mockedExec).not.toHaveBeenCalled();
      expect(result.continue).toBe(true);
    });
  });
});