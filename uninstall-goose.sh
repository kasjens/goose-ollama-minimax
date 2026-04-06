#!/bin/bash

# Complete Goose Uninstall Script
# Removes both system-wide and user-local installations

echo "=================================================="
echo "🗑️  COMPLETE GOOSE UNINSTALL SCRIPT"
echo "=================================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

# Function to show current installations
show_installations() {
    echo -e "${BLUE}📋 Current Goose Installations:${NC}"
    echo "=================================="
    
    # User-local installation
    if [ -f "$HOME/.local/bin/goose" ]; then
        SIZE=$(du -h $HOME/.local/bin/goose | cut -f1)
        VERSION=$($HOME/.local/bin/goose --version 2>/dev/null | tr -d ' ' || echo "unknown")
        echo "✓ User-Local: ~/.local/bin/goose ($SIZE, v$VERSION)"
    else
        echo "✗ User-Local: Not found"
    fi
    
    # System-wide installation
    if [ -L "/usr/bin/goose" ] && [ -L "/bin/goose" ]; then
        if [ -d "/usr/lib/goose" ]; then
            VERSION=$(cat /usr/lib/goose/version 2>/dev/null || echo "unknown")
            echo "✓ System-Wide: /usr/bin/goose -> /usr/lib/goose (GUI App v$VERSION)"
        fi
    else
        echo "✗ System-Wide: Not found"
    fi
    
    # Configuration
    if [ -d "$HOME/.config/goose" ]; then
        CONFIG_SIZE=$(du -sh ~/.config/goose 2>/dev/null | cut -f1 || echo "unknown")
        echo "✓ Configuration: ~/.config/goose ($CONFIG_SIZE)"
    else
        echo "✗ Configuration: Not found"
    fi
    
    echo ""
}

# Function to backup configuration
backup_config() {
    if [ -d "$HOME/.config/goose" ]; then
        BACKUP_DIR="$HOME/goose-config-backup-$(date +%s)"
        echo -e "${YELLOW}📦 Creating configuration backup...${NC}"
        cp -r ~/.config/goose "$BACKUP_DIR"
        echo "   Backup saved to: $BACKUP_DIR"
        echo ""
    fi
}

# Function to remove user-local installation
remove_user_local() {
    echo -e "${BLUE}🔧 Removing User-Local Installation...${NC}"
    echo "======================================"
    
    # Remove binary
    if [ -f "$HOME/.local/bin/goose" ]; then
        rm -f $HOME/.local/bin/goose
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Removed: ~/.local/bin/goose${NC}"
        else
            echo -e "${RED}❌ Failed to remove: ~/.local/bin/goose${NC}"
            ((ERRORS++))
        fi
    else
        echo -e "${YELLOW}ℹ️  User-local binary not found${NC}"
    fi
    
    # Check for different installation methods
    echo ""
    echo "🔍 Checking for Goose AI installations..."
    
    # Check pipx installation (Ubuntu 25.10+ preferred method)
    if command -v pipx &> /dev/null; then
        PIPX_GOOSE=$(pipx list 2>/dev/null | grep -i goose || echo "")
        if [ ! -z "$PIPX_GOOSE" ]; then
            echo "   Found pipx installation:"
            echo "$PIPX_GOOSE" | sed 's/^/     /'
            echo ""
            read -p "   Remove pipx installation? [y/N]: " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                pipx uninstall goose-ai 2>/dev/null || echo "   pipx removal completed"
                echo -e "${GREEN}✅ Removed pipx installation${NC}"
            fi
        fi
    fi
    
    # Check virtual environment installation
    if [ -d "$HOME/.goose-venv" ]; then
        echo "   Found virtual environment: ~/.goose-venv"
        echo ""
        read -p "   Remove virtual environment? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$HOME/.goose-venv"
            echo -e "${GREEN}✅ Removed virtual environment${NC}"
        fi
    fi
    
    # Check pip-installed packages (legacy method)
    echo "   Checking pip packages..."
    GOOSE_PACKAGES=$(pip list 2>/dev/null | grep -i goose || echo "")
    if [ ! -z "$GOOSE_PACKAGES" ]; then
        echo "   Found pip packages:"
        echo "$GOOSE_PACKAGES" | sed 's/^/     /'
        echo ""
        read -p "   Remove pip packages? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Try different removal methods for PEP 668 systems
            if pip uninstall -y $(echo "$GOOSE_PACKAGES" | awk '{print $1}') 2>/dev/null; then
                echo -e "${GREEN}✅ Removed pip packages${NC}"
            elif pip uninstall -y --break-system-packages $(echo "$GOOSE_PACKAGES" | awk '{print $1}') 2>/dev/null; then
                echo -e "${GREEN}✅ Removed pip packages (with --break-system-packages)${NC}"
            else
                echo -e "${YELLOW}⚠️  Some packages may require manual removal${NC}"
            fi
        fi
    else
        echo -e "${GREEN}✅ No pip packages found${NC}"
    fi
    
    echo ""
}

