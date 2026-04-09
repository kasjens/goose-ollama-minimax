#!/bin/bash

# Goose Desktop UI Runner Script
# Launches the Goose Desktop application with proper configuration

# Ensure we're in the project root (where .agents/skills/ lives)
cd "$(dirname "$0")/.."

echo "=================================================="
echo "🖥️  GOOSE DESKTOP UI LAUNCHER"
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
    echo -e "${RED}❌ Goose Desktop UI not found!${NC}"
    echo ""
    echo "Please install Goose Desktop UI first:"
    echo "  ./install-goose-ui.sh"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Goose Desktop UI found: /usr/lib/goose/Goose${NC}"

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Ollama not running. Starting Ollama...${NC}"
    ollama serve &
    sleep 3
    echo ""
fi

# Check for cloud models
CLOUD_MODELS=$(ollama list | grep ":cloud" | wc -l)
if [ $CLOUD_MODELS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No cloud models found!${NC}"
    echo "Run: ollama signin && ollama pull qwen3.5:cloud"
    echo ""
else
    echo -e "${GREEN}✅ Cloud models available: $CLOUD_MODELS models${NC}"
fi

# Show available models
echo ""
echo -e "${BLUE}📋 Available Cloud Models:${NC}"
ollama list | grep ":cloud" | awk '{print "  • " $1}' | head -5
TOTAL_CLOUD=$(ollama list | grep ":cloud" | wc -l)
if [ $TOTAL_CLOUD -gt 5 ]; then
    echo "  • ... and $((TOTAL_CLOUD - 5)) more"
fi

echo ""
echo -e "${BLUE}🎯 Configuration:${NC}"
echo "  • Provider: Ollama (Cloud Models)"
echo "  • Default Model: qwen3.5:cloud"
echo "  • Skills: 31 auto-discovered"
echo "  • Web Search: Brave Search API"
echo ""

# Activate Python virtual environment so skills can access installed packages
VENV_DIR="$HOME/.local/share/goose-ollama/venv"
if [ -f "$VENV_DIR/bin/activate" ]; then
    source "$VENV_DIR/bin/activate"
fi

# Set environment variables (desktop app reads these too)
export GOOSE_PROVIDER=ollama
export GOOSE_MODEL=qwen3.5:cloud

echo -e "${GREEN}🚀 Launching Goose Desktop UI...${NC}"
echo ""

# Launch the desktop application
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    echo "Detected Wayland session"
    /usr/lib/goose/Goose &
elif [ "$XDG_SESSION_TYPE" = "x11" ]; then
    echo "Detected X11 session"
    /usr/lib/goose/Goose &
else
    echo "Launching with default settings"
    /usr/lib/goose/Goose &
fi

GOOSE_PID=$!

echo "Goose Desktop UI launched (PID: $GOOSE_PID)"
echo ""
echo -e "${BLUE}💡 Tips:${NC}"
echo "• Configure providers in Settings > Configure Providers"
echo "• Access all 31 skills through the chat interface"
echo "• Use web search: 'Search the web for...'"
echo "• Switch models in Settings > Models"
echo "• Sessions are shared between CLI and Desktop UI"
echo ""
echo "Press Ctrl+C to stop this launcher (app will continue running)"
echo ""

# Wait for the process or user interrupt
wait $GOOSE_PID 2>/dev/null

echo ""
echo "Goose Desktop UI launcher finished."