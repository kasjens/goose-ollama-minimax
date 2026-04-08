#!/bin/bash

# Goose Desktop UI Installation Script
# Installs the official Goose Desktop application alongside CLI

echo "=================================================="
echo "🖥️  GOOSE DESKTOP UI INSTALLER"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if already installed
if [ -f "/usr/lib/goose/Goose" ]; then
    echo -e "${GREEN}✅ Goose Desktop UI already installed${NC}"
    echo "   Location: /usr/lib/goose/Goose"
    echo ""
    read -p "Reinstall/Update? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
fi

echo -e "${BLUE}📦 Installing Goose Desktop UI...${NC}"
echo "=================================="

# Download latest .deb package if not exists
DEB_FILE="/tmp/goose-desktop.deb"
if [ ! -f "$DEB_FILE" ]; then
    echo "Downloading Goose Desktop UI package..."
    # Get the actual download URL for the latest release
    DOWNLOAD_URL=$(curl -sL https://api.github.com/repos/block/goose/releases/latest | grep -E '"browser_download_url".*\.deb"' | cut -d'"' -f4)
    
    if [ -z "$DOWNLOAD_URL" ]; then
        echo -e "${RED}❌ Could not find download URL for latest release${NC}"
        exit 1
    fi
    
    echo "Downloading from: $DOWNLOAD_URL"
    curl -L "$DOWNLOAD_URL" -o "$DEB_FILE"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to download Goose Desktop package${NC}"
        exit 1
    fi
else
    echo "Using existing package: $DEB_FILE"
fi

# Verify package size
FILE_SIZE=$(stat -f%z "$DEB_FILE" 2>/dev/null || stat -c%s "$DEB_FILE" 2>/dev/null || echo "0")
if [ "$FILE_SIZE" -lt 100000000 ]; then  # Less than 100MB indicates incomplete download
    echo -e "${YELLOW}⚠️  Package seems incomplete, re-downloading...${NC}"
    rm -f "$DEB_FILE"
    # Get the actual download URL for the latest release
    DOWNLOAD_URL=$(curl -sL https://api.github.com/repos/block/goose/releases/latest | grep -E '"browser_download_url".*\.deb"' | cut -d'"' -f4)
    curl -L "$DOWNLOAD_URL" -o "$DEB_FILE"
fi

echo ""
echo "Package size: $(du -h "$DEB_FILE" | cut -f1)"
echo ""

# Install the package
echo "Installing Goose Desktop UI (requires sudo)..."
echo "This will install:"
echo "  • Desktop application at /usr/lib/goose/"
echo "  • Application launcher in Applications menu"
echo "  • Desktop integration"
echo ""

if sudo dpkg -i "$DEB_FILE"; then
    echo -e "${GREEN}✅ Goose Desktop UI installed successfully${NC}"
    
    # Fix any dependency issues
    echo "Fixing dependencies..."
    sudo apt-get install -f -y
    
else
    echo -e "${RED}❌ Installation failed${NC}"
    echo "Trying to fix dependencies and retry..."
    sudo apt-get install -f -y
    sudo dpkg -i "$DEB_FILE"
fi

echo ""

# Verify installation
echo -e "${BLUE}🔍 Verifying installation...${NC}"
echo "============================="

if [ -f "/usr/lib/goose/Goose" ]; then
    echo -e "${GREEN}✅ Desktop binary: /usr/lib/goose/Goose${NC}"
else
    echo -e "${RED}❌ Desktop binary not found${NC}"
fi

if [ -f "/usr/share/applications/goose.desktop" ]; then
    echo -e "${GREEN}✅ Desktop entry: /usr/share/applications/goose.desktop${NC}"

    # Set working directory to project root so Desktop UI discovers .agents/skills/
    PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
    if ! grep -q "^Path=" /usr/share/applications/goose.desktop; then
        sudo sed -i "/^Exec=/a Path=$PROJECT_DIR" /usr/share/applications/goose.desktop
        echo -e "${GREEN}✅ Desktop entry configured to use project directory${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Desktop entry not found${NC}"
fi

if [ -L "/usr/bin/goose" ]; then
    echo -e "${GREEN}✅ System command: /usr/bin/goose${NC}"
else
    echo -e "${YELLOW}⚠️  System command not found${NC}"
fi

echo ""

# Clean up
echo "Cleaning up..."
rm -f "$DEB_FILE"

echo ""
echo "=================================================="
echo -e "${GREEN}🎉 GOOSE DESKTOP UI INSTALLATION COMPLETE!${NC}"
echo "=================================================="
echo ""
echo -e "${BLUE}🚀 How to Use:${NC}"
echo ""
echo "1. **Launch from Applications Menu:**"
echo "   • Look for 'Goose' in your Applications"
echo "   • Click to open the desktop UI"
echo ""
echo "2. **Launch from Command Line:**"
echo "   • Desktop UI: ./run-goose-ui.sh"
echo "   • CLI version: ./run-goose.sh"
echo ""
echo "3. **Both versions share the same configuration:**"
echo "   • Configuration: ~/.config/goose/config.yaml"
echo "   • Sessions: ~/.local/share/goose/"
echo "   • Same cloud models and skills"
echo ""
echo -e "${YELLOW}📝 Note:${NC}"
echo "• Desktop UI and CLI are fully compatible"
echo "• You can switch between them seamlessly"
echo "• Both use your Ollama cloud models"
echo "• All 32 skills available in both interfaces"
echo ""