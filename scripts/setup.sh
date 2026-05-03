#!/bin/bash
set -e

# Goose + Ollama MiniMax — One-Step Setup
# Works on a fresh WSL2 Ubuntu install with zero prerequisites.

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

step()  { echo -e "\n${BLUE}[$1/9]${NC} $2"; }
ok()    { echo -e "  ${GREEN}OK${NC} $1"; }
warn()  { echo -e "  ${YELLOW}!!${NC} $1"; }
fail()  { echo -e "  ${RED}FAIL${NC} $1"; exit 1; }

# Ollama helpers — use API when Windows Ollama, CLI otherwise
do_ollama_pull() {
    local model="$1"
    if [ "$WINDOWS_OLLAMA" = true ]; then
        curl -sf "${OLLAMA_URL}/api/pull" -d "{\"name\":\"$model\"}" --max-time 300 &>/dev/null
    else
        ollama pull "$model" 2>/dev/null
    fi
}
do_ollama_rm() {
    local model="$1"
    if [ "$WINDOWS_OLLAMA" = true ]; then
        curl -sf "${OLLAMA_URL}/api/delete" -X DELETE -d "{\"name\":\"$model\"}" &>/dev/null
    else
        ollama rm "$model" &>/dev/null
    fi
}

# ── 1. System packages ─────────────────────────────────────────────
step 1 "Installing system prerequisites..."

PYTHON_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || echo "")
if [ -z "$PYTHON_VER" ]; then
    fail "python3 not found. Please install python3 first."
fi

NEEDED_PKGS=""
for pkg in zstd curl git bzip2 libgomp1 "python${PYTHON_VER}-venv"; do
    if ! dpkg -s "${pkg}" &>/dev/null; then
        NEEDED_PKGS="$NEEDED_PKGS $pkg"
    fi
done

if [ -n "$NEEDED_PKGS" ]; then
    echo "  Installing:$NEEDED_PKGS"
    sudo apt-get update -qq
    sudo apt-get install -y -qq $NEEDED_PKGS
    ok "System packages installed"
else
    ok "All system packages already present"
fi

# ── 2. Ollama ───────────────────────────────────────────────────────
step 2 "Checking Ollama..."