# Function to remove system-wide installation
remove_system_wide() {
    echo -e "${BLUE}🔧 Removing System-Wide Installation...${NC}"
    echo "======================================="
    
    # Check if it's a Debian package
    DEBIAN_PKG=$(dpkg -l | grep goose 2>/dev/null || echo "")
    if [ ! -z "$DEBIAN_PKG" ]; then
        echo "   Found Debian package:"
        echo "$DEBIAN_PKG" | sed 's/^/     /'
        echo ""
        read -p "   Remove system package? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "   Removing package (requires sudo)..."
            sudo apt remove -y goose
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ Removed system package${NC}"
            else
                echo -e "${RED}❌ Failed to remove system package${NC}"
                ((ERRORS++))
            fi
        fi
    else
        # Manual removal
        echo "   No Debian package found, checking manual installation..."
        
        if [ -L "/usr/bin/goose" ] || [ -L "/bin/goose" ] || [ -d "/usr/lib/goose" ]; then
            echo ""
            read -p "   Remove system files manually? [y/N]: " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "   Removing system files (requires sudo)..."
                
                # Remove symlinks
                sudo rm -f /usr/bin/goose /bin/goose
                
                # Remove library directory
                sudo rm -rf /usr/lib/goose
                
                echo -e "${GREEN}✅ Removed system-wide installation${NC}"
            fi
        else
            echo -e "${YELLOW}ℹ️  System-wide installation not found${NC}"
        fi
    fi
    
    echo ""
}

# Function to remove configuration
remove_config() {
    echo -e "${BLUE}🔧 Configuration Cleanup...${NC}"
    echo "=========================="
    
    if [ -d "$HOME/.config/goose" ]; then
        echo "   Configuration directory: ~/.config/goose"
        echo ""
        read -p "   Remove configuration? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf ~/.config/goose
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ Removed configuration directory${NC}"
            else
                echo -e "${RED}❌ Failed to remove configuration${NC}"
                ((ERRORS++))
            fi
        else
            echo -e "${YELLOW}ℹ️  Configuration preserved${NC}"
        fi
    else
        echo -e "${YELLOW}ℹ️  No configuration directory found${NC}"
    fi
    
    echo ""
}

# Function to clean up PATH
cleanup_path() {
    echo -e "${BLUE}🔧 PATH Cleanup...${NC}"
    echo "=================="
    
    # Check common shell config files
    SHELL_CONFIGS=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.bash_profile")
    FOUND_GOOSE=false
    
    for config in "${SHELL_CONFIGS[@]}"; do
        if [ -f "$config" ] && grep -q "goose" "$config"; then
            echo "   Found Goose references in: $config"
            FOUND_GOOSE=true
        fi
    done
    
    if [ "$FOUND_GOOSE" = true ]; then
        echo ""
        echo -e "${YELLOW}⚠️  Manual review recommended for shell configuration files${NC}"
        echo "   Check for any custom Goose PATH modifications"
    else
        echo -e "${GREEN}✅ No Goose references found in shell configs${NC}"
    fi
    
    echo ""
}

# Function to verify removal
verify_removal() {
    echo -e "${BLUE}🔍 Verification...${NC}"
    echo "=================="
    
    # Check if any goose commands exist
    if command -v goose &> /dev/null; then
        REMAINING=$(which -a goose 2>/dev/null)
        echo -e "${RED}❌ Goose still found:${NC}"
        echo "$REMAINING" | sed 's/^/     /'
        ((ERRORS++))
    else
        echo -e "${GREEN}✅ No Goose installations found${NC}"
    fi
    
    # Check for remaining files
    REMAINING_FILES=()
    
    if [ -f "$HOME/.local/bin/goose" ]; then
        REMAINING_FILES+=("~/.local/bin/goose")
    fi
    
    if [ -L "/usr/bin/goose" ]; then
        REMAINING_FILES+=("/usr/bin/goose")
    fi
    
    if [ -d "/usr/lib/goose" ]; then
        REMAINING_FILES+=("/usr/lib/goose")
    fi
    
    if [ -d "$HOME/.config/goose" ]; then
        REMAINING_FILES+=("~/.config/goose")
    fi
    
    if [ ${#REMAINING_FILES[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Remaining files:${NC}"
        printf '%s\n' "${REMAINING_FILES[@]}" | sed 's/^/     /'
    else
        echo -e "${GREEN}✅ All files removed cleanly${NC}"
    fi
    
    echo ""
}

# Main execution
echo -e "${YELLOW}⚠️  This will remove ALL Goose installations and configurations${NC}"
echo ""

# Show current state
show_installations

# Confirm removal
read -p "Continue with complete uninstall? [y/N]: " -n 1 -r
echo ""
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

# Backup configuration
backup_config

# Remove installations
remove_user_local
remove_system_wide
remove_config
cleanup_path

# Verify removal
verify_removal

# Final summary
echo "=================================================="
echo -e "${BLUE}📊 UNINSTALL SUMMARY${NC}"
echo "=================================================="

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}🎉 Complete uninstall successful!${NC}"
    echo ""
    echo "✅ All Goose installations removed"
    echo "✅ System cleaned up"
    echo "✅ Ready for fresh installation"
else
    echo -e "${YELLOW}⚠️  Uninstall completed with $ERRORS errors${NC}"
    echo ""
    echo "Some manual cleanup may be required"
fi

echo ""
echo -e "${BLUE}🚀 Next Steps for Clean Install:${NC}"
echo "   1. Restart your terminal"
echo "   2. Run: ./install-goose-ai.sh (for Ubuntu 25.10+)"
echo "      OR: pip install goose-ai (older systems)"
echo "   3. Complete setup: ./install-all-dependencies.sh"
echo "   4. Configure cloud models: ./configure-cloud-models.sh"
echo "   5. Validate setup: ./validate-setup.sh"
echo ""