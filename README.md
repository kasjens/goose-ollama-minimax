# Goose AI with Local Ollama MiniMax and Skills

This project sets up Goose AI to work with a local Ollama instance accessing cloud models, integrated with MiniMax and Anthropic skills repositories.

✅ **Setup Complete!** Goose is now configured to use cloud models through local Ollama (no GPU/RAM requirements).

## Prerequisites

- **Ollama** installed and signed in (`ollama signin`)
- **Python 3.8+** for skill dependencies  
- **Internet connection** for cloud model access
- **Goose AI** will be installed automatically by setup scripts

## Project Structure

```
goose-ollama-minimax/
├── .goose/
│   └── config.yaml         # Main Goose configuration
├── minimax-skills/         # Cloned MiniMax skills repository
│   └── skills/            # Available skills
├── profiles.yaml          # Goose profile configuration
├── toolkits.yaml         # Custom toolkit definitions
├── setup.sh              # Setup script
├── run-goose.sh          # Launch script
└── README.md             # This file
```

## Available Skills

### MiniMax Skills (14 skills)
- **frontend-dev**: Frontend development with AI asset generation
- **fullstack-dev**: Full-stack development capabilities
- **minimax-pdf**: PDF processing and manipulation
- **minimax-xlsx**: Excel file operations
- **minimax-docx**: Word document processing
- **vision-analysis**: Image and vision analysis
- **minimax-multimodal-toolkit**: Multimodal content (audio/video/image)
- **gif-sticker-maker**: Animated GIF creation
- **pptx-generator**: PowerPoint generation
- **shader-dev**: GLSL shader development
- Plus mobile development skills (iOS, Android, Flutter, React Native)

### Anthropic Skills (18 skills)
- **claude-api**: Build apps with Claude API/SDK
- **pdf/docx/pptx/xlsx**: Production-ready document processing
- **mcp-builder**: Create MCP servers
- **webapp-testing**: Web application testing
- **algorithmic-art**: Generate algorithmic art
- **frontend-design**: Design frontend interfaces
- **skill-creator**: Create new AI skills
- Plus creative, communication, and branding skills

### Web Search
- **Brave Search**: Integrated web search capability (2000 queries/month free)

## Quick Start

### New Installation
1. **Install Goose AI** (Ubuntu 25.10+ with PEP 668)
   ```bash
   ./install-goose-ai.sh          # Handles modern Python environments
   ```

2. **Complete Setup** (Installs everything)
   ```bash
   ./install-all-dependencies.sh  # Full installation with all packages
   ```

3. **Configure Web Search** (Optional)
   ```bash
   ./setup-brave-search.sh       # Setup Brave Search API
   ```

4. **Validate Setup**
   ```bash
   ./validate-setup.sh           # Comprehensive validation
   ```

### Existing Installation (If Goose AI already installed)
1. **Basic Setup**
   ```bash
   ./setup.sh                    # Uses requirements.txt
   ```

2. **Configure Latest Cloud Models** (New!)
   ```bash
   ./configure-cloud-models.sh  # Setup 2025 cloud models (DeepSeek, Qwen, GPT-OSS)
   ```

3. **Run Goose with Cloud Models**
   ```bash
   ./run-goose.sh               # Auto-detect installation + current model
   ./run-goose-local.sh         # Force user-local Goose AI (recommended)  
   ./run-goose-system.sh        # Force system-wide installation
   ./switch-model.sh            # Interactive model switcher
   ```

4. **Manage All Skills**
   ```bash
   ./goose-skills.sh            # Interactive skills manager
   ```
   
   Or directly:
   ```bash
   python3 integrate-anthropic-skills.py list  # List Anthropic skills
   python3 integrate-skills.py list            # List MiniMax skills
   python3 test-enhanced-skills.py             # Test all 30 packages
   ```

## Configuration

### Ollama Settings
- **Default Model**: `minimax-m2.7:cloud` 
- **Available Models**: 15+ cloud models (DeepSeek V3.2, Qwen3-Coder 480B, GPT-OSS 120B, etc.)
- **Base URL**: `http://localhost:11434`
- **Provider**: `ollama`
- **Cloud Integration**: Latest 2025 models via Ollama cloud

