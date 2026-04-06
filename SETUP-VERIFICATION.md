# 🔍 Complete Setup Verification Guide

This document outlines the complete end-to-end setup verification process to ensure reproducibility on fresh installations.

## 📋 Prerequisites Checklist

### Required Software
- [ ] **Ollama**: Latest version installed and running
- [ ] **Python 3.8+**: With pip and venv support
- [ ] **Node.js 16+**: For PowerPoint generation and MCP servers
- [ ] **Git**: For cloning repositories
- [ ] **Internet Connection**: For cloud model access

### System Requirements
- [ ] **RAM**: 8GB minimum, 16GB+ recommended
- [ ] **Storage**: 10GB+ free space
- [ ] **OS**: Linux/macOS/Windows (tested on Ubuntu 24.04)

## 🚀 Fresh Installation Process

### Step 1: Initial Setup
```bash
# 1. Clone repository
git clone https://github.com/kasjens/goose-ollama-minimax.git
cd goose-ollama-minimax

# 2. Install Goose AI (user-local recommended)
pip install goose-ai

# 3. Sign in to Ollama for cloud access
ollama signin
```

### Step 2: Dependencies Installation
```bash
# Complete dependency installation
./install-all-dependencies.sh

# Choose option 1 (Essential) for most users
# This installs all 30 Python packages including PyTorch
```

### Step 3: Configure Cloud Models
```bash
# Set up latest 2025 cloud models
./configure-cloud-models.sh

# Choose option 1 (Essential) for recommended models:
# - minimax-m2.7:cloud (default)
# - deepseek-v3.2:cloud
# - qwen3-coder:480b-cloud
# - gpt-oss:120b-cloud
# - glm-5:cloud
```

### Step 4: Configure Web Search (Optional)
```bash
# Set up Brave Search integration
./setup-brave-search.sh

# You'll need a free Brave Search API key
# Get it from: https://brave.com/search/api/
```

### Step 5: Validation
```bash
# Run comprehensive validation
./validate-setup.sh

# Should show 90%+ score with minimal errors
```

## 🧪 Testing & Verification

### Test All Components
```bash
# Test Python dependencies
python3 test-enhanced-skills.py

# Test skills integration
./goose-skills.sh

# Test Goose with cloud models
./run-goose.sh
```

### Expected Results
- **Dependencies**: 30/30 Python packages installed
- **Cloud Models**: 5+ models available
- **Validation Score**: 90%+ (55+ checks passing)
- **Skills**: 32 total (18 Anthropic + 14 MiniMax)

## 📊 Verification Benchmarks

### Performance Indicators
| Metric | Target | Command |
|--------|--------|---------|
| Dependency Success Rate | 100% | `python3 test-enhanced-skills.py` |
| Validation Score | >90% | `./validate-setup.sh` |
| Cloud Models Available | 5+ | `ollama list \| grep :cloud` |
| Skills Available | 32 | `./goose-skills.sh list` |
| Response Time | <30s | Model test in validation |

### Common Issues & Solutions

#### Issue: Cloud Models Not Available
```bash
# Solution: Ensure signed in to Ollama
ollama signin
./configure-cloud-models.sh
```

#### Issue: Dependencies Failed
```bash
# Solution: Check Python version and venv
python3 --version  # Should be 3.8+
./install-all-dependencies.sh
```

#### Issue: Web Search Not Working
```bash
# Solution: Check API key configuration
./setup-brave-search.sh
```

## 🎯 Success Criteria

A successful installation should achieve:

✅ **Core Functionality**
- Goose AI responds to prompts
- Cloud models accessible (minimax-m2.7:cloud works)
- Skills integration functional

✅ **Advanced Features**
- Web search capability (if configured)
- Document processing (PDF, DOCX, PPTX, XLSX)
- Computer vision and AI/ML libraries

✅ **Development Environment**
- PyTorch for deep learning
- OpenCV for computer vision
- Streamlit/Gradio for web apps
- FastAPI for backend development

## 📝 Reproducibility Checklist

Before publishing repository:

- [ ] All sensitive data removed (API keys)
- [ ] `.gitignore` includes all necessary exclusions
- [ ] Example configuration files provided (`.env.example`)
- [ ] Installation scripts tested on fresh system
- [ ] Documentation complete and accurate
- [ ] Version requirements specified
- [ ] Error handling implemented in scripts

## 🔧 Troubleshooting Reference

### Quick Fixes
```bash
# Reset configuration
rm -rf ~/.config/goose/config.yaml
./configure-cloud-models.sh

# Reinstall dependencies
rm -rf venv node_modules
./install-all-dependencies.sh

# Check system status
./validate-setup.sh
```

### Support Commands
```bash
# System information
./validate-setup.sh              # Complete system check
ollama list                      # Available models
which goose                      # Goose installation path
python3 -m pip list | grep -E "(pandas|torch|opencv)"  # Key packages
```

---

**Result**: This verification process ensures 100% reproducible setup on fresh installations with enterprise-grade reliability.