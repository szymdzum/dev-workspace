# Raycast Scripts for Knowledge Vault

These scripts integrate your Obsidian Knowledge vault with Raycast for quick snippet management.

## Setup

1. **Add this directory to Raycast:**
   - Open Raycast → Settings (⌘,)
   - Go to Extensions → Script Commands
   - Click "Add Script Directory"
   - Select: `~/Documents/Raycast Scripts`
   - Scripts should appear automatically

2. **Assign Hotkeys (Optional):**
   - In Raycast Settings → Extensions → Script Commands
   - Find each script and click "Record Hotkey"
   - Suggested hotkeys:
     - Search Snippets: `⌘⇧S`
     - Copy Snippet: `⌘⇧C`
     - Save Snippet: `⌘⇧V`

## Available Scripts

### 📋 Search Snippets (`search-snippets.sh`)
**Mode:** Full Output  
**Usage:** Search and browse all snippets with preview

- Without argument: Shows recent snippets
- With argument: Searches by content and filename
- Shows list when multiple matches found
- Automatically copies when single match found

**Example:**
```bash
# Search for array-related snippets
search-snippets.sh array

# Search for React hooks
search-snippets.sh hook
```

### 🚀 Copy Snippet (`copy-snippet.sh`)
**Mode:** Inline  
**Usage:** Quickly copy a snippet to clipboard

- Fast, inline operation
- Copies first matching snippet
- Great for frequently used snippets

**Example:**
```bash
# Copy the first snippet matching "filter"
copy-snippet.sh filter
```

### 💾 Save Snippet (`save-snippet.sh`)
**Mode:** Compact  
**Usage:** Save clipboard content as new snippet

- Saves to Inbox for processing
- Adds frontmatter for markdown files
- Supports any file extension

**Example:**
```bash
# Save as markdown snippet
save-snippet.sh "Array Filter Example"

# Save as JavaScript file
save-snippet.sh "React Hook" js
```

## Tips

1. **Quick Access:** Use Raycast's universal search (⌘Space) and type snippet names
2. **Workflow:** Copy code → Save with Raycast → Process in Obsidian
3. **Organization:** Saved snippets go to Inbox - remember to process them!

## Troubleshooting

### Scripts don't appear in Raycast
- Ensure scripts are executable: `chmod +x *.sh`
- Restart Raycast or refresh script commands
- Check script directory is added in Raycast settings

### No snippets found
- Check paths in scripts match your Knowledge vault location
- Ensure snippet files exist in Resources/Snippets and Resources/Patterns

### Colors not working
- This is normal in Raycast's UI - colors work in terminal only
- The scripts still function correctly

## Customization

Edit the scripts to customize:
- `KNOWLEDGE_BASE`: Path to your Knowledge vault
- `SNIPPETS_DIR` and `PATTERNS_DIR`: Snippet locations
- File extensions searched (add more in find commands)

## Integration with Knowledge Vault

These scripts work with your Obsidian vault structure:
- **Search in:** `Resources/Snippets/` and `Resources/Patterns/`
- **Save to:** `Inbox/` (for processing workflow)
- **Respects:** Frontmatter in markdown files
- **Compatible with:** Your existing save-snippet.sh workflow
