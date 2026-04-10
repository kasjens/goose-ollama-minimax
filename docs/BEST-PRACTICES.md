# Best Practices Guide: Goose + Ollama Cloud Models

## Overview
This guide documents enterprise-grade best practices for setting up and optimizing a local AI development environment using Goose, Ollama, and MiniMax models.

## 🏗️ Architecture Best Practices

### Hardware Requirements

#### Minimum Requirements
- **CPU**: 4 cores, 3.0GHz+
- **RAM**: 16GB (8GB for OS, 8GB for models)
- **Storage**: 50GB free space (SSD preferred)
- **Network**: Stable internet for initial setup

#### Recommended Configuration
- **CPU**: 8+ cores, 3.5GHz+
- **RAM**: 32GB+ (allows multiple models, larger context)
- **GPU**: NVIDIA RTX 4060+ (8GB VRAM) or equivalent
- **Storage**: 100GB+ NVMe SSD
- **Network**: High-speed for model downloads

#### Optimal Configuration
- **CPU**: 12+ cores, 4.0GHz+
- **RAM**: 64GB+ (enterprise workloads)
- **GPU**: RTX 4080+ (16GB+ VRAM) or A6000 (48GB VRAM)
- **Storage**: 500GB+ NVMe SSD
- **Network**: Dedicated bandwidth

### Model Selection Strategy

#### By Hardware Tier

**8GB VRAM / 16GB RAM:**
```yaml
Primary: qwen3.5:cloud (lightweight)
Secondary: qwen2.5:7b
Avoid: Models >10B parameters
```

**16GB VRAM / 32GB RAM:**
```yaml
Primary: qwen3.5:cloud
Secondary: llama3.1:13b, qwen2.5:14b
Experimental: gemma2:27b
```

**24GB+ VRAM / 64GB+ RAM:**
```yaml
Primary: Any model up to 70B
Multiple: Run 2-3 models simultaneously
Specialized: Code-specific models (deepseek-coder)
```

## ⚡ Performance Optimization

### Ollama Optimization

#### Core Environment Variables
```bash
# GPU Memory Management
export OLLAMA_GPU_MEMORY_FRACTION=0.85    # Use 85% of GPU memory

# Flash Attention (NVIDIA only)
export OLLAMA_FLASH_ATTENTION=1           # Enables Flash Attention

# KV Cache Optimization
export OLLAMA_KV_CACHE_TYPE=q8_0          # Quantize KV cache (50% memory reduction)

# Context Window
export OLLAMA_CONTEXT_LENGTH=131072       # Extended context (131K tokens)

# Concurrency
export OLLAMA_NUM_PARALLEL=2              # Parallel requests
export OLLAMA_MAX_LOADED_MODELS=2         # Models in memory

# Performance
export OLLAMA_LOAD_TIMEOUT=300            # Model loading timeout
export OLLAMA_MAX_QUEUE=10                # Request queue size
```

#### GPU-Specific Optimizations

**NVIDIA Configuration:**
```bash
export CUDA_VISIBLE_DEVICES=0             # Use primary GPU
export NVIDIA_VISIBLE_DEVICES=0           # Explicit GPU selection
```

**AMD ROCm Configuration:**
```bash
export HSA_OVERRIDE_GFX_VERSION=10.3.0    # ROCm compatibility
export OLLAMA_GPU_DRIVER=rocm             # Use ROCm driver
```

**CPU-Only Fallback:**
```bash
export OLLAMA_NUM_THREAD=8                # CPU thread count
export OLLAMA_GPU_LAYERS=0                # Disable GPU offloading
```

### Goose Optimization

#### Configuration Parameters
```yaml
# Performance Settings
GOOSE_CONTEXT_SIZE: 32768                 # Context window
GOOSE_MAX_TOOL_REPETITIONS: 5             # Tool call limits
GOOSE_MAX_TURNS: 20                       # Conversation turns
GOOSE_REQUEST_TIMEOUT: 300                # Request timeout

# Memory Management
GOOSE_CACHE_SIZE: 1000                    # Response cache
GOOSE_HISTORY_LIMIT: 100                  # History retention

# Ollama Integration
OLLAMA_REQUEST_TIMEOUT: 180               # Ollama-specific timeout
OLLAMA_KEEP_ALIVE: 300                    # Keep model loaded
```