# Detect if running in WSL and check for Windows Ollama
WINDOWS_OLLAMA=false
IS_WSL=false
OLLAMA_URL="http://localhost:11434"
if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=true

    # WSL2 helper: find the Windows host IP (localhost may not forward to Windows)
    WIN_HOST_IP=$(ip route show default 2>/dev/null | awk '{print $3}')

    # Check WSL2 networking mode — mirrored allows localhost to reach Windows
    WSLCONFIG="/mnt/c/Users/$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d '\r')/.wslconfig"
    WSL_NET_MODE=$(grep -i "^networkingMode" "$WSLCONFIG" 2>/dev/null | cut -d= -f2 | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

    if [ "$WSL_NET_MODE" != "mirrored" ]; then
        warn "WSL2 networking is '${WSL_NET_MODE:-NAT}' — localhost may not reach Windows."
        echo "  Recommended: set networkingMode=mirrored in $WSLCONFIG"
        echo ""
        if [ -f "$WSLCONFIG" ]; then
            echo "  Your current .wslconfig:"
            cat "$WSLCONFIG" | sed 's/^/    /'
            echo ""
        fi
        echo "  To fix, run this in PowerShell:"
        echo "    (Get-Content ~\.wslconfig) -replace 'networkingMode=.*','networkingMode=mirrored' | Set-Content ~\.wslconfig"
        echo "  Then:  wsl --shutdown  and reopen this terminal."
        echo ""
        read -r -p "  Fix now and restart WSL? [Y/n]: " FIX_WSL </dev/tty
        if [[ ! $FIX_WSL =~ ^[Nn]$ ]]; then
            if [ -f "$WSLCONFIG" ] && grep -qi "^networkingMode" "$WSLCONFIG" 2>/dev/null; then
                # Replace existing line
                tmpfile=$(mktemp /tmp/wslconfig.XXXXXX)
                sed 's/^networkingMode=.*/networkingMode=mirrored/I' "$WSLCONFIG" > "$tmpfile"
                cp "$tmpfile" "$WSLCONFIG"
                rm -f "$tmpfile"
            elif [ -f "$WSLCONFIG" ]; then
                # Add under [wsl2] section
                tmpfile=$(mktemp /tmp/wslconfig.XXXXXX)
                sed '/^\[wsl2\]/a networkingMode=mirrored' "$WSLCONFIG" > "$tmpfile"
                cp "$tmpfile" "$WSLCONFIG"
                rm -f "$tmpfile"
            else
                echo -e "[wsl2]\nnetworkingMode=mirrored" > "$WSLCONFIG"
            fi
            ok "Updated .wslconfig to networkingMode=mirrored"
            echo ""
            warn "WSL must restart for this to take effect."
            echo "  Run:  wsl --shutdown"
            echo "  Then reopen this terminal and run ./setup.sh again."
            exit 0
        fi
    fi

    # Check 1: Is Windows Ollama API already reachable via localhost or host IP?
    if curl -sf http://localhost:11434/api/tags &>/dev/null; then
        WINDOWS_OLLAMA=true
        OLLAMA_URL="http://localhost:11434"
        ok "Ollama API reachable at localhost:11434"
    elif [ -n "$WIN_HOST_IP" ] && curl -sf "http://${WIN_HOST_IP}:11434/api/tags" &>/dev/null; then
        WINDOWS_OLLAMA=true
        OLLAMA_URL="http://${WIN_HOST_IP}:11434"
        ok "Ollama API reachable at ${WIN_HOST_IP}:11434"
    # Check 2: Is Ollama installed on Windows but not reachable from WSL?
    elif [ -f "/mnt/c/Users/$(whoami)/AppData/Local/Programs/Ollama/ollama.exe" ] || \
         cmd.exe /C "where ollama" &>/dev/null 2>&1; then
        WINDOWS_OLLAMA=true
        warn "Ollama is installed on Windows but not reachable from WSL."
        echo ""
        echo "  WSL2 needs networkingMode=mirrored to reach Windows localhost."
        echo "  The setup script should have already offered to fix this (step 2)."
        echo "  If not, add this to C:\\Users\\$(whoami)\\.wslconfig:"
        echo ""
        echo "    [wsl2]"
        echo "    networkingMode=mirrored"
        echo ""
        echo "  Then run: wsl --shutdown and reopen this terminal."
        echo ""
        echo "  Also make sure Ollama is running on Windows."
        echo ""
        read -r -p "  Press Enter after fixing networking and starting Ollama..." _ </dev/tty
        if curl -sf http://localhost:11434/api/tags &>/dev/null; then
            OLLAMA_URL="http://localhost:11434"
            ok "Ollama is now reachable at localhost:11434"
        elif [ -n "$WIN_HOST_IP" ] && curl -sf "http://${WIN_HOST_IP}:11434/api/tags" &>/dev/null; then
            OLLAMA_URL="http://${WIN_HOST_IP}:11434"
            ok "Ollama is now reachable at ${WIN_HOST_IP}:11434"
        else
            fail "Ollama is still not reachable from WSL. Ensure networkingMode=mirrored is set and Ollama is running."
        fi
    fi

    # Always set OLLAMA_HOST with explicit port — without it Goose may fall back to port 1234
    if [ "$WINDOWS_OLLAMA" = true ] && [ "$OLLAMA_URL" != "http://localhost:11434" ]; then
        export OLLAMA_HOST="$OLLAMA_URL"
        echo "  Setting OLLAMA_HOST=$OLLAMA_URL for this session"
    else
        export OLLAMA_HOST="localhost:11434"
    fi
fi

if [ "$WINDOWS_OLLAMA" = false ]; then
    if ! command -v ollama &>/dev/null; then
        echo "  Ollama not found — installing..."
        curl -fsSL https://ollama.com/install.sh | sh
        ok "Ollama installed"
    else
        ok "Ollama already installed"
    fi
fi

# ── 3. Ollama service ──────────────────────────────────────────────
step 3 "Ensuring Ollama service is running..."

if [ "$WINDOWS_OLLAMA" = true ]; then
    # Windows Ollama is already running — verify it's still responding
    if curl -sf "${OLLAMA_URL}/api/tags" &>/dev/null; then
        ok "Using Windows Ollama (${OLLAMA_URL})"
    else
        fail "Windows Ollama was detected but is no longer responding at ${OLLAMA_URL}. Start Ollama on Windows and retry."
    fi
elif ! curl -sf http://localhost:11434/api/tags &>/dev/null; then
    if command -v systemctl &>/dev/null && systemctl is-active ollama &>/dev/null; then
        ok "Ollama service active (systemd)"
    else
        echo "  Starting ollama serve in background..."
        nohup ollama serve &>/dev/null &
    fi
    # Wait for the API to become ready (up to 30 seconds)
    echo "  Waiting for Ollama API to become ready..."
    for i in $(seq 1 10); do
        if curl -sf http://localhost:11434/api/tags &>/dev/null; then
            break
        fi
        sleep 3
    done
    if curl -sf http://localhost:11434/api/tags &>/dev/null; then
        ok "Ollama service is running"
    else
        fail "Could not start Ollama. Try manually: ollama serve"
    fi
else
    ok "Ollama service already running"
fi

# ── 4. Ollama sign-in ──────────────────────────────────────────────
step 4 "Checking Ollama cloud sign-in..."

if [ "$WINDOWS_OLLAMA" = true ]; then
    # Using Windows Ollama — check for cloud models via API instead of CLI
    if curl -sf "${OLLAMA_URL}/api/tags" 2>/dev/null | grep -q ":cloud"; then
        ok "Windows Ollama has cloud models available"
    else
        warn "No cloud models found. Sign in to Ollama on Windows:"
        echo "  Open a PowerShell window and run: ollama signin"
        echo "  Then pull a model: ollama pull qwen3.5:cloud"
        echo ""
        read -r -p "  Press Enter after you have signed in and pulled models..." _ </dev/tty
        if curl -sf "${OLLAMA_URL}/api/tags" 2>/dev/null | grep -q ":cloud"; then
            ok "Cloud models now available"
        else
            fail "Still no cloud models. Sign in on Windows: ollama signin"
        fi
    fi
else
    # Using local Linux Ollama — check via CLI
    if ollama list 2>&1 | grep -q ":cloud" || ollama pull qwen3.5:cloud 2>&1 | grep -q "success\|up to date"; then
        ok "Signed in to Ollama cloud"
    else
        warn "You need to sign in to Ollama for cloud model access."
        echo ""
        echo "  Run this now (it will open a browser link):"
        echo "    ollama signin"
        echo ""
        read -r -p "  Press Enter after you have signed in..." _ </dev/tty
        if ! ollama pull qwen3.5:cloud 2>&1 | grep -q "success\|up to date"; then
            fail "Still not signed in. Run 'ollama signin' and try setup again."
        fi
        ok "Signed in to Ollama cloud"
    fi
fi

# ── 5. Fetch and pull cloud models ───────────────────────────────
step 5 "Fetching latest cloud models from ollama.com..."

# Discover all available cloud models dynamically
echo "  Querying ollama.com for cloud models..."
CLOUD_MODEL_NAMES=$(curl -sL "https://ollama.com/search?c=cloud" | \
    grep -oP 'href="/library/[^"]*"' | \
    sed 's|href="/library/||;s|"||g' | \
    sort -u)

CLOUD_TAGS=()
if [ -n "$CLOUD_MODEL_NAMES" ]; then
    for model_name in $CLOUD_MODEL_NAMES; do
        tags=$(curl -sL "https://ollama.com/library/${model_name}/tags" | \
            grep -oP "href=\"/library/${model_name}:[^\"]*cloud[^\"]*\"" | \
            sed "s|href=\"/library/||;s|\"||g" | \
            sort -u)
        while IFS= read -r tag; do
            [ -n "$tag" ] && CLOUD_TAGS+=("$tag")
        done <<< "$tags"
    done
fi

if [ ${#CLOUD_TAGS[@]} -eq 0 ]; then
    warn "Could not fetch model list from ollama.com — falling back to defaults"
    CLOUD_TAGS=("qwen3.5:cloud" "qwen3-coder:480b-cloud" "deepseek-v3.1:671b-cloud" "gemma4:31b-cloud")
else
    ok "Found ${#CLOUD_TAGS[@]} cloud models on ollama.com"
fi

# Show available models and let user choose
if [ "$WINDOWS_OLLAMA" = true ]; then
    # Get installed models via API (works regardless of local CLI auth)
    INSTALLED=$(curl -sf "${OLLAMA_URL}/api/tags" 2>/dev/null | grep -oP '"name"\s*:\s*"[^"]*cloud[^"]*"' | sed 's/"name"\s*:\s*"//;s/"//' | sort)
else
    INSTALLED=$(ollama list 2>/dev/null | grep ":.*cloud" | awk '{print $1}')
fi

echo ""
echo "  Available cloud models:"
for i in "${!CLOUD_TAGS[@]}"; do
    marker="  "
    echo "$INSTALLED" | grep -qx "${CLOUD_TAGS[$i]}" && marker="ok"
    if [ "$marker" = "ok" ]; then
        echo -e "    ${GREEN}[installed]${NC} ${CLOUD_TAGS[$i]}"
    else
        echo -e "    ${YELLOW}[new]      ${NC} ${CLOUD_TAGS[$i]}"
    fi
done

echo ""
echo "  1) Pull all cloud models (${#CLOUD_TAGS[@]} total)"
echo "  2) Pull only new/missing models"
echo "  3) Skip (keep current models)"
read -r -p "  Choice [1-3, default=1]: " MODEL_CHOICE </dev/tty
echo ""

case "${MODEL_CHOICE:-1}" in
    3)
        ok "Skipping model pull"
        ;;
    2)
        for model in "${CLOUD_TAGS[@]}"; do
            if echo "$INSTALLED" | grep -qx "$model"; then
                ok "$model already pulled"
            else
                echo "  Pulling $model ..."
                do_ollama_pull "$model"
                ok "$model pulled"
            fi
        done
        ;;
    *)
        for model in "${CLOUD_TAGS[@]}"; do
            if echo "$INSTALLED" | grep -qx "$model"; then
                ok "$model already pulled"
            else
                echo "  Pulling $model ..."
                do_ollama_pull "$model"
                ok "$model pulled"
            fi
        done
        ;;
