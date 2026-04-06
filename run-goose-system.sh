#!/bin/bash

# Goose Runner Script - Force System-Wide Installation
# Uses the system-wide Goose installation specifically

# Ensure we're in the project directory
cd "$(dirname "$0")"

SYSTEM_GOOSE="/usr/bin/goose"

# Check if system-wide Goose exists
if [[ ! -x "$SYSTEM_GOOSE" ]]; then
    echo "❌ Error: System-wide Goose installation not found at $SYSTEM_GOOSE"
    echo "Available installations:"
    which -a goose 2>/dev/null || echo "No Goose installations found in PATH"
    exit 1
fi

echo "🔧 Using System-Wide Goose Installation"
echo "Path: $SYSTEM_GOOSE"

# Check if it's a CLI version or GUI app
if [[ -d "/usr/lib/goose" ]]; then
    SYSTEM_VERSION=$(cat /usr/lib/goose/version 2>/dev/null || echo "unknown")
    echo "Type: Desktop GUI App (v$SYSTEM_VERSION)"
    echo "⚠️  Warning: This appears to be a GUI application, not Goose AI CLI"
    echo "   It may not support Ollama integration or our configuration"
    echo ""
    read -p "Continue anyway? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborting. Use ./run-goose.sh for the CLI version."
        exit 1
    fi
else
    SYSTEM_VERSION=$("$SYSTEM_GOOSE" --version 2>/dev/null | tr -d ' ')
    echo "Version: $SYSTEM_VERSION"
fi

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

echo "Starting System-Wide Goose..."
echo "Model: minimax-m2.7:cloud (if supported)"
echo "Skills available in: minimax-skills/skills/ (if supported)"
echo ""

# Run Goose session with system installation
"$SYSTEM_GOOSE" session --name minimax-ollama-system 2>/dev/null || {
    echo "❌ System Goose failed to start session"
    echo "This installation may not support CLI sessions"
    echo "Try running: $SYSTEM_GOOSE --help"
    "$SYSTEM_GOOSE" --help || echo "Command not recognized"
}