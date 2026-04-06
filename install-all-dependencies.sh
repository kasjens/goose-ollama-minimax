#!/bin/bash

# Comprehensive MiniMax Skills Dependency Installation Script
# This script installs all dependencies for all MiniMax skills

echo "============================================"
echo "MiniMax Skills - Complete Dependency Setup"
echo "============================================"

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
fi

echo "Detected OS: $OS"
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1. System Dependencies
echo "📦 Installing System Dependencies..."
echo "-----------------------------------"

# FFmpeg (required for multiple skills)
if ! command_exists ffmpeg; then
    echo "Installing FFmpeg..."
    if [ "$OS" = "macos" ]; then
        brew install ffmpeg
    elif [ "$OS" = "linux" ]; then
        sudo apt update && sudo apt install -y ffmpeg
    fi
else
    echo "✅ FFmpeg already installed"
fi

# jq (JSON processor for multimodal toolkit)
if ! command_exists jq; then
    echo "Installing jq..."
    if [ "$OS" = "macos" ]; then
        brew install jq
    elif [ "$OS" = "linux" ]; then
        sudo apt install -y jq
    fi
else
    echo "✅ jq already installed"
fi

# ImageMagick (for image processing)
if ! command_exists convert; then
    echo "Installing ImageMagick..."
    if [ "$OS" = "macos" ]; then
        brew install imagemagick
    elif [ "$OS" = "linux" ]; then
        sudo apt install -y imagemagick
    fi
else
    echo "✅ ImageMagick already installed"
fi

echo ""

# 2. Python Virtual Environment
echo "🐍 Setting up Python Virtual Environment..."
echo "-----------------------------------------"

# Create venv if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

echo ""

# 3. Python Dependencies
echo "📚 Installing Python Dependencies..."
echo "-----------------------------------"

# Core dependencies (already in requirements.txt)
echo "Installing core dependencies..."
pip install -q --upgrade pip
pip install -q \
    pandas \
    numpy \
    pillow \
    pypdf \
    python-docx \
    openpyxl \
    matplotlib \
    requests

# PowerPoint and document processing
echo "Installing document processing tools..."
pip install -q \
    "markitdown[pptx]" \
    python-pptx

# Additional AI/ML dependencies for vision and multimodal
echo "Installing AI/ML dependencies..."
pip install -q \
    opencv-python \
    scikit-image \
    scikit-learn \
    transformers

# Install PyTorch (CPU version for compatibility)
echo "Installing PyTorch (CPU version)..."
pip install -q torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Web scraping and parsing (for some skills)
echo "Installing web tools..."
pip install -q \
    beautifulsoup4 \
    lxml \
    html5lib

# Video/Audio processing
echo "Installing media processing tools..."
pip install -q \
    moviepy \
    pydub \
    librosa \
    soundfile

# Web frameworks for advanced skills
echo "Installing web frameworks..."
pip install -q \
    fastapi \
    uvicorn \
    streamlit \
    gradio \
    jinja2 \
    websockets \
    aiofiles

# Additional utilities
echo "Installing additional utilities..."
pip install -q \
    python-dotenv \
    pyyaml \
    jsonschema \
    click \
    rich

echo ""

# 4. Node.js Dependencies
echo "📦 Installing Node.js Dependencies..."
echo "------------------------------------"

# Check if Node.js is installed
if ! command_exists node; then
    echo "⚠️  Node.js not found. Please install Node.js first."
    echo "   Visit: https://nodejs.org/"
else
    echo "Node.js version: $(node --version)"
    
    # Install global packages for frontend development
    echo "Installing global Node packages..."
    
    # Check if running with sufficient permissions for global install
    if [ "$OS" = "linux" ] && [ "$EUID" -ne 0 ]; then
        echo "Note: Some global packages may require sudo"
    fi
    
    # Try to install common frontend tools (optional, may fail without sudo)
    npm install -g pptxgenjs 2>/dev/null || echo "Note: pptxgenjs global install skipped (may need sudo)"
    
    # Create local package.json if not exists
    if [ ! -f "package.json" ]; then
        npm init -y >/dev/null 2>&1
    fi
    
    # Install local packages
    echo "Installing local Node packages..."
    npm install --save \
        pptxgenjs \
        react \
        react-dom \
        react-icons \
        sharp \
        2>/dev/null || echo "Note: Some Node packages installation attempted"
fi

echo ""

# 5. Goose AI Installation
echo "🪿 Installing Goose AI..."
echo "-------------------------"

# Check if Goose AI is already installed
if command -v goose &> /dev/null; then
    EXISTING_VERSION=$(goose --version 2>/dev/null | tr -d ' ' || echo "unknown")
    echo "✅ Goose AI already installed: $EXISTING_VERSION"
