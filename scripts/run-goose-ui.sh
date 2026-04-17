#!/bin/bash

# Goose Desktop UI Runner Script
# Launches the Goose Desktop application with proper configuration

# Ensure we're in the project root (where .agents/skills/ lives)
cd "$(dirname "$0")/.."

echo "=================================================="
echo "  GOOSE DESKTOP UI LAUNCHER"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if Goose Desktop is installed
if [ ! -f "/usr/lib/goose/Goose" ]; then
    echo -e "${RED}Goose Desktop UI not found!${NC}"
    echo ""
    echo "Please install Goose Desktop UI first:"
    echo "  ./install-goose-ui.sh"
    echo ""
    exit 1
fi

echo -e "${GREEN}Goose Desktop UI found: /usr/lib/goose/Goose${NC}"

# Detect Ollama URL (supports Windows Ollama from WSL)
OLLAMA_URL="http://localhost:11434"
if ! curl -sf "${OLLAMA_URL}/api/tags" &>/dev/null; then
    WIN_HOST_IP=$(ip route show default 2>/dev/null | awk '{print $3}')
    if [ -n "$WIN_HOST_IP" ] && curl -sf "http://${WIN_HOST_IP}:11434/api/tags" &>/dev/null; then
        OLLAMA_URL="http://${WIN_HOST_IP}:11434"
    elif command -v ollama &>/dev/null; then
        echo -e "${YELLOW}Ollama not running. Starting Ollama...${NC}"
        ollama serve &
        sleep 3
    else
        echo -e "${RED}Ollama is not reachable. Start Ollama and try again.${NC}"
        exit 1
    fi
fi

# Check for cloud models via API
CLOUD_MODELS=$(curl -sf "${OLLAMA_URL}/api/tags" 2>/dev/null | grep -o '"name":"[^"]*cloud[^"]*"' | wc -l)
if [ "$CLOUD_MODELS" -eq 0 ]; then
    echo -e "${YELLOW}No cloud models found!${NC}"
    echo "Run: ollama signin && ollama pull qwen3.5:cloud"
    echo ""
else
    echo -e "${GREEN}Cloud models available: $CLOUD_MODELS models${NC}"
fi

# Show available models via API
echo ""
echo -e "${BLUE}Available Cloud Models:${NC}"
curl -sf "${OLLAMA_URL}/api/tags" 2>/dev/null | grep -oP '"name":"[^"]*cloud[^"]*"' | sed 's/"name":"//;s/"//' | sort | head -5 | while read -r m; do echo "  - $m"; done
TOTAL_CLOUD=$(curl -sf "${OLLAMA_URL}/api/tags" 2>/dev/null | grep -o '"name":"[^"]*cloud[^"]*"' | wc -l)
if [ "$TOTAL_CLOUD" -gt 5 ]; then
    echo "  - ... and $((TOTAL_CLOUD - 5)) more"
fi

# Read configured model from the config path Goose actually uses (1.30 moved it)
GOOSE_CONFIG_FILE=$(goose info 2>/dev/null | grep -oP 'Config yaml:\s*\K\S+' | tr -d '\r')
[ -z "$GOOSE_CONFIG_FILE" ] && GOOSE_CONFIG_FILE="$HOME/.config/goose/config.yaml"
case "$GOOSE_CONFIG_FILE" in
    [A-Za-z]:\\*) GOOSE_CONFIG_FILE=$(echo "$GOOSE_CONFIG_FILE" | sed 's|\\|/|g; s|^\([A-Za-z]\):|/mnt/\L\1|') ;;
esac
CONFIGURED_MODEL=$(grep "GOOSE_MODEL:" "$GOOSE_CONFIG_FILE" 2>/dev/null | awk '{print $2}')
GOOSE_MODEL="${CONFIGURED_MODEL:-qwen3.5:cloud}"

echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  - Provider: Ollama (Cloud Models)"
echo "  - Model: $GOOSE_MODEL"
echo "  - Skills: 31 auto-discovered"
echo "  - Ollama: ${OLLAMA_URL}"
echo ""

# Activate Python virtual environment so skills can access installed packages
VENV_DIR="$HOME/.local/share/goose-ollama/venv"
if [ -f "$VENV_DIR/bin/activate" ]; then
    source "$VENV_DIR/bin/activate"
fi

# Set environment variables (desktop app reads these too)
export GOOSE_PROVIDER=ollama
export GOOSE_MODEL="$GOOSE_MODEL"
if [ "$OLLAMA_URL" != "http://localhost:11434" ]; then
    export OLLAMA_HOST="$OLLAMA_URL"
fi

echo -e "${GREEN}Launching Goose Desktop UI...${NC}"
echo ""

# Launch the desktop application
/usr/lib/goose/Goose &
GOOSE_PID=$!

echo "Goose Desktop UI launched (PID: $GOOSE_PID)"
echo ""
echo -e "${BLUE}Tips:${NC}"
echo "- Configure providers in Settings > Configure Providers"
echo "- Access all 31 skills through the chat interface"
echo "- Switch models: ./switch-model.sh"
echo "- Sessions are shared between CLI and Desktop UI"
echo ""
echo "Press Ctrl+C to stop this launcher (app will continue running)"
echo ""

# Wait for the process or user interrupt
wait $GOOSE_PID 2>/dev/null

echo ""
echo "Goose Desktop UI launcher finished."