esac

# Remove models no longer available on ollama.com
if [ -n "$INSTALLED" ]; then
    while IFS= read -r installed_model; do
        [ -z "$installed_model" ] && continue
        found=false
        for tag in "${CLOUD_TAGS[@]}"; do
            [ "$installed_model" = "$tag" ] && found=true && break
        done
        if ! $found; then
            echo -e "  ${RED}[obsolete]${NC} $installed_model is no longer on ollama.com"
            read -r -p "  Remove $installed_model? [Y/n]: " RM_REPLY </dev/tty
            echo ""
            if [[ ! $RM_REPLY =~ ^[Nn]$ ]]; then
                do_ollama_rm "$installed_model" && ok "Removed $installed_model"
            fi
        fi
    done <<< "$INSTALLED"
fi

# ── 6. Python virtual environment ─────────────────────────────────
step 6 "Setting up Python environment..."

# On WSL2 the project may live on /mnt/c (NTFS) where venvs break.
# Always create the venv in the native Linux filesystem.
VENV_DIR="$HOME/.local/share/goose-ollama/venv"

if [ ! -f "$VENV_DIR/bin/activate" ]; then
    # Remove broken venv from a previous failed attempt
    [ -d "$VENV_DIR" ] && rm -rf "$VENV_DIR"
    mkdir -p "$(dirname "$VENV_DIR")"
    python3 -m venv "$VENV_DIR" || fail "venv creation failed. Is python${PYTHON_VER}-venv installed?"
    ok "Virtual environment created at $VENV_DIR"
