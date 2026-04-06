#!/bin/bash

# Goose Runner Script - Force User-Local Installation  
# Uses the user-local Goose AI installation specifically

# Ensure we're in the project directory
cd "$(dirname "$0")"

USER_GOOSE="/home/kasjens/.local/bin/goose"

# Check if user-local Goose exists
if [[ ! -x "$USER_GOOSE" ]]; then
    echo "❌ Error: User-local Goose AI installation not found at $USER_GOOSE"
    echo "To install:"
    echo "  pip install goose-ai"
    echo ""
    echo "Available installations:"
    which -a goose 2>/dev/null || echo "No Goose installations found in PATH"
    exit 1
fi

echo "🔧 Using User-Local Goose AI Installation"
echo "Path: $USER_GOOSE"
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

echo "Starting User-Local Goose AI with Ollama MiniMax..."
echo "Model: minimax-m2.7:cloud"
echo "Skills available in: minimax-skills/skills/"
echo "Configuration: ~/.config/goose/config.yaml"
echo ""

# Run Goose session with user-local installation
"$USER_GOOSE" session --name minimax-ollama-local