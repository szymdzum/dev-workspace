---
type: guide
created: 2025-01-23
tags: [knowledge-base, obsidian, documentation]
version: "1.0"
---

# 🧠 Knowledge Vault

*Central knowledge management system for development work - optimized for AI assistance and cross-project learning.*

## Overview

This Obsidian vault serves as the **brain** of your development environment, storing all documentation, decisions, patterns, and learning in a searchable, linkable format that works seamlessly with AI assistants.

### Core Philosophy
- **Documentation as Code**: Every project has comprehensive documentation
- **Knowledge as Power**: All decisions, patterns, and learnings are captured
- **AI-First**: Structured for maximum AI assistant effectiveness
- **Connected Thinking**: Everything links to everything else

## Vault Structure

```
Knowledge/
├── Projects/           # 📁 Project documentation (one per project)
├── Areas/             # 🎯 Ongoing responsibilities (Development, Learning)
├── Resources/         # 📚 Reference materials and reusable assets
│   ├── Snippets/      # Code patterns by language
│   ├── Patterns/      # Architectural patterns
│   ├── Tools/         # Tool documentation
│   └── Attachments/   # Images, files, media
├── Daily/             # 📅 Daily notes and journals
├── Archive/           # 📦 Completed/inactive content
├── Templates/         # 📋 Document templates
└── Inbox/             # 📥 Quick capture area
```

## Getting Started

