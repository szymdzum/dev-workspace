#!/usr/bin/env node

import { HookInput } from './types';
import { defaultConfig } from './config';
import { SecurityHandler } from './handlers/security.handler';
import { TypeScriptHandler } from './handlers/typescript.handler';
import { BashHandler } from './handlers/bash.handler';

const handlers: Record<string, any> = {
  'security': new SecurityHandler(),
  'typescript': new TypeScriptHandler(),
  'bash': new BashHandler(),
};

async function main() {
  try {
    // Read JSON input from stdin
    const input: HookInput = JSON.parse(await readStdin());
    
    // Check if hooks are enabled
    if (!defaultConfig.enabled) {
      process.exit(0);
    }

    // Determine which handlers to run
    const handlersToRun = getApplicableHandlers(input);
    
    // Execute handlers sequentially
    for (const handlerName of handlersToRun) {
      const handler = handlers[handlerName];
      if (!handler) {
        console.warn(`⚠️ Handler not found: ${handlerName}`);
        continue;
      }

      const result = await handler.handle(input);
      if (!result.shouldContinue) {
        process.exit(1);
      }
    }

    process.exit(0);
  } catch (error) {
    console.error('Hook execution failed:', error);
    process.exit(1);
  }
}

function getApplicableHandlers(input: HookInput): string[] {
  const handlerNames: string[] = [];

  // Tool-based handlers
  if (input.tool_name && defaultConfig.handlers[input.tool_name]) {
    handlerNames.push(...defaultConfig.handlers[input.tool_name]);
  }

  // File-based handlers
  if (input.tool_input?.file_path) {
    const extension = getFileExtension(input.tool_input.file_path);
    if (extension && defaultConfig.fileHandlers[extension]) {
      handlerNames.push(...defaultConfig.fileHandlers[extension]);
    }
  }

  // Remove duplicates
  return [...new Set(handlerNames)];
}

function getFileExtension(filePath: string): string | null {
  const match = filePath.match(/\.([^.]+)$/);
  return match ? match[1] : null;
}

function readStdin(): Promise<string> {
  return new Promise((resolve) => {
    let data = '';
    process.stdin.on('data', chunk => data += chunk);
    process.stdin.on('end', () => resolve(data));
  });
}

if (require.main === module) {
  main();
}