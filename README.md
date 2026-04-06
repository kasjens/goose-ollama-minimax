# Goose AI with Local Ollama MiniMax and Skills

This project sets up Goose AI to work with a local Ollama instance accessing cloud models, integrated with MiniMax and Anthropic skills repositories.

✅ **Setup Complete!** Goose is now configured to use cloud models through local Ollama (no GPU/RAM requirements).

## Prerequisites

- **Ollama** installed and signed in (`ollama signin`)
- **Python 3.8+** for skill dependencies  
- **Internet connection** for cloud model access
- **Goose AI** (CLI + Desktop UI) will be installed automatically

## Project Structure

```
goose-ollama-minimax/
├── .agents/
│   └── skills/            # 31 integrated skills (auto-discovered)
├── anthropic-skills/      # Original Anthropic skills repository  
├── minimax-skills/        # Original MiniMax skills repository
├── brave-search-mcp/      # Web search integration
├── slides/               # PowerPoint generation workspace
├── setup scripts/        # Installation and configuration
├── run-goose.sh          # CLI launcher
├── run-goose-ui.sh       # Desktop UI launcher
└── documentation files   # Comprehensive guides
```

## Available Skills

### 🎯 **31 Skills Available** (Auto-Discovered)

All skills are **automatically detected** by Goose based on your requests - no manual loading needed!

#### 📄 **Document Processing (8 skills)**
- **PowerPoint**: `pptx`, `pptx-generator` - Professional presentation creation
- **Word**: `docx`, `minimax-docx` - Document creation with TOC, formatting
- **Excel**: `xlsx`, `minimax-xlsx` - Spreadsheet operations and analysis  
- **PDF**: `pdf`, `minimax-pdf` - PDF processing and manipulation

#### 📱 **Mobile Development (4 skills)**
- **iOS**: `ios-application-dev` - Native iOS app development
- **Android**: `android-native-dev` - Native Android development
- **React Native**: `react-native-dev` - Cross-platform mobile apps
- **Flutter**: `flutter-dev` - Google's UI toolkit

#### 🎨 **Creative & Design (6 skills)**
- **Frontend Design**: `frontend-design`, `frontend-dev` - UI/UX with animations
- **Art Creation**: `algorithmic-art`, `canvas-design` - Generative and visual art
- **Media**: `gif-sticker-maker`, `slack-gif-creator` - Animated content
- **Branding**: `theme-factory`, `brand-guidelines` - Professional theming

#### 💻 **Development Tools (6 skills)**
- **APIs**: `claude-api` - Build with Claude API/Anthropic SDK
- **MCP Servers**: `mcp-builder` - Create Model Context Protocol servers
- **Testing**: `webapp-testing` - Playwright-based web app testing
- **Full-Stack**: `fullstack-dev` - Complete web development
- **Shaders**: `shader-dev` - GLSL shader development  
- **Skills**: `skill-creator` - Create and improve AI skills

#### 💼 **Communication & Business (4 skills)**
- **Documentation**: `doc-coauthoring` - Structured doc writing
- **Internal Comms**: `internal-comms` - Professional communication
- **Vision**: `vision-analysis` - Computer vision and image analysis
- **Multimedia**: `minimax-multimodal-toolkit` - Audio/video/image tools

#### 🌐 **Web Development (3 skills)**
- **Artifacts**: `web-artifacts-builder` - HTML/CSS/JS applications
- **Frontend**: Advanced UI with animations and AI-generated assets
- **Testing**: Comprehensive web application testing and validation

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

4. **Install Desktop UI** (Optional)
   ```bash
   ./install-goose-ui.sh         # Install Goose Desktop application
   ```

5. **Validate Setup**
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
   # Command Line Interface
   ./run-goose.sh               # Auto-detect installation + current model
   ./run-goose-local.sh         # Force user-local Goose AI (recommended)  
   ./run-goose-system.sh        # Force system-wide installation
   ./switch-model.sh            # Interactive model switcher
   
   # Desktop UI (if installed)
   ./run-goose-ui.sh            # Launch Goose Desktop application
   ```

4. **Check Skills Status**
   ```bash
   python3 integrate-skills.py list           # List all 31 integrated skills
   python3 test-enhanced-skills.py            # Test all 30 Python packages
   ./validate-setup.sh                        # Complete system validation
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