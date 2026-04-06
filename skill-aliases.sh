#!/bin/bash
# Skill loading aliases for Goose

# Function to load an Anthropic skill
load_anthropic_skill() {
    python3 integrate-anthropic-skills.py load "$1"
}

# Function to load a MiniMax skill  
load_minimax_skill() {
    python3 integrate-skills.py prompt "$1"
}

# Aliases for common skills
alias goose-pdf='load_anthropic_skill pdf'
alias goose-pptx='load_anthropic_skill pptx'
alias goose-docx='load_anthropic_skill docx'
alias goose-xlsx='load_anthropic_skill xlsx'
alias goose-claude-api='load_anthropic_skill claude-api'
alias goose-webapp-test='load_anthropic_skill webapp-testing'
alias goose-mcp='load_anthropic_skill mcp-builder'

echo "Skill aliases loaded! Examples:"
echo "  goose-pdf     - Load PDF processing skill"
echo "  goose-pptx    - Load PowerPoint skill"
echo "  goose-claude-api - Load Claude API skill"
