# AI Infra — Local LLM Stack

Three-service stack for running LLMs locally:

| Service | URL | Purpose |
|---|---|---|
| **Ollama** | http://localhost:11434 | Model runner (downloads + serves models) |
| **LiteLLM** | http://localhost:4000 | OpenAI-compatible proxy — use this from VS Code |
| **Open WebUI** | http://localhost:3000 | Chat UI (talks to LiteLLM) |

## Requirements

- Docker + Docker Compose v2
- NVIDIA GPU (optional but recommended): install [`nvidia-container-toolkit`](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)

## First-time setup

```bash
# Create data directories
sudo mkdir -p /data/ollama /data/ai-infra
sudo chown $USER /data/ollama /data/ai-infra

# Pull the models used in litellm_config.yaml
docker exec -it ollama ollama pull qwen2.5-coder:7b   # used as gpt-4o alias
docker exec -it ollama ollama pull llama3.2            # general chat
```

## Start

```bash
docker compose up -d
```

## VS Code Copilot Agent Mode

The LiteLLM proxy maps the model name `gpt-4o` (what Copilot requests) to your local
`qwen2.5-coder:7b`. This means Copilot completions, Copilot Chat, and **Agent Mode**
all run on-device with no cloud calls.

### 1. Install the GitHub Copilot extension (requires a Copilot subscription)

### 2. Add to VS Code `settings.json`

Open the Command Palette → **Preferences: Open User Settings (JSON)** and add:

```json
{
  "github.copilot.advanced": {
    "debug.overrideEngine": "gpt-4o",
    "debug.overrideProxyUrl": "http://localhost:4000",
    "debug.testOverrideProxyUrl": "http://localhost:4000"
  }
}
```

### 3. Use Agent Mode

Open Copilot Chat (`Ctrl+Shift+I`), switch the dropdown from **Ask** to **Agent**, then
give it a task. It will plan, edit files, run terminal commands, and iterate — all
powered by your local model.

### Swap the local model

Edit `litellm_config.yaml` and change the `ollama/*` model under the `gpt-4o` alias,
then restart:

```bash
docker compose restart litellm
```

Good choices for agent mode (require tool-calling support):

| Model | Pull command | VRAM | Notes |
|---|---|---|---|
| `qwen2.5-coder:7b` | `ollama pull qwen2.5-coder:7b` | ~5 GB | Fast, great for code |
| `qwen2.5-coder:32b` | `ollama pull qwen2.5-coder:32b` | ~20 GB | Best code quality |
| `llama3.1:8b` | `ollama pull llama3.1:8b` | ~5 GB | General purpose |
| `deepseek-r1:8b` | `ollama pull deepseek-r1:8b` | ~5 GB | Strong reasoning |
| `mistral-nemo` | `ollama pull mistral-nemo` | ~7 GB | Tool calling, multilingual |

## No GPU?

Remove the `deploy` block from the `ollama` service in `docker-compose.yaml`:

```yaml
# Delete these lines from the ollama service:
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

CPU inference works but is significantly slower.

## Volumes

| Variable | Default | Container path | Purpose |
|---|---|---|---|
| `OLLAMA_DATA_HOST_VOLUME` | `/data/ollama` | `/root/.ollama` | Downloaded model weights |
| `PROJECTS_HOST_VOLUME` | `$HOME/Projects` | `~/projects` | Source code |
| `DATA_HOST_VOLUME` | `/data/ai-infra` | `~/data` | Datasets |

## Stopping

```bash
docker compose down
```
