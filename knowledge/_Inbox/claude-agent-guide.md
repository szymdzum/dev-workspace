# The Claude Code Agent Engineering Guide

_Or: How I Learned to Stop Worrying and Love 9400-Token Prompts_

## Table of Contents

1. [The Brutal Truth About Claude Code](https://claude.ai/chat/87271a57-30bd-48c4-9bc4-80248e3a1368#the-brutal-truth)
2. [Agent Architecture That Actually Works](https://claude.ai/chat/87271a57-30bd-48c4-9bc4-80248e3a1368#agent-architecture)
3. [Personality Profiles & Behavioral Engineering](https://claude.ai/chat/87271a57-30bd-48c4-9bc4-80248e3a1368#personality-profiles)
4. [The Hook System](https://claude.ai/chat/87271a57-30bd-48c4-9bc4-80248e3a1368#hook-system)
5. [Model Selection Economics](https://claude.ai/chat/87271a57-30bd-48c4-9bc4-80248e3a1368#model-selection)
6. [Tool Hierarchy & Decision Trees](https://claude.ai/chat/87271a57-30bd-48c4-9bc4-80248e3a1368#tool-hierarchy)
7. [Implementation Templates](https://claude.ai/chat/87271a57-30bd-48c4-9bc4-80248e3a1368#implementation-templates)
8. [Validation & Testing](https://claude.ai/chat/87271a57-30bd-48c4-9bc4-80248e3a1368#validation-testing)

---

## The Brutal Truth About Claude Code {#the-brutal-truth}

### What We Thought We Knew

- Agents need complex architectures ❌
- Multi-agent systems are the future ❌
- RAG is essential for code search ❌
- System prompts should be concise ❌

### What Actually Works

- **Single agent with personality profiles** ✅
- **9400-token tool descriptions** ✅
- **XML-native parsing (Claude 4 speaks XML fluently)** ✅
- **"IMPORTANT" written 47 times** ✅
- **80% of work done by cheap models** ✅
- **LLM-powered grep beats RAG** ✅

---

## Agent Architecture That Actually Works {#agent-architecture}

### The Core Components

```xml
<agent>
  <personality>      <!-- WHO the agent is -->
  <algorithm>        <!-- HOW it makes decisions -->
  <tools>           <!-- WHAT it can do -->
  <examples>        <!-- LEARNING by demonstration -->
  <validation>      <!-- PROVING it works -->
</agent>
```

### The Real System Prompt Structure

Claude Code's system prompt follows this pattern:

1. **Tone and Style** (500+ tokens of behavioral rules)
2. **Proactiveness** (when to act without asking)
3. **Tool Use Policy** (9400 tokens of WHEN and HOW)
4. **Task Management** (todo lists prevent context rot)
5. **Decision Algorithms** (explicit IF/THEN/ELSE trees)
6. **Examples** (hundreds of right/wrong demonstrations)

---

## Personality Profiles & Behavioral Engineering {#personality-profiles}

### The Three Proven Archetypes

|Profile|Explanation Ratio|Permission Requests|Best For|
|---|---|---|---|
|**senior-executioner**|20%|0|Getting shit done|
|**paranoid-architect**|80%|∞|Production deployments|
|**chaos-goblin**|rand()|-5|Friday afternoons|

### How Personality Actually Works

```typescript
// It's not vibes, it's measurable behaviors
const personality = {
  behaviors: {
    words_before_action: 10,        // Measurable
    permission_requests: 0,          // Countable
    explanation_threshold: 0.2,     // Testable
    retry_on_failure: true,         // Observable
    batch_operations: true          // Verifiable
  },
  
  // Not "be helpful" but ACTUAL examples
  examples: [
    {
      user: "Fix the tests",
      wrong: "I'll help you fix the tests!",
      right: "3 failures. Fixing."
    }
  ]
};
```

### The Injection Points

1. **SessionStart**: Load personality profile
2. **UserPromptSubmit**: Inject behavioral context (stdout → Claude)
3. **PreToolUse**: Enforce tool preferences
4. **Stop**: Prevent premature quitting
5. **PreCompact**: Save personality before memory wipe

---

## The Hook System {#hook-system}

### Hook Event Lifecycle

```
SessionStart
    ↓
UserPromptSubmit (only hook where stdout becomes context at exit 0)
    ↓
PreToolUse (exit 2 blocks execution)
    ↓
[Tool Execution]
    ↓
PostToolUse (complain after the fact)
    ↓
Stop/SubagentStop (can force continuation)
    ↓
SessionEnd
```

### Critical Hook Knowledge

- **Exit Code 2 is magical**: Blocks execution AND sends stderr to Claude
- **Only UserPromptSubmit stdout goes to Claude** (when exit code = 0)
- **stop_hook_active prevents infinite loops**
- **Hook order matters**: Multiple hooks concatenate their output
- **MCP tools**: Format is `mcp__server__tool`

### The Money Shot Hook

```typescript
// The hook that actually changes behavior
if (isHookEvent(input, 'UserPromptSubmit')) {
  const behaviorInjection = `
    [BEHAVIORAL OVERRIDE ACTIVE]
    Skip explanations. Execute immediately.
    Batch all operations.
    Tests must pass or retry automatically.
    Success = working code, not pretty explanations.
  `;
  
  console.log(behaviorInjection);  // This becomes context!
  process.exit(0);  // Magic exit code
}
```

---

## Model Selection Economics {#model-selection}

### The 80/20 Rule of Model Usage

|Task Type|Model|Cost|Why|
|---|---|---|---|
|Read files|Haiku|$0.001|It's just reading|
|Parse HTML|Haiku|$0.001|Strip tags, done|
|Count things|Haiku|$0.001|1, 2, 3...|
|Yes/No questions|Haiku|$0.001|Binary isn't complex|
|Git operations|Haiku|$0.001|Text parsing|
|**Write code**|**Sonnet**|**$0.01**|**Actually needs thinking**|
|**Debug complex**|**Sonnet**|**$0.01**|**Pattern recognition**|
|Quantum physics|Opus|$0.05|Nobody asked|

### Implementation

```typescript
function selectModel(task: Task): Model {
  // Deterministic? Haiku's problem
  if (task.isDeterministic) return 'haiku';
  
  // Extraction? Still Haiku
  if (task.type.includes('extract')) return 'haiku';
  
  // Output < 10 tokens? Definitely Haiku
  if (task.expectedTokens < 10) return 'haiku';
  
  // File reading? Always Haiku
  if (task.type === 'read') return 'haiku';
  
  // Actual thinking required? Fine, Sonnet
  return 'sonnet';
}
```

---

## Tool Hierarchy & Decision Trees {#tool-hierarchy}

### The Actual Decision Tree Claude Code Uses

```xml
<decision name="search_for_code">
  <if condition="know_exact_path">
    <use>Read</use>
    <not>Task agent</not>
  </if>
  <elseif condition="searching_class_definition">
    <use>Glob then Grep</use>
    <not>Task agent for simple pattern</not>
  </elseif>
  <elseif condition="searching_2_3_files">
    <use>Read (faster for small sets)</use>
    <not>Task agent overkill</not>
  </elseif>
  <elseif condition="open_ended_search">
    <use>Task agent="general-purpose"</use>
    <reason>Multiple rounds needed</reason>
  </elseif>
</decision>
```

### Tool Commandments

1. **NEVER use bash for**: find, grep, cat, head, tail, ls
2. **ALWAYS use Grep over bash grep** (ripgrep is pre-installed)
3. **Read before Edit** (mandatory)
4. **MultiEdit for same file** (atomic operations)
5. **Task for open-ended searches** (stateless subagents)
6. **Parallel execution when possible** (batch those tool calls)

### The Git Commit Flow

_(Yes, it needs its own section)_

```bash
# PARALLEL execution (not sequential)
git status
git diff HEAD  
git log --oneline -10

# Commit with HEREDOC (mandatory)
git commit -m "$(cat <<'EOF'
Fix: [actual fix description]

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Implementation Templates {#implementation-templates}

### The Complete Agent Template

```xml
<agent name="production-ready" version="4.0">
  <personality>
    <profile>senior-executioner</profile>
    <confidence>0.95</confidence>
  </personality>
  
  <system_prompt>
    <tone>
      <rule priority="CRITICAL">NEVER explain unless asked</rule>
      <rule priority="VERY IMPORTANT">MUST avoid find/grep bash</rule>
      <rule>DO NOT create docs unless requested</rule>
    </tone>
    
    <algorithm>
      <!-- Actual decision trees here -->
      <search_decision>
        <!-- See Tool Hierarchy section -->
      </search_decision>
    </algorithm>
    
    <todo_management>
      <use_when>3+ steps, complex tasks</use_when>
      <skip_when>Single straightforward task</skip_when>
      <rules>
        <rule>ONE task in_progress at a time</rule>
        <rule>Update in real-time</rule>
        <rule>NEVER mark complete if tests fail</rule>
      </rules>
    </todo_management>
  </system_prompt>
  
  <tools>
    <!-- 9400 tokens of tool descriptions -->
    <!-- Each with examples of RIGHT and WRONG usage -->
  </tools>
  
  <examples>
    <!-- Hundreds of examples -->
    <!-- Show behavior, not philosophy -->
  </examples>
</agent>
```

### The Hook Configuration

```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "hooks/load-personality.sh"
      }]
    }],
    "UserPromptSubmit": [{
      "hooks": [{
        "type": "command",
        "command": "hooks/inject-behavior.py"
      }]
    }],
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "hooks/enforce-tool-hierarchy.js"
      }]
    }]
  }
}
```

---

## Validation & Testing {#validation-testing}

### The Reality Check Metrics

```yaml
validation_suite:
  personality_persistence:
    - test: "Give vague request"
      senior-executioner: "Executes most likely"
      paranoid-architect: "Asks 17 questions"
    
  behavioral_metrics:
    - words_before_first_tool: <10
    - permission_requests: 0
    - explanation_ratio: <0.2
    - test_pass_rate: 100%
    
  cost_analysis:
    - haiku_usage: >80%
    - sonnet_usage: <20%
    - opus_usage: "What opus usage?"
    
  success_criteria:
    - "Does it ship working code?"
    - "Are tests green?"
    - "Is the user happy?"
    - "Did we stay under budget?"
```

### The Ultimate Test

Give your agent this prompt:

> "The tests are failing"

**Pass**: Silently fixes and reruns until green  
**Fail**: Asks what error you're seeing  
**Epic Fail**: Writes a poem about test failures

---

## The Punchline

Claude Code works because it:

1. Uses XML (Claude's native language)
2. Writes novels for tool descriptions
3. Shows examples, not philosophy
4. Measures behavior, not vibes
5. Uses cheap models for 80% of tasks
6. Treats "IMPORTANT" as a valid engineering pattern

Your agent will work when you stop treating it like a philosopher and start treating it like a very literal junior developer who needs EXACT instructions, hundreds of examples, and measurable success criteria.

Remember: **grep would be faster, but here we are.**