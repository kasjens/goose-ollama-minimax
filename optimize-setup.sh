#!/bin/bash

# Comprehensive Goose + Ollama Optimization Script
# Applies best practices and performance optimizations

echo "============================================"
echo "Goose + Ollama Setup Optimization"
echo "============================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ️${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# Function to detect GPU
detect_gpu() {
    if command -v nvidia-smi &> /dev/null; then
        GPU_INFO=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "nvidia"
            return 0
        fi
    fi
    
    if command -v rocm-smi &> /dev/null; then
        echo "amd"
        return 0
    fi
    
    echo "cpu"
    return 1
}

# Function to get system memory
get_system_memory() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        awk '/MemTotal/ {printf "%.0f\n", $2/1024}' /proc/meminfo
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo $(($(sysctl -n hw.memsize) / 1024 / 1024))
    else
        echo "unknown"
    fi
}

# 1. Optimize Ollama Configuration
echo "🔧 Optimizing Ollama Configuration..."
echo "-----------------------------------"

# Detect system specs
GPU_TYPE=$(detect_gpu)
SYSTEM_RAM=$(get_system_memory)

print_info "Detected GPU: $GPU_TYPE"
print_info "System RAM: ${SYSTEM_RAM}MB"

# Create optimized Ollama environment
cat > ollama-env.sh << 'EOF'
#!/bin/bash
# Optimized Ollama Environment Variables

# GPU Configuration
export OLLAMA_GPU_MEMORY_FRACTION=0.85  # Use 85% of GPU memory
export OLLAMA_FLASH_ATTENTION=1         # Enable Flash Attention (NVIDIA only)
export OLLAMA_KV_CACHE_TYPE=q8_0        # Quantize KV cache
export OLLAMA_CONTEXT_LENGTH=131072     # Extended context window

# Performance Tuning
export OLLAMA_NUM_PARALLEL=2            # Parallel requests
export OLLAMA_MAX_LOADED_MODELS=2       # Models kept in memory
export OLLAMA_LOAD_TIMEOUT=300          # Model loading timeout

# Logging and Debug
export OLLAMA_DEBUG=false               # Disable debug for performance
export OLLAMA_VERBOSE=false             # Reduce verbosity

# Host Configuration
export OLLAMA_HOST=0.0.0.0              # Accept connections from all interfaces
export OLLAMA_PORT=11434                # Standard port

# Memory Management
export OLLAMA_MAX_QUEUE=10              # Request queue size
EOF

chmod +x ollama-env.sh

# Apply GPU-specific optimizations
if [ "$GPU_TYPE" = "nvidia" ]; then
    cat >> ollama-env.sh << 'EOF'

# NVIDIA-specific optimizations
export CUDA_VISIBLE_DEVICES=0           # Use first GPU
export NVIDIA_VISIBLE_DEVICES=0         # Use first GPU
EOF
    print_info "Applied NVIDIA optimizations"
elif [ "$GPU_TYPE" = "amd" ]; then
    cat >> ollama-env.sh << 'EOF'

# AMD-specific optimizations
export HSA_OVERRIDE_GFX_VERSION=10.3.0  # ROCm compatibility
export OLLAMA_GPU_DRIVER=rocm           # Use ROCm driver
EOF
    print_info "Applied AMD ROCm optimizations"
else
    cat >> ollama-env.sh << 'EOF'

# CPU-only optimizations
export OLLAMA_NUM_THREAD=8              # CPU threads
export OLLAMA_GPU_LAYERS=0              # No GPU layers
EOF
    print_info "Applied CPU-only optimizations"
fi

print_status "Created optimized Ollama environment: ollama-env.sh"

# 2. Create Optimized Goose Configuration
echo ""
echo "🪿 Optimizing Goose Configuration..."
echo "-----------------------------------"

# Backup current config
if [ -f ~/.config/goose/config.yaml ]; then
    cp ~/.config/goose/config.yaml ~/.config/goose/config.yaml.backup
    print_info "Backed up current config to config.yaml.backup"
fi

# Add performance optimizations to Goose config
cat >> ~/.config/goose/config.yaml << 'EOF'

# Performance Optimizations
GOOSE_CONTEXT_SIZE: 32768
GOOSE_MAX_TOOL_REPETITIONS: 5
GOOSE_MAX_TURNS: 20
GOOSE_REQUEST_TIMEOUT: 300

# Ollama Optimization
OLLAMA_REQUEST_TIMEOUT: 180
OLLAMA_KEEP_ALIVE: 300

