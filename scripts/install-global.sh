#!/bin/bash

# Install a global 'goose-cloud' command that can be run from any directory.
# It sets up Ollama env vars, activates the venv, and launches Goose
# in the current working directory.

set -e

GREEN='\033[0;32m'
NC='\033[0m'

WRAPPER="$HOME/.local/bin/goose-cloud"
mkdir -p "$HOME/.local/bin"

cat > "$WRAPPER" << 'WRAPPER_EOF'
#!/bin/bash

# goose-cloud — Launch Goose with Ollama cloud models from any directory.
# Installed by goose-ollama/scripts/install-global.sh

# Detect Ollama URL
OLLAMA_URL="http://localhost:11434"
if ! curl -sf "${OLLAMA_URL}/api/tags" &>/dev/null; then
    WIN_HOST_IP=$(ip route show default 2>/dev/null | awk '{print $3}')
    if [ -n "$WIN_HOST_IP" ] && curl -sf "http://${WIN_HOST_IP}:11434/api/tags" &>/dev/null; then
        OLLAMA_URL="http://${WIN_HOST_IP}:11434"
    else
        echo "Ollama is not reachable at localhost:11434"
        if command -v ollama &>/dev/null; then
            echo "Starting Ollama..."
            ollama serve &
            sleep 3
        else
            echo "Start Ollama on Windows or install it: curl -fsSL https://ollama.com/install.sh | sh"
            exit 1
        fi
    fi
fi

# Activate Python venv (for skills that need packages)
VENV_DIR="$HOME/.local/share/goose-ollama/venv"
if [ -f "$VENV_DIR/bin/activate" ]; then
    source "$VENV_DIR/bin/activate"
fi

# Set Goose environment
export GOOSE_PROVIDER=ollama
if [ "$OLLAMA_URL" != "http://localhost:11434" ]; then
    export OLLAMA_HOST="$OLLAMA_URL"
fi
# Goose 1.30 moved its config; ask the binary where it is rather than guessing
GOOSE_CONFIG_FILE=$(goose info 2>/dev/null | grep -oP 'Config yaml:\s*\K\S+' | tr -d '\r')
[ -z "$GOOSE_CONFIG_FILE" ] && GOOSE_CONFIG_FILE="$HOME/.config/goose/config.yaml"
case "$GOOSE_CONFIG_FILE" in
    [A-Za-z]:\\*) GOOSE_CONFIG_FILE=$(echo "$GOOSE_CONFIG_FILE" | sed 's|\\|/|g; s|^\([A-Za-z]\):|/mnt/\L\1|') ;;
esac
CONFIGURED_MODEL=$(grep "^GOOSE_MODEL:" "$GOOSE_CONFIG_FILE" 2>/dev/null | awk '{print $2}')
export GOOSE_MODEL="${CONFIGURED_MODEL:-qwen3.5:cloud}"

# Performance
export GOOSE_REQUEST_TIMEOUT=300
export OLLAMA_KEEP_ALIVE=300
export OLLAMA_CONTEXT_LENGTH=32768

# Find Goose binary
GOOSE_CMD=""
if [ -x "$HOME/.local/bin/goose" ]; then
    GOOSE_CMD="$HOME/.local/bin/goose"
elif command -v goose &>/dev/null; then
    GOOSE_CMD="$(command -v goose)"
else
    echo "Goose not found. Run setup.sh first."
    exit 1
fi

# Show info
echo "Goose Cloud | model: $GOOSE_MODEL | ollama: $OLLAMA_URL"
echo "Directory: $(pwd)"
echo ""

# Launch Goose in the current directory — pass any extra args through
exec "$GOOSE_CMD" session "$@"
WRAPPER_EOF

chmod +x "$WRAPPER"

# Also install goose-switch (model switcher)
SWITCHER="$HOME/.local/bin/goose-switch"
cat > "$SWITCHER" << 'SWITCHER_EOF'
#!/bin/bash

# goose-switch — Switch Ollama cloud model from any directory.

