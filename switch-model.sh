#!/bin/bash

# Goose Model Switcher for Cloud Models
echo "🌩️  Available Ollama Cloud Models:"
echo "=================================="

models=($(ollama list | grep ":cloud" | awk '{print $1}' | sort))

if [ ${#models[@]} -eq 0 ]; then
    echo "No cloud models found. Run ./configure-cloud-models.sh first."
    exit 1
fi

for i in "${!models[@]}"; do
    current=""
    if grep -q "GOOSE_MODEL: ${models[$i]}" ~/.config/goose/config.yaml; then
        current=" (CURRENT)"
    fi
    echo "$((i+1))) ${models[$i]}$current"
done

echo ""
read -p "Select model [1-${#models[@]}]: " -n 1 -r choice
echo ""

if [[ $choice =~ ^[0-9]+$ ]] && [ $choice -le ${#models[@]} ] && [ $choice -gt 0 ]; then
    selected_model="${models[$((choice-1))]}"
    
    # Update config file
    sed -i "s/GOOSE_MODEL: .*/GOOSE_MODEL: $selected_model/" ~/.config/goose/config.yaml
    
    echo "✅ Switched to: $selected_model"
    echo "Run ./run-goose.sh to start with the new model"
else
    echo "❌ Invalid selection"
fi
