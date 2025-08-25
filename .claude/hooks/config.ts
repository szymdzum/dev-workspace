export interface HookConfig {
  enabled: boolean;
  handlers: {
    [toolName: string]: string[];
  };
  fileHandlers: {
    [extension: string]: string[];
  };
}

export const defaultConfig: HookConfig = {
  enabled: true,
  handlers: {
    'Write': ['security', 'typescript'],
    'Edit': ['security', 'typescript'],
    'MultiEdit': ['security', 'typescript'],
    'Bash': ['bash', 'security']
  },
  fileHandlers: {
    'ts': ['typescript'],
    'tsx': ['typescript'],
    'js': ['typescript'], // Still use TS handler for organizing imports
    'jsx': ['typescript'],
    'env': ['security']
  }
};