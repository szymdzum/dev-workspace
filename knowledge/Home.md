---
type: dashboard
cssclass: dashboard
---
# 🏠 Knowledge Hub Dashboard

*Welcome to your AI-powered development knowledge center*

---


> [!tip] Todos
> - [ ] Format date format globaly
> - [ ] 3 column view for recent stuff



---

### 🔥 Hot Snippets
```dataview
TABLE language, difficulty, use-cases
FROM "Resources/Snippets" 
SORT created DESC
LIMIT 3
```

## 🎯 Active Projects

```dataview
TABLE status as "Status", created as "Started", tech-stack as "Tech Stack"
FROM "Projects"
WHERE status = "active" AND file.name != "README"
SORT created DESC
```

*No active projects yet? [Create your first project →](project.md)*

---

## 📈 Recent Learning Progress

### ✅ Completed Resources
```dataview
LIST 
FROM "Resources/Patterns"
WHERE contains(tags, "javascript")
SORT created DESC
LIMIT 5
```

### 🔄 JavaScript Mastery Path
**Array Methods Series Progress:**
- [x] [[js-array-1-filtering|🎯 Filtering]] - `filter()`, `slice()`
- [x] [[js-array-2-finding|🔍 Finding]] - `find()`, `indexOf()`, `includes()`  
- [x] [[js-array-3-iteration|🔄 Iteration]] - `forEach()`, `map()`
- [x] [[js-array-4-transformation|🔄 Transformation]] - `map()`, `flatMap()`
- [x] [[js-array-5-mutating|⚠️ Mutating]] - `push()`, `pop()`, `shift()`, `unshift()`
- [x] [[js-array-6-reduce|🧮 Reduce]] - The Swiss Army knife
- [x] [[js-array-7-pipeline|🚀 Pipeline]] - Experimental operator

**Progress: 7/7 Complete!** 🎉

---

## 📝 This Week's Activity

### 📅 Recent Daily Notes
```dataview
LIST
FROM "Daily"
SORT file.ctime DESC
LIMIT 7
```

*[Open today's note →](<Daily/{{date:DD-MM-YYYY}}.md>)*


---

## ⚡ Quick Actions

### 📋 Templates
- 📄 [New Project](project.md)
- 📝 [Daily Note](daily.md) 
- 🔧 [Code Snippet](snippet.md)
- 🎯 [Decision Record](decision.md)
- 🤖 [AI Context](context.md)

### 📁 Quick Navigation  
- 💼 [Development Area](Areas/Development.md)
- 📚 [Learning Area](Areas/Learning.md)
- 📦 [All Projects](Projects/)
- 🎨 [Patterns](Resources/Patterns/)
- 💎 [Snippets](Resources/Snippets/)

### 🔍 Discovery Tools
- 🏷️ Tags: `#javascript` `#react` `#patterns`
- 📊 Graph View
- 🔎 Global Search
- 📋 Command Palette (`Ctrl+P`)

### 📥 Processing
- 🗂️ [Inbox](Inbox/) `$= "(" + (dv.pages('"Inbox"').length - 1) + " items)"`
- 📦 [Archive](Archive/)
- 🧹 Weekly Review
- 📈 [Health Check](AI_RULES.md)

---

## 🎯 Focus Areas

### 🔥 Current Priorities
- [ ] Process inbox items (keep under 20)
- [ ] Update project documentation 
- [ ] Extract reusable patterns to snippets
- [ ] Review and connect related notes

### 📊 Knowledge Health Metrics
- **Documentation Coverage**: `$= Math.round((dv.pages('"Projects"').where(p => p.status == 'active').length / Math.max(dv.pages('"Projects"').where(p => p.status == 'active').length, 1)) * 100)`%
- **Cross-Reference Density**: 📈 Growing
- **Template Usage**: ✅ Consistent  
- **Inbox Processing**: `$= dv.pages('"Inbox"').length <= 5 ? "🟢 Excellent" : dv.pages('"Inbox"').length <= 20 ? "🟡 Good" : "🔴 Needs Attention"`


---

*Built with ❤️ for AI-assisted development*  
*Last updated: `$= dv.date("now").toFormat("DD-MM-YYYY HH:mm")`*