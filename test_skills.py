#!/usr/bin/env python3
"""Test script to verify all MiniMax skills dependencies are working"""

import sys
import os

# Add venv to path
sys.path.insert(0, './venv/lib/python3.13/site-packages')

def test_imports():
    """Test that all required packages can be imported"""
    success = True
    packages = [
        ('pandas', 'Data manipulation'),
        ('numpy', 'Numerical computing'),
        ('PIL', 'Image processing (Pillow)'),
        ('pypdf', 'PDF processing'),
        ('docx', 'Word document processing'),
        ('openpyxl', 'Excel processing'),
        ('matplotlib', 'Data visualization'),
        ('markitdown', 'PowerPoint text extraction'),
        ('pptx', 'PowerPoint manipulation')
    ]
    
    print("Testing Python package imports:")
    print("-" * 50)
    
    for package, description in packages:
        try:
            if package == 'PIL':
                from PIL import Image
            elif package == 'docx':
                import docx
            elif package == 'pptx':
                import pptx
            else:
                __import__(package)
            print(f"✅ {package:15} - {description}")
        except ImportError as e:
            print(f"❌ {package:15} - {description} - Error: {e}")
            success = False
    
    return success

def test_pptx_reading():
    """Test reading the generated PowerPoint"""
    try:
        from markitdown import MarkItDown
        
        pptx_path = "slides/output/goose-presentation.pptx"
        if os.path.exists(pptx_path):
            print("\nTesting PowerPoint reading with markitdown:")
            print("-" * 50)
            
            md = MarkItDown()
            result = md.convert(pptx_path)
            
            if result.text_content:
                print(f"✅ Successfully read PowerPoint")
                print(f"   Content length: {len(result.text_content)} characters")
                print(f"   First 200 chars: {result.text_content[:200]}...")
            else:
                print(f"❌ Could not extract text from PowerPoint")
        else:
            print(f"\n⚠️  PowerPoint file not found at {pptx_path}")
    except Exception as e:
        print(f"❌ Error testing PowerPoint reading: {e}")

def main():
    print("=" * 50)
    print("MiniMax Skills Dependency Test")
    print("=" * 50)
    print()
    
    # Test imports
    imports_ok = test_imports()
    
    # Test PowerPoint functionality
    test_pptx_reading()
    
    print("\n" + "=" * 50)
    if imports_ok:
        print("✅ All dependencies are correctly installed!")
        print("You can now use Goose with all MiniMax skills.")
    else:
        print("❌ Some dependencies are missing.")
        print("Please check the errors above.")
    print("=" * 50)

if __name__ == "__main__":
    main()