#!/bin/bash

# Goose + Ollama MiniMax Setup Script

echo "Setting up Goose with Ollama MiniMax..."

# Check if Ollama is running
if ! pgrep -x "ollama" > /dev/null; then
    echo "Starting Ollama service..."
    ollama serve &
    sleep 2
fi

# Check if MiniMax model is available
if ! ollama list | grep -q "minimax-m2.7:cloud"; then
    echo "MiniMax model not found. Please pull it first:"
    echo "  ollama pull minimax-m2.7:cloud"
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
fi

# Install Python dependencies in virtual environment
echo "Installing Python dependencies for skills..."
source venv/bin/activate
pip install -q -r requirements.txt
deactivate

echo "Setup complete! You can now run Goose with:"
echo "  ./run-goose.sh"