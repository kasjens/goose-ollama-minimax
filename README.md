# Goose AI with Ollama Cloud Models and 31 Skills

An AI development environment using [Goose AI](https://github.com/block/goose) with [Ollama](https://ollama.com) cloud models. Includes 31 auto-discovered skills for document creation, web development, mobile apps, creative design, and more. Integrated with [Brave Search](https://brave.com/search/api/) for web search.

Works on **Windows 11 (native PowerShell)**, **WSL2 Ubuntu**, and **standalone Ubuntu**.

---

## Prerequisites: Ollama Account (Free)

Before installing, sign up for a free Ollama account to access cloud models:

1. Go to [ollama.com](https://ollama.com) and click **Sign Up**
2. Create an account (email or GitHub)
3. The free tier includes access to cloud models like `minimax-m2.7:cloud`, `deepseek-v3.1:671b`, `qwen3-coder:480b`, and more
4. Free tier has usage limits that reset every 5 hours (session) and 7 days (weekly)
5. No GPU or powerful hardware needed - cloud models run on Ollama's servers

During setup, you'll be prompted to run `ollama signin` which links your local install to your account.

See [Ollama Cloud pricing](https://ollama.com/pricing) for plan details.

---

## Installation Guide

### Option A: Windows 11 (Native PowerShell)

This installs everything natively on Windows - no WSL or Linux needed.

**Prerequisites**: Windows 11 with PowerShell 5.1+ and [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) (included in Windows 11).

**Step 1: Clone the repository**

```powershell
cd C:\Users\$env:USERNAME\Projects
git clone https://github.com/kasjens/goose-ollama.git
cd goose-ollama
```

**Step 2: Allow PowerShell scripts** (one-time)

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Step 3: Run setup**

```powershell
.\setup.ps1
```

This will:
- Install Python and Git (via winget, if missing)
- Install Ollama (via official PowerShell installer)
- Start the Ollama service
- Prompt you to sign in to Ollama cloud (`ollama signin`)
- Pull 3 cloud models (Qwen 3.5, Gemma 4, MiniMax M2.7)
- Create a Python virtual environment with core dependencies
- Clone and integrate 31 skills
- Install the Goose AI CLI
- Create the Goose config file

**Step 4: Run Goose**

```powershell
.\run-goose.ps1
```

**Step 5: Validate** (optional)

```powershell
.\validate.ps1
```

**Step 6: Install extras** (optional)

```powershell
# Full ML/AI stack (PyTorch, OpenCV, Node.js via fnm, FFmpeg, etc.)
scripts\setup\install-all-dependencies.ps1

# Brave Search web integration (free API key)
scripts\setup\setup-brave-search.ps1

# Goose Desktop UI
scripts\setup\install-goose-ui.ps1
```

---

### Option B: WSL2 Ubuntu (on Windows)

Run Goose inside WSL2 with full Linux compatibility.

**Step 1: Install WSL2 and Ubuntu** (from PowerShell as Admin)

```powershell
wsl --install Ubuntu
```

Follow the prompts to create a Linux username and password.

**Step 2: Open Ubuntu and clone the repository**

```bash
cd /mnt/c/Users/$USER/Projects
git clone https://github.com/kasjens/goose-ollama.git
cd goose-ollama
```

Or if the repo is already cloned on Windows:

```bash
cd /mnt/c/Users/$USER/Projects/goose-ollama
```

**Step 3: Run setup**

```bash
./setup.sh
```

This will:
- Install system packages (zstd, bzip2, libgomp1, python3-venv, git, curl)
- Install Ollama
- Start the Ollama service
- Prompt you to sign in to Ollama cloud (`ollama signin`)
- Pull 3 cloud models (Qwen 3.5, Gemma 4, MiniMax M2.7)
- Create a Python venv in the native Linux filesystem (avoids NTFS issues)
- Clone and integrate 31 skills
- Install the Goose AI CLI (Linux binary, avoids WSL2 misdetection)
- Create a `~/.agents` symlink for Desktop UI skill discovery

**Step 4: Run Goose**

```bash
./run-goose.sh
```

**Step 5: Validate** (optional)

```bash
./validate.sh
```

**Step 6: Install extras** (optional)

```bash
# Full ML/AI stack (PyTorch, OpenCV, Node.js, FFmpeg, etc.)
scripts/setup/install-all-dependencies.sh

# Brave Search web integration (free API key)
scripts/setup/setup-brave-search.sh

# Goose Desktop UI (Linux GUI via WSL2)
scripts/setup/install-goose-ui.sh
```

---

### Option C: Standalone Ubuntu (no Windows)

Same as WSL2 but on a native Ubuntu machine or VM.

```bash
git clone https://github.com/kasjens/goose-ollama.git
cd goose-ollama
./setup.sh
./run-goose.sh
```

Everything works the same as WSL2, except the Python venv is created in the project directory (`./venv/`) instead of `~/.local/share/`.

---

## Cloud Models

Setup pulls 5 cloud models automatically. No GPU or large downloads needed - inference runs on Ollama's servers.

| Model | Default | Vision | Best For |
|-------|---------|--------|----------|
| `qwen3.5:cloud` | Yes | Yes | General purpose, multimodal (images + text) |
| `qwen3-coder:480b-cloud` | | No | Coding (#1 on SWE-bench, 480B params) |
| `deepseek-v3.1:671b-cloud` | | No | Coding & reasoning (671B params) |
| `gemma4:31b-cloud` | | Yes | Large context (256K), multimodal |
| `minimax-m2.7:cloud` | | No | Balanced text generation |

**Switch models** in the Goose Desktop UI via Settings, or edit the config file:

```yaml
# ~/.config/goose/config.yaml (WSL2/Ubuntu)
# %USERPROFILE%\.config\goose\config.yaml (Windows)
GOOSE_MODEL: qwen3-coder:480b-cloud
```

**Pull additional models** from [ollama.com/search?c=cloud](https://ollama.com/search?c=cloud):

```bash
ollama pull llama4-maverick:cloud
ollama pull phi-4:cloud
```

---

## Desktop UI Setup

The Goose Desktop app provides a graphical interface as an alternative to the CLI.

### Install

```powershell
# Windows
scripts\setup\install-goose-ui.ps1
```

```bash
# WSL2 / Ubuntu
scripts/setup/install-goose-ui.sh
```

### First Launch

When you open the Desktop app for the first time:
1. Select **Use Free/Local Providers**
2. Choose **Ollama** and select `minimax-m2.7:cloud`

### Add Brave Search to Desktop UI

MCP extensions (like Brave Search) must be added through the Desktop UI settings - they cannot be configured via the config file.

1. Open Goose Desktop > **Settings** (gear icon) > **Extensions**
2. Click **Add custom extension**
3. Fill in:
   - **Name**: `brave-search`
   - **Type**: `STDIO`
   - **Command**: `npx -y @brave/brave-search-mcp-server`
4. Add environment variable: `BRAVE_API_KEY` = your key
5. Click **Add Extension**
6. Start a **new chat session**

Get a free API key (2,000 queries/month) at [brave.com/search/api](https://brave.com/search/api/)

### Skills in Desktop UI

The Desktop UI discovers skills from `.agents/skills/` in your home directory. The setup scripts create a symlink/junction automatically:

- **Windows**: Junction at `%USERPROFILE%\.agents\`
- **WSL2/Ubuntu**: Symlink at `~/.agents`

If skills don't appear, verify the link exists and points to the project's `.agents/` directory.

---

## Available Skills (31)

All skills are **auto-discovered** by Goose - just ask naturally and the right skill activates.

| Category | Skills |
|----------|--------|
| **Document Processing** | `pptx`, `pptx-generator`, `docx`, `minimax-docx`, `xlsx`, `minimax-xlsx`, `pdf`, `minimax-pdf` |
| **Mobile Development** | `ios-application-dev`, `android-native-dev`, `react-native-dev`, `flutter-dev` |
| **Creative & Design** | `frontend-design`, `frontend-dev`, `algorithmic-art`, `canvas-design`, `gif-sticker-maker`, `slack-gif-creator` |
| **Development Tools** | `claude-api`, `mcp-builder`, `webapp-testing`, `fullstack-dev`, `shader-dev`, `skill-creator` |
| **Communication** | `doc-coauthoring`, `internal-comms`, `vision-analysis`, `minimax-multimodal-toolkit` |
| **Web & Branding** | `web-artifacts-builder`, `theme-factory`, `brand-guidelines` |

---

## Usage Examples

Just ask Goose naturally:

- "Create a PowerPoint about AI trends"
- "Build a landing page with animations"
- "Search for latest React best practices"
- "Help me create a Flutter app"
- "Generate a Word document with a table of contents"
- "Analyze this image"
- "Create an Excel spreadsheet from this data"

---

## Project Structure

```
goose-ollama/
+-- .agents/skills/          # 31 auto-discovered skills
+-- config/                  # requirements, config template
+-- scripts/
|   +-- setup/               # installation scripts (.sh + .ps1)
|   +-- run/                 # launcher scripts
|   +-- utils/               # validation, maintenance
+-- brave-search-mcp/        # Brave Search integration
+-- setup.sh                 # WSL2/Ubuntu setup (symlink)
+-- setup.ps1                # Windows setup
+-- run-goose.sh             # WSL2/Ubuntu launcher (symlink)
+-- run-goose.ps1            # Windows launcher
+-- validate.sh              # WSL2/Ubuntu validation (symlink)
+-- validate.ps1             # Windows validation
```

## Key Paths

| What | Windows | WSL2 / Ubuntu |
|------|---------|---------------|
| Python venv | `.\venv\` | `~/.local/share/goose-ollama/venv` |
| Goose CLI | `%LOCALAPPDATA%\Programs\goose\` | `~/.local/bin/goose` |
| Goose config | `%USERPROFILE%\.config\goose\config.yaml` | `~/.config/goose/config.yaml` |
| Skills | `.agents\skills\` + junction in `%USERPROFILE%` | `.agents/skills/` + symlink in `~` |

---

## Troubleshooting

**PowerShell: "running scripts is disabled"**
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Ollama not running**
- Windows: Check Services (`services.msc`) for "Ollama", or run `ollama serve`
- WSL2/Ubuntu: Run `ollama serve` in a terminal

**Model not found**
```
ollama pull minimax-m2.7:cloud
```

**Ollama cloud sign-in required**
```
ollama signin
```

**Skills not found in Desktop UI**
Verify the junction/symlink exists:
```powershell
# Windows
dir $env:USERPROFILE\.agents\skills\
```
```bash
# WSL2/Ubuntu
ls ~/.agents/skills/
```
If missing, recreate:
```powershell
# Windows
cmd /c mklink /J $env:USERPROFILE\.agents $PWD\.agents
```
```bash
# WSL2/Ubuntu
ln -s $(pwd)/.agents ~/.agents
```

**Brave Search not working in Desktop UI**
Must be added through the Desktop UI Settings > Extensions (not the config file). See [Desktop UI Setup](#add-brave-search-to-desktop-ui) above.

**Node.js install fails (corporate policy)**
The `install-all-dependencies` script uses [fnm](https://github.com/Schniz/fnm) on Windows (no admin needed) or NodeSource on Ubuntu.

**Python venv fails on WSL2**
The setup script creates the venv in the native Linux filesystem (`~/.local/share/...`) to avoid NTFS compatibility issues. If you see venv errors, delete and re-run:
```bash
rm -rf ~/.local/share/goose-ollama/venv
./setup.sh
```
