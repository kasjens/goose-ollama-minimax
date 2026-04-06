#!/bin/bash

# Comprehensive Setup Validation Script
# Validates entire Goose + Ollama + Skills + Search setup

echo "============================================"
echo "🔍 COMPREHENSIVE SETUP VALIDATION"
echo "============================================"
echo ""

ERRORS=0
WARNINGS=0
TOTAL_CHECKS=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

check_pass() {
    echo -e "${GREEN}✅ PASS${NC} $1"
    ((TOTAL_CHECKS++))
}

check_fail() {
    echo -e "${RED}❌ FAIL${NC} $1"
    ((ERRORS++))
    ((TOTAL_CHECKS++))
}

check_warn() {
    echo -e "${YELLOW}⚠️  WARN${NC} $1"
    ((WARNINGS++))
    ((TOTAL_CHECKS++))
}

check_info() {
    echo -e "${BLUE}ℹ️  INFO${NC} $1"
}

section_header() {
    echo ""
    echo -e "${PURPLE}📋 $1${NC}"
    echo "$(printf '=%.0s' $(seq 1 ${#1}))"
}

# 1. Core System Requirements
section_header "CORE SYSTEM REQUIREMENTS"

# Check Ollama
if command -v ollama &> /dev/null; then
    OLLAMA_VERSION=$(ollama --version 2>/dev/null | head -n1)
    check_pass "Ollama installed: $OLLAMA_VERSION"
else
    check_fail "Ollama not installed"
fi

# Check Goose installations
USER_GOOSE="/home/kasjens/.local/bin/goose"
SYSTEM_GOOSE="/usr/bin/goose"

if [[ -x "$USER_GOOSE" ]]; then
    USER_VERSION=$("$USER_GOOSE" --version 2>/dev/null | tr -d ' ')
    check_pass "User-local Goose AI installed: $USER_VERSION"
else
    check_info "User-local Goose AI not found"
fi

if [[ -x "$SYSTEM_GOOSE" ]]; then
    # Check if it's the GUI app or CLI version
    if [[ -d "/usr/lib/goose" ]]; then
        SYSTEM_VERSION=$(cat /usr/lib/goose/version 2>/dev/null || echo "unknown")
        check_pass "System-wide Goose app installed: v$SYSTEM_VERSION (GUI)"
    else
        SYSTEM_VERSION=$("$SYSTEM_GOOSE" --version 2>/dev/null | tr -d ' ')
        check_pass "System-wide Goose AI installed: $SYSTEM_VERSION"
    fi
else
    check_info "System-wide Goose installation not found"
fi

# Check which Goose is active
ACTIVE_GOOSE=$(which goose 2>/dev/null)
if [[ -n "$ACTIVE_GOOSE" ]]; then
    ACTIVE_VERSION=$(goose --version 2>/dev/null | tr -d ' ')
    check_pass "Active Goose installation: $ACTIVE_GOOSE ($ACTIVE_VERSION)"
else
    check_fail "No Goose installation accessible in PATH"
fi

# Check Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    check_pass "Node.js installed: $NODE_VERSION"
else
    check_fail "Node.js not installed (needed for PowerPoint generation)"
fi

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    check_pass "Python installed: $PYTHON_VERSION"
else
    check_fail "Python3 not installed"
fi

# Check Git
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version)
    check_pass "Git installed: $GIT_VERSION"
else
    check_fail "Git not installed"
fi

# 2. Ollama Service and Models
section_header "OLLAMA SERVICE AND MODELS"

