# Marimo

Reactive Python notebook server. Notebooks are plain `.py` files that re-execute automatically when cells change.

## Start

```bash
# From this directory:
docker compose up -d
```

Open http://localhost:2718 in your browser.

## First-time setup

Create the data directory before starting:

```bash
sudo mkdir -p /data/marimo && sudo chown $USER /data/marimo
```

## Volumes

| `.env` variable | Default | Container path | Purpose |
|---|---|---|---|
| `DATA_HOST_VOLUME` | `/data/marimo` | `~/data` | Datasets / outputs |
| `PROJECTS_HOST_VOLUME` | `$HOME/Projects` | `~/projects` | Notebooks |
| `MODULES_HOST_VOLUME` | `$PWD` | `~/modules` | Shared Python packages |

Edit `.env` before first start to override any path.

## Creating a notebook

From the Marimo UI click **New notebook**, or from a host terminal:

```bash
docker exec -it marimo marimo edit ~/projects/my_notebook.py
```

## Stopping

```bash
docker compose down
```
