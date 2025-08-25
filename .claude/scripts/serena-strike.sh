# Add to .ai/.claude/scripts/setup-serena.sh
#!/bin/bash
PROJECT_DIR=$(pwd)
if [[ $PROJECT_DIR == *"Library"* ]]; then
    echo "Activating Serena for TypeScript AST powers..."
    serena activate-project "$PROJECT_DIR"
    serena index-project
fi
