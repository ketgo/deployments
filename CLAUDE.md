# Deployments Repo

Infrastructure-as-code and deployment configurations for Docker and Kubernetes.

## Repo Structure

Each service lives in its own directory. Docker deployments follow this layout:

```
<service>/
├── docker-compose.yaml   # Compose stack definition
├── .env                  # Environment variable defaults (safe to commit)
├── Dockerfile            # Only if a custom image is needed
├── litellm_config.yaml   # Only for ai-infra — LiteLLM model routing config
└── README.md             # Service-specific setup and usage notes
```

Kubernetes configs go under `<service>/k8s/`.

## Volume Convention

All services share the same three host-path volume variables, set in each service's `.env`:

| Variable | Default container path | Purpose |
|---|---|---|
| `DATA_HOST_VOLUME` | `~/data` | Datasets, outputs |
| `PROJECTS_HOST_VOLUME` | `~/projects` | Source code / notebooks |
| `MODULES_HOST_VOLUME` | `~/modules` | Shared Python packages |

Always use these three vars. Don't invent new volume variables.

## Network Convention

Each compose file defines a single bridge network named `app_vnet` with an explicit external
name matching the service (e.g. `name: marimo`, `name: ai-infra`). This lets other stacks reach
the service by its name.

## Services

| Service | Directory | Port(s) | Notes |
|---|---|---|---|
| JupyterLab | `jupyterlab/` | 8080 | scipy-notebook base, custom extensions |
| Marimo | `marimo/` | 2718 | Reactive Python notebooks |
| Airflow | `airflow/` | 8080 | Workflow orchestration |
| AI Infra | `ai-infra/` | 11434 (Ollama), 4000 (LiteLLM), 3000 (Open WebUI) | Local LLM serving — VS Code Copilot Agent Mode compatible |

## Adding a New Service

1. Copy the closest existing service dir as a template.
2. Update the image, port, and network `name:`.
3. Keep `DATA_HOST_VOLUME`, `PROJECTS_HOST_VOLUME`, `MODULES_HOST_VOLUME` — don't rename them.
4. Mount `/var/run/docker.sock` if the container needs to spawn sibling containers.
5. Add a `README.md` covering: start command, volume setup, and how to use the service.

## Common Commands

```bash
# Start a stack (run from within its directory)
docker compose up -d

# Rebuild and start
docker compose up -d --build

# View logs
docker compose logs -f

# Stop
docker compose down
```

## GPU Note

`ai-infra` includes GPU passthrough via `deploy.resources.reservations.devices`.
Requires `nvidia-container-toolkit` on the host. Remove the `deploy` block if no GPU is present.

## VS Code Copilot Agent Mode

The `ai-infra` stack exposes a LiteLLM proxy on port 4000 that speaks the OpenAI API and remaps
`gpt-4o` → your chosen local Ollama model. Add this to VS Code `settings.json`:

```json
{
  "github.copilot.advanced": {
    "debug.overrideEngine": "gpt-4o",
    "debug.overrideProxyUrl": "http://localhost:4000",
    "debug.testOverrideProxyUrl": "http://localhost:4000"
  }
}
```

See `ai-infra/README.md` for model pull commands and full setup details.