# Check Ollama service
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    check_pass "Ollama service running on port 11434"
    
    # Check models
    MODELS=$(ollama list 2>/dev/null | grep -v "NAME" | wc -l)
    if [ "$MODELS" -gt 0 ]; then
        check_pass "Models installed: $MODELS"
        
        # Check cloud models
        CLOUD_COUNT=$(ollama list | grep ":cloud" | wc -l)
        if [ $CLOUD_COUNT -gt 0 ]; then
            check_pass "Cloud models available: $CLOUD_COUNT"
            
            # Check MiniMax model specifically (default)
            if ollama list | grep -q "minimax-m2.7:cloud"; then
                check_pass "MiniMax default model available"
            else
                check_warn "MiniMax default model not found (other cloud models available)"
            fi
        else
            check_fail "No cloud models found"
        fi
        
        # Test default model response
        CURRENT_MODEL=$(grep "GOOSE_MODEL:" ~/.config/goose/config.yaml 2>/dev/null | awk '{print $2}' || echo "minimax-m2.7:cloud")
        if ollama list | grep -q "$CURRENT_MODEL"; then
            TEST_RESPONSE=$(echo "test" | timeout 30 ollama run "$CURRENT_MODEL" 2>/dev/null)
            if [ $? -eq 0 ] && [ ! -z "$TEST_RESPONSE" ]; then
                check_pass "Current model ($CURRENT_MODEL) responds correctly"
            else
                check_fail "Current model ($CURRENT_MODEL) response test failed"
            fi
        else
            check_warn "Current model ($CURRENT_MODEL) not available locally"
        fi
        
    else
        check_fail "No models installed"
    fi
    
else
    check_fail "Ollama service not responding"
fi

# 3. Goose Configuration
section_header "GOOSE CONFIGURATION"

# Check Goose config directory
if [ -d ~/.config/goose ]; then
    check_pass "Goose config directory exists"
    
    # Check config file
    if [ -f ~/.config/goose/config.yaml ]; then
        check_pass "Goose config file exists"
        
        # Check MiniMax model configuration
        if grep -q "minimax-m2.7:cloud" ~/.config/goose/config.yaml; then
            check_pass "MiniMax model configured in Goose"
        else
            check_fail "MiniMax model not configured in Goose"
        fi
        
        # Check extensions count
        EXTENSIONS=$(grep -c "enabled: true" ~/.config/goose/config.yaml 2>/dev/null || echo 0)
        if [ "$EXTENSIONS" -gt 5 ]; then
            check_pass "Extensions configured: $EXTENSIONS"
        else
            check_warn "Few extensions configured: $EXTENSIONS"
        fi
        
        # Check Brave Search extension (optional feature)
        if grep -q "brave-search:" ~/.config/goose/config.yaml; then
            check_pass "Brave Search extension configured"
            
            # Check API key
            if grep -q "BRAVE_API_KEY" ~/.config/goose/config.yaml; then
                check_pass "Brave Search API key configured"
            else
                check_warn "Brave Search API key missing (optional feature)"
            fi
        else
            check_info "Brave Search extension not configured (optional - for web search)"
        fi
        
    else
        check_fail "Goose config file missing"
    fi
else
    check_fail "Goose config directory missing"
fi

# 4. Python Virtual Environment and Dependencies
section_header "PYTHON ENVIRONMENT AND DEPENDENCIES"

