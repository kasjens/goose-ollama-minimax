#!/bin/bash

# Goose Model Switcher for Cloud Models
echo "Available Ollama Cloud Models:"
echo "=================================="

# Ask Goose where its config lives (path changed in 1.30)
CONFIG_FILE=$(goose info 2>/dev/null | grep -oP 'Config yaml:\s*\K\S+' | tr -d '\r')
[ -z "$CONFIG_FILE" ] && CONFIG_FILE="$HOME/.config/goose/config.yaml"
case "$CONFIG_FILE" in
    [A-Za-z]:\\*)
        CONFIG_FILE=$(echo "$CONFIG_FILE" | sed 's|\\|/|g; s|^\([A-Za-z]\):|/mnt/\L\1|')
        ;;
esac

# Detect Ollama URL (supports Windows Ollama from WSL)
OLLAMA_URL="http://localhost:11434"
if ! curl -sf "${OLLAMA_URL}/api/tags" &>/dev/null; then
    WIN_HOST_IP=$(ip route show default 2>/dev/null | awk '{print $3}')
    if [ -n "$WIN_HOST_IP" ] && curl -sf "http://${WIN_HOST_IP}:11434/api/tags" &>/dev/null; then
        OLLAMA_URL="http://${WIN_HOST_IP}:11434"
    fi
fi

# Get cloud models via API
models=($(curl -sf "${OLLAMA_URL}/api/tags" 2>/dev/null | grep -oP '"name":"[^"]*cloud[^"]*"' | sed 's/"name":"//;s/"//' | sort))

if [ ${#models[@]} -eq 0 ]; then
    echo "No cloud models found. Ensure Ollama is running with cloud models pulled."
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

    # Update config file
    mkdir -p "$(dirname "$CONFIG_FILE")"
    if [ -f "$CONFIG_FILE" ] && grep -q "^GOOSE_MODEL:" "$CONFIG_FILE" 2>/dev/null; then
        # Replace existing line (use temp file — sed -i fails on NTFS in WSL)
        tmpfile=$(mktemp /tmp/goose-config.XXXXXX)
        sed "s/^GOOSE_MODEL: .*/GOOSE_MODEL: $selected_model/" "$CONFIG_FILE" > "$tmpfile"
        cp "$tmpfile" "$CONFIG_FILE"
        rm -f "$tmpfile"
    elif [ -f "$CONFIG_FILE" ]; then
        # Line doesn't exist yet — append it
        echo "GOOSE_MODEL: $selected_model" >> "$CONFIG_FILE"
    else
        echo "GOOSE_MODEL: $selected_model" > "$CONFIG_FILE"
    fi

    # Verify the change took effect
    VERIFY=$(grep "^GOOSE_MODEL:" "$CONFIG_FILE" 2>/dev/null | awk '{print $2}')
    if [ "$VERIFY" = "$selected_model" ]; then
        echo "Switched to: $selected_model"
        echo "Run ./run-goose.sh to start with the new model"
    else
        echo "Warning: config file update may have failed. Setting env var instead."
        echo "Run:  export GOOSE_MODEL=$selected_model && ./run-goose.sh"
    fi
else
    echo "Invalid selection"
fi
