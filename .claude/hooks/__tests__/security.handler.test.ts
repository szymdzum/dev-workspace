import { SecurityHandler, HookInput } from '@claude-dev/hooks';
import { createMockHookInput, TEST_CWD } from './test-utils';

describe('SecurityHandler', () => {
  let handler: SecurityHandler;

  beforeEach(() => {
    handler = new SecurityHandler();
  });

  describe('secret detection', () => {
    it('should detect API keys in code content', async () => {
      const mockInput = createMockHookInput({
        tool_input: {
          file_path: '/test/config.ts',
          content: 'const apiKey = "sk-1234567890abcdef1234567890abcdef";'
        }
      });

      const result = await handler.execute(mockInput);
      
      expect(result.hookSpecificOutput?.permissionDecision).toBe('deny');
      expect(result.hookSpecificOutput?.permissionDecisionReason).toContain('Hardcoded secret detected');
    });

    it('should detect database passwords', async () => {
      const mockInput = createMockHookInput({
        tool_name: 'Edit',
        tool_input: {
          file_path: '/test/db.ts',
          new_string: 'const password = "super_secret_password_123";'
        }
      });

      const result = await handler.execute(mockInput);
      
      expect(result.hookSpecificOutput?.permissionDecision).toBe('deny');
    });

    it('should detect JWT tokens', async () => {
      const mockInput = createMockHookInput({
        tool_name: 'MultiEdit',
        tool_input: {
          file_path: '/test/auth.ts',
          edits: [{
            old_string: 'token: ""',
            new_string: 'token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ"'
          }]
        }
      });

      const result = await handler.execute(mockInput);
      
      expect(result.hookSpecificOutput?.permissionDecision).toBe('deny');
    });

    it('should allow safe code without secrets', async () => {
      const mockInput: HookInput = {
        session_id: 'test-session',
        cwd: '/test',
        tool_name: 'Write',
        tool_input: {
          file_path: '/test/safe.ts',
          content: 'const message = "Hello world!"; export default message;'
        }
      };

      const result = await handler.execute(mockInput);
      
      expect(result.hookSpecificOutput?.permissionDecision).not.toBe('deny');
      expect(result.continue).toBe(true);
    });
  });

  describe('file path validation', () => {
    it('should block writes to sensitive system paths', async () => {
      const mockInput: HookInput = {
        session_id: 'test-session',
        cwd: '/test',
        tool_name: 'Write',
        tool_input: {
          file_path: '/etc/passwd',
          content: 'malicious content'
        }
      };

      const result = await handler.execute(mockInput);
      
      expect(result.hookSpecificOutput?.permissionDecision).toBe('deny');
      expect(result.hookSpecificOutput?.permissionDecisionReason).toContain('Sensitive path');
    });

    it('should allow writes to project paths', async () => {
      const mockInput = createMockHookInput({
        tool_input: {
          file_path: `${TEST_CWD}/src/component.tsx`,
          content: 'export const Component = () => <div>Hello</div>;'
        }
      });

      const result = await handler.execute(mockInput);
      
      expect(result.hookSpecificOutput?.permissionDecision).not.toBe('deny');
    });
  });

  describe('bash command validation', () => {
    it('should block dangerous rm commands', async () => {
      const mockInput: HookInput = {
        session_id: 'test-session',
        cwd: '/test',
        tool_name: 'Bash',
        tool_input: {
          command: 'rm -rf /'
        }
      };

      const result = await handler.execute(mockInput);
      
      expect(result.hookSpecificOutput?.permissionDecision).toBe('deny');
      expect(result.hookSpecificOutput?.permissionDecisionReason).toContain('Dangerous command');
    });

    it('should allow safe commands', async () => {
      const mockInput: HookInput = {
        session_id: 'test-session',
        cwd: '/test',
        tool_name: 'Bash',
        tool_input: {
          command: 'npm test'
        }
      };

      const result = await handler.execute(mockInput);
      
      expect(result.hookSpecificOutput?.permissionDecision).not.toBe('deny');
    });
  });
});