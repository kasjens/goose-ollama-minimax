# Complete Skills Guide for Goose

## Overview
Your Goose setup now has access to two powerful skill sets:
1. **Anthropic Skills** - Claude-native skills for documents, development, and creative tasks
2. **MiniMax Skills** - Specialized skills for multimodal AI and development

## Anthropic Skills (18 skills)

### Document Processing
- **pdf** - Extract, analyze, and create PDF documents
- **docx** - Create and edit Word documents  
- **pptx** - Generate PowerPoint presentations
- **xlsx** - Work with Excel spreadsheets

### Development & Technical
- **claude-api** - Build apps with Claude API/SDK
- **mcp-builder** - Create MCP servers
- **skill-creator** - Create new skills
- **webapp-testing** - Test web applications

### Creative & Design
- **algorithmic-art** - Generate algorithmic art
- **canvas-design** - Create canvas designs
- **frontend-design** - Design frontend interfaces
- **theme-factory** - Generate color themes
- **slack-gif-creator** - Create animated GIFs

### Communication
- **doc-coauthoring** - Collaborative document writing
- **internal-comms** - Internal communications
- **brand-guidelines** - Apply brand guidelines

### Web
- **web-artifacts-builder** - Build web artifacts

## MiniMax Skills (14 skills)

### Development
- **frontend-dev** - Full frontend development with asset generation
- **fullstack-dev** - Full-stack development
- **shader-dev** - GLSL shader development

### Mobile Development
- **android-native-dev** - Android app development
- **ios-application-dev** - iOS app development
- **flutter-dev** - Flutter development
- **react-native-dev** - React Native development

### Media & Creative
- **gif-sticker-maker** - Create GIFs and stickers
- **vision-analysis** - Analyze images with AI
- **minimax-multimodal-toolkit** - Generate audio, video, images

### Document Processing
- **minimax-pdf** - PDF processing
- **minimax-xlsx** - Excel processing
- **minimax-docx** - Word processing
- **pptx-generator** - PowerPoint generation

## Usage in Goose

### Method 1: Direct Reference
Simply mention the skill name in your request:
```
🪿 Use the claude-api skill to create a Python script that calls Claude
🪿 Apply the pdf skill to extract text from document.pdf
🪿 Use frontend-dev to create a landing page
```

### Method 2: Load Skill Context
```bash
# Load Anthropic skill
python3 integrate-anthropic-skills.py load claude-api

# Load MiniMax skill  
python3 integrate-skills.py prompt frontend-dev
```

### Method 3: Combined Usage
You can use multiple skills together:
```
🪿 Use the webapp-testing skill to test the site created with frontend-dev
🪿 Use pdf skill to extract data, then minimax-xlsx to create a spreadsheet
```

## Skill Selection Guide

### Choose Anthropic Skills When:
- Working with Claude API/SDK
- Creating MCP servers
- Need production-tested document tools
- Building web artifacts
- Testing web applications

### Choose MiniMax Skills When:
- Need AI-generated media (images, video, audio)
- Mobile app development
- Shader/graphics programming
- Multimodal AI features

### Overlapping Capabilities
Both skill sets offer document processing. Generally:
- **Anthropic** (pdf, docx, pptx, xlsx) - More mature, production-tested
- **MiniMax** (minimax-pdf, etc.) - Integrated with AI generation features

## Best Practices

1. **Start Simple**: Begin with one skill at a time
2. **Check Dependencies**: Some skills require API keys or specific tools
3. **Read Skill Docs**: Each skill has a SKILL.md file with detailed instructions
4. **Combine Wisely**: Use complementary skills together
5. **Test Thoroughly**: Verify outputs, especially for production use

## Troubleshooting

### Skill Not Working?
1. Check if skill name is correct
2. Verify any required dependencies
3. Check for API keys (MiniMax skills)
4. Read the skill's SKILL.md file

### Performance Issues?
- Some skills are compute-intensive
- Multimodal generation requires good internet
- Document processing may be slow for large files

## Quick Reference Card

```bash
# List all skills
python3 integrate-anthropic-skills.py list
python3 integrate-skills.py list

# Load a skill
python3 integrate-anthropic-skills.py load <skill-name>

# View skill documentation
cat anthropic-skills/skills/<skill-name>/SKILL.md
cat minimax-skills/skills/<skill-name>/SKILL.md
```
