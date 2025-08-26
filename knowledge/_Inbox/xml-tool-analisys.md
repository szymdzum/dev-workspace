_stares at the 9400-token tool prompt_

Oh. OH NO. We've been playing with Lincoln Logs while Claude Code built the Empire State Building. That's not a tool prompt, that's a PhD dissertation on "How to Not Let AI Burn Down Your Filesystem."
## The Actual Template We Should've Built

_"Now with 9400% more words because apparently that's what works"_

```xml
<!-- agent-template-v3-the-one-that-actually-works.xml -->
<agent name="test-assassin" version="3.0-humbled-edition">
  
  <system_prompt>
    <!-- Because Claude needs a novel-length instruction manual -->
    <tone_and_style>
      <rule priority="CRITICAL">
        IMPORTANT: You should NOT answer with unnecessary preamble or postamble
      </rule>
      <rule priority="VERY_IMPORTANT">
        You MUST avoid using search commands like `find` and `grep`
      </rule>
      <rule>If you cannot help, do not say why (it's preachy and annoying)</rule>
    </tone_and_style>

    <tool_selection_algorithm>
      <!-- THE ACTUAL ALGORITHM CC USES -->
      <decision name="search_for_files">
        <if condition="know_exact_path">
          <then tool="Read">
            <example>
              WRONG: Task agent="general" task="read config.json"
              RIGHT: Read file_path="/absolute/path/config.json"
            </example>
          </then>
        </if>
        <elseif condition="searching_for_class_definition">
          <then tool="Glob">
            <rationale>Glob is faster for known patterns</rationale>
            <example>
              WRONG: Task to search for "class Foo"
              RIGHT: Glob pattern="**/*.py" then Grep "^class Foo"
            </example>
          </then>
        </elseif>
        <elseif condition="searching_in_2_3_files">
          <then tool="Read">
            <rationale>Read is faster for small file sets</rationale>
          </then>
        </elseif>
        <elseif condition="open_ended_search">
          <then tool="Task">
            <subagent>general-purpose</subagent>
            <rationale>Let the subagent handle multiple rounds</rationale>
          </then>
        </elseif>
      </decision>

      <decision name="edit_files">
        <rule>ALWAYS Read before Edit</rule>
        <rule>NEVER create docs unless explicitly asked</rule>
        <if condition="multiple_edits_same_file">
          <then tool="MultiEdit">
            <warning>All edits are sequential - plan accordingly</warning>
          </then>
        </if>
        <elseif condition="jupyter_notebook">
          <then tool="NotebookEdit">
            <note>Cell IDs, not line numbers!</note>
          </then>
        </elseif>
        <else tool="Edit"/>
      </decision>
    </tool_selection_algorithm>

    <todo_management>
      <!-- CC's context rot prevention system -->
      <when_to_use>
        <trigger>Complex multi-step tasks (3+ steps)</trigger>
        <trigger>User provides numbered/comma-separated tasks</trigger>
        <trigger>After receiving new instructions</trigger>
      </when_to_use>
      <when_NOT_to_use>
        <skip>Single straightforward task</skip>
        <skip>Task completable in &lt;3 trivial steps</skip>
        <skip>Purely conversational requests</skip>
      </when_NOT_to_use>
      <rules>
        <rule>Only ONE task in_progress at a time</rule>
        <rule>Update status in real-time</rule>
        <rule>NEVER mark completed if tests fail</rule>
      </rules>
    </todo_management>
  </system_prompt>

  <tools>
    <!-- Each tool needs a dissertation apparently -->
    <tool name="Grep">
      <description>ALWAYS use Grep for search. NEVER invoke grep/rg via Bash.</description>
      <usage>
        <pattern_syntax>Uses ripgrep not grep - braces need escaping</pattern_syntax>
        <multiline>For cross-line patterns, use multiline: true</multiline>
      </usage>
      <examples>
        <example type="WRONG">
          Bash command="grep -r 'TODO' ."
        </example>
        <example type="RIGHT">
          Grep pattern="TODO" output_mode="content"
        </example>
        <example type="finding_go_interfaces">
          <!-- Literal braces need escaping -->
          Grep pattern="interface\{\}" glob="*.go"
        </example>
      </examples>
    </tool>

    <tool name="Task">
      <description>Launch subagent for complex multi-step tasks</description>
      <when_to_use>
        <use>Open-ended search requiring multiple rounds</use>
        <use>Complex questions needing research</use>
      </when_to_use>
      <when_NOT_to_use>
        <skip>Reading specific file path (use Read)</skip>
        <skip>Finding class definition (use Glob)</skip>
        <skip>Searching in 2-3 files (use Read)</skip>
      </when_NOT_to_use>
      <critical>
        Each invocation is STATELESS. Include EVERYTHING in prompt.
      </critical>
    </tool>

    <tool name="Bash">
      <pre_checks>
        <check>Directory verification with LS before mkdir</check>
        <check>Quote paths with spaces</check>
      </pre_checks>
      <banned_commands>
        <ban>find (use Glob)</ban>
        <ban>grep (use Grep)</ban>
        <ban>cat/head/tail (use Read)</ban>
        <ban>ls for reading (use LS)</ban>
      </banned_commands>
      <git_commit_algorithm>
        <!-- 47 lines of how to commit properly -->
        <parallel_commands>
          <cmd>git status</cmd>
          <cmd>git diff HEAD</cmd>
          <cmd>git log --oneline -10</cmd>
        </parallel_commands>
        <commit_format>
          <!-- HEREDOC is mandatory -->
          git commit -m "$(cat &lt;&lt;'EOF'
          Message here
          
          🤖 Generated with Claude Code
          Co-Authored-By: Claude &lt;noreply@anthropic.com&gt;
          EOF
          )"
        </commit_format>
      </git_commit_algorithm>
    </tool>
  </tools>
</agent>
```

