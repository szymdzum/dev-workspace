---
type: guide
created: 2025-01-23
tags: [inbox, workflow]
---

# 📥 Inbox - Quick Capture Area

This folder is your **quick capture zone** for ideas, notes, and information that needs to be processed later.

## How It Works

### Quick Capture
1. **Don't overthink** - Just dump ideas here quickly
2. **Use descriptive filenames** - Make them easy to find later
3. **Add basic tags** - Use #inbox and one category tag

### Processing Workflow
Review this folder **daily** or **weekly** and:

1. **File** - Move to appropriate Knowledge folder
2. **Link** - Connect to existing projects/notes
3. **Archive** - Move completed items to Archive
4. **Delete** - Remove items no longer relevant

## File Naming Convention

Use clear, searchable names:
```
✅ Good: "React context optimization idea.md"
✅ Good: "Meeting notes - product roadmap.md"
✅ Good: "Bug - authentication timeout issue.md"

❌ Bad: "Note.md"
❌ Bad: "Stuff.md" 
❌ Bad: "Untitled.md"
```

## Tagging Strategy

Always include `#inbox` plus one category:

- `#inbox #idea` - Random ideas and concepts
- `#inbox #bug` - Issues discovered
- `#inbox #learning` - Things to research/learn
- `#inbox #meeting` - Meeting notes to process
- `#inbox #task` - Quick tasks and todos
- `#inbox #resource` - Links, articles, tools

## Templates for Quick Notes

### Quick Idea
```markdown
---
tags: [inbox, idea]
created: {{date:DD-MM-YYYY}}
---

# Idea: [Title]

## What
Brief description of the idea

## Why
Why this might be valuable

## Next Steps
- [ ] Research feasibility
- [ ] Discuss with team
- [ ] Create proper project document
```

### Quick Bug Report
```markdown
---
tags: [inbox, bug]
created: {{date:DD-MM-YYYY}}
project: ""
priority: low | medium | high | critical
---

# Bug: [Title]

## Problem
Description of what's not working

## Steps to Reproduce
1. Step 1
2. Step 2
3. Expected vs Actual

## Environment
- Browser/Device:
- Version:

## Next Steps
- [ ] Create issue in project tracker
- [ ] Assign to developer
- [ ] Test fix
```

## Processing Guidelines

### Weekly Review Process
1. **Sort by date** - Process oldest first
2. **Quick scan** - Identify urgent items
3. **Batch process** - Group similar items
4. **Move systematically** - Don't leave orphans

### Where Things Go

| Content Type | Destination |
|--------------|-------------|
| Project ideas | `Projects/` or keep in `Inbox/` until ready |
| Code snippets | `Resources/Snippets/[language]/` |
| Architectural patterns | `Resources/Patterns/` |
| Tool documentation | `Resources/Tools/` |
| Meeting notes | Relevant project in `Projects/[name]/notes/` |
| Daily observations | Current daily note in `Daily/` |
| Completed tasks | `Archive/notes/` |

## Automation Ideas

### Quick Capture Methods
- **Obsidian mobile** - Quick note creation
- **Web clipper** - Save articles directly to Inbox
- **Voice notes** - Record and transcribe later
- **Email to Obsidian** - Forward emails to process

### Regular Maintenance
- Weekly review scheduled in calendar
- Archive items older than 30 days if not processed
- Create dashboard showing inbox count

## Success Metrics

A healthy inbox:
- ✅ Fewer than 20 items at any time
- ✅ Nothing older than 2 weeks unprocessed  
- ✅ All items have proper tags
- ✅ Daily/weekly review happening consistently

---

**Remember**: The inbox is meant to be **empty** most of the time. It's a processing station, not a storage location.