### Modifying Skills
Edit `.goose/config.yaml` to enable/disable specific skills:
```yaml
enabled_skills:
  - frontend-dev
  - fullstack-dev
  # Add or remove skills as needed
```

## Troubleshooting

### Multiple Goose Installations
This setup supports both user-local and system-wide Goose installations:

**User-Local Goose AI** (Recommended):
- Location: `/home/kasjens/.local/bin/goose`
- Type: Goose AI CLI (supports Ollama)
- Use: `./run-goose-local.sh`

**System-Wide Installation**:
- Location: `/usr/bin/goose`
- Type: May be GUI app or different version
- Use: `./run-goose-system.sh`

**Auto-Detection**:
- Use: `./run-goose.sh` (automatically chooses best)

### Ollama Not Running
If you see "Ollama is not running", ensure Ollama service is started:
```bash
ollama serve
```

### Model Not Found
If MiniMax model is not available:
```bash
ollama pull minimax-m2.7:cloud
```

### Port Conflicts
If port 11434 is in use, update the base_url in `.goose/config.yaml`

## 🚀 Advanced Setup & Optimization

For production use and maximum performance:

1. **Validate Complete Setup**
   ```bash
   ./validate-setup.sh  # Comprehensive validation
   ```

2. **Apply Performance Optimizations**
   ```bash
   ./optimize-setup.sh  # GPU, memory, and performance tuning
   ```

3. **Monitor System Health**
   ```bash
   ./health-check.sh           # Quick health check
   ./monitor-performance.sh    # Real-time performance monitoring
   ```

## 📖 Documentation

- **[BEST-PRACTICES.md](BEST-PRACTICES.md)** - Enterprise-grade setup guide
- **[DEPENDENCIES.md](DEPENDENCIES.md)** - Complete dependency documentation  
- **[WEB-SEARCH-GUIDE.md](WEB-SEARCH-GUIDE.md)** - Web search integration
- **[COMPLETE-SKILLS-GUIDE.md](COMPLETE-SKILLS-GUIDE.md)** - All skills reference

## Usage Examples

Your enhanced Goose can now handle:
- **Web Search**: "Search for latest React best practices"
- **Document Processing**: "Create a PowerPoint about AI trends"
- **Frontend Development**: "Build a landing page with animations"
- **API Integration**: "Use the Claude API to create a chatbot"
- **Computer Vision**: "Analyze this image and detect objects"
- **Deep Learning**: "Train a PyTorch model for image classification"
- **Web Apps**: "Create a Streamlit dashboard for this data"
- **Audio Processing**: "Analyze this audio file and extract features"
- **Video Editing**: "Extract key frames from this video"
- **Mobile Development**: "Help me create a Flutter app"

**30 Python packages** installed including PyTorch, OpenCV, Streamlit, Gradio, and more!

## 🔧 Maintenance Commands

```bash
# Health & Performance
./validate-setup.sh           # Full system validation (supports both installations)
./health-check.sh             # Quick status check
./monitor-performance.sh      # Performance monitoring

# Goose Installation & Model Management
./run-goose.sh                # Auto-detect installation + show current model
./run-goose-local.sh          # Force user-local Goose AI
./run-goose-system.sh         # Force system-wide installation
./configure-cloud-models.sh   # Setup latest 2025 cloud models
./switch-model.sh             # Interactive model switcher

# Skills Management  
./goose-skills.sh             # Interactive skills manager
python3 integrate-anthropic-skills.py list
python3 integrate-skills.py list

# Optimization
./optimize-setup.sh           # Apply performance optimizations
source ollama-env.sh          # Load environment optimizations
```

## System Architecture

```
🪿 Goose AI Agent
├── 🧠 Local LLM (Ollama + MiniMax)
├── 🔍 Web Search (Brave Search API)
├── 📚 Skills Engine
│   ├── 18 Anthropic Skills (Claude-native)
│   └── 14 MiniMax Skills (Multimodal AI)
├── 🔧 MCP Extensions
├── 🐍 Python Environment (10+ packages)
└── 📦 Node.js Tools (PowerPoint, etc.)
```

This setup provides a complete, enterprise-ready local AI development environment.