/// <reference types="vitest" />
import { defineConfig } from 'vite'

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['../../vitest.setup.ts'],
    coverage: {
      provider: 'v8',
      thresholds: {
        global: {
          branches: 25,
          functions: 25,
          lines: 25,
          statements: 25,
        },
      },
    },
  },
  esbuild: {
    target: 'node14',
    jsx: 'automatic',
  },
})
