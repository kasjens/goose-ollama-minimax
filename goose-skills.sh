#!/bin/bash

# Master Skills Manager for Goose
# Manages both Anthropic and MiniMax skills

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    echo -e "${2}${1}${NC}"
}

# Function to display menu
show_menu() {
    clear
    echo "============================================"
    print_color "   GOOSE SKILLS MANAGER" "$BLUE"
    echo "============================================"
    echo ""
    print_color "Anthropic Skills (18 available)" "$GREEN"
    print_color "MiniMax Skills (14 available)" "$YELLOW"
    echo ""
    echo "1. List all Anthropic skills"
    echo "2. List all MiniMax skills"
    echo "3. Load an Anthropic skill"
    echo "4. Load a MiniMax skill"
    echo "5. Show combined skills guide"
    echo "6. Search for a skill"
    echo "7. Show skill details"
    echo "8. Exit"
    echo ""
}

# Function to list Anthropic skills
list_anthropic() {
    print_color "\n📚 ANTHROPIC SKILLS" "$GREEN"
    python3 integrate-anthropic-skills.py list
}

# Function to list MiniMax skills
list_minimax() {
    print_color "\n🚀 MINIMAX SKILLS" "$YELLOW"
    python3 integrate-skills.py list
}

# Function to load Anthropic skill
load_anthropic() {
    echo "Available Anthropic skills:"
    echo "----------------------------"
    ls -1 anthropic-skills/skills/ | grep -v "^$" | nl
    echo ""
    read -p "Enter skill name to load: " skill_name
    
    if [ -d "anthropic-skills/skills/$skill_name" ]; then
        python3 integrate-anthropic-skills.py load "$skill_name"
        print_color "\n✅ Skill loaded! You can now use it in Goose." "$GREEN"
    else
        print_color "❌ Skill not found: $skill_name" "$RED"
    fi
}

# Function to load MiniMax skill
load_minimax() {
    echo "Available MiniMax skills:"
    echo "-------------------------"
    ls -1 minimax-skills/skills/ | grep -v "^$" | nl
    echo ""
    read -p "Enter skill name to load: " skill_name
    
    if [ -d "minimax-skills/skills/$skill_name" ]; then
        python3 integrate-skills.py prompt "$skill_name"
        print_color "\n✅ Skill loaded! You can now use it in Goose." "$GREEN"
    else
        print_color "❌ Skill not found: $skill_name" "$RED"
    fi
}

# Function to search for skills
search_skills() {
    read -p "Enter search term: " search_term
    echo ""
    
    print_color "Searching Anthropic skills..." "$GREEN"
    echo "----------------------------"
    grep -l -i "$search_term" anthropic-skills/skills/*/SKILL.md 2>/dev/null | while read file; do
        skill_name=$(basename $(dirname "$file"))
        echo "  • $skill_name"
    done
    
    echo ""
    print_color "Searching MiniMax skills..." "$YELLOW"
    echo "-------------------------"
    grep -l -i "$search_term" minimax-skills/skills/*/SKILL.md 2>/dev/null | while read file; do
        skill_name=$(basename $(dirname "$file"))
        echo "  • $skill_name"
    done
}

# Function to show skill details
show_skill_details() {
    read -p "Enter skill name: " skill_name
    echo ""
    
    # Check Anthropic skills
    if [ -f "anthropic-skills/skills/$skill_name/SKILL.md" ]; then
        print_color "📚 Anthropic Skill: $skill_name" "$GREEN"
        echo "================================"
        head -n 20 "anthropic-skills/skills/$skill_name/SKILL.md"
        echo ""
        echo "[... truncated ...]"
        echo ""
        echo "Files in skill directory:"
        ls -la "anthropic-skills/skills/$skill_name/" | tail -n +2
        
    # Check MiniMax skills
    elif [ -f "minimax-skills/skills/$skill_name/SKILL.md" ]; then
        print_color "🚀 MiniMax Skill: $skill_name" "$YELLOW"
        echo "=============================="
        head -n 20 "minimax-skills/skills/$skill_name/SKILL.md"
        echo ""
        echo "[... truncated ...]"
        echo ""
        echo "Files in skill directory:"
        ls -la "minimax-skills/skills/$skill_name/" | tail -n +2
    else
        print_color "❌ Skill not found: $skill_name" "$RED"
    fi
}

# Function to show combined guide
show_guide() {
    if [ -f "COMPLETE-SKILLS-GUIDE.md" ]; then
        less COMPLETE-SKILLS-GUIDE.md
    else
        print_color "Creating skills guide..." "$BLUE"
        python3 integrate-anthropic-skills.py setup
        less COMPLETE-SKILLS-GUIDE.md
    fi
}

# Main loop
while true; do
    show_menu
    read -p "Select an option (1-8): " choice
    
    case $choice in
        1)
            list_anthropic
            ;;
        2)
            list_minimax
            ;;
        3)
            load_anthropic
            ;;
        4)
            load_minimax
            ;;
        5)
            show_guide
            ;;
        6)
            search_skills
            ;;
        7)
            show_skill_details
            ;;
        8)
            print_color "\nGoodbye! Happy coding with Goose! 🪿" "$BLUE"
            exit 0
            ;;
        *)
            print_color "Invalid option. Please try again." "$RED"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done