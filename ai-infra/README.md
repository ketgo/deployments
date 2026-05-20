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

## Start

```bash
./infra.sh start
```

This creates `/mnt/m2-0/machine_learning/llm-models/`, starts all three services, waits for
Ollama to be ready, then pulls the models listed in `infra.sh`.

Other commands:

```bash
./infra.sh stop     # docker compose down
./infra.sh pull     # re-pull / update models (stack must be running)
./infra.sh status   # show containers and loaded models
```

## Volumes

| Variable | Host path | Container path | Purpose |
|---|---|---|---|
| `OLLAMA_DATA_HOST_VOLUME` | `/mnt/m2-0/machine_learning/llm-models` | `/root/.ollama` | LLM weight files |
| `PROJECTS_HOST_VOLUME` | `/mnt/m2-0/machine_learning/ml-projects` | `~/projects` | Notebooks / source code |
| `DATA_HOST_VOLUME` | `/mnt/m2-0/machine_learning/data` | `~/data` | Datasets |

`llm-models/` is intentionally separate from `machine_learning/output/` (where notebooks
save trained model artifacts) so Ollama's multi-GB weight files don't mix with project outputs.

## VS Code Copilot Agent Mode

The LiteLLM proxy maps `gpt-4o` (what Copilot requests) to `qwen2.5-coder:32b` running
locally. Copilot completions, Chat, and Agent Mode all run on-device with no cloud calls.

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

### Swap the active model

Edit `litellm_config.yaml` and change the `ollama/*` model under the `gpt-4o` alias,
then restart LiteLLM:

```bash
docker compose restart litellm
```

## Models (RTX PRO 6000 Blackwell — 96 GB VRAM)

| Model | VRAM Q4 | VRAM Q8 | Use case |
|---|---|---|---|
| `qwen2.5-coder:32b` | ~19 GB | ~34 GB | **Default** — code, tool calling, Agent Mode |
| `llama3.3:70b` | ~42 GB | ~74 GB | General reasoning, chat |
| `deepseek-r1:70b` | ~42 GB | ~74 GB | Multi-step planning, reasoning |
| `qwen2.5:72b` | ~46 GB | ~76 GB | General chat at 70B scale |

`qwen2.5-coder:32b` + `llama3.3:70b` fit simultaneously at Q4 (~61 GB combined).

Q8 is near-fp16 quality and fits on this machine — recommended:

```bash
docker exec -it ollama ollama pull qwen2.5-coder:32b:q8_0
```

Pull commands for all configured models are in `infra.sh` under `MODELS=(...)`.

## No GPU?

Remove the `deploy` block from the `ollama` service in `docker-compose.yaml`:

```yaml
# Delete these lines:
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

CPU inference works but is significantly slower.

## Stopping

```bash
./infra.sh stop
```
