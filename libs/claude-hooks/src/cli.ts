#!/usr/bin/env node

/**
 * Claude Hooks CLI Runner
 * 
 * Automatically discovers and runs hook configurations.
 * Handles TypeScript compilation on-the-fly.
 */

import * as fs from 'fs';
import * as path from 'path';
import { ClaudeHooks, HookPresets } from './builder/ClaudeHooks';
import { exit } from './types/helpers';
import { ExitCode } from './types/responses';

async function main() {
  try {
    // Look for hook configuration
    const cwd = process.cwd();
    const hookPaths = [
      path.resolve(cwd, '.claude/hooks/index.ts'),
      path.resolve(cwd, '.claude/hooks/index.js'),
      path.resolve(cwd, '.claude/hooks.ts'),
      path.resolve(cwd, '.claude/hooks.js'),
      path.resolve(cwd, 'claude-hooks.ts'),
      path.resolve(cwd, 'claude-hooks.js')
    ];
    
    let hooksInstance: ClaudeHooks | null = null;
    
    // Try to find and load configuration
    for (const hookPath of hookPaths) {
      if (fs.existsSync(hookPath)) {
        console.log(`🔍 Loading hooks from: ${hookPath}`);
        
        try {
          // Register ts-node for TypeScript files
          if (hookPath.endsWith('.ts')) {
            try {
              require('ts-node/register');
            } catch {
              // Try tsx as fallback
              try {
                require('tsx/cjs');
              } catch {
                exit(`TypeScript hooks found but no TypeScript runner available. Please install ts-node or tsx.`, ExitCode.Error);
              }
            }
          }
          
          // Load the configuration
          const config = require(hookPath);
          hooksInstance = config.default || config;
          
          if (!(hooksInstance instanceof ClaudeHooks)) {
            exit(`Invalid hook configuration in ${hookPath}. Must export a ClaudeHooks instance.`, ExitCode.Error);
          }
          
          break;
        } catch (error: any) {
          exit(`Failed to load hooks from ${hookPath}: ${error.message}`, ExitCode.Error);
        }
      }
    }
    
    // Fall back to default configuration if no config found
    if (!hooksInstance) {
      console.log(`🔍 No hook configuration found, using defaults`);
      hooksInstance = HookPresets.basic();
    }
    
    // Run the hooks
    await hooksInstance.run();
    
  } catch (error: any) {
    exit(`Hook runner failed: ${error.message}`, ExitCode.Error);
  }
}

// Handle uncaught errors
process.on('uncaughtException', (error) => {
  console.error('Uncaught exception:', error);
  process.exit(ExitCode.Error);
});

process.on('unhandledRejection', (reason) => {
  console.error('Unhandled rejection:', reason);
  process.exit(ExitCode.Error);
});

// Run if this is the main module
if (require.main === module) {
  main();
}