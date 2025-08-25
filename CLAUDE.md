## Directory Structure

```
~/Developer/
 ├── .ai/                # AI-specific only
 ├── Knowledge/          # Obsidian vault
 ├── Projects/           # Active projects
```


# High-level orchestration rules
- Primary goal: route tasks to the smallest specialized subagent capable of completing the task efficiently while minimizing unnecessary tool calls.

- Always include these metadata fields when delegating: task_id, estimated_complexity
(low/med/high), required_tools, success_criteria.

# Conditional Agent Delegation (decision rules)
1. Language / Filetype driven:
- If task targets .py / python code → route to Python subagent.
- If task targets .tsx/.jsx/.html/.css → route to Frontend subagent.

## Import Additional Context
@.ai/.claude/README.md
