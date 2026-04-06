#!/bin/bash

# Configure Goose to use Ollama with MiniMax model

echo "Configuring Goose to use Ollama with MiniMax..."

# Create proper Goose provider config
cat > ~/.config/goose/provider.yaml << 'EOF'
provider: ollama
ollama:
  model: minimax-m2.7:cloud
  base_url: http://localhost:11434
EOF

echo "✅ Goose configured to use Ollama with MiniMax M2.7 Cloud"
echo ""
echo "Testing configuration..."

# Test the setup
if goose session list &>/dev/null; then
    echo "✅ Goose is ready to use with Ollama!"
    echo ""
    echo "Start Goose with: ./run-goose.sh"
else
    echo "⚠️  Please run: goose configure"
    echo "   Select: Ollama → minimax-m2.7:cloud → http://localhost:11434"
fi