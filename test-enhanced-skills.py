#!/usr/bin/env python3
"""
Enhanced Skills Dependencies Test
Tests all packages needed for comprehensive AI skills
"""

import sys
import importlib

def test_package(package_name, import_name=None, description=""):
    """Test if a package can be imported"""
    import_name = import_name or package_name
    try:
        module = importlib.import_module(import_name)
        version = getattr(module, '__version__', 'unknown')
        print(f"✅ {package_name:20} v{version:15} - {description}")
        return True
    except ImportError as e:
        print(f"❌ {package_name:20} {'MISSING':15} - {description}")
        return False

def main():
    print("=" * 70)
    print("🧪 ENHANCED SKILLS DEPENDENCIES TEST")
    print("=" * 70)
    print()
    
    # Core Dependencies
    print("📚 Core Dependencies:")
    print("-" * 30)
    core_packages = [
        ('pandas', None, 'Data manipulation and analysis'),
        ('numpy', None, 'Numerical computing'),
        ('PIL', 'PIL', 'Image processing (Pillow)'),
        ('requests', None, 'HTTP library'),
        ('matplotlib', None, 'Data visualization'),
    ]
    
    core_success = 0
    for pkg, imp, desc in core_packages:
        if test_package(pkg, imp, desc):
            core_success += 1
    
    print()
    
    # Document Processing
    print("📄 Document Processing:")
    print("-" * 30)
    doc_packages = [
        ('pypdf', None, 'PDF processing'),
        ('python-docx', 'docx', 'Word document processing'),
        ('openpyxl', None, 'Excel processing'),
        ('python-pptx', 'pptx', 'PowerPoint processing'),
        ('markitdown', None, 'Document text extraction'),
    ]
    
    doc_success = 0
    for pkg, imp, desc in doc_packages:
        if test_package(pkg, imp, desc):
            doc_success += 1
    
    print()
    
    # AI/ML Libraries
    print("🤖 AI/ML Libraries:")
    print("-" * 30)
    ai_packages = [
        ('opencv-python', 'cv2', 'Computer vision'),
        ('scikit-image', 'skimage', 'Image processing algorithms'),
        ('scikit-learn', 'sklearn', 'Machine learning'),
        ('transformers', None, 'Hugging Face transformers'),
        ('torch', None, 'PyTorch (if available)'),
    ]
    
    ai_success = 0
    for pkg, imp, desc in ai_packages:
        if test_package(pkg, imp, desc):
            ai_success += 1
    
    print()
    
    # Media Processing
    print("🎵 Media Processing:")
    print("-" * 30)
    media_packages = [
        ('moviepy', None, 'Video editing'),
        ('pydub', None, 'Audio processing'),
        ('librosa', None, 'Audio analysis'),
        ('soundfile', None, 'Audio file I/O'),
    ]
    
    media_success = 0
    for pkg, imp, desc in media_packages:
        if test_package(pkg, imp, desc):
            media_success += 1
    
    print()
    
    # Web Frameworks
    print("🌐 Web Frameworks:")
    print("-" * 30)
    web_packages = [
        ('fastapi', None, 'Modern web framework'),
        ('uvicorn', None, 'ASGI server'),
        ('streamlit', None, 'Data app framework'),
        ('gradio', None, 'ML app framework'),
        ('jinja2', None, 'Template engine'),
        ('websockets', None, 'WebSocket support'),
    ]
    
    web_success = 0
    for pkg, imp, desc in web_packages:
        if test_package(pkg, imp, desc):
            web_success += 1
    
    print()
    
    # Additional Utilities
    print("🔧 Additional Utilities:")
    print("-" * 30)
    util_packages = [
        ('python-dotenv', 'dotenv', 'Environment variables'),
        ('pyyaml', 'yaml', 'YAML processing'),
        ('jsonschema', None, 'JSON validation'),
        ('click', None, 'CLI framework'),
        ('rich', None, 'Terminal formatting'),
    ]
    
    util_success = 0
    for pkg, imp, desc in util_packages:
        if test_package(pkg, imp, desc):
            util_success += 1
    
    print()
    
    # Summary
    total_packages = len(core_packages) + len(doc_packages) + len(ai_packages) + len(media_packages) + len(web_packages) + len(util_packages)
    total_success = core_success + doc_success + ai_success + media_success + web_success + util_success
    
    print("=" * 70)
    print("📊 SUMMARY")
    print("=" * 70)
    print(f"Core Dependencies:     {core_success}/{len(core_packages)}")
    print(f"Document Processing:   {doc_success}/{len(doc_packages)}")
    print(f"AI/ML Libraries:       {ai_success}/{len(ai_packages)}")
    print(f"Media Processing:      {media_success}/{len(media_packages)}")
    print(f"Web Frameworks:        {web_success}/{len(web_packages)}")
    print(f"Additional Utilities:  {util_success}/{len(util_packages)}")
    print("-" * 30)
    print(f"TOTAL:                 {total_success}/{total_packages}")
    
    percentage = (total_success / total_packages) * 100
    print(f"Success Rate:          {percentage:.1f}%")
    
    if percentage >= 95:
        print("\n🎉 EXCELLENT! All dependencies are ready for advanced skills!")
    elif percentage >= 85:
        print("\n✅ GOOD! Most dependencies ready. Some optional packages missing.")
    elif percentage >= 70:
        print("\n⚠️  PARTIAL! Core functionality available but some features limited.")
    else:
        print("\n❌ INCOMPLETE! Several important packages missing.")
    
    print()
    print("🚀 Skills now available:")
    print("  • Document processing (PDF, Word, Excel, PowerPoint)")
    print("  • Computer vision and image analysis") 
    print("  • Audio and video processing")
    print("  • Web application creation")
    print("  • Machine learning pipelines")
    print("  • Data visualization")
    print("  • API development")
    
    return total_success == total_packages

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)