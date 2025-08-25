// Test utilities for Claude hooks

export const TEST_CWD = '/Users/szymondzumak/Developer';

export const createMockHookInput = (overrides: any = {}) => ({
  session_id: 'test-session',
  cwd: TEST_CWD,
  tool_name: 'Write',
  tool_input: {
    file_path: '/test/file.ts',
    content: 'test content'
  },
  ...overrides
});

export const mockExecSuccess = (output = 'success') => ({
  stdout: output,
  stderr: ''
});

export const mockExecFailure = (error = 'failure') => {
  const err = new Error('Command failed');
  (err as any).stdout = '';
  (err as any).stderr = error;
  return err;
};