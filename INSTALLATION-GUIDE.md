# 🔧 Goose AI Installation Guide

This project supports multiple Goose AI installation methods. Here's how to identify and manage them:

## 📍 Current Installation Status

Your system has **2 Goose installations**:

### 1. User-Local Goose AI (Recommended)
- **Location**: `/home/kasjens/.local/bin/goose`
- **Type**: Goose AI CLI (supports Ollama integration)
- **Version**: 1.29.1
- **Size**: 248MB
- **Installation Method**: `pip install goose-ai`
- **Use Case**: AI agent with Ollama, skills, and extensions
- **Launcher**: `./run-goose-local.sh`

### 2. System-Wide Installation
- **Location**: `/usr/bin/goose` → `/usr/lib/goose/Goose`
- **Type**: Desktop GUI application
- **Version**: v41.0.0 (Debian package shows v1.29.1)
- **Size**: ~206MB + Chromium libraries
- **Installation Method**: Debian package manager
- **Use Case**: Different "Goose" application (not AI agent)
- **Launcher**: `./run-goose-system.sh`

## 🚀 Quick Start

### Option 1: Auto-Detection (Recommended)
```bash
./run-goose.sh              # Automatically uses best installation
```

### Option 2: Force Specific Installation
```bash
./run-goose-local.sh        # Force user-local Goose AI
./run-goose-system.sh       # Force system-wide installation
```

## 🔍 Installation Detection

Our scripts automatically detect and handle both installations:

1. **Priority Order**: User-local takes precedence over system-wide
2. **Validation**: Both installations are validated in `./validate-setup.sh`
3. **Version Display**: Each script shows which installation and version is being used

## ⚙️ Configuration

### User-Local Configuration
- **Config**: `~/.config/goose/config.yaml`
- **Skills**: Both MiniMax and Anthropic skills supported
- **Extensions**: Web search, MCP servers, etc.
- **Model**: minimax-m2.7:cloud via Ollama

### System-Wide Configuration
- **Config**: May use different configuration location
- **Compatibility**: May not support Ollama integration
- **Warning**: Scripts will warn if using GUI app for CLI tasks

## 🔧 Installation Management

### Install User-Local Goose AI
```bash
pip install goose-ai
```

### Remove User-Local Installation
```bash
pip uninstall goose-ai
rm -f ~/.local/bin/goose
```

### Check System-Wide Installation
```bash
dpkg -l | grep goose           # Check if installed via package manager
sudo apt remove goose          # Remove if needed
```

## 📊 Validation

Check all installations:
```bash
./validate-setup.sh            # Comprehensive validation
which -a goose                 # Show all installations in PATH
```

## 🎯 Recommendations

1. **Use User-Local** (recommended): Best compatibility with Ollama and skills
2. **Keep Both**: No conflicts - they serve different purposes  
3. **Auto-Detection**: Use `./run-goose.sh` for automatic selection
4. **Specific Use**: Use explicit scripts when you need specific version

## 🔒 Security Notes

- Both installations are properly validated
- API keys are protected in `.gitignore`
- No conflicts between installations
- Each has separate configuration space

---

**Result**: Your setup now fully supports both Goose installations with automatic detection and explicit control options.