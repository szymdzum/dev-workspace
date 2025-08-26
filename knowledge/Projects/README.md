---
type: guide
created: 2025-01-23
tags: [projects, workflow, documentation]
---
# 📁 Projects - Documentation Structure Guide

This folder contains documentation for all development projects. Each project gets its own folder with a standardized structure.

## Project Lifecycle

```
Idea → Planning → Active Development → Testing → Production → Archive
  ↓        ↓              ↓              ↓           ↓          ↓
Inbox → Projects/   → Projects/    → Projects/ → Projects/ → Archive/
```

## Standard Project Structure

Each project folder should contain:

```
project-name/
├── README.md          # Main project documentation (use Templates/project.md)
├── CONTEXT.md         # AI assistant context (symlinked as Claude.md)
├── DECISIONS.md       # Architecture Decision Records
├── ROADMAP.md         # Future plans and feature backlog
└── notes/            # Ongoing notes and meeting records
    ├── meetings/     # Meeting notes
    ├── reviews/      # Code review notes
    └── scratch/      # Temporary notes and ideas
```

## Required Frontmatter

Every project README.md must include:

```yaml
---
type: project
status: planning | active | testing | production | maintenance | archived
created: DD-MM-YYYY
modified: DD-MM-YYYY
tags: [project-type, technology-tags]
aliases: [alternative-names]
tech-stack: [languages, frameworks, tools]
repository: "github.com/user/repo"
team: [team-member-names]
---
```

## Project Status Definitions

| Status | Description | Location |
|--------|-------------|----------|
| **planning** | Concept phase, requirements gathering | `Projects/` |
| **active** | Currently under development | `Projects/` |
| **testing** | Feature complete, in QA/testing | `Projects/` |
| **production** | Live and serving users | `Projects/` |
| **maintenance** | No new features, bug fixes only | `Projects/` |
| **archived** | Completed or cancelled | `Archive/projects/` |

## AI Assistant Integration

### CONTEXT.md File
Every project must have a `CONTEXT.md` file that:
- Explains project purpose and architecture
- Lists current development guidelines
- Describes coding standards and patterns
- Provides AI assistants with necessary context

This file will be symlinked as `Claude.md` in the actual project repository.

### Symlinking Process
When creating a new project repository:

```bash
# In your project repository
ln -sf ../../Knowledge/Projects/[project-name]/CONTEXT.md Claude.md
ln -sf ../../Knowledge/Projects/[project-name]/ .claude
```

## Documentation Standards

### README.md Requirements
- **Overview**: What the project does and why it exists
- **Architecture**: Technical design and key components  
- **Getting Started**: Setup and development instructions
- **API Documentation**: If applicable
- **Deployment**: How to deploy the project
- **Contributing**: Development workflow and standards

### DECISIONS.md Structure
Use ADR (Architecture Decision Record) format:
- One decision per section
- Include context, decision, and consequences
- Number decisions (ADR-001, ADR-002, etc.)
- Link related decisions

### ROADMAP.md Organization
- **Current Sprint/Iteration**: What's being worked on now
- **Next**: Planned for upcoming iterations  
- **Future**: Longer-term goals and ideas
- **Completed**: Finished features (or link to changelog)

## Workflow Integration

### Creating a New Project
1. Use `Templates/project.md` to create `README.md`
2. Use `Templates/context.md` to create `CONTEXT.md`
3. Create folder structure with `notes/` subdirectories
4. Set project status to "planning"
5. Link from relevant areas or daily notes

### During Development
- Update CONTEXT.md when architecture changes
- Record decisions in DECISIONS.md as they're made
- Keep meeting notes in `notes/meetings/`
- Update project status as it progresses

### Project Completion
- Update status to "archived"  
- Move entire folder to `Archive/projects/`
- Update any linking documents
- Create project retrospective in `notes/`

## Cross-Referencing

### Linking Projects
- Link related projects: `[[Related Project Name]]`
- Reference shared patterns: `[[Authentication Pattern]]`
- Connect to team areas: `[[Development Area]]`

### From Other Areas
- Daily notes can reference: `[[Project Name]]`
- Area notes track: `Current projects: [[P1]], [[P2]], [[P3]]`
- Learning notes connect: `Applied in [[Project Name]]`

## Quality Standards

### Complete Project Documentation Includes
- [ ] Clear purpose and value proposition
- [ ] Technical architecture overview
- [ ] Setup and development instructions
- [ ] Deployment procedures
- [ ] Contribution guidelines
- [ ] Decision history
- [ ] Current roadmap
- [ ] AI context file

### Regular Maintenance
- **Monthly**: Review and update project status
- **Quarterly**: Update roadmaps and archive completed projects
- **As needed**: Record architectural decisions

## Examples

### Good Project Names
```
✅ ecommerce-api
✅ customer-dashboard  
✅ ml-recommendation-engine
✅ auth-microservice
```

### Bad Project Names
```
❌ project1
❌ new-app
❌ stuff
❌ untitled-project
```

---

**Remember**: Good project documentation is an investment that pays dividends in reduced onboarding time, clearer decision-making, and more effective AI assistance.