else
    ok "Virtual environment already exists"
fi

# Clean up any broken venv in the project directory from earlier attempts
[ -d "venv" ] && rm -rf venv

source "$VENV_DIR/bin/activate"
echo "  Installing pip packages (this may take a few minutes)..."
pip install --upgrade pip 2>&1 | tail -1
pip install -r config/requirements-core.txt 2>&1 | grep -E "^(Collecting|Installing|Successfully)" | sed 's/^/  /'
deactivate
ok "Python dependencies installed"

# ── 7. Skills integration ─────────────────────────────────────────
step 7 "Integrating skills..."

if [ ! -d ".agents/skills" ] || [ "$(ls .agents/skills/ 2>/dev/null | wc -l)" -eq 0 ]; then
    mkdir -p .agents/skills

    # Clone into /tmp to avoid NTFS chmod issues on WSL2 (/mnt/c)
    SKILLS_TMP="/tmp/goose-skills-$$"
    mkdir -p "$SKILLS_TMP"

    if [ ! -d "anthropic-skills" ]; then
        echo "  Cloning Anthropic skills..."
        git clone --depth 1 -q https://github.com/anthropics/skills.git "$SKILLS_TMP/anthropic-skills"
        cp -r "$SKILLS_TMP/anthropic-skills/skills/"* .agents/skills/ 2>/dev/null || true
    fi
    if [ ! -d "minimax-skills" ]; then
        echo "  Cloning MiniMax skills..."
        git clone --depth 1 -q https://github.com/MiniMax-AI/skills.git "$SKILLS_TMP/minimax-skills"
        cp -r "$SKILLS_TMP/minimax-skills/skills/"* .agents/skills/ 2>/dev/null || true
    fi

    rm -rf "$SKILLS_TMP"

    SKILL_COUNT=$(ls .agents/skills/ 2>/dev/null | wc -l)
    ok "$SKILL_COUNT skills integrated"
