#!/bin/bash

# Goose AI Installation Script for Ubuntu 25.10+ (PEP 668 Compatible)
# Handles externally managed Python environments

echo "=================================================="
echo "🪿 GOOSE AI INSTALLATION (Ubuntu 25.10+)"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if already installed
if command -v goose &> /dev/null; then
    EXISTING_VERSION=$(goose --version 2>/dev/null | tr -d ' ' || echo "unknown")
    echo -e "${GREEN}✅ Goose AI already installed: $EXISTING_VERSION${NC}"
    echo ""
    read -p "Reinstall/Update? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
fi

echo -e "${BLUE}🔍 Detecting Python environment...${NC}"

# Check Python version
PYTHON_VERSION=$(python3 --version 2>&1 | grep -o '[0-9]\+\.[0-9]\+')
echo "   Python version: $PYTHON_VERSION"

# Check Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "unknown")
echo "   Ubuntu version: $UBUNTU_VERSION"

# Check for externally managed environment
EXTERNALLY_MANAGED=false
if python3 -c "import sys; exit(0 if sys.version_info >= (3,11) else 1)" 2>/dev/null; then
    if [ -f "/usr/lib/python$PYTHON_VERSION/EXTERNALLY-MANAGED" ]; then
        EXTERNALLY_MANAGED=true
        echo "   Environment: Externally managed (PEP 668)"
    fi
fi

echo ""

# Installation method selection
echo -e "${BLUE}📦 Available installation methods:${NC}"
echo "1. Official installer (recommended - from Block/Square)"
echo "2. Virtual environment (isolated, if available on PyPI)"  
echo "3. System packages (if available)"
echo "4. Manual binary download (fallback)"
echo ""

if [ "$EXTERNALLY_MANAGED" = true ]; then
    echo -e "${YELLOW}⚠️  Externally managed environment detected${NC}"
    echo "   Recommended: Option 1 (pipx) or Option 2 (venv)"
    DEFAULT_CHOICE=1
else
    echo "   All options available"
    DEFAULT_CHOICE=4
fi

echo ""
read -p "Choose installation method [1-4] (default: $DEFAULT_CHOICE): " -n 1 -r CHOICE
echo ""
echo ""

if [ -z "$CHOICE" ]; then
    CHOICE=$DEFAULT_CHOICE
fi

case $CHOICE in
    1)
        echo -e "${BLUE}🔧 Installing with official installer (recommended)...${NC}"
        echo "===================================================="
        
        # Use the official Goose installation script (download_cli.sh)
        echo "Downloading and running official Goose installer..."
        curl -fsSL https://github.com/block/goose/releases/latest/download/download_cli.sh | bash
        
        if [ $? -eq 0 ]; then
            # Add to PATH if needed
            if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
                export PATH="$HOME/.local/bin:$PATH"
            fi
            
            echo -e "${GREEN}✅ Goose AI installed via official installer${NC}"
        else
            echo -e "${RED}❌ Official installer failed${NC}"
            echo "Trying direct binary download..."
            
            # Fallback: direct binary download for x86_64 Linux
            echo "Downloading Goose binary for x86_64 Linux..."
            BINARY_URL="https://github.com/block/goose/releases/latest/download/goose-x86_64-unknown-linux-gnu.tar.bz2"
            
            mkdir -p ~/.local/bin
            cd /tmp
            curl -L "$BINARY_URL" -o goose.tar.bz2
            
            if [ $? -eq 0 ]; then
                tar -xf goose.tar.bz2
                cp goose ~/.local/bin/goose
                chmod +x ~/.local/bin/goose
                rm -f goose.tar.bz2 goose
                cd - > /dev/null
                
                echo -e "${GREEN}✅ Goose AI installed via direct binary download${NC}"
            else
                echo -e "${RED}❌ All installation methods failed${NC}"
                exit 1
            fi
        fi
        ;;
        
    2)
        echo -e "${BLUE}🔧 Installing with virtual environment...${NC}"
        echo "========================================="
        
        VENV_PATH="$HOME/.goose-venv"
        
        # Create virtual environment
        echo "Creating virtual environment at $VENV_PATH..."
        python3 -m venv "$VENV_PATH"
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to create virtual environment${NC}"
            exit 1
        fi
        
        # Activate and install
        echo "Installing goose-ai in virtual environment..."
        source "$VENV_PATH/bin/activate"
        pip install --upgrade pip
        pip install goose-ai
        
        if [ $? -eq 0 ]; then
            # Create wrapper script
            cat > "$HOME/.local/bin/goose" << EOF
