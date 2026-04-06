#!/usr/bin/env python3
"""
Anthropic Skills Integration for Goose
This script helps integrate Anthropic skills into Goose workflow
"""

import os
import json
import yaml
import sys
from pathlib import Path

ANTHROPIC_SKILLS_DIR = Path("anthropic-skills/skills")
MINIMAX_SKILLS_DIR = Path("minimax-skills/skills")

def list_anthropic_skills():
    """List all available Anthropic skills"""
    if not ANTHROPIC_SKILLS_DIR.exists():
        print("Error: Anthropic skills directory not found. Run git clone first.")
        return []
    
    skills = []
    for skill_dir in ANTHROPIC_SKILLS_DIR.iterdir():
        if skill_dir.is_dir():
            skill_file = skill_dir / "SKILL.md"
            if skill_file.exists():
                # Parse YAML frontmatter
                with open(skill_file) as f:
                    content = f.read()
                    if content.startswith('---'):
                        yaml_end = content.find('---', 3)
                        if yaml_end > 0:
                            yaml_content = content[3:yaml_end]
                            try:
                                metadata = yaml.safe_load(yaml_content)
                                skills.append({
                                    "name": metadata.get("name", skill_dir.name),
                                    "description": metadata.get("description", ""),
                                    "path": str(skill_dir),
                                    "license": metadata.get("license", "Apache 2.0")
                                })
                            except:
                                skills.append({
                                    "name": skill_dir.name,
                                    "description": f"{skill_dir.name} skill",
                                    "path": str(skill_dir),
                                    "license": "Unknown"
                                })
    
    return skills

def display_all_skills():
    """Display both Anthropic and MiniMax skills"""
    anthropic_skills = list_anthropic_skills()
    
    print("\n" + "="*70)
    print("ANTHROPIC SKILLS (Claude Native)")
    print("="*70)
    
    categories = {
        "Document Processing": ["docx", "pdf", "pptx", "xlsx"],
        "Development": ["claude-api", "mcp-builder", "skill-creator", "webapp-testing"],
        "Creative & Design": ["algorithmic-art", "canvas-design", "frontend-design", "theme-factory", "slack-gif-creator"],
        "Communication": ["doc-coauthoring", "internal-comms", "brand-guidelines"],
        "Web": ["web-artifacts-builder"]
    }
    
    for category, skill_names in categories.items():
        print(f"\n📂 {category}")
        print("-" * 40)
        for skill in anthropic_skills:
            if skill['name'] in skill_names:
                print(f"  • {skill['name']}")
                if skill['description']:
                    # Truncate long descriptions
                    desc = skill['description'][:100] + "..." if len(skill['description']) > 100 else skill['description']
                    print(f"    {desc}")
    
    # List uncategorized skills
    all_categorized = sum(categories.values(), [])
    uncategorized = [s for s in anthropic_skills if s['name'] not in all_categorized]
    if uncategorized:
        print(f"\n📂 Other")
        print("-" * 40)
        for skill in uncategorized:
            print(f"  • {skill['name']}")
    
    print("\n" + "="*70)
    print(f"Total Anthropic skills available: {len(anthropic_skills)}")
    print("="*70)

def create_skill_context(skill_name, skills_type="anthropic"):
    """Create a context file for using a specific skill in Goose"""
    
    if skills_type == "anthropic":
        skill_path = ANTHROPIC_SKILLS_DIR / skill_name / "SKILL.md"
    else:
        skill_path = MINIMAX_SKILLS_DIR / skill_name / "SKILL.md"
    
    if not skill_path.exists():
        print(f"Error: Skill '{skill_name}' not found.")
        return None
    
    # Read the skill content
    with open(skill_path) as f:
        content = f.read()
    
    # Create a context file for Goose
    context_file = Path(f"skill-context-{skill_name}.md")
    
    context = f"""# Active Skill: {skill_name}

## Skill Content
{content}

## How to Use This Skill in Goose
1. This skill is now loaded as context
2. Follow the instructions in the skill documentation above
3. Any resources referenced in the skill are available at: {skill_path.parent}

## Additional Resources
- Full skill directory: {skill_path.parent}
- Related files: {list(skill_path.parent.glob('*'))}
"""
    
    with open(context_file, 'w') as f:
        f.write(context)
    
    print(f"✅ Created context file: {context_file}")
    print(f"   You can now reference this skill in your Goose session")
    
    return str(context_file)

def setup_skills_aliases():
    """Create convenient aliases for using skills in Goose"""
    
    aliases_script = """#!/bin/bash
# Skill loading aliases for Goose

# Function to load an Anthropic skill
load_anthropic_skill() {
    python3 integrate-anthropic-skills.py load "$1"
}

# Function to load a MiniMax skill  
load_minimax_skill() {
    python3 integrate-skills.py prompt "$1"
}

# Aliases for common skills
alias goose-pdf='load_anthropic_skill pdf'
alias goose-pptx='load_anthropic_skill pptx'
alias goose-docx='load_anthropic_skill docx'
alias goose-xlsx='load_anthropic_skill xlsx'
alias goose-claude-api='load_anthropic_skill claude-api'
alias goose-webapp-test='load_anthropic_skill webapp-testing'
alias goose-mcp='load_anthropic_skill mcp-builder'

echo "Skill aliases loaded! Examples:"
echo "  goose-pdf     - Load PDF processing skill"
echo "  goose-pptx    - Load PowerPoint skill"
echo "  goose-claude-api - Load Claude API skill"
"""
    
    with open("skill-aliases.sh", 'w') as f:
        f.write(aliases_script)
    
    os.chmod("skill-aliases.sh", 0o755)
    print("✅ Created skill-aliases.sh - source this file to use skill shortcuts")

def create_combined_skills_guide():
    """Create a guide for using both Anthropic and MiniMax skills"""
    
    guide = """# Complete Skills Guide for Goose

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
"""
    
    with open("COMPLETE-SKILLS-GUIDE.md", 'w') as f:
        f.write(guide)
    
    print("✅ Created COMPLETE-SKILLS-GUIDE.md")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        command = sys.argv[1]
        
        if command == "list":
            display_all_skills()
        elif command == "load" and len(sys.argv) > 2:
            skill = sys.argv[2]
            context_file = create_skill_context(skill)
            if context_file:
                print(f"\nTo use this skill in Goose:")
                print(f"1. The skill context is saved in: {context_file}")
                print(f"2. You can reference the skill documentation in your prompts")
                print(f"3. Ask Goose to apply the {skill} skill to your task")
        elif command == "setup":
            setup_skills_aliases()
            create_combined_skills_guide()
            print("\n✅ Setup complete!")
            print("   - Created skill-aliases.sh")
            print("   - Created COMPLETE-SKILLS-GUIDE.md")
        else:
            print("Usage: python integrate-anthropic-skills.py [list|load <skill-name>|setup]")
    else:
        # Default action - list skills
        display_all_skills()
        print("\nUsage:")
        print("  python integrate-anthropic-skills.py list       - List all skills")
        print("  python integrate-anthropic-skills.py load <name> - Load a skill")
        print("  python integrate-anthropic-skills.py setup      - Setup aliases and guides")