else
    SKILL_COUNT=$(ls .agents/skills/ | wc -l)
    ok "$SKILL_COUNT skills already available"
fi

# Symlink .agents into home so the Desktop UI can discover skills
if [ ! -e "$HOME/.agents" ]; then
    ln -s "$PROJECT_DIR/.agents" "$HOME/.agents"
    ok "Symlinked ~/.agents for Desktop UI skill discovery"
elif [ -L "$HOME/.agents" ]; then
    ok "~/.agents symlink already exists"
fi

# ── 8. Goose AI ───────────────────────────────────────────────────
step 8 "Checking Goose AI (always fetching latest release)..."

export PATH="$HOME/.local/bin:$PATH"

# Always query GitHub for the latest release tag — never pins to a fixed version.
echo "  Querying GitHub for the latest Goose release..."
LATEST_VER=$(curl -sf "https://api.github.com/repos/aaif-goose/goose/releases/latest" 2>/dev/null | grep -oP '"tag_name"\s*:\s*"v?\K[^"]+' || echo "")
[ -n "$LATEST_VER" ] && echo "  Latest Goose release on GitHub: $LATEST_VER"
CURRENT_VER=""
if command -v goose &>/dev/null; then
    CURRENT_VER=$(goose --version 2>/dev/null | tr -d ' ' | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
fi

NEEDS_INSTALL=false
if [ -z "$CURRENT_VER" ]; then
    NEEDS_INSTALL=true
elif [ -n "$LATEST_VER" ] && [ "$CURRENT_VER" != "$LATEST_VER" ]; then
    NEEDS_INSTALL=true
    echo "  Updating Goose AI ($CURRENT_VER -> $LATEST_VER)..."
fi

if [ "$NEEDS_INSTALL" = true ]; then
    [ -z "$CURRENT_VER" ] && echo "  Installing Goose AI..."

    # Download the Linux binary directly to native Linux filesystem.
    mkdir -p "$HOME/.local/bin"
    GOOSE_TMP="/tmp/goose-install-$$"
    mkdir -p "$GOOSE_TMP"
    GOOSE_URL="https://github.com/aaif-goose/goose/releases/latest/download/goose-x86_64-unknown-linux-gnu.tar.bz2"
    echo "  Downloading Linux binary..."
    curl -fSL "$GOOSE_URL" -o "$GOOSE_TMP/goose.tar.bz2" || fail "Download failed"
    echo "  Extracting..."
    cd "$GOOSE_TMP"
    tar -xjf goose.tar.bz2 || fail "Extraction failed — try again (download may have been corrupted)"
    GOOSE_BIN=$(find "$GOOSE_TMP" -name "goose" -type f ! -name "*.tar.*" | head -1)
    if [ -z "$GOOSE_BIN" ]; then
        fail "Could not find goose binary in archive"
    fi
    cp "$GOOSE_BIN" "$HOME/.local/bin/goose"
    chmod +x "$HOME/.local/bin/goose"
    cd "$PROJECT_DIR"
    rm -rf "$GOOSE_TMP"

    # Ensure PATH includes ~/.local/bin
    if ! grep -q 'HOME/.local/bin' ~/.bashrc 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    fi
    export PATH="$HOME/.local/bin:$PATH"

    if command -v goose &>/dev/null; then
        NEW_VER=$(goose --version 2>/dev/null | tr -d ' ' || echo "unknown")
        ok "Goose AI installed ($NEW_VER)"
    else
        warn "Goose AI may need a shell restart. Run: source ~/.bashrc"
    fi
else
    ok "Goose AI up to date ($CURRENT_VER)"
fi

# Apply config template (preserves GOOSE_MODEL + brave-search if already set)
# Ask goose where its config lives (path changed in 1.30; ~/.config/goose is stale)
GOOSE_CONFIG=$(goose info 2>/dev/null | grep -oP 'Config yaml:\s*\K\S+' | tr -d '\r')
[ -z "$GOOSE_CONFIG" ] && GOOSE_CONFIG="$HOME/.config/goose/config.yaml"
# Translate a Windows path (e.g. C:\Users\...) to WSL form if we're in WSL
case "$GOOSE_CONFIG" in
    [A-Za-z]:\\*)
        GOOSE_CONFIG=$(echo "$GOOSE_CONFIG" | sed 's|\\|/|g; s|^\([A-Za-z]\):|/mnt/\L\1|')
        ;;
