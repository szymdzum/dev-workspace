# What This Repository Is (And Isn't)

This is an **Obsidian knowledge vault**, not a traditional code repository:
- **Purpose**: Central, AI-optimized knowledge management system for development work and cross-project learning
- **Content**: Documentation, patterns, snippets, decisions, learning notes, and daily journals in a flat file structure
- **Not for**: Building/running code or package management - treat it as structured content with metadata and links
- **Full details**: See `README.md` for complete vault overview

## Vault Architecture

High-level structure (see `README.md` for full details):
```
Knowledge/
├── Projects/     # Project documentation with AI CONTEXT.md files
├── Areas/        # Ongoing responsibilities (Development, Learning)
├── Resources/    # Reusable assets
│   ├── Snippets/ # Code patterns by language
│   ├── Patterns/ # Architectural patterns  
│   ├── Tools/    # Tool documentation
│   └── Attachments/
├── Daily/        # Daily notes and journals
├── Archive/      # Completed/inactive content
├── Templates/    # Document templates (project, snippet, decision, context)
└── Inbox/        # Temporary capture area (process within 48h)
```

**Key principle**: Maintain flat structure - prefer metadata and naming conventions over deep folders (max 2-3 levels).

## Essential Commands

### 1. Save Clipboard as Snippet
```bash
# Ensure executable
chmod +x ~/Developer/Knowledge/save-snippet.sh

# Run to save clipboard content
~/Developer/Knowledge/save-snippet.sh
# Prompts for: title, file extension, optional Cursor open
```
**Note**: Requires macOS `pbpaste`. Saves to `Inbox/` - must process per workflow.

### 2. Symlink AI Context to Code Repos
From within a project repository:
```bash
# Link CONTEXT.md as Claude.md
ln -sf ../../Knowledge/Projects/my-project/CONTEXT.md Claude.md

# Optional: Link entire project folder
ln -sf ../../Knowledge/Projects/my-project/ .claude
```

### 3. Git Operations
```bash
git add .
git commit -m "Update knowledge vault"
git push
```
Preferred: Use Obsidian Git plugin for auto-sync.

## Key Principles

From `AI_RULES.md`:
- **Flat is better**: Max 2-3 folder levels. Use naming conventions and metadata instead
- **No redundant indexes**: Rely on Obsidian search, tags, and Dataview queries
- **Metadata over folders**: Rich frontmatter (type, category, tags, series) for organization
- **Inbox is temporary**: Process within 24-48h, keep under 20 items
- **Template discipline**: Always start from `Templates/` for consistency
- **Rich cross-referencing**: Link projects ↔ areas ↔ patterns ↔ snippets

See `AI_RULES.md` for complete guidelines and examples.

## Content Organization

### Frontmatter Standards
```yaml
---
type: project | area | resource | daily | template
status: active | completed | archived
created: DD-MM-YYYY 
modified: DD-MM-YYYY 
tags: [relevant, tags]
---
```

### Naming Conventions
- ✅ Good: `js-array-1-filtering.md`, `react-hooks-useState.md`, `docker-compose-examples.md`
- ❌ Avoid: `note1.md`, `stuff.md`, `new-document.md`, `untitled.md`

### Linking and Tagging
- Use `[[Double Brackets]]` for cross-references
- Tag systematically: `#snippet`, `#active`, `#react`, `#learning`

### Placement Rules
- `Projects/` - Project documentation and CONTEXT.md
- `Resources/Snippets/` - Reusable code patterns
- `Resources/Patterns/` - Architectural patterns
- `Areas/` - Ongoing responsibilities
- `Daily/` - Daily notes
- `Inbox/` - Temporary capture only

## Common Workflows

### A. Add Code Snippet
1. Copy code to clipboard
2. Run `save-snippet.sh` with clear title and extension
3. Add frontmatter (type: resource, tags, language)
4. Move from `Inbox/` to `Resources/Snippets/`
5. Link from related projects and patterns

### B. Create Project Documentation
1. Create folder in `Projects/`
2. Use `Templates/project.md` for README
3. Use `Templates/context.md` for CONTEXT.md (AI context)
4. Link to patterns and snippets
5. Symlink CONTEXT.md to project repo as Claude.md
6. Keep CONTEXT.md current with architecture

### C. Process Inbox (Daily/48h Max)
1. Open each item, understand purpose
2. Add frontmatter metadata
3. Choose destination (Projects/, Resources/, Areas/, Daily/)
4. Rename per conventions, move from Inbox/
5. Add cross-links
6. Keep Inbox under 20 items

See `README.md` "Workflows" section for detailed routines.

## Environment Assumptions

- **OS/Shell**: macOS with zsh; `.zshrc` symlinked to `/Users/szymondzumak/Repos/dotfiles/.zshrc`
- **Python**: pyenv configured; respect existing PYENV_ROOT and PATH
- **Tools**: 
  - Obsidian with core plugins; community plugins recommended
  - `pbpaste` for clipboard (macOS-specific in save-snippet.sh)
  - Optional Cursor CLI
- **Encoding**: Prefer simple Unicode; avoid complex emojis (see AI_RULES.md pitfalls)

## Testing & Validation

### Run Tests
This is a content repository - no traditional tests to run. Instead:
- Validate markdown syntax in Obsidian
- Check cross-links resolve correctly
- Ensure frontmatter is valid YAML

### Linting
- Use Obsidian's built-in lint features
- Check for broken links via graph view
- Validate frontmatter consistency

### Development
- Open vault in Obsidian: `~/Developer/Knowledge`
- Use daily notes for work tracking
- Process Inbox regularly
- Keep documentation current with code changes

## Common Development Tasks

### Search for Patterns
```bash
# Find all JavaScript array patterns
grep -r "js-array" Resources/Patterns/

# Find React snippets
ls Resources/Snippets/react/

# Search for specific tags in frontmatter
grep -r "tags:.*react" --include="*.md" .
```

### Check Vault Health
```bash
# Count Inbox items (should be < 20)
ls Inbox/ | wc -l

# Find files without frontmatter
grep -L "^---" $(find . -name "*.md" -type f)

# List recently modified files
find . -name "*.md" -mtime -7 | head -20
```

### Quick Captures
```bash
# Quick note to Inbox
echo "# Quick Idea\n\nContent here" > Inbox/quick-$(date +%Y%m%d-%H%M%S).md

# Save current directory structure to Inbox
tree -L 2 > Inbox/project-structure-$(date +%Y%m%d).txt
```

## References

- `README.md` - Vault overview, structure, workflows, AI integration, quality standards
- `AI_RULES.md` - Organization rules, workflows, symlink strategy, common pitfalls
- `Templates/` - Canonical templates (project.md, context.md, snippet.md, decision.md)

---

**Last Updated**: 2025-01-23  
**Next Review**: Monthly, alongside vault maintenance checklist in README.md