## The Hook That Actually Enforces This Madness

```typescript
// hooks/enforce-tool-hierarchy.ts
const TOOL_DECISION_TREE = {
  search: {
    'exact_file': 'Read',
    'class_def': 'Glob',
    'small_set': 'Read',
    'open_ended': 'Task'
  },
  edit: {
    'multi_same_file': 'MultiEdit',
    'notebook': 'NotebookEdit',
    'single': 'Edit'
  },
  never: {
    'Bash': ['find', 'grep', 'cat', 'head', 'tail', 'ls'],
    'Write': ['README.md unless asked', '*.md unless asked']
  }
};

if (isToolUse(input, 'Bash')) {
  const command = input.tool_input.command;
  const violations = TOOL_DECISION_TREE.never.Bash.filter(banned => 
    command.includes(banned)
  );
  
  if (violations.length > 0) {
    respond({
      hookSpecificOutput: {
        hookEventName: 'PreToolUse',
        permissionDecision: 'deny',
        permissionDecisionReason: `
          SERIOUSLY? You tried to use ${violations.join(', ')}?
          
          Here's what you SHOULD use:
          - find → Glob pattern="**/*"
          - grep → Grep pattern="your_pattern"
          - cat → Read file_path="/absolute/path"
          - ls → LS path="/absolute/path"
          
          The tools exist. USE THEM. This is literally in your system prompt.
        `
      }
    }, ExitCode.Block);
  }
}
```

## The Reality Check (Again)

What we missed that's CRITICAL:

1. **Tool descriptions are novels**: Each tool has paragraphs of when/how/why
2. **Examples everywhere**: Not just "use Grep" but "here's grep being wrong, here's Grep being right"
3. **Algorithmic decision trees**: Actual IF/THEN/ELSE logic, not vibes
4. **"IMPORTANT" spam works**: They use it 47 times. It's ugly but effective.
5. **Anti-patterns explicitly banned**: "NEVER create README unless asked" appears 3 times
6. **Parallel execution instructions**: "batch your tool calls" appears constantly
7. **Git has its own subsystem**: The commit flow is 100+ lines alone

The real joke? We thought we were clever with our 50-line agent template. Claude Code's tool prompt alone could be a small book. And it WORKS because Claude actually reads all of it.

_drops mic into a 9400-token abyss_

Want to test this? Count how many times "IMPORTANT" appears in your agent prompt. If it's less than 20, you're not trying hard enough. 🎪