#!/bin/bash

# Validate Goose + Ollama MiniMax setup
# Aligned with what setup.sh actually installs (core setup).

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

ERRORS=0
WARNINGS=0
TOTAL_CHECKS=0

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

check_pass() { echo -e "  ${GREEN}PASS${NC} $1"; ((TOTAL_CHECKS++)); }
check_fail() { echo -e "  ${RED}FAIL${NC} $1"; ((ERRORS++)); ((TOTAL_CHECKS++)); }
check_warn() { echo -e "  ${YELLOW}WARN${NC} $1"; ((WARNINGS++)); ((TOTAL_CHECKS++)); }
check_info() { echo -e "  ${BLUE}INFO${NC} $1"; }
section()    { echo -e "\n${PURPLE}$1${NC}"; }

# Ensure ~/.local/bin is in PATH (setup puts Goose there)
export PATH="$HOME/.local/bin:$PATH"

echo "============================================"
echo "  SETUP VALIDATION"
echo "============================================"

# ── 1. Core tools ─────────────────────────────────────────────────
section "Core Tools"

if command -v ollama &>/dev/null; then
    check_pass "Ollama installed ($(ollama --version 2>/dev/null | head -1))"
else
    check_fail "Ollama not installed"
fi

if command -v goose &>/dev/null; then
    GOOSE_VER=$(goose --version 2>/dev/null | tr -d ' ' || echo "unknown")
    check_pass "Goose AI installed ($GOOSE_VER) at $(which goose)"
else
    check_fail "Goose AI not found in PATH"
fi

if command -v python3 &>/dev/null; then
    check_pass "Python installed ($(python3 --version 2>&1))"
else
    check_fail "Python3 not installed"
fi

if command -v git &>/dev/null; then
    check_pass "Git installed"
else
    check_fail "Git not installed"
fi

# Node.js is optional (only needed for full deps)
if command -v node &>/dev/null; then
    check_pass "Node.js installed ($(node --version))"
else
    check_info "Node.js not installed (optional — needed for PowerPoint generation)"
fi

# ── 2. Ollama service & model ────────────────────────────────────
section "Ollama Service & Model"

if curl -sf http://localhost:11434/api/tags &>/dev/null; then
    check_pass "Ollama service running on port 11434"
else
    check_fail "Ollama service not responding on port 11434"
fi

CLOUD_COUNT=$(ollama list 2>/dev/null | grep -c ":cloud" || echo 0)
if [ "$CLOUD_COUNT" -gt 0 ]; then
    check_pass "$CLOUD_COUNT cloud model(s) available"
else
    check_fail "No cloud models pulled (run: ollama pull qwen3.5:cloud)"
fi

# ── 3. Python environment ────────────────────────────────────────
section "Python Environment"

VENV_DIR="$HOME/.local/share/goose-ollama/venv"

if [ -f "$VENV_DIR/bin/activate" ]; then
    check_pass "Virtual environment exists at $VENV_DIR"

    source "$VENV_DIR/bin/activate"

    # Check core dependencies (from requirements-core.txt)
    declare -A DEPS=(
        ["pandas"]="pandas"
        ["numpy"]="numpy"
        ["pillow"]="PIL"
        ["pypdf"]="pypdf"
        ["python-docx"]="docx"
        ["openpyxl"]="openpyxl"
        ["matplotlib"]="matplotlib"
        ["requests"]="requests"
        ["python-pptx"]="pptx"
        ["pyyaml"]="yaml"
        ["rich"]="rich"
    )

    MISSING=0
    for dep in "${!DEPS[@]}"; do
        if python -c "import ${DEPS[$dep]}" 2>/dev/null; then
            check_pass "Python: $dep"
        else
            check_fail "Python: $dep missing"
            ((MISSING++))
        fi
    done

    deactivate
else
    check_fail "Virtual environment missing (expected at $VENV_DIR)"
fi

# ── 4. Skills ────────────────────────────────────────────────────
section "Skills"

if [ -d ".agents/skills" ]; then
    SKILL_COUNT=$(ls .agents/skills/ 2>/dev/null | wc -l)
    if [ "$SKILL_COUNT" -gt 20 ]; then
        check_pass "$SKILL_COUNT skills in .agents/skills/"
    elif [ "$SKILL_COUNT" -gt 0 ]; then
        check_warn "Only $SKILL_COUNT skills found (expected ~31)"
    else
        check_fail ".agents/skills/ is empty"
    fi

    # Spot-check key skill categories
    [ -d ".agents/skills/docx" ] || [ -d ".agents/skills/minimax-docx" ] && check_pass "Document skills" || check_warn "Document skills missing"
    [ -d ".agents/skills/pptx" ] || [ -d ".agents/skills/pptx-generator" ] && check_pass "PowerPoint skills" || check_warn "PowerPoint skills missing"
    [ -d ".agents/skills/frontend-dev" ] && check_pass "Frontend dev skills" || check_warn "Frontend dev skills missing"
else
    check_fail ".agents/skills/ directory missing"
fi

# ── 5. Goose configuration (optional — may not exist on first run) ─
section "Goose Configuration"

if [ -f ~/.config/goose/config.yaml ]; then
    check_pass "Goose config file exists"
else
    check_info "Goose config not yet created (will be created on first run)"
fi

# ── 6. Optional extras ──────────────────────────────────────────
section "Optional Extras"

if [ -d "brave-search-mcp" ] && [ -f "brave-search-mcp/package.json" ]; then
    check_info "Brave Search MCP directory present"
    if [ -f "brave-search-mcp/.env" ] && grep -q "BRAVE_API_KEY" brave-search-mcp/.env 2>/dev/null; then
        check_pass "Brave Search API key configured"
    else
        check_info "Brave Search API key not configured (run scripts/setup-brave-search.sh)"
    fi
else
    check_info "Brave Search MCP not set up (optional)"
fi

# ── 7. System resources ─────────────────────────────────────────
section "System"

TOTAL_RAM=$(free -m 2>/dev/null | awk '/^Mem:/ {print $2}' || echo "unknown")
if [ "$TOTAL_RAM" != "unknown" ]; then
    check_pass "RAM: ${TOTAL_RAM}MB"
fi

DISK_FREE=$(df -h . 2>/dev/null | awk 'NR==2 {print $4}')
if [ -n "$DISK_FREE" ]; then
    check_pass "Disk free: $DISK_FREE"
fi

# ── 8. Security ──────────────────────────────────────────────────
section "Security"

if [ -f ".gitignore" ]; then
    check_pass ".gitignore exists"
else
    check_warn ".gitignore missing"
fi

# ── Summary ──────────────────────────────────────────────────────
echo ""
echo "============================================"
PASSED=$((TOTAL_CHECKS - ERRORS - WARNINGS))

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "  ${GREEN}ALL CHECKS PASSED${NC} ($TOTAL_CHECKS/$TOTAL_CHECKS)"
elif [ $ERRORS -eq 0 ]; then
    echo -e "  ${GREEN}GOOD${NC} — $PASSED passed, $WARNINGS warnings"
else
    echo -e "  ${RED}$ERRORS ERRORS${NC}, $WARNINGS warnings out of $TOTAL_CHECKS checks"
fi
echo "============================================"

if [ $ERRORS -gt 0 ]; then
    echo ""
    echo "Fix errors above, then re-run: ./validate.sh"
fi

exit $ERRORS