## 🔧 System Configuration

### System Service Setup

#### Systemd Service (Linux)
```ini
[Unit]
Description=Ollama Large Language Model Service
After=network.target

[Service]
Type=simple
User=your-user
Group=your-group
ExecStart=/usr/local/bin/ollama serve
Restart=always
RestartSec=3
Environment="OLLAMA_GPU_MEMORY_FRACTION=0.85"
Environment="OLLAMA_FLASH_ATTENTION=1"

[Install]
WantedBy=multi-user.target
```

#### Startup Script Best Practices
```bash
#!/bin/bash
# Production startup script

# Load environment
source ollama-env.sh

# Verify GPU availability
nvidia-smi > /dev/null 2>&1 || echo "Warning: No NVIDIA GPU detected"

# Start Ollama with logging
ollama serve 2>&1 | tee -a ollama.log &

# Preload critical models
sleep 5
ollama run qwen3.5:cloud "warmup" > /dev/null 2>&1 &

# Start Goose
goose session --name production
```

## 🛡️ Security Best Practices

### API Key Management

#### Environment Variables
```bash
# Use .env files (never commit)
echo 'MINIMAX_API_KEY=your-key' > .env
echo 'BRAVE_API_KEY=your-key' >> .env
chmod 600 .env
```

#### .gitignore Configuration
```gitignore
# API Keys and Secrets
.env
*.env
.env.*

# Virtual Environments
venv/
__pycache__/

# Model Files (large)
*.gguf
*.bin
models/

# Logs
*.log
logs/

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db
```

### Network Security

#### Firewall Configuration
```bash
# Allow Ollama on localhost only
sudo ufw allow from 127.0.0.1 to any port 11434
sudo ufw deny 11434

# Or for LAN access
sudo ufw allow from 192.168.1.0/24 to any port 11434
```

#### HTTPS Proxy (Production)
```nginx
server {
    listen 443 ssl;
    server_name ai.yourdomain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:11434;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 📊 Monitoring and Maintenance

### Health Checks

#### Automated Monitoring
```bash
#!/bin/bash
# health-monitor.sh - Run every 5 minutes via cron

# Check Ollama API
if ! curl -s http://localhost:11434/api/version > /dev/null; then
    echo "$(date): Ollama API down" | tee -a monitor.log
    systemctl restart ollama
fi

# Check GPU memory
if command -v nvidia-smi; then
    GPU_MEM=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
    if [ $GPU_MEM -gt 15000 ]; then  # Alert if >15GB used
        echo "$(date): High GPU memory usage: ${GPU_MEM}MB" | tee -a monitor.log
    fi
fi

# Check disk space
DISK_USAGE=$(df -h . | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 90 ]; then
    echo "$(date): High disk usage: ${DISK_USAGE}%" | tee -a monitor.log
fi
```

#### Cron Configuration
```bash
# Add to crontab -e
*/5 * * * * /path/to/health-monitor.sh
0 2 * * * /path/to/cleanup-logs.sh
0 3 * * 0 /path/to/weekly-maintenance.sh
```

### Performance Monitoring

#### Key Metrics
- **Token Generation Speed**: Target 10+ tokens/second
- **Memory Usage**: GPU <85%, System RAM <80%
- **Response Latency**: First token <2s, subsequent <100ms
- **Model Loading Time**: <30s for 7B models
- **API Response Time**: <500ms for health checks

#### Monitoring Script
```bash
#!/bin/bash
# monitor-performance.sh

