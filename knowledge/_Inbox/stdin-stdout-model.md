## The Claude Code Hooks stdin/stdout Model: Where UNIX Pipes Meet AI Drama

Alright, buckle up buttercup, because Claude Code's hook system is basically UNIX philosophy with a JSON addiction. Here's how this beautiful mess works:

### The Input Dance (stdin)

Every hook gets fed a JSON meal through stdin like it's 1970 and pipes are still cool (spoiler: they are). Here's what arrives at your hook's doorstep:

```json
{
  "session_id": "abc123",
  "transcript_path": "/Users/whoever/.claude/projects/blah/uuid.jsonl",
  "cwd": "/Users/whoever/project",
  "hook_event_name": "PreToolUse",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/disaster.js",
    "content": "console.log('hello world')"  // yes, they're writing console.log in 2025
  }
}
```

Your hook script reads this like:
```python
import json
import sys

# Slurp that JSON like it's morning coffee
input_data = json.load(sys.stdin)
```

### The Response Tango (stdout/stderr + exit codes)

Now here's where it gets *spicy*. You've got two ways to talk back:

#### Method 1: Exit Code Caveman Style

- **Exit 0**: "All good, chief!" - stdout shown in transcript mode (Ctrl-R)
- **Exit 2**: "STOP RIGHT THERE!" - stderr feeds back to Claude (blocks tool execution)
- **Any other exit**: "Meh, whatever" - stderr shown to user, life goes on

```bash
#!/bin/bash
# The simplest hook that could possibly work
echo "Tool ran at $(date)" >> ~/claude-is-watching.log
exit 0  # Claude proceeds, blissfully unaware
```

#### Method 2: JSON Sophisticate Mode

Return structured JSON for when exit codes aren't fancy enough for your taste:

```python
#!/usr/bin/env python3
import json
import sys

# After reading stdin and judging Claude's choices...
output = {
    "decision": "block",  # "I think not!"
    "reason": "You're trying to delete node_modules again, aren't you?",
    "suppressOutput": True,  # Shhh, no one needs to see this
    "systemMessage": "⚠️ Hook prevented a catastrophe"
}

print(json.dumps(output))
sys.exit(0)  # Exit 0 but JSON says "block" - chef's kiss
```

### The Special Cases (Because Of Course)

**UserPromptSubmit is the special snowflake**: When exit code is 0, stdout actually becomes context for Claude. It's the only hook where your stdout isn't just theater mode decoration:

```python
# UserPromptSubmit hook
print("BTW Claude, it's 3am and the user hasn't slept in 72 hours")
sys.exit(0)  # Claude now knows to suggest sleep instead of more coding
```

**PreToolUse can play permission god**:
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",  // "Not today, Satan"
    "permissionDecisionReason": "Nice try writing to /etc/passwd"
  }
}
```

### The Execution Reality Check

- **60-second timeout**: Because infinite loops are so 2010
- **Parallel execution**: All matching hooks run simultaneously like a distributed circus
- **CLAUDE_PROJECT_DIR**: The only env var that matters (it's your project root, genius)

### A Working Example That Actually Does Something

```python
#!/usr/bin/env python3
"""Post-write Python formatter - because Claude's formatting is... optimistic"""
import json
import sys
import subprocess

data = json.load(sys.stdin)

if data.get("tool_name") == "Write":
    file_path = data.get("tool_input", {}).get("file_path", "")

    if file_path.endswith(".py"):
        # Format it because Claude thinks 8-space indents are "readable"
        result = subprocess.run(
            ["black", file_path],
            capture_output=True,
            text=True
        )

        if result.returncode != 0:
            print(f"Black failed: {result.stderr}", file=sys.stderr)
            sys.exit(1)  # Non-blocking error

        print(f"✨ Formatted {file_path} - you're welcome")
        sys.exit(0)

sys.exit(0)  # Not our circus, not our monkeys
```

### The TL;DR

1. **Input**: JSON through stdin (read it with `json.load(sys.stdin)`)
2. **Output Method 1**: Exit codes (0=good, 2=block, other=meh)
3. **Output Method 2**: JSON to stdout for fancy control
4. **Special sauce**: UserPromptSubmit's stdout becomes context, PreToolUse can override permissions
5. **Remember**: stderr on exit 2 talks to Claude, everything else is user theater

And that's how Claude Code reinvented CGI scripts with extra steps. *mic drop* 🎤

Want me to show you how to build a hook that prevents Claude from creating yet another `utils.js` file? Because we both know it's coming.