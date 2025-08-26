/// <reference types="vitest" />
import { defineConfig } from 'vite'
import { resolve } from 'path'

export default defineConfig({
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
      '@ui': resolve(__dirname, './libs/ui/src'),
      '@playground': resolve(__dirname, './apps/playground/src'),
    },
  },
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./vitest.setup.ts'],
    include: ['**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}'],
    exclude: [
      '**/node_modules/**',
      '**/dist/**',
      '**/build/**',
      '**/cypress/**',
      '**/.{idea,git,cache,output,temp}/**',
      '**/coverage/**',
    ],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'lcov'],
      reportsDirectory: './coverage',
      exclude: [
        'node_modules/',
        'dist/',
        'coverage/',
        '**/*.d.ts',
        '**/*.config.{js,ts}',
        '**/.{eslint,prettier}rc.{js,cjs,yml}',
        '**/test-utils.ts',
        '**/vitest.setup.ts',
      ],
      thresholds: {
        global: {
          branches: 25,
          functions: 25,
          lines: 25,
          statements: 25,
        },
      },
    },
    // Performance optimizations
    poolOptions: {
      threads: {
        singleThread: false,
        isolate: true,
      },
    },
    // Test timeout configurations
    testTimeout: 10000,
    hookTimeout: 10000,
    teardownTimeout: 5000,
    // Reporter configuration
    reporter: ['verbose', 'html'],
    outputFile: {
      html: './coverage/test-report.html',
    },
  },
})
