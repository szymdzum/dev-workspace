/**
 * Results Validator Handler - Final Quality Gate
 * 
 * Runs comprehensive validation before Claude presents results.
 * Prevents showing work with lint errors, type issues, or other problems.
 */

import { execSync } from 'child_process';
import { TypedHandler } from './base';
import { StopInput } from '../types/claude-code';
import { StopResponse } from '../types/responses';

/**
 * Configuration for results validation
 */
export interface ResultsValidatorConfig {
  /** Whether to run lint checks */
  runLint: boolean;
  
  /** Whether to run build/type checks */
  runBuild: boolean;
  
  /** Whether to check for test cleanup */
  checkTestFiles: boolean;
  
  /** Whether to scan for debug code */
  checkDebugCode: boolean;
  
  /** Whether to validate TODOs */
  checkTodos: boolean;
  
  /** Maximum execution time for validation (ms) */
  timeout: number;
  
  /** Files/patterns to exclude from validation */
  excludePatterns: string[];
}

/**
 * Results validator - ensures quality before presenting work
 */
export class ResultsValidatorHandler extends TypedHandler<'Stop'> {
  readonly event = 'Stop' as const;
  private validatorConfig: ResultsValidatorConfig;
  
  // Track session changes (shared across all instances)
  private static sessionChanges = new Set<string>();
  
  constructor(config: Partial<ResultsValidatorConfig> = {}) {
    super();
    
    this.validatorConfig = {
      runLint: true,
      runBuild: true,
      checkTestFiles: true,
      checkDebugCode: true,
      checkTodos: false, // Can be noisy
      timeout: 60000, // 1 minute
      excludePatterns: [
        'node_modules/**',
        'dist/**',
        '.git/**',
        '**/*.d.ts',
        '**/coverage/**'
      ],
      ...config
    };
  }
  
  async handle(input: StopInput): Promise<StopResponse> {
    this.debug(`Results validation triggered`);
    
    // Prevent infinite recursion
    if (input.stop_hook_active) {
      this.debug('Already in stop hook, skipping validation');
      return { continue: true };
    }
    
    console.log('🔍 Running final validation before presenting results...');
    
    try {
      const validationResults = await this.runComprehensiveValidation();
      
      if (validationResults.hasErrors) {
        this.debug(`Validation failed: ${validationResults.summary}`);
        
        // Force Claude to continue and fix issues
        return {
          decision: 'block',
          reason: `Hold on! I found issues that need to be fixed first:\n${validationResults.summary}\n\nLet me address these before presenting the results.`
        };
      }
      
      console.log('✅ All validation checks passed!');
      this.debug('All validations passed successfully');
      
      return { continue: true };
      
    } catch (error: any) {
      this.debug(`Validation error: ${error.message}`);
      console.warn(`⚠️ Validation system error: ${error.message}`);
      
      // Don't block on validation system errors
      return { continue: true };
    }
  }
  
  /**
   * Add a file to the session changes tracking
   */
  static trackChange(filePath: string): void {
    ResultsValidatorHandler.sessionChanges.add(filePath);
  }
  
  /**
   * Get all tracked changes in this session
   */
  static getTrackedChanges(): string[] {
    return Array.from(ResultsValidatorHandler.sessionChanges);
  }
  
  /**
   * Clear tracked changes (e.g., at session start)
   */
  static clearTrackedChanges(): void {
    ResultsValidatorHandler.sessionChanges.clear();
  }
  
  /**
   * Run all validation checks
   */
  private async runComprehensiveValidation(): Promise<ValidationResults> {
    const results: ValidationResults = {
      hasErrors: false,
      issues: [],
      summary: ''
    };
    
    // Get changed files for targeted validation
    const changedFiles = ResultsValidatorHandler.getTrackedChanges();
    this.debug(`Validating ${changedFiles.length} changed files`, true);
    
    // Run validation checks in parallel for speed
    const checks = await Promise.allSettled([
      this.validatorConfig.runLint ? this.validateLinting() : Promise.resolve(null),
      this.validatorConfig.runBuild ? this.validateBuild() : Promise.resolve(null),
      this.validatorConfig.checkTestFiles ? this.checkForTestFiles() : Promise.resolve(null),
      this.validatorConfig.checkDebugCode ? this.scanForDebugCode() : Promise.resolve(null),
      this.validatorConfig.checkTodos ? this.checkUnresolved() : Promise.resolve(null)
    ]);
    
    // Process results
    checks.forEach((result, index) => {
      if (result.status === 'fulfilled' && result.value) {
        results.issues.push(result.value);
        results.hasErrors = true;
      } else if (result.status === 'rejected') {
        this.debug(`Check ${index} failed: ${result.reason}`);
      }
    });
    
    // Build summary
    if (results.hasErrors) {
      results.summary = results.issues.map(issue => `• ${issue}`).join('\n');
    }
    
    return results;
  }
  