while true; do
    # Response time test
    RESPONSE_TIME=$(curl -w "%{time_total}" -s -o /dev/null \
        -H "Content-Type: application/json" \
        -d '{"model":"qwen3.5:cloud","prompt":"test","stream":false}' \
        http://localhost:11434/api/generate)
    
    echo "$(date): API Response Time: ${RESPONSE_TIME}s"
    
    # Log if slow
    if (( $(echo "$RESPONSE_TIME > 2.0" | bc -l) )); then
        echo "$(date): Slow response detected: ${RESPONSE_TIME}s" >> slow-responses.log
    fi
    
    sleep 60
done
```

## 🔄 Maintenance Procedures

### Regular Maintenance

#### Weekly Tasks
```bash
#!/bin/bash
# weekly-maintenance.sh

# Update models
echo "Checking for model updates..."
ollama list | grep -v "NAME" | awk '{print $1}' | while read model; do
    ollama pull $model
done

# Clean old logs
find . -name "*.log" -mtime +7 -delete

# Vacuum model cache
ollama prune

# System updates
if command -v apt; then
    sudo apt update && sudo apt upgrade -y
fi

# Restart services
sudo systemctl restart ollama
sleep 5
./health-check.sh
```

#### Monthly Tasks
- Review and rotate API keys
- Update Goose and dependencies
- Backup configuration files
- Performance baseline testing
- Security audit

### Backup Strategy

#### Configuration Backup
```bash
#!/bin/bash
# backup-config.sh

BACKUP_DIR="backups/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Goose configuration
cp -r ~/.config/goose/ $BACKUP_DIR/

# Project configuration
cp .env $BACKUP_DIR/ 2>/dev/null || echo "No .env file"
cp *.yaml $BACKUP_DIR/
cp *.sh $BACKUP_DIR/
cp *.md $BACKUP_DIR/

# Skills (lightweight)
tar czf $BACKUP_DIR/skills.tar.gz */skills/ --exclude="*.git*"

echo "Backup created in $BACKUP_DIR"
```

## 🚀 Production Deployment

### Docker Configuration

#### Dockerfile
```dockerfile
FROM nvidia/cuda:12.0-runtime-ubuntu22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    python3 \
    python3-pip \
    nodejs \
    npm \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Install Goose
RUN curl -fsSL https://install.goose.run | sh

# Copy project
COPY . /app
WORKDIR /app

# Install dependencies
RUN pip3 install -r requirements.txt
RUN npm install

# Start services
CMD ["./start-production.sh"]
```

#### Docker Compose
```yaml
version: '3.8'

services:
  goose-ollama:
    build: .
    ports:
      - "11434:11434"
    environment:
      - OLLAMA_GPU_MEMORY_FRACTION=0.85
      - OLLAMA_FLASH_ATTENTION=1
    volumes:
      - ./data:/data
      - ./models:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

### Kubernetes Deployment

#### Resource Limits
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: goose-ollama
spec:
  containers:
  - name: goose-ollama
    image: your-registry/goose-ollama:latest
    resources:
      requests:
        memory: "16Gi"
        nvidia.com/gpu: 1
      limits:
        memory: "32Gi"
        nvidia.com/gpu: 1
    env:
    - name: OLLAMA_GPU_MEMORY_FRACTION
      value: "0.85"
```

## 📈 Scaling Considerations

### Multi-Model Setup
```bash
# Load balancing between models
export OLLAMA_MODELS="qwen3.5:cloud,qwen3.5:9b"
export OLLAMA_LOAD_BALANCE=true
```

### Distributed Deployment
- Use Ollama clusters for high availability
- Implement model routing based on task type
- Set up monitoring and alerting
- Plan for horizontal scaling

## 🔍 Troubleshooting Guide

### Common Issues

#### Stream Stalls with Cloud Models
The error "Ollama stream stalled: no data received for 30s" means the model is overwhelmed by the request payload. The 30s timeout is hardcoded in Goose ([aaif-goose/goose#7635](https://github.com/aaif-goose/goose/issues/7635)).

**Fixes (in priority order):**

1. **Reduce enabled extensions** — Each extension adds tool definitions to every request. In `config/goose-config-template.yaml`, keep only `todo` and `developer` enabled. Disable everything else (`apps`, `analyze`, `extensionmanager`, `tom`, `summon`, `code_execution`) unless actively needed. This minimizes the tool definition payload.

2. **Set performance environment variables** (already added to run scripts):
```bash
export GOOSE_REQUEST_TIMEOUT=300      # Request timeout (seconds)
export OLLAMA_KEEP_ALIVE=300          # Keep model loaded (seconds)
export OLLAMA_CONTEXT_LENGTH=32768    # Context window size
```

3. **Break large outputs into smaller steps** — Use `.goosehints` to instruct the model to never generate files longer than 200 lines in a single response and to split large tasks into sequential steps.

4. **Try a faster cloud model** — `deepseek-v3.2:cloud` has faster time-to-first-token than `qwen3.5:cloud` and is less likely to trigger the 30s stall.

5. **Enable `code_execution` extension** — Described as "saving tokens" by having the model write code instead of using tool schemas. Can reduce payload overhead.

**Known bug:** [aaif-goose/goose#6117](https://github.com/aaif-goose/goose/issues/6117) — Goose sends tool definitions even in chat mode during streaming, inflating payloads unnecessarily.

#### High Memory Usage
```bash
# Check model memory usage
ollama ps
nvidia-smi

# Solutions
export OLLAMA_GPU_MEMORY_FRACTION=0.75  # Reduce GPU usage
export OLLAMA_MAX_LOADED_MODELS=1       # Limit loaded models
```

#### Slow Response Times
```bash
# Enable Flash Attention (NVIDIA)
export OLLAMA_FLASH_ATTENTION=1

# Optimize KV cache
export OLLAMA_KV_CACHE_TYPE=q8_0

# Check GPU utilization
nvidia-smi -l 1
```

#### Model Loading Failures
```bash
# Check disk space
df -h

# Verify model integrity
ollama show qwen3.5:cloud

# Re-pull if corrupted
ollama rm qwen3.5:cloud
ollama pull qwen3.5:cloud
```

## WSL2 with Windows Ollama

### How It Works

When running Goose in WSL2 with Ollama installed on Windows, all scripts communicate with Ollama via its HTTP API (`localhost:11434`) instead of the CLI. This means:

- No Ollama installation needed inside WSL
- Cloud sign-in, model pulling, and model switching all work through the Windows Ollama instance
- Goose in WSL connects to the same models you use on Windows

### Network Configuration

WSL2 runs in a separate virtual network. By default (`networkingMode=NAT`), WSL cannot reach Windows services on `localhost`. The fix is to enable mirrored networking:

In `C:\Users\<you>\.wslconfig`:
```ini
[wsl2]
networkingMode=mirrored
```
Then restart WSL: `wsl --shutdown`

With mirrored networking, WSL shares the host network stack and `localhost` works bidirectionally. The setup script detects this and offers to fix it automatically.

**Important:** Do NOT set `OLLAMA_HOST=0.0.0.0` on Windows — this breaks the Goose Desktop UI and CLI, which interpret it as a connection target rather than a listen address. Mirrored networking is the correct solution.

### Fallback: Gateway IP

If mirrored networking is not an option, the scripts also try the WSL gateway IP (found via `ip route show default`). This requires Ollama to listen on all interfaces, but setting `OLLAMA_HOST` system-wide causes issues. As a temporary workaround, start Ollama manually with: `$env:OLLAMA_HOST='0.0.0.0'; ollama serve`

### NTFS Limitations

Scripts running on `/mnt/c` (Windows NTFS) have these known issues:
- `sed -i` (in-place edit) fails silently — scripts use temp files as a workaround
- `git clone` fails with `chmod` errors — setup clones into `/tmp` (native ext4)
- Python venvs break on NTFS — setup creates them at `~/.local/share/goose-ollama/venv`
- `read -n 1` can behave inconsistently — scripts use full-line reads with `</dev/tty`

## 📚 Additional Resources

### Documentation Links
- [Ollama Documentation](https://github.com/ollama/ollama)
- [Goose Documentation](https://github.com/aaif-goose/goose)
- [MiniMax API Docs](https://platform.minimaxi.com/docs)
- [Flash Attention Paper](https://arxiv.org/abs/2307.08691)

### Community Resources
- [Ollama Discord](https://discord.gg/ollama)
- [Goose GitHub Discussions](https://github.com/aaif-goose/goose/discussions)
- [MiniMax Developer Community](https://developers.minimaxi.com/)

### Performance Benchmarks
- Token generation speed tests
- Memory usage profiles
- Latency measurements
- Throughput comparisons

---

*This guide is updated based on the latest research and best practices as of 2025. Refer to official documentation for the most current information.*