---
name: find
description: Find components, hooks, or utilities
argument-hint: search-term
---

Looking for "$ARGUMENTS":

Components:
!`find ~/Developer/Library -name "*$ARGUMENTS*.tsx" -type f | grep -v node_modules | grep -v .next | head -10`

Hooks:
!`grep -r "use$ARGUMENTS" ~/Developer/Library/libs --include="*.ts" --include="*.tsx" | head -10`

Imports:
!`grep -r "from.*$ARGUMENTS" ~/Developer/Library --include="*.ts" --include="*.tsx" | head -10`
