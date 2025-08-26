/// <reference types="vitest" />
import { defineConfig } from 'vite'

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['../../vitest.setup.ts'],
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
      reportsDirectory: '../../coverage/libs/ui',
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
    },
    // Performance optimizations - CI-safe settings
    poolOptions: {
      threads: {
        singleThread: process.env.CI === 'true',
        isolate: true,
        maxThreads: process.env.CI === 'true' ? 1 : undefined,
        minThreads: process.env.CI === 'true' ? 1 : undefined,
      },
    },
    // Test timeout configurations - more generous for CI
    testTimeout: process.env.CI === 'true' ? 30000 : 10000,
    hookTimeout: process.env.CI === 'true' ? 30000 : 10000,
    teardownTimeout: process.env.CI === 'true' ? 10000 : 5000,
    // Retry configuration for flaky tests
    retry: process.env.CI === 'true' ? 2 : 0,
  },
  esbuild: {
    target: 'node14',
    jsx: 'automatic',
  },
})
