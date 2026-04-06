#!/bin/bash

# Ollama Cloud Models Configuration Script
# Fetches latest cloud models and configures Goose for optimal usage

echo "=================================================="
echo "🌩️  OLLAMA CLOUD MODELS CONFIGURATION"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Ensure we're signed into Ollama
echo -e "${BLUE}🔐 Checking Ollama authentication...${NC}"
if ! ollama signin 2>/dev/null | grep -q "signed in"; then
    echo -e "${YELLOW}⚠️  Not signed in. Please sign in to access cloud models:${NC}"
    echo "ollama signin"
    exit 1
fi
echo -e "${GREEN}✅ Signed in to Ollama cloud${NC}"
echo ""

# Define comprehensive list of 2025 cloud models
echo -e "${BLUE}📋 2025 Cloud Models List${NC}"
echo "================================="

declare -A CLOUD_MODELS=(
    # DeepSeek Models (State-of-the-art reasoning)
    ["deepseek-v3.2:cloud"]="DeepSeek V3.2 - Latest reasoning model"
    ["deepseek-v3.1:671b-cloud"]="DeepSeek V3.1 671B - Massive reasoning model"
    ["deepseek-r1:671b-cloud"]="DeepSeek R1 671B - Advanced reasoning"
    
    # Qwen Models (Multilingual & Coding)
    ["qwen3-coder:480b-cloud"]="Qwen3 Coder 480B - Advanced coding assistant"
    ["qwen3.5:cloud"]="Qwen 3.5 - Multilingual general model"
    ["qwen3-vl:235b-cloud"]="Qwen3 VL 235B - Vision-language model"
    ["qwen3-next:80b-cloud"]="Qwen3 Next 80B - Next generation model"
    
    # GPT-OSS Models (Open source GPT)
    ["gpt-oss:120b-cloud"]="GPT-OSS 120B - Large open-source model"
    ["gpt-oss:20b-cloud"]="GPT-OSS 20B - Efficient open-source model"
    
    # MiniMax Models (Default choice)
    ["minimax-m2.7:cloud"]="MiniMax M2.7 - Balanced performance (DEFAULT)"
    ["minimax-m2.5:cloud"]="MiniMax M2.5 - Fast inference"
    ["minimax-m2.1:cloud"]="MiniMax M2.1 - Compact model"
    
    # GLM Models (General Language Models)
    ["glm-5:cloud"]="GLM-5 - Latest general model"
    ["glm-4.6:cloud"]="GLM-4.6 - Stable general model"
    
    # Kimi Models
    ["kimi-k2.5:cloud"]="Kimi K2.5 - Conversational AI"
    
    # Gemma Models (Google)
    ["gemma3-instruct:cloud"]="Gemma3 Instruct - Instruction-tuned"
)

# Function to pull cloud model
pull_cloud_model() {
    local model="$1"
    local description="$2"
    
    echo -e "${BLUE}📥 Pulling: ${model}${NC}"
    echo "   Description: $description"
    
    if ollama pull "$model" >/dev/null 2>&1; then
        echo -e "${GREEN}   ✅ Successfully pulled${NC}"
        return 0
    else
        echo -e "${RED}   ❌ Failed to pull${NC}"
        return 1
    fi
}

# Interactive model selection
echo ""
echo -e "${YELLOW}🤔 Select models to configure:${NC}"
echo "1) Essential models only (recommended)"
echo "2) All available models"
echo "3) Custom selection"
echo "4) Just update existing models"
echo ""
read -p "Choose option [1-4]: " -n 1 -r CHOICE
echo ""
echo ""

MODELS_TO_PULL=()

