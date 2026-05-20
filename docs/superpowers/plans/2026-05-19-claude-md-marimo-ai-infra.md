# CLAUDE.md + Marimo + AI-Infra Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Set up Claude agent scaffolding (CLAUDE.md), add a Marimo notebook deployment matching existing volume/network conventions, and create an `ai-infra` folder for local LLM serving (Ollama + Open WebUI) with VS Code integration.

**Architecture:** Three independent deliverables sharing the same docker network/volume pattern used by `jupyterlab/` — each service gets its own subdirectory with `docker-compose.yaml`, `.env`, and `README.md`. The `ai-infra` stack runs Ollama as the LLM backend and Open WebUI as the chat frontend; VS Code connects via the Continue extension pointing at Ollama's OpenAI-compatible API on `localhost:11434`.

**Tech Stack:** Docker Compose v3.8, Marimo (`ghcr.io/marimo-team/marimo`), Ollama (`ollama/ollama`), Open WebUI (`ghcr.io/open-webui/open-webui`), Python 3.11

---

## Existing Conventions (read before touching anything)

| Pattern | Example |
|---|---|
| Per-service dir | `jupyterlab/`, `airflow/docker/` |
| Compose file | `docker-compose.yaml` |
| Env file | `.env` (committed with safe defaults, secrets in `.env.local`) |
| Network name | `app_vnet` (internal), named externally as the service name |
| Volume vars | `DATA_HOST_VOLUME`, `PROJECTS_HOST_VOLUME`, `MODULES_HOST_VOLUME` |
| Container mounts | `~/data`, `~/projects`, `~/modules` inside container |
| Docker socket | `/var/run/docker.sock:/var/run/docker.sock:rw` always mounted |

---

## File Map

```
deployments/
├── CLAUDE.md                          CREATE — repo guide for Claude agents
├── README.md                          MODIFY — add marimo + ai-infra to index
├── marimo/
│   ├── docker-compose.yaml            CREATE
│   ├── .env                           CREATE
│   └── README.md                      CREATE
└── ai-infra/
    ├── docker-compose.yaml            CREATE — Ollama + Open WebUI
    ├── .env                           CREATE
    └── README.md                      CREATE
```

---

## Task 1: CLAUDE.md — Repo Guide for Claude Agents

**Files:**
- Create: `CLAUDE.md`

- [ ] **Step 1: Write CLAUDE.md**

```markdown
# Deployments Repo

Infrastructure-as-code and deployment configurations for Docker and Kubernetes.

## Repo Structure

Each service lives in its own directory. Docker deployments follow this layout:

```
<service>/
├── docker-compose.yaml   # Compose stack definition
├── .env                  # Environment variable defaults (safe to commit)
├── Dockerfile            # Only if a custom image is needed
└── README.md             # Service-specific setup and usage notes
```

Kubernetes configs go under `<service>/k8s/`.

## Volume Convention

All services share the same three host-path volume variables (set in `.env`):

| Variable | Container path | Purpose |
|---|---|---|
| `DATA_HOST_VOLUME` | `~/data` | Datasets, outputs |
| `PROJECTS_HOST_VOLUME` | `~/projects` | Source code / notebooks |
| `MODULES_HOST_VOLUME` | `~/modules` | Shared Python packages |

## Network Convention

Each compose file defines a single network named `app_vnet` with an explicit external name matching the service (e.g. `jupyterlab`, `marimo`). This lets other stacks reach the service by name.

## Adding a New Service

1. Copy the closest existing service dir as a template.
2. Update the image, port, and network name.
3. Keep the three volume vars — don't invent new ones.
4. Add a `README.md` explaining how to start and use the service.

## Services

| Service | Dir | Default Port | Notes |
|---|---|---|---|
| JupyterLab | `jupyterlab/` | 8080 | scipy-notebook base, custom extensions |
| Marimo | `marimo/` | 2718 | Reactive Python notebooks |
| Airflow | `airflow/` | 8080 | Workflow orchestration |
| AI Infra | `ai-infra/` | 11434 (Ollama), 3000 (Open WebUI) | Local LLM serving + chat UI |

## Common Commands

```bash
# Start a stack (from within its directory)
docker compose up -d

# Rebuild and start
docker compose up -d --build

# View logs
docker compose logs -f

# Stop
docker compose down
```

## GPU Note

The `ai-infra` stack includes GPU passthrough via the `deploy.resources.reservations.devices` field. Requires `nvidia-container-toolkit` on the host. Remove the `deploy` block if no GPU is available.
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add CLAUDE.md for Claude agent context"
```

---

## Task 2: Marimo Docker Compose Deployment

**Files:**
- Create: `marimo/docker-compose.yaml`
- Create: `marimo/.env`
- Create: `marimo/README.md`