else
    echo "Installing Goose AI..."
    
    # Check for externally managed environment (Ubuntu 24.04+)
    if python3 -m pip install --help | grep -q "externally-managed-environment"; then
        echo "Detected externally managed Python environment"
        
        # Use official Goose installer
        echo "Using official Goose installer..."
        curl -fsSL https://github.com/block/goose/releases/latest/download/download_cli.sh | bash
        
        # Ensure .local/bin directory is in PATH
        if [ ! -d "$HOME/.local/bin" ] || [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            echo "Adding ~/.local/bin to PATH..."
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
            export PATH="$HOME/.local/bin:$PATH"
        fi
        
    else
        # Older system - use official installer too
        echo "Using official Goose installer..."
        curl -fsSL https://github.com/block/goose/releases/latest/download/download_cli.sh | bash
    fi
    
    # Verify installation
    if command -v goose &> /dev/null; then
        GOOSE_VERSION=$(goose --version 2>/dev/null | tr -d ' ' || echo "unknown")
        echo "✅ Goose AI installed successfully: $GOOSE_VERSION"
    else
        echo "❌ Goose AI installation may have failed"
        echo "Try manually: ./install-goose-ai.sh"
        echo "Or direct installer: curl -fsSL https://github.com/block/goose/releases/latest/download/download_cli.sh | bash"
    fi
fi

echo ""

# 6. Ollama Cloud Setup
echo "☁️ Ollama Cloud Configuration..."
echo "-------------------------------"

# Check Ollama installation
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama not found. Please install Ollama first:"
    echo "   curl -fsSL https://ollama.com/install.sh | sh"
    echo ""
fi

# Check Ollama signin status
if ollama list &> /dev/null; then
    echo "✅ Ollama is accessible"
    
    # Check if signed in (try to access a cloud model)
    if ollama pull minimax-m2.7:cloud --help &> /dev/null 2>&1; then
        echo "✅ Signed in to Ollama cloud"
    else
        echo "⚠️  Please sign in to Ollama cloud:"
        echo "   ollama signin"
        echo "   This enables access to 2025 cloud models"
    fi
else
    echo "⚠️  Ollama service not running or not accessible"
    echo "   Start with: ollama serve"
fi

echo ""

# 6. Skills Integration
echo "🎯 Integrating Skills (31 total)..."
echo "-----------------------------------"

# Create .agents/skills directory if it doesn't exist
if [ ! -d ".agents/skills" ]; then
    echo "Creating .agents/skills directory..."
    mkdir -p .agents/skills
    
    # Clone skill repositories if they don't exist
    if [ ! -d "anthropic-skills" ]; then
        echo "Cloning Anthropic skills..."
        git clone https://github.com/anthropics/skills.git anthropic-skills
    fi
    
    if [ ! -d "minimax-skills" ]; then
        echo "Cloning MiniMax skills..."
        git clone https://github.com/MiniMax-AI/skills.git minimax-skills
    fi
    
    # Copy all skills to .agents/skills directory
    echo "Integrating Anthropic skills..."
    if [ -d "anthropic-skills/skills" ]; then
        cp -r anthropic-skills/skills/* .agents/skills/ 2>/dev/null || echo "   Some Anthropic skills may not be compatible"
    fi
    
    echo "Integrating MiniMax skills..."
    if [ -d "minimax-skills/skills" ]; then
        cp -r minimax-skills/skills/* .agents/skills/ 2>/dev/null || echo "   Some MiniMax skills may not be compatible"
    fi
    
    # Count total skills
    SKILL_COUNT=$(ls .agents/skills/ 2>/dev/null | wc -l || echo "0")
    echo "✅ Skills integrated: $SKILL_COUNT skills available"
    
    echo ""
    echo "📋 Skill Categories:"
    echo "   📄 Document Processing: PowerPoint, Word, Excel, PDF"
    echo "   📱 Mobile Development: iOS, Android, React Native, Flutter"
    echo "   🎨 Creative & Design: Art generation, GIFs, Frontend"
    echo "   💻 Development Tools: APIs, MCP servers, Testing"
    echo "   💼 Communication: Documentation, Analysis, Multimedia"
else
    EXISTING_SKILLS=$(ls .agents/skills/ 2>/dev/null | wc -l || echo "0")
    echo "✅ Skills already integrated: $EXISTING_SKILLS skills available"
fi

echo ""

# 7. Verify Installation
echo "✨ Verifying Installation..."
echo "---------------------------"

# Run the test script if available
if [ -f "test_skills.py" ]; then
    python test_skills.py
fi

echo ""

# 8. Skills Usage Guide
echo "📝 How to Use Skills:"
echo "--------------------"
echo ""
echo "🎯 **Skills are auto-discovered! Just ask naturally:**"
echo ""
echo "Document Processing:"
echo "  🪿 'Create a PowerPoint about AI'           → Uses pptx skills"
echo "  🪿 'Help me make a Word document'          → Uses docx skills"  
echo "  🪿 'Generate an Excel spreadsheet'         → Uses xlsx skills"
echo ""
echo "Mobile Development:"
echo "  🪿 'Build an iOS app'                      → Uses ios-application-dev"
echo "  🪿 'Create a React Native app'             → Uses react-native-dev"
echo "  🪿 'Develop a Flutter application'         → Uses flutter-dev"
echo ""
echo "Creative & Design:"
echo "  🪿 'Create algorithmic art'                → Uses algorithmic-art"
echo "  🪿 'Make a GIF animation'                  → Uses gif-sticker-maker"
echo "  🪿 'Design a frontend interface'           → Uses frontend-design"
echo ""
echo "Development Tools:"
echo "  🪿 'Build an MCP server'                   → Uses mcp-builder"
echo "  🪿 'Test my web application'               → Uses webapp-testing"
echo "  🪿 'Use the Claude API'                    → Uses claude-api"
echo ""

# Deactivate virtual environment
deactivate

echo "============================================"
echo "✅ Dependency Installation Complete!"
echo "============================================"
echo ""
echo "🚀 **Next steps:**"
echo "1. Configure cloud models: ./configure-cloud-models.sh"
echo "2. Set up web search (optional): ./setup-brave-search.sh"
echo "3. Install Desktop UI (optional): ./install-goose-ui.sh"
echo "4. Validate setup: ./validate-setup.sh"
echo "5. Start Goose: ./run-goose.sh"
echo ""
echo "✨ **You now have 31 skills ready to use automatically!**"
echo ""