esac

CURRENT_MODEL=""
BRAVE_BLOCK=""
if [ -f "$GOOSE_CONFIG" ]; then
    CURRENT_MODEL=$(grep "^GOOSE_MODEL:" "$GOOSE_CONFIG" 2>/dev/null | awk '{print $2}')
    # Preserve the user's brave-search block if present (has API-key env_keys)
    BRAVE_BLOCK=$(awk '/^  brave-search:/,/^  [a-zA-Z]/{ if ($0 ~ /^  [a-zA-Z]/ && $0 !~ /^  brave-search:/) exit; print }' "$GOOSE_CONFIG")
fi

mkdir -p "$(dirname "$GOOSE_CONFIG")"
if [ -f "$PROJECT_DIR/config/goose-config-template.yaml" ]; then
    cp "$PROJECT_DIR/config/goose-config-template.yaml" "$GOOSE_CONFIG"
    # Restore model selection
    if [ -n "$CURRENT_MODEL" ]; then
        tmpfile=$(mktemp /tmp/goose-cfg.XXXXXX)
        sed "s|^GOOSE_MODEL: .*|GOOSE_MODEL: $CURRENT_MODEL|" "$GOOSE_CONFIG" > "$tmpfile"
        cp "$tmpfile" "$GOOSE_CONFIG"
        rm -f "$tmpfile"
    fi
    # Restore brave-search block so the user doesn't lose their API-key wiring
    if [ -n "$BRAVE_BLOCK" ] && ! grep -q "^  brave-search:" "$GOOSE_CONFIG"; then
        tmpfile=$(mktemp /tmp/goose-cfg.XXXXXX)
        awk -v block="$BRAVE_BLOCK" '
            /^  skills:/ && !done { print block; done=1 }
            { print }
        ' "$GOOSE_CONFIG" > "$tmpfile"
        cp "$tmpfile" "$GOOSE_CONFIG"
        rm -f "$tmpfile"
    fi
    # Set OLLAMA_HOST to the detected URL (with port) in the config — without an
    # explicit port Goose falls back to port 1234 (LM Studio default).
    OLLAMA_HOST_VALUE="localhost:11434"
    if [ "$OLLAMA_URL" != "http://localhost:11434" ]; then
        OLLAMA_HOST_VALUE="$OLLAMA_URL"
    fi
    if grep -q "^OLLAMA_HOST:" "$GOOSE_CONFIG" 2>/dev/null; then
        tmpfile=$(mktemp /tmp/goose-cfg.XXXXXX)
        sed "s|^OLLAMA_HOST: .*|OLLAMA_HOST: $OLLAMA_HOST_VALUE|" "$GOOSE_CONFIG" > "$tmpfile"
        cp "$tmpfile" "$GOOSE_CONFIG"
        rm -f "$tmpfile"
    else
        echo "OLLAMA_HOST: $OLLAMA_HOST_VALUE" >> "$GOOSE_CONFIG"
    fi
    ok "Goose config applied to $GOOSE_CONFIG"
    # Clean up stale pre-1.30 config so users aren't confused
    if [ "$GOOSE_CONFIG" != "$HOME/.config/goose/config.yaml" ] && [ -f "$HOME/.config/goose/config.yaml" ]; then
        mv "$HOME/.config/goose/config.yaml" "$HOME/.config/goose/config.yaml.stale"
        ok "Moved pre-1.30 config aside: ~/.config/goose/config.yaml.stale"
    fi
