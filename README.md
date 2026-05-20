# Deployment Scripts

Docker and Kubernetes deployment configurations.

## Services

| Service | Directory | Port(s) | Description |
|---|---|---|---|
| JupyterLab | `jupyterlab/` | 8080 | Scipy-notebook with custom extensions |
| Marimo | `marimo/` | 2718 | Reactive Python notebooks |
| Airflow | `airflow/` | 8080 | Workflow orchestration |
| AI Infra | `ai-infra/` | 11434, 4000, 3000 | Local LLM (Ollama) + proxy (LiteLLM) + chat UI (Open WebUI) |

## Usage

Each service is self-contained. Navigate to the service directory and run:

```bash
docker compose up -d
```

See each service's `README.md` for first-time setup, volume paths, and usage details.

## VS Code Copilot Agent Mode with local LLMs

Start `ai-infra/` and follow the setup in [`ai-infra/README.md`](ai-infra/README.md).
The LiteLLM proxy on port 4000 makes Copilot Agent Mode work with models running on your own machine.