### 1. Open in Obsidian
1. Install [Obsidian](https://obsidian.md)
2. Open folder as vault: `~/Developer/Knowledge`
3. Essential plugins should auto-enable

### 2. Essential Plugins (Core)
Already configured:
- ✅ **Daily Notes** - Auto-create daily journals
- ✅ **Templates** - Consistent document structure  
- ✅ **File Explorer** - Navigate vault
- ✅ **Backlinks** - See connections
- ✅ **Search** - Find anything instantly

### 3. Recommended Community Plugins
Install these for enhanced functionality:
- **Dataview** - Query notes like a database
- **Templater** - Advanced templates with variables
- **Obsidian Git** - Auto-sync to repository
- **Calendar** - Visual daily note navigation

### 4. First Steps
1. **Create your first project**: Use `Templates/project.md`
2. **Set up daily notes**: They auto-generate each day
3. **Capture quick ideas**: Use the `Inbox/` folder
4. **Start linking**: Connect related concepts with `[[Double Brackets]]`

## Workflows

### 📋 Project Documentation Workflow
```
New Project → Use Templates/project.md → Create CONTEXT.md → Symlink to repo
```

1. Create project folder in `Projects/`
2. Use `Templates/project.md` for README
3. Use `Templates/context.md` for AI context
4. Symlink files to actual project repository
5. Document decisions as you make them

### 📝 Daily Development Workflow
```
Morning → Open daily note → Plan tasks → Work → Evening → Reflect & link
```

1. **Morning**: Review yesterday, plan today
2. **During work**: Capture ideas in `Inbox/`
3. **Evening**: Process inbox, link to projects
4. **Weekly**: Review and organize

### 🧠 Learning Workflow
```
Learn Something → Create Note → Tag & Link → Apply to Project → Share Knowledge
```

1. Capture learning in appropriate area
2. Use `Templates/snippet.md` for code patterns
3. Link to related projects and concepts
4. Apply in real projects when possible

### 💭 Quick Capture Workflow
```
Idea/Note → Inbox → Process Daily/Weekly → File in Appropriate Location
```

1. Don't overthink - dump in `Inbox/`
2. Use descriptive filenames
3. Add basic tags (`#inbox #category`)
4. Process regularly (daily ideal, weekly minimum)

## AI Integration

### How AI Assistants Use This Vault

#### Project Context
Each project has a `CONTEXT.md` file that:
- Explains project purpose and architecture
- Lists current development guidelines  
- Describes coding standards and patterns
- Provides AI with necessary context

This gets symlinked as `Claude.md` in actual project repos:
```bash
ln -sf ../../Knowledge/Projects/my-project/CONTEXT.md Claude.md
```

#### Cross-Project Knowledge
AI can reference:
- **Patterns**: Reusable architectural decisions
- **Snippets**: Proven code solutions
- **Decisions**: Historical context for choices
- **Standards**: Team conventions and practices

#### Search & Discovery
With proper linking and tagging, AI can:
- Find relevant examples from past projects
- Suggest patterns used in similar contexts
- Reference architectural decisions
- Recommend learning resources

## Organization Principles

### Frontmatter Standards
All documents include metadata:
```yaml
---
type: project | area | resource | daily | template
status: active | completed | archived
created: YYYY-MM-DD
modified: YYYY-MM-DD
tags: [relevant, tags]
---
```

### Linking Strategy
- **Projects link to**: Areas, Resources, other Projects
- **Areas track**: Current projects and responsibilities  
- **Resources referenced by**: Projects and Areas
- **Daily notes connect**: To projects, areas, and resources

### Tagging Conventions
- **Content Type**: `#project`, `#snippet`, `#meeting`, `#idea`
- **Status**: `#active`, `#completed`, `#archived`
- **Technology**: `#react`, `#node`, `#docker`, `#aws`
- **Context**: `#learning`, `#bug`, `#feature`, `#refactor`

## Key Features

### 🔍 Powerful Search
- **Global Search**: Find anything across all notes
- **Tag Search**: Filter by categories and context
- **Link Navigation**: Follow connections between ideas
- **Graph View**: Visualize knowledge relationships

### 📊 Dynamic Queries (with Dataview)
```dataview
TABLE status, created, tech-stack
FROM "Projects"
WHERE status = "active"
SORT created DESC
```

### 🔗 Automatic Linking
- `[[Project Name]]` - Link to projects
- `[[Area Name]]` - Link to areas  
- `[[Pattern Name]]` - Link to patterns
- `#tag` - Tag for categorization

### 📅 Daily Notes Integration
- Auto-created each day with template
- Links to relevant projects and areas
- Tracks learning and decisions
- Connects daily work to larger context

## Maintenance

### Daily (5 minutes)
- [ ] Open today's daily note
- [ ] Capture any quick ideas in `Inbox/`
- [ ] Link today's work to relevant projects

### Weekly (30 minutes)  
- [ ] Process `Inbox/` folder
- [ ] Update project statuses
- [ ] Review and connect related notes
- [ ] Archive completed items

### Monthly (1 hour)
- [ ] Review project documentation completeness
- [ ] Archive completed projects to `Archive/`
- [ ] Update area definitions and goals
- [ ] Clean up unused tags and links

## Quality Standards

### Well-Documented Project Includes
- [ ] Clear purpose and value proposition
- [ ] Technical architecture overview
- [ ] Setup and development instructions  
- [ ] Current status and roadmap
- [ ] Decision history (ADRs)
- [ ] AI context file (`CONTEXT.md`)

### Healthy Knowledge Base Has
- [ ] < 20 items in Inbox at any time
- [ ] All projects have current status
- [ ] Regular daily note creation
- [ ] Cross-links between related concepts
- [ ] Up-to-date area definitions

## Advanced Features

### Templates with Variables
Using Templater plugin:
- `{{date:YYYY-MM-DD}}` - Current date
- `{{title}}` - Note title
- `{{date-1d:YYYY-MM-DD}}` - Yesterday's date

### Query Examples (Dataview)
```dataview
LIST
FROM #active AND #project
SORT file.ctime DESC
```

### Graph Filters
- Filter by tags to see related concepts
- Hide/show different node types
- Explore knowledge connections visually

## Success Metrics

Track your knowledge management effectiveness:

### Documentation Coverage
- ✅ All active projects have complete documentation
- ✅ Decisions are recorded when made
- ✅ Learning is captured and organized
- ✅ Patterns are documented and reusable

### Usage Patterns
- ✅ Daily notes created consistently
- ✅ Inbox processed regularly (stays under 20 items)
- ✅ Cross-linking happens naturally
- ✅ AI assistants have sufficient context

### Knowledge Growth
- ✅ Snippet library grows over time
- ✅ Patterns emerge from repeated solutions
- ✅ Connections form between projects
- ✅ Historical decisions inform new choices

## Resources

### Getting Help
- [Obsidian Help](https://help.obsidian.md/) - Official documentation
- [Obsidian Community](https://obsidian.md/community) - Forums and Discord
- [Dataview Plugin](https://github.com/blacksmithgu/obsidian-dataview) - Query language

### Recommended Reading
- "Building a Second Brain" by Tiago Forte
- "How to Take Smart Notes" by Sönke Ahrens
- [Zettelkasten Method](https://zettelkasten.de/)

---

**Version**: 1.0  
**Last Updated**: 2025-01-23  
**Next Review**: 2025-02-23

*This vault grows more valuable with consistent use. Every note, link, and connection makes your future self (and AI assistants) more effective.*