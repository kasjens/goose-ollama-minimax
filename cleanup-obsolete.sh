#!/bin/bash

# Cleanup obsolete files and directories from the Goose Ollama MiniMax project
# These files are no longer needed after the refactoring to use .agents/skills/ auto-discovery

echo "================================================"
echo "🧹 Cleaning up obsolete files and directories"
echo "================================================"
echo ""

# Track what we're removing
REMOVED_COUNT=0

# Function to safely remove files/directories
safe_remove() {
    local path="$1"
    local type="$2"  # "file" or "directory"
    
    if [ -e "$path" ]; then
        echo "  Removing $type: $path"
        rm -rf "$path"
        ((REMOVED_COUNT++))
    fi
}

echo "📋 Removing obsolete configuration files..."
echo "-----------------------------------------"

# Obsolete config files (now using .agents/skills/ auto-discovery)
safe_remove ".goose/config.yaml" "file"  # Skills config moved to auto-discovery
safe_remove "profiles.yaml" "file"       # Old Goose profile config
safe_remove "toolkits.yaml" "file"       # Old toolkit definitions

echo ""
echo "📋 Removing obsolete skill management scripts..."
echo "-----------------------------------------------"

# Obsolete skill management scripts (replaced by auto-discovery)
safe_remove "integrate-anthropic-skills.py" "file"  # Replaced by integrate-skills.py
safe_remove "skill-aliases.sh" "file"               # No longer needed with auto-discovery
safe_remove "goose-skills.sh" "file"                # Old interactive skills manager

echo ""
echo "📋 Removing obsolete setup scripts..."
echo "-------------------------------------"

# Old/duplicate setup script
safe_remove "setup-websearch.sh" "file"  # Replaced by setup-brave-search.sh

echo ""
echo "📋 Cleaning up .goose directory..."
echo "----------------------------------"

# Remove .goose directory if it only contains config.yaml or is empty
if [ -d ".goose" ]; then
    FILE_COUNT=$(find .goose -type f 2>/dev/null | wc -l)
    if [ "$FILE_COUNT" -eq 0 ]; then
        echo "  Removing empty .goose directory"
        rmdir .goose 2>/dev/null
        ((REMOVED_COUNT++))
    else
        echo "  ℹ️ .goose directory contains other files, keeping it"
    fi
fi

echo ""
echo "📋 Optional: Documentation consolidation..."
echo "------------------------------------------"
echo ""
echo "The following documentation files could be consolidated:"
echo "  • SETUP-COMPLETE.md         → Could merge into README.md"
echo "  • SETUP-VERIFICATION.md     → Covered by validate-setup.sh"
echo "  • FINAL-STATUS.md           → Historical, could archive"
echo "  • SKILLS-INTEGRATION-SUCCESS.md → Historical, could archive"
echo "  • INSTALLATION-GUIDE.md     → Mostly duplicates README.md"
echo ""
echo "To consolidate docs, you could:"
echo "  1. Move historical docs to a 'docs/archive/' folder"
echo "  2. Merge setup guides into README.md"
echo "  3. Keep only essential guides (BEST-PRACTICES.md, DEPENDENCIES.md, etc.)"
echo ""

echo "================================================"
if [ "$REMOVED_COUNT" -gt 0 ]; then
    echo "✅ Cleanup complete! Removed $REMOVED_COUNT obsolete items."
else
    echo "✅ No obsolete files found to remove."
fi
echo "================================================"
echo ""
echo "📌 Next steps:"
echo "  1. Review optional documentation consolidation above"
echo "  2. Run: git add -A && git commit -m 'Remove obsolete files'"
echo "  3. Run: ./validate-setup.sh to ensure everything still works"
echo ""