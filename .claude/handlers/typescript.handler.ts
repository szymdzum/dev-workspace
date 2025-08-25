import { execSync } from 'child_process';
import { TypedHandler, PostToolUseInput, PostToolUseResponse } from '@claude-dev/hooks';

export class CustomTypeScriptHandler extends TypedHandler<'PostToolUse'> {
  readonly event = 'PostToolUse' as const;
  
  async handle(input: PostToolUseInput): Promise<PostToolUseResponse> {
    this.debug(`Processing tool: ${input.tool_name}`);
    
    // Only handle file operations
    if (!this.isFileOperation(input)) {
      this.debug(`Skipping non-file operation: ${input.tool_name}`, true);
      return this.success();
    }

    const filePath = this.getFilePath(input);
    if (!filePath || !this.isTypeScriptFile(filePath)) {
      this.debug(`Skipping non-TypeScript file: ${filePath}`, true);
      return this.success();
    }

    this.debug(`Processing TypeScript file: ${filePath}`);

    try {
      // Auto-organize imports for TypeScript files
      if (this.shouldOrganizeImports(filePath)) {
        this.debug('Organizing imports...');
        console.log(`📝 Organizing imports in ${filePath}...`);
        try {
          execSync(`npx organize-imports-cli ${filePath}`, {
            cwd: input.cwd,
            stdio: 'pipe'
          });
          this.debug('Imports organized successfully', true);
        } catch {
          // Non-fatal, just warn
          this.debug('Could not organize imports');
          return this.warn('Could not organize imports');
        }
      }

      // If editing a schema file, trigger type generation
      if (this.isSchemaFile(filePath)) {
        this.debug('Schema file detected, running type check');
        console.log('🔄 Schema file changed, triggering type generation...');
        try {
          execSync('npm run type-check', {
            cwd: input.cwd,
            stdio: 'inherit'
          });
          this.debug('Type check completed successfully', true);
        } catch {
          this.debug('Type check failed');
          return this.warn('Type checking failed - please review changes');
        }
      }

      this.debug('TypeScript handler completed successfully');
      return this.success();
    } catch (error: any) {
      return {
        decision: 'block',
        reason: `TypeScript handler error: ${error.message}`,
        continue: false
      };
    }
  }

  /**
   * Check if this is a file operation
   */
  private isFileOperation(input: PostToolUseInput): boolean {
    return ['Write', 'Edit', 'MultiEdit'].includes(input.tool_name);
  }

  /**
   * Get file path from any file operation
   */
  private getFilePath(input: PostToolUseInput): string | null {
    const toolInput = input.tool_input as any;
    return toolInput?.file_path || null;
  }

  private isTypeScriptFile(filePath: string): boolean {
    return /\.(ts|tsx|js|jsx)$/.test(filePath);
  }

  private shouldOrganizeImports(filePath: string): boolean {
    // Skip organizing imports for certain files
    return !filePath.includes('node_modules') && 
           !filePath.includes('.d.ts') &&
           !filePath.endsWith('.stories.tsx');
  }

  private isSchemaFile(filePath: string): boolean {
    return filePath.includes('schema') || 
           filePath.includes('types') || 
           filePath.endsWith('.d.ts');
  }
}