else
    warn "Config template not found"
fi

# Install global goose-cloud command
bash "$PROJECT_DIR/scripts/install-global.sh"

# ── 9. Optional extras ───────────────────────────────────────────
step 9 "Optional extras..."

echo ""
read -r -p "  Install full ML/AI dependencies (PyTorch, OpenCV, Node.js, FFmpeg)? [y/N]: " INSTALL_DEPS </dev/tty
if [[ $INSTALL_DEPS =~ ^[Yy]$ ]]; then
    echo "  Running install-all-dependencies.sh..."
    bash "$PROJECT_DIR/scripts/install-all-dependencies.sh"
    ok "Full dependencies installed"
else
    ok "Skipped (run scripts/install-all-dependencies.sh later if needed)"
fi

echo ""
read -r -p "  Set up Brave Search web integration (free API key)? [y/N]: " SETUP_BRAVE </dev/tty
if [[ $SETUP_BRAVE =~ ^[Yy]$ ]]; then
    bash "$PROJECT_DIR/scripts/setup-brave-search.sh"
else
    ok "Skipped (run scripts/setup-brave-search.sh later if needed)"
fi

echo ""
read -r -p "  Install Claude Code CLI (enables 'ollama launch claude')? [y/N]: " INSTALL_CLAUDE </dev/tty
if [[ $INSTALL_CLAUDE =~ ^[Yy]$ ]]; then
    if command -v claude &>/dev/null; then
        ok "Claude Code already installed ($(claude --version 2>&1 | head -1))"
    elif ! command -v npm &>/dev/null; then
        warn "npm not found — install Node.js first (scripts/install-all-dependencies.sh), then: npm install -g @anthropic-ai/claude-code"
    else
        echo "  Running: npm install -g @anthropic-ai/claude-code ..."
        if npm install -g @anthropic-ai/claude-code 2>&1 | tail -3; then
            ok "Claude Code installed — run 'ollama launch claude' or 'claude'"
        else
            fail "Claude Code install failed. See https://code.claude.com/docs/en/quickstart"
        fi
    fi
else
    ok "Skipped (install later with: npm install -g @anthropic-ai/claude-code)"
fi

# ── Done ──────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "  Run Goose:  ./run-goose.sh"
echo "  Validate:   ./validate.sh"
echo ""
echo "Skills are auto-discovered — just ask naturally:"
echo "  'Create a PowerPoint presentation'"
echo "  'Help me build an iOS app'"
echo "  'Generate a Word document'"
