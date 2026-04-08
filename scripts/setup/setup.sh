#!/bin/bash
set -e

# Goose + Ollama MiniMax — One-Step Setup
# Works on a fresh WSL2 Ubuntu install with zero prerequisites.

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

step()  { echo -e "\n${BLUE}[$1/8]${NC} $2"; }
ok()    { echo -e "  ${GREEN}OK${NC} $1"; }
warn()  { echo -e "  ${YELLOW}!!${NC} $1"; }
fail()  { echo -e "  ${RED}FAIL${NC} $1"; exit 1; }

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

if ! command -v ollama &>/dev/null; then
    echo "  Ollama not found — installing..."
    curl -fsSL https://ollama.com/install.sh | sh
    ok "Ollama installed"
else
    ok "Ollama already installed"
fi

# ── 3. Ollama service ──────────────────────────────────────────────
step 3 "Ensuring Ollama service is running..."

if ! curl -sf http://localhost:11434/api/tags &>/dev/null; then
    if command -v systemctl &>/dev/null && systemctl is-active ollama &>/dev/null; then
        ok "Ollama service active (systemd)"
    else
        echo "  Starting ollama serve in background..."
        nohup ollama serve &>/dev/null &
        sleep 3
    fi
    # Verify it came up
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

# Try pulling a tiny cloud manifest to test sign-in
if ollama list 2>&1 | grep -q ":cloud" || ollama pull minimax-m2.7:cloud 2>&1 | grep -q "success\|up to date"; then
    ok "Signed in to Ollama cloud"
else
    warn "You need to sign in to Ollama for cloud model access."
    echo ""
    echo "  Run this now (it will open a browser link):"
    echo "    ollama signin"
    echo ""
    read -p "  Press Enter after you have signed in..." _
    # Verify sign-in worked
    if ! ollama pull minimax-m2.7:cloud 2>&1 | grep -q "success\|up to date"; then
        fail "Still not signed in. Run 'ollama signin' and try setup again."
    fi
    ok "Signed in to Ollama cloud"
fi

# ── 5. Pull cloud models ─────────────────────────────────────────
step 5 "Pulling cloud models..."

for model in "qwen3.5:cloud" "qwen3-coder:480b-cloud" "deepseek-v3.1:671b-cloud" "gemma4:31b-cloud" "minimax-m2.7:cloud"; do
    if ollama list 2>/dev/null | grep -q "$model"; then
        ok "$model already pulled"
    else
        echo "  Pulling $model ..."
        ollama pull "$model" 2>/dev/null
        ok "$model pulled"
    fi
done

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

    if [ ! -d "anthropic-skills" ]; then
        echo "  Cloning Anthropic skills..."
        git clone --depth 1 -q https://github.com/anthropics/skills.git anthropic-skills
    fi
    if [ ! -d "minimax-skills" ]; then
        echo "  Cloning MiniMax skills..."
        git clone --depth 1 -q https://github.com/MiniMax-AI/skills.git minimax-skills
    fi

    cp -r anthropic-skills/skills/* .agents/skills/ 2>/dev/null || true
    cp -r minimax-skills/skills/* .agents/skills/ 2>/dev/null || true

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
step 8 "Checking Goose AI..."

export PATH="$HOME/.local/bin:$PATH"

if command -v goose &>/dev/null; then
    GOOSE_VER=$(goose --version 2>/dev/null | tr -d ' ' || echo "unknown")
    ok "Goose AI already installed ($GOOSE_VER)"
else
    echo "  Installing Goose AI..."

    # The official installer misdetects WSL2 on /mnt/c as Windows.
    # Download the Linux binary directly to native Linux filesystem.
    mkdir -p "$HOME/.local/bin"
    GOOSE_TMP="/tmp/goose-install-$$"
    mkdir -p "$GOOSE_TMP"
    GOOSE_URL="https://github.com/block/goose/releases/latest/download/goose-x86_64-unknown-linux-gnu.tar.bz2"
    echo "  Downloading Linux binary..."
    curl -fSL "$GOOSE_URL" -o "$GOOSE_TMP/goose.tar.bz2" || fail "Download failed"
    echo "  Extracting..."
    cd "$GOOSE_TMP"
    tar -xjf goose.tar.bz2 || fail "Extraction failed — try again (download may have been corrupted)"
    # The archive may contain the binary at top level or in a subdirectory
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
        ok "Goose AI installed"
    else
        warn "Goose AI may need a shell restart. Run: source ~/.bashrc"
    fi
fi

# Create Goose config if it doesn't exist (use full template with all extensions)
if [ ! -f "$HOME/.config/goose/config.yaml" ]; then
    mkdir -p "$HOME/.config/goose"
    if [ -f "$PROJECT_DIR/config/goose-config-template.yaml" ]; then
        cp "$PROJECT_DIR/config/goose-config-template.yaml" "$HOME/.config/goose/config.yaml"
    fi
    ok "Goose config created"
else
    ok "Goose config already exists"
fi

# ── Done ──────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "  Run Goose:  ./run-goose.sh"
echo "  Validate:   ./validate.sh"
echo "  Full deps:  scripts/setup/install-all-dependencies.sh  (optional — adds PyTorch, Node.js, etc.)"
echo ""
echo "Skills are auto-discovered — just ask naturally:"
echo "  'Create a PowerPoint presentation'"
echo "  'Help me build an iOS app'"
echo "  'Generate a Word document'"
