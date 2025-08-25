import { ChangeTrackerHandler } from '@claude-dev/hooks';
import { HookInput } from '@claude-dev/hooks';
import fs from 'fs/promises';
import path from 'path';

// Mock fs for testing
jest.mock('fs/promises');
const mockedFs = fs as jest.Mocked<typeof fs>;

describe('ChangeTrackerHandler', () => {
  let handler: ChangeTrackerHandler;
  const testSessionId = 'test-session-123';
  const testCwd = '/Users/szymondzumak/Developer';

  beforeEach(() => {
    handler = new ChangeTrackerHandler();
    jest.clearAllMocks();
    
    // Mock file operations
    mockedFs.mkdir.mockResolvedValue(undefined);
    mockedFs.writeFile.mockResolvedValue();
    mockedFs.readFile.mockResolvedValue('[]'); // Empty changes initially
  });

  describe('change tracking', () => {
    it('should track Write operations', async () => {
      const mockInput: HookInput = {
        session_id: testSessionId,
        cwd: testCwd,
        tool_name: 'Write',
        tool_input: {
          file_path: '/Users/szymondzumak/Developer/src/component.tsx',
          content: 'export const Component = () => <div>Hello</div>;'
        }
      };

      const result = await handler.execute(mockInput);

      expect(result.continue).toBe(true);
      expect(mockedFs.writeFile).toHaveBeenCalledWith(
        expect.stringContaining(`${testSessionId}-changes.json`),
        expect.stringContaining('"operation":"Write"')
      );
    });

    it('should track Edit operations with old and new content', async () => {
      const mockInput: HookInput = {
        session_id: testSessionId,
        cwd: testCwd,
        tool_name: 'Edit',
        tool_input: {
          file_path: '/Users/szymondzumak/Developer/src/utils.ts',
          old_string: 'const oldFunction = () => {};',
          new_string: 'const newFunction = () => { return "updated"; };'
        }
      };

      const result = await handler.execute(mockInput);

      expect(result.continue).toBe(true);
      expect(mockedFs.writeFile).toHaveBeenCalledWith(
        expect.stringContaining(`${testSessionId}-changes.json`),
        expect.stringMatching(/"operation":"Edit".*"old_string":"const oldFunction.*"new_string":"const newFunction/)
      );
    });

    it('should track MultiEdit operations with all edits', async () => {
      const mockInput: HookInput = {
        session_id: testSessionId,
        cwd: testCwd,
        tool_name: 'MultiEdit',
        tool_input: {
          file_path: '/Users/szymondzumak/Developer/src/config.ts',
          edits: [
            { old_string: 'version: "1.0.0"', new_string: 'version: "1.1.0"' },
            { old_string: 'debug: false', new_string: 'debug: true' }
          ]
        }
      };

      const result = await handler.execute(mockInput);

      expect(result.continue).toBe(true);
      expect(mockedFs.writeFile).toHaveBeenCalledWith(
        expect.stringContaining(`${testSessionId}-changes.json`),
        expect.stringMatching(/"operation":"MultiEdit".*"edits":\[/)
      );
    });

    it('should not track non-file operations', async () => {
      const mockInput: HookInput = {
        session_id: testSessionId,
        cwd: testCwd,
        tool_name: 'Bash',
        tool_input: {
          command: 'npm test'
        }
      };

      const result = await handler.execute(mockInput);

      expect(result.continue).toBe(true);
      expect(mockedFs.writeFile).not.toHaveBeenCalled();
    });
  });

  describe('change aggregation', () => {
    it('should aggregate changes to the same file', async () => {
      // Mock existing changes file
      const existingChanges = JSON.stringify([
        {
          timestamp: new Date().toISOString(),
          file_path: '/Users/szymondzumak/Developer/src/component.tsx',
          operation: 'Write',
          content: 'initial content'
        }
      ]);
      mockedFs.readFile.mockResolvedValue(existingChanges);

      const mockInput: HookInput = {
        session_id: testSessionId,
        cwd: testCwd,
        tool_name: 'Edit',
        tool_input: {
          file_path: '/Users/szymondzumak/Developer/src/component.tsx',
          old_string: 'initial content',
          new_string: 'updated content'
        }
      };

      const result = await handler.execute(mockInput);

      expect(result.continue).toBe(true);
      // Should have written an array with both changes
      const writeCall = mockedFs.writeFile.mock.calls[0][1] as string;
      const changes = JSON.parse(writeCall);
      expect(changes).toHaveLength(2);
      expect(changes[1].operation).toBe('Edit');
    });

    it('should include file statistics in session summary', async () => {
      const mockInput: HookInput = {
        session_id: testSessionId,
        cwd: testCwd,
        tool_name: 'Write',
        tool_input: {
          file_path: '/Users/szymondzumak/Developer/src/new-feature.ts',
          content: 'export const newFeature = () => "awesome";'
        }
      };

      const result = await handler.execute(mockInput);

      expect(result.hookSpecificOutput?.sessionSummary).toContain('Files modified: 1');
      expect(result.hookSpecificOutput?.sessionSummary).toContain('Total operations: 1');
    });
  });

  describe('session persistence', () => {
    it('should create runtime directory if it does not exist', async () => {
      const mockInput: HookInput = {
        session_id: testSessionId,
        cwd: testCwd,
        tool_name: 'Write',
        tool_input: {
          file_path: '/test/file.ts',
          content: 'test content'
        }
      };

      await handler.execute(mockInput);

      expect(mockedFs.mkdir).toHaveBeenCalledWith(
        expect.stringContaining('.claude/runtime'),
        { recursive: true }
      );
    });

    it('should handle file read errors gracefully', async () => {
      // Mock file read error (file doesn't exist yet)
      mockedFs.readFile.mockRejectedValue(new Error('ENOENT: file not found'));

      const mockInput: HookInput = {
        session_id: testSessionId,
        cwd: testCwd,
        tool_name: 'Write',
        tool_input: {
          file_path: '/test/file.ts',
          content: 'test content'
        }
      };

      const result = await handler.execute(mockInput);

      // Should still work and create new changes file
      expect(result.continue).toBe(true);
      expect(mockedFs.writeFile).toHaveBeenCalled();
    });

    it('should handle write errors gracefully', async () => {
      mockedFs.writeFile.mockRejectedValue(new Error('Permission denied'));

      const mockInput: HookInput = {
        session_id: testSessionId,
        cwd: testCwd,
        tool_name: 'Write',
        tool_input: {
          file_path: '/test/file.ts',
          content: 'test content'
        }
      };

      const result = await handler.execute(mockInput);

      // Should not fail the operation due to logging issues
      expect(result.continue).toBe(true);
    });
  });

  describe('session insights', () => {
    it('should provide meaningful session statistics', async () => {
      // Simulate multiple operations
      const operations = [
        { tool_name: 'Write', file_path: '/test/file1.ts' },
        { tool_name: 'Edit', file_path: '/test/file1.ts' },
        { tool_name: 'Write', file_path: '/test/file2.ts' },
        { tool_name: 'MultiEdit', file_path: '/test/file3.ts' }
      ];

      for (const op of operations) {
        const mockInput: HookInput = {
          session_id: testSessionId,
          cwd: testCwd,
          tool_name: op.tool_name,
          tool_input: {
            file_path: op.file_path,
            content: 'test content'
          }
        };
        await handler.execute(mockInput);
      }

      // The last operation should have comprehensive stats
      const lastWriteCall = mockedFs.writeFile.mock.calls.slice(-1)[0][1] as string;
      expect(lastWriteCall).toContain('MultiEdit');
      
      // Check that session summary includes multiple operations
      // This would need to be tested with the actual implementation
    });
  });
});