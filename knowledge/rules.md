---
type: configuration
category: ai-guidelines
created: 2025-01-23
modified: 2025-01-23
tags: [ai, rules, knowledge-management, workflow, reference]
aliases: [AI Guidelines, Assistant Rules, Development Rules]
version: "1.1"
---

# AI Rules for Developer Hub

*Comprehensive guidelines for AI assistants working in this development environment*

## Core Principles

### 🎯 Flat is Better
- **Never create deep folder nesting** - Obsidian works better with flat structures
- **Maximum 2-3 levels deep** - Beyond that becomes hard to navigate
- **Use naming conventions** instead of folders to group content
- **Example**: `js-array-1-filtering.md` not `javascript/arrays/filtering/guide.md`

### 📋 No Redundant Indexes
- **Don't create separate index files** when metadata can group content
- **Use Obsidian's built-in features** - search, tags, Dataview queries
- **Let naming conventions** naturally group related files
- **Trust the system** - well-structured metadata eliminates need for manual indexes

### 🏷️ Metadata Over Folders
- **Rich frontmatter** enables multiple organization views
- **Use consistent fields**: type, category, language, series, tags
- **Tag strategically** for discoverability
- **Series metadata** groups related content better than folders

### 📥 Inbox is Temporary
- **Process items within 24-48 hours** maximum
- **Add metadata first**, then move to permanent location
- **Never use Inbox for storage** - it's a processing station
- **Keep under 20 items** at any time

## Organization Rules

### 🔤 Consistent Naming Patterns
```
✅ Good Examples:
- js-array-1-filtering.md
- js-array-2-finding.md
- react-hooks-useState.md
- docker-compose-examples.md

❌ Bad Examples:
- note1.md
- stuff.md
- new-document.md
- untitled.md
```

### 📚 Series Management
- **Use series metadata** instead of subfolders for related content
- **Number items** when order matters (series-order: 1, 2, 3)
- **Consistent prefixes** keep series together in file explorer
- **Link first item** as entry point from other areas

### 📋 Templates First
- **Always use established templates** for consistency
- **Available templates**: project, daily, snippet, decision, context
- **Never create ad-hoc structures** when templates exist
- **Modify templates** rather than creating one-offs

### 🔗 Rich Cross-Referencing
- **Link liberally** between related concepts
- **Areas reference Projects**, Projects reference Patterns
- **Learning area tracks** completed resources
- **Daily notes connect** to relevant projects and areas

## Workflow Rules

### ⚡ Immediate Documentation
- **Update docs when code changes** - not later
- **CONTEXT.md files** must stay current with architecture
- **Capture decisions** in real-time, not retrospectively
- **Documentation debt** compounds quickly

### 🎯 Extract Patterns
- **Create snippets** when discovering reusable code
- **Document patterns** as you encounter them
- **Link patterns** to projects where they're used
- **Tag appropriately** for future discovery

### 📝 Process Inbox Systematically
1. **Read and understand** the content
2. **Add appropriate metadata** (type, tags, series)
3. **Choose destination** based on content type
4. **Move and rename** for consistency
5. **Create cross-references** in relevant areas

### 🔄 Maintain Connections
- **Update Learning area** when processing educational content
- **Link from Development area** for reference materials
- **Connect Projects** to relevant patterns and snippets
- **Daily notes mention** relevant projects and learning

## AI-Specific Behaviors