- [ ] **Step 1: Write `marimo/.env`**

```env
# Exposed port on the host
HOST_PORT=2718

# Modules volume mount (shared Python packages)
MODULES_CONTAINER_VOLUME=/home/marimo/modules
MODULES_HOST_VOLUME=${PWD}

# Projects volume mount (notebooks and source code)
PROJECTS_CONTAINER_VOLUME=/home/marimo/projects
PROJECTS_HOST_VOLUME=${HOME}/Projects

# Data volume mount (datasets, outputs)
DATA_CONTAINER_VOLUME=/home/marimo/data
DATA_HOST_VOLUME=/data/marimo
```

- [ ] **Step 2: Write `marimo/docker-compose.yaml`**

```yaml
version: "3.8"

services:

  marimo:
    image: ghcr.io/marimo-team/marimo:latest
    container_name: marimo
    restart: always
    command: ["marimo", "edit", "--host", "0.0.0.0", "--port", "2718", "--no-token"]
    environment:
      PYTHONPATH: ${MODULES_CONTAINER_VOLUME}
    env_file:
      - .env
    networks:
      - app_vnet
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:rw
      - ${DATA_HOST_VOLUME}:${DATA_CONTAINER_VOLUME}
      - ${PROJECTS_HOST_VOLUME}:${PROJECTS_CONTAINER_VOLUME}
      - ${MODULES_HOST_VOLUME}:${MODULES_CONTAINER_VOLUME}
    ports:
      - "${HOST_PORT:-2718}:2718"

networks:
  app_vnet:
    name: marimo
```

- [ ] **Step 3: Write `marimo/README.md`**

```markdown
# Marimo

Reactive Python notebook server — notebooks are plain `.py` files and re-run automatically when cells change.

## Start

```bash
# From this directory:
docker compose up -d
```

Open http://localhost:2718 in your browser.

## Volumes

| Host path | Container path | Purpose |
|---|---|---|
| `DATA_HOST_VOLUME` (default `/data/marimo`) | `~/data` | Datasets / outputs |
| `PROJECTS_HOST_VOLUME` (default `$HOME/Projects`) | `~/projects` | Notebooks |
| `MODULES_HOST_VOLUME` (default `$PWD`) | `~/modules` | Shared packages |

Edit `.env` to change any of these before first start. Create the data dir if it does not exist:

```bash
sudo mkdir -p /data/marimo && sudo chown $USER /data/marimo
```

## Creating a Notebook

Inside the Marimo UI click **New notebook**, or from a terminal inside the container:

```bash
docker exec -it marimo marimo edit ~/projects/my_notebook.py
```

## Stopping

```bash
docker compose down
```
```

- [ ] **Step 4: Verify compose file is valid**

```bash
cd /home/ketan/Projects/deployments/marimo
docker compose config
```

Expected: full merged YAML with no errors.

- [ ] **Step 5: Commit**

```bash
git add marimo/
git commit -m "feat: add marimo docker-compose deployment"
```

---

## Task 3: AI-Infra — Local LLM Serving (Ollama + Open WebUI)

**Files:**
- Create: `ai-infra/docker-compose.yaml`
- Create: `ai-infra/.env`
- Create: `ai-infra/README.md`

- [ ] **Step 1: Write `ai-infra/.env`**

```env
# Ollama API port (OpenAI-compatible endpoint)
OLLAMA_HOST_PORT=11434

# Open WebUI port
WEBUI_HOST_PORT=3000

# Ollama data dir — stores downloaded models
OLLAMA_DATA_HOST_VOLUME=/data/ollama

# Projects / notebooks volume (same as other stacks)
PROJECTS_CONTAINER_VOLUME=/root/projects
PROJECTS_HOST_VOLUME=${HOME}/Projects

# Data volume
DATA_CONTAINER_VOLUME=/root/data
DATA_HOST_VOLUME=/data/ai-infra

# Default model to pull on first start (override as needed)
OLLAMA_DEFAULT_MODEL=llama3.2
```

- [ ] **Step 2: Write `ai-infra/docker-compose.yaml`**

```yaml
version: "3.8"

services:

  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: always
    environment:
      OLLAMA_HOST: 0.0.0.0
    env_file:
      - .env
    networks:
      - app_vnet
    volumes:
      - ${OLLAMA_DATA_HOST_VOLUME:-/data/ollama}:/root/.ollama
      - ${PROJECTS_HOST_VOLUME}:${PROJECTS_CONTAINER_VOLUME}
      - ${DATA_HOST_VOLUME}:${DATA_CONTAINER_VOLUME}
    ports:
      - "${OLLAMA_HOST_PORT:-11434}:11434"
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]

  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    restart: always
    environment:
      OLLAMA_BASE_URL: http://ollama:11434
      WEBUI_AUTH: "false"
    env_file:
      - .env
    networks:
      - app_vnet
    volumes:
      - open-webui-data:/app/backend/data
    ports:
      - "${WEBUI_HOST_PORT:-3000}:8080"
    depends_on:
      - ollama

volumes:
  open-webui-data:

networks:
  app_vnet:
    name: ai-infra
```