# Memory Management  
GOOSE_CACHE_SIZE: 1000
GOOSE_HISTORY_LIMIT: 100
EOF

print_status "Applied Goose performance optimizations"

# 3. Create System Service for Ollama
echo ""
echo "🚀 Setting up Ollama as System Service..."
echo "----------------------------------------"

# Create systemd service file
cat > ollama.service << 'EOF'
[Unit]
Description=Ollama Large Language Model Service
After=network.target

[Service]
Type=simple
User=%i
Group=%i
ExecStart=/usr/local/bin/ollama serve
Restart=always
RestartSec=3
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_GPU_MEMORY_FRACTION=0.85"
Environment="OLLAMA_FLASH_ATTENTION=1"
Environment="OLLAMA_KV_CACHE_TYPE=q8_0"

[Install]
WantedBy=multi-user.target
EOF

if [ "$EUID" -eq 0 ]; then
    # Running as root, install service
    cp ollama.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable ollama
    print_status "Installed Ollama systemd service"
else
    print_warning "Run as root to install systemd service, or manually copy ollama.service to /etc/systemd/system/"
fi

# 4. Model Optimization Recommendations
echo ""
echo "🧠 Model Optimization Recommendations..."
echo "---------------------------------------"

# Check current models
echo "Current models installed:"
ollama list

echo ""
print_info "Recommended model optimizations:"

if [ "$SYSTEM_RAM" -lt 16000 ]; then
    print_warning "System has less than 16GB RAM - recommend smaller models"
    echo "  • Keep: minimax-m2.7:cloud (lightweight)"
    echo "  • Consider: qwen2.5:7b instead of qwen3.5:9b"
elif [ "$SYSTEM_RAM" -lt 32000 ]; then
    print_info "System has 16-32GB RAM - good for medium models"
    echo "  • Current setup looks optimal"
    echo "  • Can handle: 7-13B parameter models"
else
    print_status "System has 32GB+ RAM - can handle large models"
    echo "  • Consider: llama3.1:13b or qwen2.5:14b"
    echo "  • Can run: Multiple models simultaneously"
fi

# 5. Create Health Check Script
echo ""
echo "🔍 Creating Health Check Script..."
echo "---------------------------------"

cat > health-check.sh << 'EOF'
#!/bin/bash

echo "=== Goose + Ollama Health Check ==="
echo ""

