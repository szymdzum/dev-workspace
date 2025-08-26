import * as matchers from '@testing-library/jest-dom/matchers'
import { cleanup } from '@testing-library/react'
import { afterEach, beforeEach, expect } from 'vitest'

// Increase test stability in CI environments
if (process.env.CI) {
  // Increase Jest timeouts for CI
  beforeEach(() => {
    // Additional setup time for CI
  })
}

// Extend Vitest's expect with jest-dom matchers
expect.extend(matchers)

// Cleanup after each test case (React Testing Library)
afterEach(() => {
  cleanup()
})

// Mock window.matchMedia for tests
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: (query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: () => {},
    removeListener: () => {},
    addEventListener: () => {},
    removeEventListener: () => {},
    dispatchEvent: () => {},
  }),
})

// Mock IntersectionObserver
global.IntersectionObserver = class IntersectionObserver {
  constructor() {}
  observe() {
    return null
  }
  disconnect() {
    return null
  }
  unobserve() {
    return null
  }
}

// Mock ResizeObserver
global.ResizeObserver = class ResizeObserver {
  constructor() {}
  observe() {
    return null
  }
  disconnect() {
    return null
  }
  unobserve() {
    return null
  }
}

// Add additional DOM environment stability
if (typeof window !== 'undefined') {
  // Mock additional browser APIs that might be missing in CI
  window.scrollTo = window.scrollTo || (() => {})
  window.requestAnimationFrame = window.requestAnimationFrame || ((cb) => setTimeout(cb, 16))
  window.cancelAnimationFrame = window.cancelAnimationFrame || ((id) => clearTimeout(id))
  
  // Ensure consistent viewport size in CI
  Object.defineProperty(window, 'innerWidth', {
    writable: true,
    configurable: true,
    value: 1024,
  })
  Object.defineProperty(window, 'innerHeight', {
    writable: true,
    configurable: true,
    value: 768,
  })
}