- [ ] **Step 3: Write `ai-infra/README.md`**

````markdown
# AI Infra — Local LLM Stack

Runs Ollama (LLM backend with OpenAI-compatible API) and Open WebUI (chat interface) on Docker.

## Requirements

- Docker + Docker Compose
- For GPU acceleration: `nvidia-container-toolkit` installed and configured on the host

## Start

```bash
# From this directory:
docker compose up -d
```

Services:
- **Ollama API:** http://localhost:11434  (OpenAI-compatible)
- **Open WebUI:** http://localhost:3000

## Pull a Model

```bash
docker exec -it ollama ollama pull llama3.2
```

Other useful models: `codestral`, `qwen2.5-coder:7b`, `mistral`, `phi4`, `gemma3`.

## VS Code Integration (Continue Extension)

1. Install the [Continue extension](https://marketplace.visualstudio.com/items?itemName=Continue.continue) in VS Code.
2. Open the Continue config file (`~/.continue/config.json`) and add:

```json
{
  "models": [
    {
      "title": "Llama 3.2 (local)",
      "provider": "ollama",
      "model": "llama3.2",
      "apiBase": "http://localhost:11434"
    },
    {
      "title": "Qwen 2.5 Coder (local)",
      "provider": "ollama",
      "model": "qwen2.5-coder:7b",
      "apiBase": "http://localhost:11434"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Qwen 2.5 Coder (autocomplete)",
    "provider": "ollama",
    "model": "qwen2.5-coder:7b",
    "apiBase": "http://localhost:11434"
  }
}
```

3. Save and reload VS Code. The Continue sidebar will show your local models.

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

CPU inference is slower but works.

## Volumes

| Host path | Container path | Purpose |
|---|---|---|
| `OLLAMA_DATA_HOST_VOLUME` (default `/data/ollama`) | `/root/.ollama` | Downloaded models |
| `PROJECTS_HOST_VOLUME` | `~/projects` | Source code |
| `DATA_HOST_VOLUME` | `~/data` | Datasets |

Create data dirs before first start:

```bash
sudo mkdir -p /data/ollama /data/ai-infra
sudo chown $USER /data/ollama /data/ai-infra
```

## Stopping

```bash
docker compose down
```
````

- [ ] **Step 4: Verify compose file is valid**

```bash
cd /home/ketan/Projects/deployments/ai-infra
docker compose config
```

Expected: full merged YAML with no errors.

- [ ] **Step 5: Commit**

```bash
git add ai-infra/
git commit -m "feat: add ai-infra stack — Ollama + Open WebUI with VS Code Continue integration"
```

---

## Task 4: Update Root README.md

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace README.md content**

```markdown
# Deployment Scripts

Scripts for deploying applications on Docker or Kubernetes.

## Services

| Service | Directory | Port(s) | Description |
|---|---|---|---|
| JupyterLab | `jupyterlab/` | 8080 | Scipy-notebook with custom extensions |
| Marimo | `marimo/` | 2718 | Reactive Python notebooks |
| Airflow | `airflow/` | 8080 | Workflow orchestration |
| AI Infra | `ai-infra/` | 11434, 3000 | Local LLM (Ollama) + chat UI (Open WebUI) |

## Usage

Each service is self-contained. Navigate to the service directory and run:

```bash
docker compose up -d
```

See the `README.md` inside each directory for service-specific setup.
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update root README with marimo and ai-infra services"
```

---

## Self-Review

**Spec coverage:**
- [x] CLAUDE.md for Claude agent setup → Task 1
- [x] Marimo docker-compose with matching volumes/networks → Task 2
- [x] `ai-infra/` with local LLM docker-compose → Task 3
- [x] VS Code integration documented → Task 3, README
- [x] Root README updated → Task 4

**Placeholder scan:** No TBDs, no "implement later", all code blocks are complete.

**Type consistency:** No shared types across tasks; each task is self-contained YAML/Markdown.

**Volume consistency check:**
- JupyterLab: `DATA_HOST_VOLUME → ~/data`, `PROJECTS_HOST_VOLUME → ~/projects`, `MODULES_HOST_VOLUME → ~/modules`
- Marimo: same three vars, same container paths under `/home/marimo/` (marimo runs as non-root)
- AI-infra: same DATA + PROJECTS vars; adds `OLLAMA_DATA_HOST_VOLUME` for model storage (separate concern)