  /**
   * Validate linting status
   */
  private async validateLinting(): Promise<string | null> {
    try {
      this.debug('Running lint validation...', true);
      
      // Run lint on affected files only
      execSync('nx affected -t lint --uncommitted --nxBail', {
        stdio: 'pipe',
        timeout: this.validatorConfig.timeout,
        cwd: process.cwd()
      });
      
      return null; // No issues
    } catch (error: any) {
      return 'Lint errors found - code style issues need to be fixed';
    }
  }
  
  /**
   * Validate build/type checking
   */
  private async validateBuild(): Promise<string | null> {
    try {
      this.debug('Running build validation...', true);
      
      // Run build on affected files only
      execSync('nx affected -t build --uncommitted --nxBail', {
        stdio: 'pipe',
        timeout: this.validatorConfig.timeout,
        cwd: process.cwd()
      });
      
      return null; // No issues
    } catch (error: any) {
      return 'Build/type errors found - code has compilation issues';
    }
  }
  
  /**
   * Check for leftover test files
   */
  private async checkForTestFiles(): Promise<string | null> {
    try {
      this.debug('Checking for test files...', true);
      
      const testFiles = execSync(
        `find . -name "test-*.*" -o -name "*-test.*" | grep -v node_modules | head -5`, 
        { encoding: 'utf-8', stdio: 'pipe' }
      ).trim();
      
      if (testFiles) {
        const fileList = testFiles.split('\n').slice(0, 3);
        return `Test files found that should be cleaned up: ${fileList.join(', ')}${fileList.length > 3 ? '...' : ''}`;
      }
      
      return null;
    } catch {
      return null; // No test files found
    }
  }
  
  /**
   * Scan for debug code that shouldn't be committed
   */
  private async scanForDebugCode(): Promise<string | null> {
    try {
      this.debug('Scanning for debug code...', true);
      
      // Look for common debug patterns
      const debugPatterns = [
        'console\\.log',
        'console\\.debug', 
        'debugger;',
        'TODO.*REMOVE',
        'FIXME.*DELETE'
      ];
      
      for (const pattern of debugPatterns) {
        const matches = execSync(
          `grep -r "${pattern}" . --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" --exclude-dir=node_modules --exclude-dir=dist | head -3`,
          { encoding: 'utf-8', stdio: 'pipe' }
        ).trim();
        
        if (matches) {
          return `Debug code found that should be removed: ${pattern}`;
        }
      }
      
      return null;
    } catch {
      return null; // No debug code found
    }
  }
  
  /**
   * Check for unresolved TODOs/FIXMEs
   */
  private async checkUnresolved(): Promise<string | null> {
    try {
      this.debug('Checking for unresolved TODOs...', true);
      
      const todos = execSync(
        `grep -r "TODO\\|FIXME" . --include="*.ts" --include="*.tsx" --exclude-dir=node_modules | wc -l`,
        { encoding: 'utf-8', stdio: 'pipe' }
      ).trim();
      
      const count = parseInt(todos, 10);
      if (count > 5) {
        return `Many unresolved TODOs/FIXMEs found (${count}) - consider addressing some`;
      }
      
      return null;
    } catch {
      return null;
    }
  }
}

/**
 * Results of validation checks
 */
interface ValidationResults {
  hasErrors: boolean;
  issues: string[];
  summary: string;
}

/**
 * Factory for common validator configurations
 */
export const ResultsValidator = {
  /**
   * Strict validation - catches everything
   */
  strict(): ResultsValidatorHandler {
    return new ResultsValidatorHandler({
      runLint: true,
      runBuild: true,
      checkTestFiles: true,
      checkDebugCode: true,
      checkTodos: true
    });
  },
  
  /**
   * Standard validation - reasonable checks
   */
  standard(): ResultsValidatorHandler {
    return new ResultsValidatorHandler({
      runLint: true,
      runBuild: true,
      checkTestFiles: true,
      checkDebugCode: false, // Can be noisy
      checkTodos: false
    });
  },
  
  /**
   * Fast validation - essential checks only
   */
  fast(): ResultsValidatorHandler {
    return new ResultsValidatorHandler({
      runLint: true,
      runBuild: false, // Skip slow build
      checkTestFiles: true,
      checkDebugCode: false,
      checkTodos: false,
      timeout: 30000 // 30 seconds
    });
  }
};