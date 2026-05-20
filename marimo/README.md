# Marimo

Reactive Python notebook server. Notebooks are plain `.py` files that re-execute automatically when cells change.

## Start

```bash
# From this directory:
docker compose up -d
```

Open http://localhost:2718 in your browser.

## Volumes

All paths live on the NVMe (`/mnt/m2-0/machine_learning/`) and are shared with JupyterLab
so notebooks, datasets, and outputs are accessible from either tool.

| `.env` variable | Host path | Container path | Purpose |
|---|---|---|---|
| `DATA_HOST_VOLUME` | `/mnt/m2-0/machine_learning/data` | `~/data` | Datasets (read) |
| `PROJECTS_HOST_VOLUME` | `/mnt/m2-0/machine_learning/ml-projects` | `~/projects` | Notebooks (read/write) |
| `OUTPUT_HOST_VOLUME` | `/mnt/m2-0/machine_learning/output` | `~/output` | Trained models, results (write) |
| `MODULES_HOST_VOLUME` | `$PWD` (repo dir) | `~/modules` | Shared Python packages |

These directories already exist on the host — no setup needed before first start.

## Creating a notebook

From the Marimo UI click **New notebook**, or from a host terminal:

```bash
docker exec -it marimo marimo edit ~/projects/my_notebook.py
```

Notebooks saved to `~/projects/` persist to `ml-projects/` on the NVMe.
Save trained model checkpoints to `~/output/` so they land in `machine_learning/output/`.

## Stopping

```bash
docker compose down
```
