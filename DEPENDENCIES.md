# MiniMax Skills - Complete Dependency List

## Overview
This document lists all dependencies required for the complete MiniMax skills suite integrated with Goose AI.

## System Dependencies

### Required
- **FFmpeg** - Audio/video processing (used by multiple skills)
  - Install: `brew install ffmpeg` (macOS) / `apt install ffmpeg` (Linux)
- **Python 3.8+** - Runtime for Python-based skills
- **Node.js 18+** - For frontend tools and PowerPoint generation

### Optional but Recommended
- **jq** - JSON processing for multimodal toolkit
  - Install: `brew install jq` (macOS) / `apt install jq` (Linux)
- **ImageMagick** - Advanced image processing
  - Install: `brew install imagemagick` (macOS) / `apt install imagemagick` (Linux)
- **curl** - HTTP client (usually pre-installed)
- **xxd** - Hex dump utility (usually pre-installed)

## Python Dependencies

### Core Libraries (Already Installed ✅)
```
pandas          - Data manipulation
numpy           - Numerical computing  
pillow          - Image processing
pypdf           - PDF processing
python-docx     - Word document processing
openpyxl        - Excel processing
matplotlib      - Data visualization
requests        - HTTP requests
markitdown[pptx] - PowerPoint text extraction
python-pptx     - PowerPoint manipulation
```

### Additional Recommended
```
opencv-python   - Computer vision
scikit-image    - Image processing algorithms
beautifulsoup4  - HTML/XML parsing
lxml           - XML processing
moviepy        - Video editing
pydub          - Audio processing
librosa        - Audio analysis
python-dotenv  - Environment variable management
pyyaml         - YAML parsing
rich           - Terminal formatting
```

## Node.js Dependencies

### Required for PowerPoint Generation
```
pptxgenjs      - PowerPoint creation (installed ✅)
```

### Optional for Frontend Development
```
react          - UI framework
react-dom      - React DOM renderer
react-icons    - Icon library
sharp          - Image processing
```

## Skill-Specific Requirements

### 1. Frontend Development (`frontend-dev`)
- **Dependencies**: Python requests, FFmpeg
- **API**: MiniMax API key for asset generation
- **Purpose**: Generate images, videos, music, TTS

### 2. Full-stack Development (`fullstack-dev`)
- **Dependencies**: None additional
- **Purpose**: Code generation and architecture

### 3. GIF/Sticker Maker (`gif-sticker-maker`)
- **Dependencies**: FFmpeg, Python requests
- **Purpose**: Create animated GIFs and stickers

### 4. Vision Analysis (`vision-analysis`)
- **Dependencies**: MiniMax Token Plan subscription
- **Setup**: Requires MCP configuration
- **Purpose**: Analyze and describe images

### 5. Multimodal Toolkit (`minimax-multimodal-toolkit`)
- **Dependencies**: FFmpeg, jq, curl, xxd (bash only)
- **API**: MiniMax API key
- **Purpose**: TTS, music, video, image generation

### 6. Document Processing Suite
- **PDF** (`minimax-pdf`): pypdf, python-pptx
- **Excel** (`minimax-xlsx`): openpyxl, pandas
- **Word** (`minimax-docx`): python-docx
- **PowerPoint** (`pptx-generator`): pptxgenjs, markitdown

### 7. Mobile Development
- **Android** (`android-native-dev`): Documentation only
- **iOS** (`ios-application-dev`): Documentation only
- **Flutter** (`flutter-dev`): Documentation only
- **React Native** (`react-native-dev`): Documentation only

### 8. Shader Development (`shader-dev`)
- **Dependencies**: None (browser-based WebGL)
- **Purpose**: GLSL shader creation

## API Keys Required

### MiniMax API
Required for most AI-powered features:
- **China**: https://platform.minimaxi.com
- **Global**: https://platform.minimax.io

Set in environment:
```bash
export MINIMAX_API_KEY="your-key-here"
export MINIMAX_API_HOST="https://api.minimaxi.com"  # or .io for global
```

## Installation Commands

### Quick Install (All Dependencies)
```bash
# Run the comprehensive installation script
./install-all-dependencies.sh
```

### Manual Installation

#### System packages
```bash
# macOS
brew install ffmpeg jq imagemagick

# Linux (Ubuntu/Debian)
sudo apt update
sudo apt install -y ffmpeg jq imagemagick
```

#### Python packages (in virtual environment)
```bash
source venv/bin/activate
pip install -r requirements.txt
pip install opencv-python scikit-image moviepy pydub librosa
```

#### Node.js packages
```bash
npm install pptxgenjs
```

## Verification

Run the test script to verify all dependencies:
```bash
source venv/bin/activate
python test_skills.py
```

## Troubleshooting

### Common Issues

1. **"externally-managed-environment" error**
   - Solution: Use virtual environment (`source venv/bin/activate`)

2. **FFmpeg not found**
   - Solution: Install FFmpeg for your OS

3. **MiniMax API errors**
   - Check API key is set correctly
   - Verify API endpoint (`.com` for China, `.io` for global)

4. **Node.js packages fail**
   - Ensure Node.js 18+ is installed
   - Try local installation instead of global

### Support

For skill-specific issues, check:
- Individual skill documentation in `minimax-skills/skills/[skill-name]/`
- MiniMax platform documentation
- Goose AI documentation