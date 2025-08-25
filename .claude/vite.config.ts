import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  build: {
    // Build all CLI tools as separate executables
    lib: {
      entry: {
        'check-secrets': resolve(__dirname, 'hooks/cli/check-secrets.ts'),
        'validate': resolve(__dirname, 'hooks/cli/validate.ts'),
        'track-changes': resolve(__dirname, 'hooks/cli/track-changes.ts'),
        'final-check': resolve(__dirname, 'hooks/cli/final-check.ts'),
        'analyze-session': resolve(__dirname, 'hooks/cli/analyze-session.ts'),
      },
      formats: ['cjs'],
      fileName: (format, name) => `${name}.js`
    },
    
    // Output to cache/dist/cli directory
    outDir: '.claude/cache/dist/cli',
    
    // Clear output directory
    emptyOutDir: true,
    
    rollupOptions: {
      // Mark Node.js built-ins as external
      external: [
        'fs', 'fs/promises', 'path', 'child_process', 'process', 'util',
        'crypto', 'os', 'events', 'stream', 'url', 'querystring'
      ],
      
      output: {
        // Add shebang to make files executable (only once)
        banner: (chunk) => chunk.isEntry ? '#!/usr/bin/env node' : '',
        
        // CommonJS format for Node.js compatibility
        format: 'cjs',
        
        // Don't create external imports for our workspace packages
        exports: 'auto',
        
        // Keep the directory structure clean
        entryFileNames: '[name].js',
        
        // Handle the claude-hooks library by bundling it
        manualChunks: undefined
      }
    },
    
    // Target Node.js environment
    target: 'node18',
    
    // Don't minify for better debugging
    minify: false,
    
    // Generate sourcemaps for debugging
    sourcemap: process.env.NODE_ENV !== 'production',
  },
  
  resolve: {
    alias: {
      '@claude-dev/hooks': resolve(__dirname, '../libs/claude-hooks/src/index.ts')
    }
  },
  
  define: {
    // Ensure environment variables are available
    'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV || 'production'),
  },
  
  // Optimize dependencies
  optimizeDeps: {
    // Don't pre-bundle Node.js built-ins
    exclude: ['fs', 'path', 'child_process', 'process', 'util', 'crypto', 'os']
  }
});