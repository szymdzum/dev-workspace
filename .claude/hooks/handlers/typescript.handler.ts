import { BaseHandler, HookInput, HandlerResult } from '../types';
import { execSync } from 'child_process';

export class TypeScriptHandler extends BaseHandler {
  async handle(input: HookInput): Promise<HandlerResult> {
    const filePath = input.tool_input?.file_path;
    if (!filePath || !this.isTypeScriptFile(filePath)) {
      return this.success();
    }

    try {
      // Auto-organize imports for TypeScript files
      if (this.shouldOrganizeImports(filePath)) {
        console.log(`📝 Organizing imports in ${filePath}...`);
        try {
          execSync(`npx organize-imports-cli ${filePath}`, {
            cwd: input.cwd,
            stdio: 'pipe'
          });
        } catch {
          // Non-fatal, just warn
          return this.warn('Could not organize imports');
        }
      }

      // If editing a schema file, trigger type generation
      if (this.isSchemaFile(filePath)) {
        console.log('🔄 Schema file changed, triggering type generation...');
        try {
          execSync('npm run type-check', {
            cwd: input.cwd,
            stdio: 'inherit'
          });
        } catch {
          return this.warn('Type checking failed - please review changes');
        }
      }

      return this.success();
    } catch (error) {
      return this.fail(`TypeScript handler error: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  private isTypeScriptFile(filePath: string): boolean {
    return /\.(ts|tsx)$/.test(filePath);
  }

  private shouldOrganizeImports(filePath: string): boolean {
    // Organize imports for most TS files, but not for generated files
    return !filePath.includes('.generated.') && 
           !filePath.includes('node_modules');
  }

  private isSchemaFile(filePath: string): boolean {
    return filePath.includes('.schema.') || 
           filePath.includes('schema.ts') ||
           filePath.includes('.prisma');
  }
}