# Deployment Scripts

Docker and Kubernetes deployment configurations for the ML workstation.

## Services

| Service | Directory | Port(s) | Description |
|---|---|---|---|
| JupyterLab | `jupyterlab/` | 8080 | Scipy-notebook with custom extensions |
| Marimo | `marimo/` | 2718 | Reactive Python notebooks |
| Airflow | `airflow/` | 8080 | Workflow orchestration |
| AI Infra | `ai-infra/` | 11434, 4000, 3000 | Local LLM (Ollama) + proxy (LiteLLM) + chat UI (Open WebUI) |

## Shared Volume Layout

All services mount from the same NVMe directory tree. Nothing overlaps.

```
/mnt/m2-0/machine_learning/
├── data/        → ~/data     (jupyterlab, marimo)   Kaggle datasets, raw inputs
├── ml-projects/ → ~/projects (jupyterlab, marimo)   Notebooks and source code
├── output/      → ~/output   (jupyterlab, marimo)   Trained model checkpoints, results
└── llm-models/  → /root/.ollama (ollama only)       LLM weights — root-owned, isolated
```

`llm-models/` is intentionally separate from `output/` so Ollama's multi-GB weight
files never mix with ML project artifacts.

## Usage

Each service is self-contained. Navigate to the service directory and run:

```bash
docker compose up -d
```

**AI Infra** has a setup script that handles directory creation and model pulls:

```bash
cd ai-infra && ./infra.sh start
```

See each service's `README.md` for full setup details.

## VS Code Copilot Agent Mode

Start `ai-infra/` then add to VS Code `settings.json`:

```json
{
  "github.copilot.advanced": {
    "debug.overrideEngine": "gpt-4o",
    "debug.overrideProxyUrl": "http://localhost:4000",
    "debug.testOverrideProxyUrl": "http://localhost:4000"
  }
}
```

The LiteLLM proxy remaps `gpt-4o` → `qwen2.5-coder:32b` running locally on the RTX PRO 6000.
See [`ai-infra/README.md`](ai-infra/README.md) for model options and swap instructions.