# Check Ollama service
echo "📊 Ollama Status:"
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "  ✅ Ollama service is running"
    
    # Get model info
    echo "  Models loaded:"
    ollama ps | grep -v "NAME" | while read line; do
        if [ ! -z "$line" ]; then
            echo "    • $line"
        fi
    done
    
    # Test model response
    echo "  Testing model response..."
    RESPONSE=$(echo "Hello" | ollama run minimax-m2.7:cloud 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "  ✅ Model responds correctly"
    else
        echo "  ❌ Model response failed"
    fi
    
else
    echo "  ❌ Ollama service not responding"
fi

echo ""
echo "🪿 Goose Status:"
if command -v goose &> /dev/null; then
    echo "  ✅ Goose is installed"
    echo "  Version: $(goose --version 2>/dev/null || echo 'unknown')"
    
    # Check extensions
    echo "  Extensions configured:"
    if [ -f ~/.config/goose/config.yaml ]; then
        grep -c "enabled: true" ~/.config/goose/config.yaml | xargs echo "    Active extensions:"
    fi
    
else
    echo "  ❌ Goose not found in PATH"
fi

echo ""
echo "💾 System Resources:"
echo "  RAM Usage: $(free -h 2>/dev/null | awk '/^Mem/ {print $3 "/" $2}' || echo 'unknown')"
if command -v nvidia-smi &> /dev/null; then
    echo "  GPU Memory: $(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | awk '{print $1 "MB/" $2 "MB"}' || echo 'unknown')"
fi

echo ""
echo "🔗 Network Status:"
echo "  Ollama API: $(curl -s -w "%{http_code}" http://localhost:11434/api/version -o /dev/null)"
if [ -f "brave-search-mcp/.env" ]; then
    echo "  Brave Search: ✅ Configured"
else
    echo "  Brave Search: ⚠️ Not configured"
fi

echo ""
echo "📁 Skills Status:"
echo "  Anthropic Skills: $(ls -1 anthropic-skills/skills/ 2>/dev/null | wc -l) available"
echo "  MiniMax Skills: $(ls -1 minimax-skills/skills/ 2>/dev/null | wc -l) available"

echo ""
echo "=== Health Check Complete ==="
EOF

chmod +x health-check.sh
print_status "Created health check script: health-check.sh"

# 6. Create Startup Script
echo ""
echo "🚀 Creating Optimized Startup Script..."
echo "--------------------------------------"

cat > start-optimized-goose.sh << 'EOF'
#!/bin/bash

# Optimized Goose Startup Script
echo "Starting optimized Goose + Ollama setup..."

# Load Ollama optimizations
if [ -f "ollama-env.sh" ]; then
    source ollama-env.sh
    echo "✅ Loaded Ollama optimizations"
fi

# Ensure Ollama is running with optimizations
if ! pgrep ollama > /dev/null; then
    echo "🚀 Starting Ollama with optimizations..."
    ollama serve &
    sleep 3
fi

# Preload the MiniMax model for faster first response
echo "🧠 Preloading MiniMax model..."
echo "Loading..." | ollama run minimax-m2.7:cloud > /dev/null 2>&1 &

# Start Goose
echo "🪿 Starting Goose..."
cd "$(dirname "$0")"
goose session --name optimized-session

EOF

chmod +x start-optimized-goose.sh
print_status "Created optimized startup script: start-optimized-goose.sh"

# 7. Performance Monitoring
echo ""
echo "📊 Setting up Performance Monitoring..."
echo "--------------------------------------"

cat > monitor-performance.sh << 'EOF'
#!/bin/bash

# Performance monitoring script
echo "=== Goose + Ollama Performance Monitor ==="
echo "Press Ctrl+C to stop monitoring"
echo ""

while true; do
    clear
    echo "$(date): Performance Status"
    echo "=========================="
    
    # System resources
    echo "💾 System Resources:"
    echo "  CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)% usage"
    echo "  RAM: $(free -h | awk '/^Mem/ {print $3 "/" $2 " (" int($3/$2*100) "%)"}')"
    
    # GPU if available
    if command -v nvidia-smi &> /dev/null; then
        GPU_USAGE=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits)
        echo "  GPU: $GPU_USAGE"
    fi
    
    # Ollama specific
    echo ""
    echo "🦙 Ollama Status:"
    OLLAMA_MODELS=$(ollama ps | grep -v "NAME" | wc -l)
    echo "  Models loaded: $OLLAMA_MODELS"
    
    # Process info
    OLLAMA_PID=$(pgrep ollama)
    if [ ! -z "$OLLAMA_PID" ]; then
        OLLAMA_MEM=$(ps -p $OLLAMA_PID -o %mem --no-headers 2>/dev/null)
        echo "  Memory usage: ${OLLAMA_MEM}%"
    fi
    
    # API response time
    RESPONSE_TIME=$(curl -w "%{time_total}" -s -o /dev/null http://localhost:11434/api/version 2>/dev/null)
    echo "  API response: ${RESPONSE_TIME}s"
    
    echo ""
    echo "Press Ctrl+C to stop..."
    sleep 5
done
EOF

chmod +x monitor-performance.sh
print_status "Created performance monitoring: monitor-performance.sh"

echo ""
echo "============================================"
echo "🎉 OPTIMIZATION COMPLETE!"
echo "============================================"
echo ""
echo "📋 What was optimized:"
echo "  ✅ Ollama environment variables"
echo "  ✅ GPU-specific configurations"
echo "  ✅ Goose performance settings"
echo "  ✅ System service configuration"
echo "  ✅ Health check and monitoring tools"
echo ""
echo "🚀 Quick Start Commands:"
echo "  ./start-optimized-goose.sh  # Start with optimizations"
echo "  ./health-check.sh           # Check system health"
echo "  ./monitor-performance.sh    # Monitor performance"
echo ""
echo "📚 Optimization Files Created:"
echo "  • ollama-env.sh             # Environment variables"
echo "  • ollama.service            # Systemd service"
echo "  • health-check.sh           # System health check"
echo "  • monitor-performance.sh    # Performance monitor"
echo "  • start-optimized-goose.sh  # Optimized startup"
echo ""
echo "⚡ Performance Tips Applied:"
echo "  • Flash Attention enabled (NVIDIA)"
echo "  • KV cache quantization (Q8_0)"
echo "  • Extended context window (131K tokens)"
echo "  • GPU memory optimization (85% usage)"
echo "  • Parallel processing enabled"
echo "  • Request timeout optimization"
echo ""
print_warning "Restart Ollama to apply optimizations: sudo systemctl restart ollama"
echo ""