#!/bin/bash
source "$VENV_PATH/bin/activate"
exec "$VENV_PATH/bin/goose" "\$@"
EOF
            chmod +x "$HOME/.local/bin/goose"
            
            # Ensure .local/bin is in PATH
            if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
                export PATH="$HOME/.local/bin:$PATH"
            fi
            
            echo -e "${GREEN}✅ Goose AI installed in virtual environment${NC}"
            echo "   Wrapper script created at ~/.local/bin/goose"
        else
            echo -e "${RED}❌ Virtual environment installation failed${NC}"
            exit 1
        fi
        ;;
        
    3)
        echo -e "${BLUE}🔧 Installing Debian package...${NC}"
        echo "==============================="
        
        # Download and install the official .deb package
        echo "Downloading official Goose .deb package..."
        DEB_URL="https://github.com/block/goose/releases/latest/download/goose_1.29.1_amd64.deb"
        
        cd /tmp
        curl -L "$DEB_URL" -o goose.deb
        
        if [ $? -eq 0 ]; then
            echo "Installing Goose package..."
            sudo dpkg -i goose.deb
            
            # Fix any dependency issues
            sudo apt-get install -f
            
            echo -e "${GREEN}✅ Goose AI installed via Debian package${NC}"
        else
            echo -e "${RED}❌ Failed to download Debian package${NC}"
            echo "   Fallback to official installer..."
            # Fallback to method 1
            curl -fsSL https://github.com/block/goose/releases/latest/download/download_cli.sh | bash
        fi
        
        cd - > /dev/null
        ;;
        
    4)
        echo -e "${BLUE}🔧 Installing with pip --user...${NC}"
        echo "================================"
        
        if [ "$EXTERNALLY_MANAGED" = true ]; then
            echo -e "${YELLOW}⚠️  This may not work on externally managed environments${NC}"
            echo ""
            read -p "Continue anyway? [y/N]: " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Installation cancelled."
                exit 0
            fi
            
            # Try with --break-system-packages flag
            echo "Attempting installation with --break-system-packages..."
            python3 -m pip install --user --break-system-packages goose-ai
        else
            python3 -m pip install --user goose-ai
        fi
        
        if [ $? -eq 0 ]; then
            # Ensure .local/bin is in PATH
            if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
                export PATH="$HOME/.local/bin:$PATH"
            fi
            
            echo -e "${GREEN}✅ Goose AI installed with pip --user${NC}"
        else
            echo -e "${RED}❌ pip --user installation failed${NC}"
            echo "Try method 1 (pipx) or 2 (venv) instead"
            exit 1
        fi
        ;;
        
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

echo ""

# Verify installation
echo -e "${BLUE}🔍 Verifying installation...${NC}"
echo "============================"

# Refresh PATH for current session
export PATH="$HOME/.local/bin:$PATH"

if command -v goose &> /dev/null; then
    GOOSE_VERSION=$(goose --version 2>/dev/null | tr -d ' ' || echo "unknown")
    GOOSE_PATH=$(which goose)
    
    echo -e "${GREEN}✅ Installation successful!${NC}"
    echo "   Version: $GOOSE_VERSION"
    echo "   Location: $GOOSE_PATH"
    echo ""
    
    # Test basic functionality
    echo "Testing basic functionality..."
    if goose --help &> /dev/null; then
        echo -e "${GREEN}✅ Goose AI is working correctly${NC}"
    else
        echo -e "${YELLOW}⚠️  Goose AI may have issues${NC}"
    fi
    
else
    echo -e "${RED}❌ Installation verification failed${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Restart your terminal"
    echo "2. Check PATH: echo \$PATH"
    echo "3. Manual check: ls ~/.local/bin/goose"
    exit 1
fi

echo ""
echo "=================================================="
echo -e "${GREEN}🎉 GOOSE AI INSTALLATION COMPLETE!${NC}"
echo "=================================================="
echo ""
echo -e "${BLUE}🚀 Next Steps:${NC}"
echo "1. Restart your terminal (or run: source ~/.bashrc)"
echo "2. Test: goose --version"
echo "3. Run project setup: ./install-all-dependencies.sh"
echo "4. Configure cloud models: ./configure-cloud-models.sh"
echo ""