case $CHOICE in
    1)
        echo -e "${BLUE}📦 Configuring essential cloud models...${NC}"
        MODELS_TO_PULL=(
            "minimax-m2.7:cloud"
            "deepseek-v3.2:cloud"
            "qwen3-coder:480b-cloud"
            "gpt-oss:120b-cloud"
            "glm-5:cloud"
        )
        ;;
    2)
        echo -e "${BLUE}📦 Configuring ALL cloud models...${NC}"
        MODELS_TO_PULL=($(printf '%s\n' "${!CLOUD_MODELS[@]}"))
        ;;
    3)
        echo -e "${BLUE}📋 Available models:${NC}"
        local i=1
        local model_array=()
        for model in "${!CLOUD_MODELS[@]}"; do
            echo "$i) $model - ${CLOUD_MODELS[$model]}"
            model_array+=("$model")
            ((i++))
        done
        echo ""
        echo "Enter model numbers (space-separated, e.g. 1 3 5):"
        read -r selection
        for num in $selection; do
            if [[ $num =~ ^[0-9]+$ ]] && [ $num -le ${#model_array[@]} ] && [ $num -gt 0 ]; then
                MODELS_TO_PULL+=("${model_array[$((num-1))]}")
            fi
        done
        ;;
    4)
        echo -e "${BLUE}🔄 Updating existing models only...${NC}"
        # Get existing cloud models
        EXISTING_MODELS=$(ollama list | grep ":cloud" | awk '{print $1}')
        MODELS_TO_PULL=($(echo $EXISTING_MODELS))
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

# Pull selected models
echo ""
echo -e "${BLUE}🚀 Pulling selected cloud models...${NC}"
echo "======================================"

SUCCESS_COUNT=0
TOTAL_COUNT=${#MODELS_TO_PULL[@]}

for model in "${MODELS_TO_PULL[@]}"; do
    if [[ -n "${CLOUD_MODELS[$model]}" ]]; then
        description="${CLOUD_MODELS[$model]}"
    else
        description="Existing model"
    fi
    
    if pull_cloud_model "$model" "$description"; then
        ((SUCCESS_COUNT++))
    fi
    echo ""
done

# Update Goose configuration with available models
echo -e "${BLUE}⚙️  Updating Goose configuration...${NC}"
echo "===================================="

# Read current config
GOOSE_CONFIG_DIR="$HOME/.config/goose"
GOOSE_CONFIG="$GOOSE_CONFIG_DIR/config.yaml"

# Backup current config
if [[ -f "$GOOSE_CONFIG" ]]; then
    cp "$GOOSE_CONFIG" "$GOOSE_CONFIG.backup.$(date +%s)"
    echo -e "${GREEN}✅ Backed up existing config${NC}"
fi

# Get currently available cloud models
AVAILABLE_MODELS=$(ollama list | grep ":cloud" | awk '{print $1}' | sort)

# Create updated configuration
cat > "$GOOSE_CONFIG" << EOF
# Goose AI Configuration with Cloud Models
# Updated: $(date)

extensions:
  todo:
    enabled: true
    type: platform
    name: todo
    description: Enable a todo list for goose so it can keep track of what it is doing
    display_name: Todo
    bundled: true
    available_tools: []
  summon:
    enabled: true
    type: platform
    name: summon
    description: Load knowledge and delegate tasks to subagents
    display_name: Summon
    bundled: true
    available_tools: []
  summarize:
    enabled: true
    type: platform
    name: summarize
    description: Load files/directories and get an LLM summary in a single call
    display_name: Summarize
    bundled: true
    available_tools: []
  tom:
    enabled: true
    type: platform
    name: tom
    description: Inject custom context into every turn via GOOSE_MOIM_MESSAGE_TEXT and GOOSE_MOIM_MESSAGE_FILE environment variables
    display_name: Top Of Mind
    bundled: true
    available_tools: []
  apps:
    enabled: true
    type: platform
    name: apps
    description: Create and manage custom Goose apps through chat. Apps are HTML/CSS/JavaScript and run in sandboxed windows.
    display_name: Apps
    bundled: true
    available_tools: []
  code_execution:
    enabled: true
    type: platform
    name: code_execution
    description: Goose will make extension calls through code execution, saving tokens
    display_name: Code Mode
    bundled: true
    available_tools: []
  analyze:
    enabled: true
    type: platform
    name: analyze
    description: 'Analyze code structure with tree-sitter: directory overviews, file details, symbol call graphs'
    display_name: Analyze
    bundled: true
    available_tools: []
  orchestrator:
    enabled: true
    type: platform
    name: orchestrator
    description: 'Manage agent sessions: list, view, start, send messages, interrupt, and stop agents'
    display_name: Orchestrator
    bundled: true
    available_tools: []
  chatrecall:
    enabled: true
    type: platform
    name: chatrecall
    description: Search past conversations and load session summaries for contextual memory
    display_name: Chat Recall
    bundled: true
    available_tools: []
  extensionmanager:
    enabled: true
    type: platform
    name: Extension Manager
    description: Enable extension management tools for discovering, enabling, and disabling extensions
    display_name: Extension Manager
    bundled: true
    available_tools: []
  developer:
    enabled: true
    type: platform
    name: developer
    description: Write and edit files, and execute shell commands
    display_name: Developer
    bundled: true
    available_tools: []
  computercontroller:
    enabled: true
    type: builtin
    name: computercontroller
    description: General computer control tools that don't require you to be a developer or engineer.
    display_name: Computer Controller
    timeout: 300
    bundled: true
    available_tools: []
  autovisualiser:
    enabled: true
    type: builtin
    name: autovisualiser
    description: Data visualization and UI generation tools
    display_name: Auto Visualiser
    timeout: 300
    bundled: true
    available_tools: []
  memory:
    enabled: true
    type: builtin
    name: memory
    description: Teach goose your preferences as you go.
    display_name: Memory
    timeout: 300
    bundled: true
    available_tools: []
  tutorial:
    enabled: true
    type: builtin
    name: tutorial
    description: Access interactive tutorials and guides
    display_name: Tutorial
    timeout: 300
    bundled: true
    available_tools: []

# Ollama Configuration with Cloud Models
GOOSE_PROVIDER: ollama
GOOSE_MODEL: minimax-m2.7:cloud
GOOSE_TELEMETRY_ENABLED: true
OLLAMA_HOST: localhost

# Available Cloud Models (configured $(date +%Y-%m-%d))
# Use these models by setting GOOSE_MODEL environment variable:
$(echo "$AVAILABLE_MODELS" | sed 's/^/# - /')

EOF

echo -e "${GREEN}✅ Updated Goose configuration${NC}"
echo "   Default model: minimax-m2.7:cloud"
echo "   Available models: $(echo "$AVAILABLE_MODELS" | wc -l)"

# Create model switcher script
echo ""
echo -e "${BLUE}🔧 Creating model switcher script...${NC}"

cat > "switch-model.sh" << 'EOF'
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
EOF

chmod +x switch-model.sh

# Summary
echo ""
echo "=================================================="
echo -e "${GREEN}🎉 CLOUD MODELS CONFIGURATION COMPLETE!${NC}"
echo "=================================================="
echo ""
echo -e "${BLUE}📊 Summary:${NC}"
echo "   Successfully pulled: $SUCCESS_COUNT/$TOTAL_COUNT models"
echo "   Default model: minimax-m2.7:cloud"
echo "   Configuration: ~/.config/goose/config.yaml"
echo ""
echo -e "${BLUE}🚀 Usage:${NC}"
echo "   ./run-goose.sh                    # Start with default model"
echo "   ./switch-model.sh                # Interactive model switcher"
echo "   ./run-goose-local.sh             # Force local Goose AI"
echo ""
echo -e "${BLUE}💡 Available Models:${NC}"
ollama list | grep ":cloud" | while read name id size modified; do
    if [[ -n "${CLOUD_MODELS[$name]}" ]]; then
        desc="${CLOUD_MODELS[$name]}"
    else
        desc="Cloud model"
    fi
    echo "   $name - $desc"
done
echo ""
echo -e "${GREEN}Ready to use latest 2025 cloud models with Goose AI! 🚀${NC}"