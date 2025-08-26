/// <reference types="vitest" />
import { defineConfig } from 'vite'

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['../../vitest.setup.ts'],
  },
  esbuild: {
    target: 'node14',
    jsx: 'automatic',
  },
})
