#!/bin/bash

# Goose Runner Script with Ollama MiniMax
# Supports both user-local and system-wide Goose installations

# Ensure we're in the project directory
cd "$(dirname "$0")"

# Function to detect and use appropriate Goose installation
detect_goose() {
    local USER_GOOSE="/home/kasjens/.local/bin/goose"
    local SYSTEM_GOOSE="/usr/bin/goose"
    
    if [[ -x "$USER_GOOSE" ]]; then
        echo "Using user-local Goose AI: $USER_GOOSE"
        GOOSE_CMD="$USER_GOOSE"
        GOOSE_VERSION=$("$USER_GOOSE" --version 2>/dev/null | tr -d ' ')
        echo "Version: $GOOSE_VERSION"
    elif [[ -x "$SYSTEM_GOOSE" ]]; then
        echo "Using system-wide Goose: $SYSTEM_GOOSE"
        GOOSE_CMD="$SYSTEM_GOOSE"
        GOOSE_VERSION=$("$SYSTEM_GOOSE" --version 2>/dev/null | tr -d ' ')
        echo "Version: $GOOSE_VERSION"
    else
        echo "❌ Error: No Goose AI installation found!"
        echo "Please install Goose AI first:"
        echo "  pip install goose-ai"
        exit 1
    fi
    echo ""
}

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "Ollama is not running. Starting Ollama..."
    ollama serve &
    sleep 3
fi

# Check for cloud models, with MiniMax as default
CLOUD_MODELS=$(ollama list | grep ":cloud" | wc -l)
if [ $CLOUD_MODELS -eq 0 ]; then
    echo "⚠️  No cloud models found!"
    echo "Run ./configure-cloud-models.sh to set up latest 2025 models"
    echo ""
    read -p "Continue anyway? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
elif ! ollama list | grep -q "minimax-m2.7:cloud"; then
    echo "⚠️  Default model (minimax-m2.7:cloud) not found!"
    echo "Available cloud models:"
    ollama list | grep ":cloud" | awk '{print "  - " $1}'
    echo ""
    echo "Run ./configure-cloud-models.sh to ensure all models are available"
fi

# Detect and configure Goose installation
detect_goose

echo "Starting Goose with Ollama Cloud Models..."

# Show current model configuration  
CURRENT_MODEL=$(grep "GOOSE_MODEL:" ~/.config/goose/config.yaml 2>/dev/null | awk '{print $2}' || echo "minimax-m2.7:cloud")
echo "Current model: $CURRENT_MODEL"

# Show available cloud models
echo "Available cloud models:"
ollama list | grep ":cloud" | awk '{print "  - " $1}' | head -5
TOTAL_CLOUD=$(ollama list | grep ":cloud" | wc -l)
if [ $TOTAL_CLOUD -gt 5 ]; then
    echo "  ... and $((TOTAL_CLOUD - 5)) more"
fi

echo ""
echo "Skills: 32 total (18 Anthropic + 14 MiniMax)"
echo "To switch models: ./switch-model.sh"
echo ""

# Set Goose environment variables
export GOOSE_PROVIDER=ollama  
export GOOSE_MODEL=minimax-m2.7:cloud

# Run Goose session with detected installation
"$GOOSE_CMD" session --name minimax-ollama