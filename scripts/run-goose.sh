#!/bin/bash

# Goose Runner Script with Ollama MiniMax
# Supports both user-local and system-wide Goose installations

# Ensure we're in the project root (where .agents/skills/ lives)
cd "$(dirname "$0")/.."

# Function to detect and use appropriate Goose installation
detect_goose() {
    local USER_GOOSE="$HOME/.local/bin/goose"
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

# Detect Ollama URL (Windows Ollama reachable from WSL via localhost or host IP)
OLLAMA_URL="http://localhost:11434"
if ! curl -sf "${OLLAMA_URL}/api/tags" &>/dev/null; then
    # Try WSL gateway IP (fallback for non-mirrored WSL2 networking)
    WIN_HOST_IP=$(ip route show default 2>/dev/null | awk '{print $3}')
    if [ -n "$WIN_HOST_IP" ] && curl -sf "http://${WIN_HOST_IP}:11434/api/tags" &>/dev/null; then
        OLLAMA_URL="http://${WIN_HOST_IP}:11434"
    elif command -v ollama &>/dev/null; then
        echo "Ollama is not running. Starting Ollama..."
        ollama serve &
        sleep 3
    else
        echo "Ollama is not running and not reachable."
        echo "Start Ollama on Windows, or install it: curl -fsSL https://ollama.com/install.sh | sh"
        exit 1
    fi
fi

# Check for cloud models via API
CLOUD_MODELS=$(curl -sf "${OLLAMA_URL}/api/tags" 2>/dev/null | grep -o '"name":"[^"]*cloud[^"]*"' | wc -l)
if [ "$CLOUD_MODELS" -eq 0 ]; then
    echo "No cloud models found!"
    echo "Run: ollama signin && ollama pull qwen3.5:cloud"
    echo ""
    read -r -p "Continue anyway? [y/N]: " CONTINUE </dev/tty
    if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Detect and configure Goose installation
detect_goose

echo "Starting Goose with Ollama Cloud Models..."

# Resolve Goose's active config path (moved in 1.30)
GOOSE_CONFIG_FILE=$(goose info 2>/dev/null | grep -oP 'Config yaml:\s*\K\S+' | tr -d '\r')
[ -z "$GOOSE_CONFIG_FILE" ] && GOOSE_CONFIG_FILE="$HOME/.config/goose/config.yaml"
case "$GOOSE_CONFIG_FILE" in
    [A-Za-z]:\\*) GOOSE_CONFIG_FILE=$(echo "$GOOSE_CONFIG_FILE" | sed 's|\\|/|g; s|^\([A-Za-z]\):|/mnt/\L\1|') ;;
esac

# Show current model configuration
CURRENT_MODEL=$(grep "GOOSE_MODEL:" "$GOOSE_CONFIG_FILE" 2>/dev/null | awk '{print $2}' || echo "qwen3.5:cloud")
echo "Current model: $CURRENT_MODEL"

# Show available cloud models via API
echo "Available cloud models:"
curl -sf "${OLLAMA_URL}/api/tags" 2>/dev/null | grep -oP '"name":"[^"]*cloud[^"]*"' | sed 's/"name":"//;s/"//' | sort | head -5 | while read -r m; do echo "  - $m"; done
TOTAL_CLOUD=$(curl -sf "${OLLAMA_URL}/api/tags" 2>/dev/null | grep -o '"name":"[^"]*cloud[^"]*"' | wc -l)
if [ "$TOTAL_CLOUD" -gt 5 ]; then
    echo "  ... and $((TOTAL_CLOUD - 5)) more"
fi

echo ""
echo "Skills: 31 auto-discovered"
echo "To switch models: ./switch-model.sh"
echo ""

# Activate Python virtual environment so skills can access installed packages
VENV_DIR="$HOME/.local/share/goose-ollama/venv"
if [ -f "$VENV_DIR/bin/activate" ]; then
    source "$VENV_DIR/bin/activate"
fi

# Set Goose environment variables
export GOOSE_PROVIDER=ollama
# Point Goose at the correct Ollama URL (may be Windows host IP in WSL)
if [ "$OLLAMA_URL" != "http://localhost:11434" ]; then
    export OLLAMA_HOST="$OLLAMA_URL"
fi
# Read model from config file; fall back to qwen3.5:cloud
CONFIGURED_MODEL=$(grep "GOOSE_MODEL:" "$GOOSE_CONFIG_FILE" 2>/dev/null | awk '{print $2}')
export GOOSE_MODEL="${CONFIGURED_MODEL:-qwen3.5:cloud}"

# Performance: prevent stream stalls with cloud models (see docs/BEST-PRACTICES.md)
export GOOSE_REQUEST_TIMEOUT=300
export OLLAMA_KEEP_ALIVE=300
export OLLAMA_CONTEXT_LENGTH=32768

# Run Goose session with detected installation
"$GOOSE_CMD" session --name goose-cloud