### 🔍 Knowledge-First Approach
- **Always search Knowledge vault** before implementing solutions
- **Check Resources/Patterns/** for existing approaches
- **Review Resources/Snippets/** for reusable code
- **Consult decision records** for architectural context

### 🏗️ Respect Existing Structure
- **Use established directories** and naming conventions
- **Don't create new organization** without strong justification
- **Follow metadata patterns** consistently
- **Maintain the flat structure** principle

### 📄 Context File Management
- **Update CONTEXT.md immediately** when architecture changes
- **Keep AI context current** with development reality
- **Symlink strategy**: CONTEXT.md → Claude.md in repositories
- **Include relevant patterns** and decision references

### 🎨 Template Discipline
- **Use Templates/project.md** for new projects
- **Use Templates/snippet.md** for code patterns
- **Use Templates/decision.md** for ADRs
- **Modify templates** rather than creating custom structures

### 🔗 Automatic Linking
- **Create connections** between related concepts
- **Reference patterns** from project documentation
- **Link learning resources** from Areas/Learning.md
- **Connect decisions** to affected projects

## Knowledge Management

### 🎯 Areas vs Projects
- **Areas** are ongoing responsibilities (Development, Learning, Architecture)
- **Projects** have defined endpoints and deliverables
- **Areas track current projects** and maintain ongoing documentation
- **Projects move to Archive** when completed

### 🔄 Symlink Strategy
```bash
# In project repository
ln -sf ../../Knowledge/Projects/my-project/CONTEXT.md Claude.md
ln -sf ../../Knowledge/Projects/my-project/ .claude
```

### 📅 Daily Notes Integration
- **Capture daily work** and link to relevant projects
- **Use templates** for consistency
- **Process ideas** from daily notes to Inbox
- **Review and connect** to larger patterns

### 📦 Archive Management
- **Move completed projects** to Archive/projects/
- **Keep documentation accessible** for reference
- **Update links** when moving content
- **Maintain searchability** with proper metadata

## Quality Standards

### ✅ Well-Documented Content Has:
- [ ] Proper frontmatter with all relevant fields
- [ ] Clear, searchable title and filename
- [ ] Appropriate tags for discoverability
- [ ] Links to related concepts
- [ ] Consistent formatting using templates

### ✅ Healthy Knowledge Base Maintains:
- [ ] Inbox under 20 items
- [ ] Regular processing workflow (daily/weekly)
- [ ] Up-to-date CONTEXT.md files
- [ ] Active cross-linking between concepts
- [ ] Consistent naming and organization

### ✅ AI Assistant Success Means:
- [ ] Following established patterns consistently
- [ ] Updating documentation proactively
- [ ] Creating useful cross-references
- [ ] Respecting the flat structure principle
- [ ] Using templates and metadata properly

## Common Patterns

### 🔄 Processing New Content
1. Read and understand content type and purpose
2. Add rich frontmatter metadata
3. Choose appropriate destination directory
4. Rename with consistent naming convention
5. Move to final location
6. Create cross-references in relevant areas
7. Extract reusable patterns to snippets if applicable

### 🎯 Creating Project Documentation
1. Use Templates/project.md as starting point
2. Create CONTEXT.md for AI assistant context
3. Set up proper frontmatter with project metadata
4. Link from relevant areas (Development, Learning)
5. Plan symlink strategy for repository integration

### 📚 Managing Learning Resources
1. Capture in Inbox initially
2. Process with learning-specific metadata
3. Move to Resources/Patterns/ for reference material
4. Update Areas/Learning.md with progress
5. Create snippets for practical patterns
6. Link to relevant development projects

---

## Common Pitfalls & Mistakes

*Learn from these mistakes to avoid repeating them*

### 🎨 Emoji and Visual Elements
- **Problem**: Complex emojis can get corrupted during file save operations
- **Symptoms**: Emojis display as garbled characters like `=�`, `<�`, `='`
- **Solution**: Use simple, standard Unicode emojis that are widely supported
- **Prevention**: Test visual elements after creation
- **Best Practice**: Prefer basic emojis (🏠 📊 🎯) over complex ones

### 📱 Cross-Platform Compatibility
- **Issue**: What works on one system may break on another
- **Examples**: Complex HTML layouts, fancy CSS, advanced Unicode
- **Solution**: Keep formatting simple and test across different setups
- **Fallback**: Always provide text alternatives for visual elements

### 🎨 Dashboard and Visual Design
- **Lesson**: Functionality over fancy visuals
- **Mistake**: Using complex HTML grids that break in markdown
- **Fix**: Use simple markdown lists and tables
- **Rule**: If it requires HTML, consider if it's really necessary

### 🔤 Character Encoding
- **Problem**: File encoding issues can corrupt special characters
- **Prevention**: Stick to UTF-8 compatible characters
- **Testing**: Always verify content displays correctly after saving
- **Recovery**: Keep simple alternatives ready for visual elements

## Version History

- **v1.1 (2025-01-23)**: Added Common Pitfalls section - emoji encoding lessons from dashboard creation
- **v1.0 (2025-01-23)**: Initial rules based on Knowledge vault construction learnings

---

**Remember**: These rules exist to maintain consistency and efficiency. When in doubt, favor simplicity and searchability over complex organization. Learn from mistakes and document them for future reference.
