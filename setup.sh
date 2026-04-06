#!/bin/bash

# Goose + Ollama MiniMax Setup Script

echo "Setting up Goose with Ollama MiniMax..."

# Check if Ollama is running
if ! pgrep -x "ollama" > /dev/null; then
    echo "Starting Ollama service..."
    ollama serve &
    sleep 2
fi

# Check if MiniMax model is available
if ! ollama list | grep -q "minimax-m2.7:cloud"; then
    echo "MiniMax model not found. Please pull it first:"
    echo "  ollama pull minimax-m2.7:cloud"
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
fi

# Install Python dependencies in virtual environment
echo "Installing Python dependencies for skills..."
source venv/bin/activate
pip install -q -r requirements.txt
deactivate

# Skills Integration (Auto-Discovery)
echo "Integrating Skills..."
if [ ! -d ".agents/skills" ]; then
    mkdir -p .agents/skills
    
    # Clone repositories if they don't exist
    if [ ! -d "anthropic-skills" ]; then
        git clone https://github.com/anthropics/skills.git anthropic-skills
    fi
    if [ ! -d "minimax-skills" ]; then
        git clone https://github.com/MiniMax-AI/skills.git minimax-skills  
    fi
    
    # Copy skills to .agents directory
    cp -r anthropic-skills/skills/* .agents/skills/ 2>/dev/null
    cp -r minimax-skills/skills/* .agents/skills/ 2>/dev/null
    
    SKILL_COUNT=$(ls .agents/skills/ | wc -l)
    echo "✅ Skills integrated: $SKILL_COUNT skills available"
else
    SKILL_COUNT=$(ls .agents/skills/ | wc -l)
    echo "✅ Skills already available: $SKILL_COUNT skills"
fi

echo ""
echo "Setup complete! You can now run Goose with:"
echo "  ./run-goose.sh"
echo ""
echo "Skills are auto-discovered - just ask naturally:"
echo "  🪿 'Create a PowerPoint presentation'"
echo "  🪿 'Help me build an iOS app'"  
echo "  🪿 'Generate a Word document'"