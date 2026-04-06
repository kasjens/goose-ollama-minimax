#!/usr/bin/env python3
"""
MiniMax Skills Integration for Goose
This script helps integrate MiniMax skills into Goose workflow
"""

import os
import json
import sys
from pathlib import Path

SKILLS_DIR = Path("minimax-skills/skills")
GOOSE_CONFIG = Path.home() / ".config/goose/config.yaml"

def list_available_skills():
    """List all available MiniMax skills"""
    if not SKILLS_DIR.exists():
        print("Error: Skills directory not found. Run git clone first.")
        return []
    
    skills = []
    for skill_dir in SKILLS_DIR.iterdir():
        if skill_dir.is_dir():
            # Check for skill metadata
            metadata_file = skill_dir / "metadata.json"
            if metadata_file.exists():
                with open(metadata_file) as f:
                    metadata = json.load(f)
                    skills.append({
                        "name": skill_dir.name,
                        "description": metadata.get("description", ""),
                        "path": str(skill_dir)
                    })
            else:
                skills.append({
                    "name": skill_dir.name,
                    "description": f"{skill_dir.name} skill",
                    "path": str(skill_dir)
                })
    
    return skills

def display_skills():
    """Display available skills in a formatted manner"""
    skills = list_available_skills()
    
    print("\n" + "="*60)
    print("Available MiniMax Skills for Goose")
    print("="*60)
    
    for skill in skills:
        print(f"\n📦 {skill['name']}")
        print(f"   Description: {skill['description']}")
        print(f"   Path: {skill['path']}")
    
    print("\n" + "="*60)
    print(f"Total skills available: {len(skills)}")
    print("="*60)

def create_skill_prompt(skill_name):
    """Create a prompt template for using a specific skill"""
    skill_path = SKILLS_DIR / skill_name
    
    if not skill_path.exists():
        print(f"Error: Skill '{skill_name}' not found.")
        return None
    
    prompt = f"""
When using the {skill_name} skill, you have access to specialized tools and capabilities.
The skill files are located at: {skill_path}

You can:
1. Load skill-specific templates and configurations
2. Use skill-specific utilities and helpers
3. Access domain-specific knowledge and patterns

To use this skill effectively:
- Check for any README or documentation in the skill directory
- Look for example files or templates
- Use the provided tools and utilities
"""
    
    return prompt

if __name__ == "__main__":
    if len(sys.argv) > 1:
        command = sys.argv[1]
        
        if command == "list":
            display_skills()
        elif command == "prompt" and len(sys.argv) > 2:
            skill = sys.argv[2]
            prompt = create_skill_prompt(skill)
            if prompt:
                print(prompt)
        else:
            print("Usage: python integrate-skills.py [list|prompt <skill-name>]")
    else:
        # Default action - list skills
        display_skills()