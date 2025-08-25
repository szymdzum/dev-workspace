import type { Config } from 'jest';

const config: Config = {
  displayName: 'claude-hooks',
  preset: '../jest.preset.js',
  testEnvironment: 'node',
  
  // Test file patterns
  testMatch: [
    '<rootDir>/hooks/__tests__/**/*.test.ts'
  ],
  
  // Coverage configuration
  collectCoverageFrom: [
    'hooks/**/*.ts',
    '!hooks/**/*.test.ts',
    '!hooks/__tests__/**/*'
  ],
  coverageDirectory: '../coverage/.claude',
  coverageReporters: ['text', 'lcov', 'html'],
  
  // Module resolution for workspace packages
  moduleNameMapper: {
    '^@claude-dev/hooks$': '<rootDir>/../libs/claude-hooks/src/index.ts',
    '^@claude-dev/hooks/(.*)$': '<rootDir>/../libs/claude-hooks/src/$1'
  },
  
  // Setup and teardown
  setupFilesAfterEnv: ['<rootDir>/hooks/__tests__/setup.ts'],
  
  // Transform configuration
  transform: {
    '^.+\\.[tj]s$': ['ts-jest', {
      tsconfig: '<rootDir>/tsconfig.json'
    }]
  },
  
  // File extensions
  moduleFileExtensions: ['ts', 'js', 'json'],
  
  // Test timeout for integration tests
  testTimeout: 10000,
  
  // Verbose output (removing - causes warning)
  // verbose: true,
  
  // Clear mocks between tests
  clearMocks: true,
  restoreMocks: true
};

export default config;