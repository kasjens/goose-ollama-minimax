#!/bin/bash

# Goose Runner Script - Force User-Local Installation
# Uses the user-local Goose AI installation specifically

# Ensure we're in the project root (where .agents/skills/ lives)
cd "$(dirname "$0")/../.."

USER_GOOSE="$HOME/.local/bin/goose"

# Check if user-local Goose exists
if [[ ! -x "$USER_GOOSE" ]]; then
    echo "Error: User-local Goose AI not found at $USER_GOOSE"
    echo "Run ./setup.sh to install."
    exit 1
fi

echo "Using User-Local Goose AI: $USER_GOOSE"
USER_VERSION=$("$USER_GOOSE" --version 2>/dev/null | tr -d ' ')
echo "Version: $USER_VERSION"
echo ""

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "Ollama is not running. Starting Ollama..."
    ollama serve &
    sleep 3
fi

# Verify MiniMax model is available
if ! ollama list | grep -q "minimax-m2.7:cloud"; then
    echo "Error: MiniMax model not found!"
    echo "Please run: ollama pull minimax-m2.7:cloud"
    exit 1
fi

# Activate Python virtual environment
VENV_DIR="$HOME/.local/share/goose-ollama/venv"
if [ -f "$VENV_DIR/bin/activate" ]; then
    source "$VENV_DIR/bin/activate"
fi

export GOOSE_PROVIDER=ollama
export GOOSE_MODEL=qwen3.5:cloud

# Run Goose session with user-local installation
"$USER_GOOSE" session --name minimax-ollama-local