# Ask Goose where its config lives (path changed in 1.30)
CONFIG_FILE=$(goose info 2>/dev/null | grep -oP 'Config yaml:\s*\K\S+' | tr -d '\r')
[ -z "$CONFIG_FILE" ] && CONFIG_FILE="$HOME/.config/goose/config.yaml"
case "$CONFIG_FILE" in
    [A-Za-z]:\\*) CONFIG_FILE=$(echo "$CONFIG_FILE" | sed 's|\\|/|g; s|^\([A-Za-z]\):|/mnt/\L\1|') ;;
esac

# Detect Ollama URL
OLLAMA_URL="http://localhost:11434"
if ! curl -sf "${OLLAMA_URL}/api/tags" &>/dev/null; then
    WIN_HOST_IP=$(ip route show default 2>/dev/null | awk '{print $3}')
    if [ -n "$WIN_HOST_IP" ] && curl -sf "http://${WIN_HOST_IP}:11434/api/tags" &>/dev/null; then
        OLLAMA_URL="http://${WIN_HOST_IP}:11434"
    else
        echo "Ollama is not reachable."
        exit 1
    fi
fi

echo "Available Ollama Cloud Models:"
echo "=================================="

models=($(curl -sf "${OLLAMA_URL}/api/tags" 2>/dev/null | grep -oP '"name":"[^"]*cloud[^"]*"' | sed 's/"name":"//;s/"//' | sort))

if [ ${#models[@]} -eq 0 ]; then
    echo "No cloud models found."
    exit 1
fi

CURRENT=$(grep "^GOOSE_MODEL:" "$CONFIG_FILE" 2>/dev/null | awk '{print $2}')

for i in "${!models[@]}"; do
    marker=""
    [ "${models[$i]}" = "$CURRENT" ] && marker=" (CURRENT)"
    echo "$((i+1))) ${models[$i]}$marker"
done

echo ""
read -r -p "Select model [1-${#models[@]}]: " choice </dev/tty
echo ""

if [[ $choice =~ ^[0-9]+$ ]] && [ "$choice" -le "${#models[@]}" ] && [ "$choice" -gt 0 ]; then
    selected_model="${models[$((choice-1))]}"

    mkdir -p "$(dirname "$CONFIG_FILE")"
    if [ -f "$CONFIG_FILE" ] && grep -q "^GOOSE_MODEL:" "$CONFIG_FILE" 2>/dev/null; then
        tmpfile=$(mktemp /tmp/goose-config.XXXXXX)
        sed "s/^GOOSE_MODEL: .*/GOOSE_MODEL: $selected_model/" "$CONFIG_FILE" > "$tmpfile"
        cp "$tmpfile" "$CONFIG_FILE"
        rm -f "$tmpfile"
    elif [ -f "$CONFIG_FILE" ]; then
        echo "GOOSE_MODEL: $selected_model" >> "$CONFIG_FILE"
    else
        echo "GOOSE_MODEL: $selected_model" > "$CONFIG_FILE"
    fi

    VERIFY=$(grep "^GOOSE_MODEL:" "$CONFIG_FILE" 2>/dev/null | awk '{print $2}')
    if [ "$VERIFY" = "$selected_model" ]; then
        echo "Switched to: $selected_model"
    else
        echo "Config update failed. Run: export GOOSE_MODEL=$selected_model && goose-cloud"
    fi
else
    echo "Invalid selection"
fi
SWITCHER_EOF

chmod +x "$SWITCHER"

# Ensure ~/.local/bin is in PATH
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$rc" ] && ! grep -q 'HOME/.local/bin' "$rc"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
        fi
    done
fi

echo -e "${GREEN}Installed:${NC} $WRAPPER"
echo -e "${GREEN}Installed:${NC} $SWITCHER"
echo ""
echo "Usage (from any directory):"
echo "  goose-cloud                    # start a new session"
echo "  goose-cloud --name my-project  # named session"
echo "  goose-switch                   # switch cloud model"
echo ""
echo "Restart your shell or run: export PATH=\"\$HOME/.local/bin:\$PATH\""
