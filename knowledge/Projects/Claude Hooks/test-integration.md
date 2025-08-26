# Testing Claude Hooks Integration

## 🧪 **How to Test the Hooks**

### **Method 1: Simulate Claude Code Tool Call**
This is what happens when Claude tries to write a file:

```bash
cd /Users/szymondzumak/Developer

# Simulate Claude trying to write a file with secrets
echo '{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "config.js",
    "content": "const apiKey = \"sk-1234567890123456789012345678901234567890123456789\";\nmodule.exports = { apiKey };"
  }
}' | .claude/hooks/test-security.sh
```

**Expected Output:**
```json
{
  "continue": false,
  "hookSpecificOutput": {
    "permissionDecision": "deny", 
    "permissionDecisionReason": "OpenAI API key detected in code. Use environment variables instead."
  }
}
```

### **Method 2: Test Safe Code**
```bash
# Simulate Claude writing safe code
echo '{
  "tool_name": "Write", 
  "tool_input": {
    "file_path": "config.js",
    "content": "const apiKey = process.env.OPENAI_API_KEY;\nmodule.exports = { apiKey };"
  }
}' | .claude/hooks/test-security.sh
```

**Expected Output:**
```json
{
  "continue": true
}
```

## 🔗 **Actual Claude Code Integration**

### **Step 1: Add Hook to Claude Code Settings**

Edit `~/.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "/Users/szymondzumak/Developer/.claude/hooks/test-security.sh"
          }
        ]
      }
    ]
  }
}
```

### **Step 2: Test with Claude Code**
1. Open Claude Code in this directory
2. Ask Claude: "Create a config.js file with this API key: sk-1234..."
3. Watch the hook intercept and block it
4. Claude will get the feedback and suggest environment variables instead

### **Step 3: Verify Hook is Active**
In Claude Code, run:
```
/hooks
```
You should see your hook listed and active.

## 🎯 **What You'll See**

### **Without Hooks (Normal Claude)**
**You:** "Write a config with API key sk-123..."
**Claude:** *Creates file with hardcoded API key* ❌

### **With Hooks (Protected)**
**You:** "Write a config with API key sk-123..." 
**Claude:** "I notice you want to include an API key. For security, I'll use environment variables instead." ✅

## 🚨 **Important Notes**

1. **Only affects Claude's actions** - not your manual file editing
2. **Runs BEFORE Claude writes** - prevents the security issue
3. **Gives Claude feedback** - so it can fix the approach
4. **Transparent to you** - you just see Claude making better choices

## 🔍 **Debug Mode**
To see hook execution in detail:
```bash
claude --debug
```

This will show:
```
[DEBUG] Executing hooks for PreToolUse:Write
[DEBUG] Hook command: /path/to/security-check.sh
[DEBUG] Hook output: {"continue":false,"reason":"API key detected"}
[DEBUG] Tool call blocked, providing feedback to Claude
```