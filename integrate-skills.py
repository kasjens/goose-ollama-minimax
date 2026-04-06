#!/usr/bin/env python3
"""
Skills Status and Listing Tool
Shows available skills in the .agents/skills directory (auto-discovered by Goose)
"""

import os
import sys
import yaml
from pathlib import Path

AGENTS_SKILLS_DIR = Path(".agents/skills")

def list_integrated_skills():
    """List all integrated skills from .agents/skills directory"""
    if not AGENTS_SKILLS_DIR.exists():
        print("❌ No skills integrated yet!")
        print("\nTo integrate skills, run:")
        print("  ./setup.sh                    # Basic setup")
        print("  ./install-all-dependencies.sh # Complete setup")
        return []

    skills = []
    skill_dirs = [d for d in AGENTS_SKILLS_DIR.iterdir() if d.is_dir()]
    
    if not skill_dirs:
        print("❌ Skills directory exists but is empty!")
        return []

    for skill_dir in skill_dirs:
        skill_file = skill_dir / "SKILL.md"
        if skill_file.exists():
            try:
                with open(skill_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    if content.startswith('---'):
                        yaml_end = content.find('---', 3)
                        if yaml_end > 0:
                            yaml_content = content[3:yaml_end]
                            metadata = yaml.safe_load(yaml_content)
                            skills.append({
                                "name": skill_dir.name,
                                "description": metadata.get("description", "No description"),
                                "path": str(skill_dir)
                            })
                        else:
                            skills.append({
                                "name": skill_dir.name, 
                                "description": f"{skill_dir.name} skill",
                                "path": str(skill_dir)
                            })
            except Exception:
                skills.append({
                    "name": skill_dir.name,
                    "description": f"{skill_dir.name} skill", 
                    "path": str(skill_dir)
                })
        else:
            # Directory without SKILL.md
            skills.append({
                "name": skill_dir.name,
                "description": "Legacy skill (no SKILL.md)",
                "path": str(skill_dir)
            })

    return sorted(skills, key=lambda x: x["name"])

def categorize_skills(skills):
    """Categorize skills by type"""
    categories = {
        "Document Processing": [],
        "Mobile Development": [],
        "Web Development": [], 
        "Creative & Design": [],
        "Development Tools": [],
        "Communication": [],
        "Other": []
    }
    
    for skill in skills:
        name = skill["name"].lower()
        if any(term in name for term in ["docx", "pdf", "pptx", "xlsx", "doc"]):
            categories["Document Processing"].append(skill)
        elif any(term in name for term in ["ios", "android", "flutter", "react-native", "mobile"]):
            categories["Mobile Development"].append(skill)
        elif any(term in name for term in ["frontend", "fullstack", "web", "webapp"]):
            categories["Web Development"].append(skill)
        elif any(term in name for term in ["art", "gif", "canvas", "design", "theme", "brand"]):
            categories["Creative & Design"].append(skill)
        elif any(term in name for term in ["api", "mcp", "skill-creator", "shader", "test"]):
            categories["Development Tools"].append(skill)
        elif any(term in name for term in ["comms", "internal", "vision", "multimodal"]):
            categories["Communication"].append(skill)
        else:
            categories["Other"].append(skill)
    
    return categories

def print_skills_status():
    """Print current skills integration status"""
    print("============================================================")
    print("📋 GOOSE SKILLS STATUS")
    print("============================================================")
    print()
    
    skills = list_integrated_skills()
    if not skills:
        return
        
    print(f"✅ **{len(skills)} skills integrated and ready**")
    print()
    print("🎯 **Skills are auto-discovered by Goose!**")
    print("   Just ask naturally - no manual loading needed.")
    print()
    
    categories = categorize_skills(skills)
    
    for category, cat_skills in categories.items():
        if cat_skills:
            print(f"📂 **{category} ({len(cat_skills)} skills)**")
            print("-" * 40)
            for skill in cat_skills:
                # Truncate long descriptions
                desc = skill["description"]
                if len(desc) > 80:
                    desc = desc[:77] + "..."
                print(f"  • **{skill['name']}**")
                print(f"    {desc}")
            print()
    
    print("============================================================")
    print("💡 **How to Use:**")
    print("============================================================")
    print()
    print("Simply ask Goose naturally:")
    print("  🪿 'Create a PowerPoint about AI'")
    print("  🪿 'Help me build an iOS app'") 
    print("  🪿 'Generate a Word document'")
    print("  🪿 'Make a GIF animation'")
    print("  🪿 'Build an MCP server'")
    print()

def print_setup_instructions():
    """Print setup instructions if skills aren't integrated"""
    print("============================================================")
    print("🔧 SKILLS SETUP REQUIRED")
    print("============================================================")
    print()
    print("Skills are not yet integrated. Choose an option:")
    print()
    print("**Option 1: Quick Setup** (recommended)")
    print("  ./setup.sh")
    print()
    print("**Option 2: Complete Setup** (includes all dependencies)")
    print("  ./install-all-dependencies.sh") 
    print()
    print("This will:")
    print("  ✅ Clone Anthropic and MiniMax skill repositories")
    print("  ✅ Copy all skills to .agents/skills/ directory")
    print("  ✅ Make them auto-discoverable by Goose")
    print("  ✅ Enable 31 specialized capabilities")
    print()

def main():
    if len(sys.argv) > 1 and sys.argv[1] == "list":
        if AGENTS_SKILLS_DIR.exists():
            print_skills_status()
        else:
            print_setup_instructions()
    else:
        print("Usage:")
        print("  python3 integrate-skills.py list    # Show available skills")
        print()
        print("ℹ️  Skills are now auto-integrated in .agents/skills/")
        print("   No manual configuration needed!")

if __name__ == "__main__":
    main()