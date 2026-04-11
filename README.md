# Goose AI with Ollama Cloud Models

AI development environment using [Goose AI](https://github.com/aaif-goose/goose) with [Ollama](https://ollama.com) cloud models. No GPU needed — inference runs on Ollama's servers. Includes 31 auto-discovered skills for documents, web dev, mobile apps, creative design, and more.

## Quick Start

```bash
# Linux / WSL2
git clone https://github.com/kasjens/goose-ollama.git
cd goose-ollama
./setup.sh
./run-goose.sh
```

```powershell
# Windows (PowerShell)
git clone https://github.com/kasjens/goose-ollama.git
cd goose-ollama
.\setup.ps1
.\run-goose.ps1
```

Setup handles everything: Ollama, latest cloud models from ollama.com, Python venv, skills, Goose CLI, config, and optionally full ML/AI dependencies and Brave Search.

You'll be prompted to run `ollama signin` during setup — sign up free at [ollama.com](https://ollama.com).

After setup, use `goose-cloud` from **any directory**:

```bash
cd ~/my-project
goose-cloud                    # start a session in the current directory
goose-cloud --name my-project  # named session
```

---

## WSL2 Setup

If using WSL2 on Windows, first install Ubuntu from PowerShell (admin):

```powershell
wsl --install Ubuntu
```

Then open Ubuntu and follow the Linux instructions above. The setup script detects WSL2 automatically and handles:

- **Windows Ollama reuse** — if Ollama is already installed on Windows, setup skips the Linux install and uses it directly via the API
- **Networking** — detects `networkingMode` in `.wslconfig` and offers to switch from NAT to `mirrored` so WSL can reach Windows services on localhost
- **NTFS quirks** — creates Python venvs and clones git repos on the native Linux filesystem to avoid permission errors

**Prerequisites for WSL2 with Windows Ollama:**

1. Set `networkingMode=mirrored` in `C:\Users\<you>\.wslconfig`:
   ```ini
   [wsl2]
   networkingMode=mirrored
   ```
2. Restart WSL: `wsl --shutdown` and reopen your terminal

With mirrored networking, WSL shares the host network — `localhost:11434` reaches Windows Ollama directly. The setup script will guide you through this if needed.

**Note:** Do NOT set `OLLAMA_HOST=0.0.0.0` on Windows — this breaks the Goose Desktop UI and CLI. Mirrored networking is the correct solution.

---

## Cloud Models

Setup fetches the latest cloud models from [ollama.com/search?c=cloud](https://ollama.com/search?c=cloud) and lets you choose which to pull. It also removes any locally installed models that are no longer available upstream.

**Switch models:**

```bash
./switch-model.sh              # Linux / WSL2
.\switch-model.ps1             # Windows
```

Or edit `~/.config/goose/config.yaml`:

```yaml
GOOSE_MODEL: qwen3-coder:480b-cloud
```

**Pull more models** from [ollama.com/search?c=cloud](https://ollama.com/search?c=cloud):

```bash
ollama pull deepseek-v3.2:cloud
```

---

## Optional Add-ons

Setup asks about full dependencies and Brave Search during installation. You can also run them separately:

| Add-on | Linux / WSL2 | Windows |
|--------|-------------|---------|
| Full ML/AI stack (PyTorch, OpenCV, Node.js, FFmpeg) | `scripts/install-all-dependencies.sh` | `scripts\install-all-dependencies.ps1` |
| Brave Search web integration | `scripts/setup-brave-search.sh` | `scripts\setup-brave-search.ps1` |
| Goose Desktop UI (install) | `scripts/install-goose-ui.sh` | `scripts\install-goose-ui.ps1` |
| Goose Desktop UI (launch) | `scripts/run-goose-ui.sh` | `scripts\run-goose-ui.ps1` |

---

## Skills (31)

All skills are auto-discovered — just ask Goose naturally.

| Category | Skills |
|----------|--------|
| **Documents** | `pptx`, `pptx-generator`, `docx`, `minimax-docx`, `xlsx`, `minimax-xlsx`, `pdf`, `minimax-pdf` |
| **Mobile** | `ios-application-dev`, `android-native-dev`, `react-native-dev`, `flutter-dev` |
| **Creative** | `frontend-design`, `frontend-dev`, `algorithmic-art`, `canvas-design`, `gif-sticker-maker`, `slack-gif-creator` |
| **Dev Tools** | `claude-api`, `mcp-builder`, `webapp-testing`, `fullstack-dev`, `shader-dev`, `skill-creator` |
| **Communication** | `doc-coauthoring`, `internal-comms`, `vision-analysis`, `minimax-multimodal-toolkit` |
| **Web & Brand** | `web-artifacts-builder`, `theme-factory`, `brand-guidelines` |

Examples: "Create a PowerPoint about AI trends", "Build a Flutter app", "Search for React best practices"

---

## Project Structure

```
goose-ollama/
  setup.sh / setup.ps1              # Setup (detects WSL, Windows Ollama)
  run-goose.sh / run-goose.ps1     # Launch Goose CLI
  switch-model.sh / switch-model.ps1  # Switch cloud model
  validate.sh / validate.ps1       # Validate installation
  scripts/                         # Setup, run, and utility scripts
  config/                          # Config template, requirements
  .agents/skills/                  # 31 auto-discovered skills
  .goosehints                      # Project conventions for Goose
  brave-search-mcp/                # Brave Search MCP integration
  docs/                            # Best practices, web search guide
```

---

## Troubleshooting

**Ollama not running** — `ollama serve`

**Model not found** — `ollama pull qwen3.5:cloud`

**Cloud sign-in required** — `ollama signin`

**PowerShell scripts disabled** — `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

**Context window stuck at 0% / connection error on port 1234** — `OLLAMA_HOST` must include the port (e.g., `localhost:11434`). Without it, Goose falls back to port 1234 (LM Studio default). Re-run `./setup.sh` or manually set `OLLAMA_HOST: localhost:11434` in `~/.config/goose/config.yaml`.

**Stream stalls / "no data received for 30s"** — Too many extensions inflating the payload. Disable unused extensions in `config/goose-config-template.yaml` (keep `todo`, `developer`). See [docs/BEST-PRACTICES.md](docs/BEST-PRACTICES.md#stream-stalls-with-cloud-models) for details.

**WSL2 can't reach Windows Ollama** — Set `networkingMode=mirrored` in `.wslconfig`, then `wsl --shutdown` and reopen the terminal. See [WSL2 Setup](#wsl2-setup) above.

**Skills missing in Desktop UI** — Verify `~/.agents` symlink exists and points to the project's `.agents/` directory.

**Python venv fails on WSL2** — Delete and re-run: `rm -rf ~/.local/share/goose-ollama/venv && ./setup.sh`

See [docs/BEST-PRACTICES.md](docs/BEST-PRACTICES.md) for model selection, performance tuning, and monitoring.
