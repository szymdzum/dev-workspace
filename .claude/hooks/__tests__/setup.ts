// Global test setup for Claude hooks tests

// Mock console methods to keep test output clean
const originalConsole = global.console;
global.console = {
  ...originalConsole,
  // Keep error and warn for debugging
  error: jest.fn(originalConsole.error),
  warn: jest.fn(originalConsole.warn),
  // Mock info and log to reduce noise
  info: jest.fn(),
  log: jest.fn(),
  debug: jest.fn()
};

// Set up test environment variables
process.env.NODE_ENV = 'test';
process.env.HOOK_DEBUG = '0'; // Disable debug output during tests
process.env.HOOK_VERBOSE = '0';

// Mock commonly used paths
const TEST_CWD = '/Users/szymondzumak/Developer';
process.cwd = jest.fn().mockReturnValue(TEST_CWD);

// Set test timeout
jest.setTimeout(10000);

// Clean up after each test
afterEach(() => {
  jest.clearAllMocks();
});