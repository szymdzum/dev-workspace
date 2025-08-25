// Test file with intentional hardcoded secrets (should be blocked by security handler)
export const config = {
  // These should trigger security warnings
  apiKey: "sk-1234567890abcdef1234567890abcdef",
  databasePassword: "super_secret_password_123",
  authToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ",
  awsSecretKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
  
  // Environment variables that should also be flagged
  env: {
    SECRET_KEY: "hardcoded-secret-key-value",
    DB_PASSWORD: "password123",
    API_SECRET: "this-should-not-be-hardcoded"
  }
};

export function authenticateUser() {
  const hardcodedPassword = "admin123"; // Another security violation
  return hardcodedPassword;
}

// GitHub token (should be detected)
const githubToken = "ghp_1234567890abcdefghijklmnopqrstuvwxyz123";

// Credit card number (should be detected)
const creditCard = "4532-1234-5678-9012";