# Check virtual environment
if [ -d "venv" ]; then
    check_pass "Python virtual environment exists"
    
    # Activate and check dependencies
    source venv/bin/activate
    
    # Core dependencies with proper import names
    declare -A DEPS=(
        ["pandas"]="pandas"
        ["numpy"]="numpy"
        ["pillow"]="PIL"
        ["pypdf"]="pypdf"
        ["python-docx"]="docx"
        ["openpyxl"]="openpyxl"
        ["matplotlib"]="matplotlib"
        ["requests"]="requests"
        ["markitdown"]="markitdown"
        ["python-pptx"]="pptx"
        ["opencv-python"]="cv2"
        ["scikit-image"]="skimage"
        ["scikit-learn"]="sklearn"
        ["transformers"]="transformers"
        ["torch"]="torch"
        ["fastapi"]="fastapi"
        ["streamlit"]="streamlit"
        ["gradio"]="gradio"
    )
    
    MISSING_DEPS=0
    
    for dep in "${!DEPS[@]}"; do
        import_name="${DEPS[$dep]}"
        if python -c "import ${import_name}" 2>/dev/null; then
            check_pass "Python dependency: $dep"
        else
            check_fail "Missing Python dependency: $dep"
            ((MISSING_DEPS++))
        fi
    done
    
    TOTAL_DEPS=${#DEPS[@]}
    INSTALLED_DEPS=$((TOTAL_DEPS - MISSING_DEPS))
    
    if [ $MISSING_DEPS -eq 0 ]; then
        check_pass "All Python dependencies installed: $INSTALLED_DEPS/$TOTAL_DEPS"
    else
        check_fail "$MISSING_DEPS/$TOTAL_DEPS Python dependencies missing"
    fi
    
    deactivate
else
    check_fail "Python virtual environment missing"
fi

# 5. Skills Integration
section_header "SKILLS INTEGRATION"

# Check .agents/skills directory
if [ -d ".agents/skills" ]; then
    SKILL_COUNT=$(ls .agents/skills/ 2>/dev/null | wc -l || echo "0")
    if [ "$SKILL_COUNT" -gt 20 ]; then
        check_pass "Skills directory exists with $SKILL_COUNT skills"
        
        # Check for specific skill categories
        if [ -d ".agents/skills/docx" ] || [ -d ".agents/skills/minimax-docx" ]; then
            check_pass "Document processing skills available"
        else
            check_warn "Document processing skills missing"
        fi
        
        if [ -d ".agents/skills/pptx" ] || [ -d ".agents/skills/pptx-generator" ]; then
            check_pass "PowerPoint generation skills available"
        else
            check_warn "PowerPoint skills missing"
        fi
        
        if [ -d ".agents/skills/frontend-dev" ] || [ -d ".agents/skills/fullstack-dev" ]; then
            check_pass "Web development skills available"
        else
            check_warn "Web development skills missing"
        fi
        
        if [ -d ".agents/skills/ios-application-dev" ] || [ -d ".agents/skills/android-native-dev" ]; then
            check_pass "Mobile development skills available"
        else
            check_info "Mobile development skills available (may require platform SDKs)"
        fi
        
    elif [ "$SKILL_COUNT" -gt 0 ]; then
        check_warn "Only $SKILL_COUNT skills found (expected 31)"
        check_info "Run: ./install-all-dependencies.sh to install missing skills"
    else
        check_fail "Skills directory exists but is empty"
    fi
else
    check_fail "Skills directory missing (.agents/skills/)"
    check_info "Run: ./setup.sh or ./install-all-dependencies.sh to integrate skills"
fi

# Check if Anthropic and MiniMax source repositories exist
if [ -d "anthropic-skills" ]; then
    check_pass "Anthropic skills repository cloned"
else
    check_info "Anthropic skills source not found (will be cloned when needed)"
fi

if [ -d "minimax-skills" ]; then
    check_pass "MiniMax skills repository cloned" 
else
    check_info "MiniMax skills source not found (will be cloned when needed)"
fi

# 6. Node.js Dependencies
section_header "NODE.JS DEPENDENCIES"

# Check package.json
if [ -f "package.json" ]; then
    check_pass "package.json exists"
    
    # Check node_modules
    if [ -d "node_modules" ]; then
        check_pass "Node modules installed"
        
        # Check pptxgenjs specifically
        if [ -d "node_modules/pptxgenjs" ] || npm list pptxgenjs &>/dev/null; then
            check_pass "pptxgenjs installed"
        else
            check_fail "pptxgenjs not installed"
        fi
    else
        check_fail "Node modules not installed"
    fi
else
    check_warn "package.json missing (Node dependencies may not be managed)"
fi

# Check slides directory
if [ -d "slides" ]; then
    check_pass "Slides directory exists"
    if [ -f "slides/package.json" ]; then
        cd slides
        if npm list pptxgenjs &>/dev/null; then
            check_pass "Slides pptxgenjs installed"
        else
            check_fail "Slides pptxgenjs not installed"
        fi
        cd ..
    fi
fi

# 6. Skills Integration
section_header "SKILLS INTEGRATION"

# Check MiniMax skills
if [ -d "minimax-skills" ]; then
    MINIMAX_SKILLS=$(ls minimax-skills/skills/ 2>/dev/null | wc -l)
    check_pass "MiniMax skills directory: $MINIMAX_SKILLS skills"
else
    check_fail "MiniMax skills directory missing"
fi

# Check Anthropic skills
if [ -d "anthropic-skills" ]; then
    ANTHROPIC_SKILLS=$(ls anthropic-skills/skills/ 2>/dev/null | wc -l)
    check_pass "Anthropic skills directory: $ANTHROPIC_SKILLS skills"
else
    check_fail "Anthropic skills directory missing"
fi

# Check integration scripts
INTEGRATION_SCRIPTS=("integrate-skills.py" "integrate-anthropic-skills.py" "goose-skills.sh")
for script in "${INTEGRATION_SCRIPTS[@]}"; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        check_pass "Integration script: $script"
    else
        check_fail "Missing or non-executable: $script"
    fi
done

# 7. Web Search Capability
section_header "WEB SEARCH CAPABILITY"

# Check Brave Search MCP
if [ -d "brave-search-mcp" ]; then
    check_pass "Brave Search MCP directory exists"
    
    # Check MCP dependencies
    if [ -f "brave-search-mcp/package.json" ]; then
        cd brave-search-mcp
        if npm list @modelcontextprotocol/sdk &>/dev/null; then
            check_pass "MCP SDK installed"
        else
            check_fail "MCP SDK not installed"
        fi
        cd ..
    else
        check_fail "Brave Search MCP package.json missing"
    fi
    
    # Check API key (optional)
    if [ -f "brave-search-mcp/.env" ] && grep -q "BRAVE_API_KEY" brave-search-mcp/.env; then
        check_pass "Brave Search API key configured"
        
        # Test API key (basic format check)
        API_KEY=$(grep "BRAVE_API_KEY" brave-search-mcp/.env | cut -d'=' -f2 | tr -d '"')
        if [ ${#API_KEY} -gt 20 ]; then
            check_pass "Brave API key format looks valid"
        else
            check_warn "Brave API key format may be invalid"
        fi
    else
        check_info "Brave Search API key not configured (optional - for web search features)"
    fi
else
    check_info "Brave Search MCP directory missing (optional - for web search features)"
fi

# 8. Documentation and Guides
section_header "DOCUMENTATION AND GUIDES"

DOCS=("README.md" "DEPENDENCIES.md" "WEB-SEARCH-GUIDE.md" "COMPLETE-SKILLS-GUIDE.md")
for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        check_pass "Documentation: $doc"
    else
        check_warn "Missing documentation: $doc"
    fi
done

# 9. System Performance
section_header "SYSTEM PERFORMANCE"

# Check system resources (for cloud models, RAM is less critical)
TOTAL_RAM=$(free -m 2>/dev/null | awk '/^Mem:/ {print $2}' || echo "unknown")
if [ "$TOTAL_RAM" != "unknown" ]; then
    if [ $TOTAL_RAM -gt 16000 ]; then
        check_pass "System RAM: ${TOTAL_RAM}MB (excellent for cloud models)"
    elif [ $TOTAL_RAM -gt 8000 ]; then
        check_pass "System RAM: ${TOTAL_RAM}MB (good for cloud models - local inference not needed)"
    else
        check_warn "System RAM: ${TOTAL_RAM}MB (sufficient for cloud models, may limit local options)"
    fi
else
    check_info "Could not determine system RAM"
fi

# Check GPU (not required for cloud models)
if command -v nvidia-smi &> /dev/null; then
    GPU_MEM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
    if [ ! -z "$GPU_MEM" ] && [ $GPU_MEM -gt 8000 ]; then
        check_pass "GPU Memory: ${GPU_MEM}MB (available for local models if needed)"
    elif [ ! -z "$GPU_MEM" ] && [ $GPU_MEM -gt 4000 ]; then
        check_pass "GPU Memory: ${GPU_MEM}MB (available for small local models)"
    else
        check_info "Limited GPU memory: ${GPU_MEM}MB (cloud models don't require GPU)"
    fi
else
    check_pass "No NVIDIA GPU detected (not needed - using cloud models via Ollama)"
fi

# Check disk space (minimal needed for cloud models)
DISK_FREE=$(df -h . 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//')
if [ ! -z "$DISK_FREE" ] && [ ${DISK_FREE%.*} -lt 5 ]; then
    check_warn "Low disk space: ${DISK_FREE}G free (cloud models need minimal space)"
elif [ ! -z "$DISK_FREE" ] && [ ${DISK_FREE%.*} -lt 10 ]; then
    check_pass "Disk space: ${DISK_FREE}G free (adequate for cloud models)"
else
    check_pass "Disk space: ${DISK_FREE}G free (excellent for cloud models)"
fi

# 10. Security and Best Practices
section_header "SECURITY AND BEST PRACTICES"

# Check .gitignore
if [ -f ".gitignore" ]; then
    check_pass ".gitignore exists"
    
    if grep -q "\.env" .gitignore && grep -q "venv/" .gitignore; then
        check_pass "Sensitive files protected in .gitignore"
    else
        check_warn ".gitignore may not protect all sensitive files"
    fi
else
    check_warn ".gitignore missing (API keys may be exposed)"
fi

# Check API key exposure (exclude common false positives)
if grep -r "BSA\|sk-\|ghu_" . --exclude-dir=.git --exclude-dir=venv --exclude-dir=node_modules --exclude="*.md" --exclude="*.sh" --exclude="*.py" 2>/dev/null | grep -v ".env" | grep -v ".gitignore" | grep -v "SKILL.md" | grep -v "test-enhanced-skills.py"; then
    check_fail "Potential API key exposure in files"
else
    check_pass "No obvious API key exposure"
fi

# Final Summary
echo ""
echo "============================================"
echo "📊 VALIDATION SUMMARY"
echo "============================================"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}🎉 PERFECT SETUP!${NC}"
    echo "   All $TOTAL_CHECKS checks passed"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}✅ GOOD SETUP${NC}"
    echo "   $TOTAL_CHECKS checks completed with $WARNINGS warnings"
else
    echo -e "${RED}⚠️  SETUP NEEDS ATTENTION${NC}"
    echo "   $TOTAL_CHECKS checks completed: $ERRORS errors, $WARNINGS warnings"
fi

echo ""
echo "📈 Setup Completeness:"
SCORE=$(( (TOTAL_CHECKS - ERRORS - WARNINGS) * 100 / TOTAL_CHECKS ))
echo "   Score: $SCORE% ($((TOTAL_CHECKS - ERRORS - WARNINGS))/$TOTAL_CHECKS checks passed)"

if [ $ERRORS -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ Critical Issues Found: $ERRORS${NC}"
    echo "   Please address these before using the setup"
fi

if [ $WARNINGS -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Warnings: $WARNINGS${NC}"
    echo "   These are optional optimizations"
fi

echo ""
echo "🔧 Next Steps:"
if [ $ERRORS -gt 0 ]; then
    echo "   1. Fix critical errors listed above"
    echo "   2. Re-run this validation script"
    echo "   3. Run ./optimize-setup.sh for performance improvements"
elif [ $WARNINGS -gt 0 ]; then
    echo "   1. Review warnings and optimize if needed"
    echo "   2. Run ./optimize-setup.sh for performance improvements"
    echo "   3. Start Goose with ./run-goose.sh"
else
    echo "   1. Run ./optimize-setup.sh for maximum performance"
    echo "   2. Start Goose with ./run-goose.sh"
    echo "   3. Enjoy your complete AI development environment!"
fi

echo ""
echo "📚 Additional Commands:"
echo "   ./health-check.sh           # Quick health check"
echo "   ./goose-skills.sh           # Manage skills"
echo "   ./monitor-performance.sh    # Monitor performance"

exit $ERRORS