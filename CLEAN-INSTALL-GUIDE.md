# 🧹 Clean Installation Guide

This guide helps you completely remove existing Goose installations and perform a fresh setup with this project.

## 🔍 Current Installation Analysis

You have **both types** of Goose installations:

### 1. User-Local Installation
- **Location**: `~/.local/bin/goose` 
- **Size**: ~248MB
- **Type**: Goose AI CLI (binary)
- **Version**: 1.29.1

### 2. System-Wide Installation  
- **Location**: `/usr/bin/goose` → `/usr/lib/goose/`
- **Type**: GUI Desktop App (Debian package)
- **Version**: v41.0.0 (package shows 1.29.1)
- **Installation**: Via `apt`/`dpkg`

### 3. Configuration
- **Location**: `~/.config/goose/`
- **Size**: ~28KB
- **Contains**: Current project configuration, MCP cache, etc.

## 🗑️ Complete Uninstall Process

### Step 1: Run Automated Uninstall
```bash
# From your project directory
./uninstall-goose.sh
```

**The script will:**
- ✅ Show current installations
- ✅ Create configuration backup 
- ✅ Remove user-local binary (`~/.local/bin/goose`)
- ✅ Remove system-wide package (`sudo apt remove goose`)
- ✅ Optionally remove configuration (`~/.config/goose/`)
- ✅ Clean up PATH references
- ✅ Verify complete removal

### Step 2: Manual Verification
After running the script, verify removal:

```bash
# Should return "command not found"
which goose
goose --version

# Check for remaining files
ls -la ~/.local/bin/goose          # Should not exist
ls -la /usr/bin/goose              # Should not exist  
ls -la /usr/lib/goose              # Should not exist
ls -la ~/.config/goose             # Should not exist (if removed)

# Check for pip packages
pip list | grep -i goose           # Should be empty
```

### Step 3: Terminal Restart
```bash
# Close and reopen terminal to refresh PATH
exit
# Open new terminal
```

## 🚀 Fresh Installation Process

### Step 1: Install Clean Goose AI

**For Ubuntu 25.10+ (Recommended):**
```bash
# Use the smart installer that handles PEP 668
./install-goose-ai.sh

# Choose option 1 (pipx) when prompted
# This creates an isolated installation
```

**For Older Systems:**
```bash
# Traditional pip installation
pip install goose-ai

# Verify installation
goose --version
which goose                        # Should show ~/.local/bin/goose
```

### Step 2: Set Up Project
```bash
# Clone project (if needed)
git clone https://github.com/kasjens/goose-ollama-minimax.git
cd goose-ollama-minimax

# Complete setup
./install-all-dependencies.sh     # Choose option 1 (Essential)

# Configure cloud models  
./configure-cloud-models.sh       # Choose option 1 (Essential)

# Validate setup
./validate-setup.sh               # Should get 100% score
```

### Step 3: Test Installation
```bash
# Test Goose with cloud models
./run-goose.sh

# Should show:
# - Current model: minimax-m2.7:cloud
# - Available cloud models list
# - 32 total skills available
```

## 🔧 Troubleshooting

### Issue: Script Permission Denied
```bash
chmod +x ./uninstall-goose.sh
./uninstall-goose.sh
```

### Issue: System Package Won't Remove
```bash
# Force remove system package
sudo apt purge goose
sudo apt autoremove

# Manual cleanup
sudo rm -f /usr/bin/goose /bin/goose
sudo rm -rf /usr/lib/goose
```

### Issue: User Binary Won't Delete
```bash
# Check installation method first
pipx list | grep goose             # Check pipx
ls -la ~/.goose-venv               # Check venv
ls -la ~/.local/bin/goose          # Check direct install

# Force remove based on method
pipx uninstall goose-ai            # For pipx
rm -rf ~/.goose-venv               # For venv
rm -f ~/.local/bin/goose           # For direct install

# Check for other locations
find ~ -name "goose" -type f 2>/dev/null
```

### Issue: Configuration Conflicts
```bash
# Completely clean configuration
rm -rf ~/.config/goose

# Or backup specific files
mv ~/.config/goose ~/.config/goose.old
```

## 📊 Verification Checklist

After clean installation:

- [ ] **Single installation**: `which goose` shows only one path
- [ ] **Correct version**: `goose --version` shows expected version
- [ ] **Method confirmed**: `pipx list | grep goose` (if using pipx)
- [ ] **Ollama access**: `ollama list` shows cloud models
- [ ] **Dependencies**: `python3 test-enhanced-skills.py` shows 30/30
- [ ] **Validation**: `./validate-setup.sh` shows 100% score
- [ ] **Functionality**: `./run-goose.sh` starts successfully

## 🎯 Benefits of Clean Install

### Removes Conflicts
- ✅ No confusion between GUI app and CLI tool
- ✅ No PATH conflicts or version mismatches
- ✅ No configuration interference

### Ensures Compatibility  
- ✅ Latest Goose AI with cloud model support
- ✅ Modern Python environment compatibility (PEP 668)
- ✅ Proper integration with this project
- ✅ Optimal performance and features

### Clean Environment
- ✅ No legacy configuration issues
- ✅ Fresh MCP server setup
- ✅ Accurate validation results

---

**Result**: A completely clean, optimized Goose AI installation that works with modern Ubuntu Python environments and is configured specifically for cloud models and this project's capabilities.