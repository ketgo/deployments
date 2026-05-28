#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load .env so we can read volume paths
set -a; source .env; set +a

OLLAMA_DATA="${OLLAMA_DATA_HOST_VOLUME:-/mnt/m2-0/machine_learning/llm-models}"

# Models to pull after Ollama starts — edit this list to add/remove models
MODELS=(
  "qwen2.5-coder:32b"
  "llama3.3:70b"
  "deepseek-r1:70b"
)

usage() {
  echo "Usage: $0 {start|stop|pull|create|status}"
  echo ""
  echo "  start   Create volumes, start all services, pull models, create custom models"
  echo "  stop    Stop all services"
  echo "  pull    Pull/update models (stack must be running)"
  echo "  create  Build custom models from modelfiles/ (stack must be running)"
  echo "  status  Show running containers and loaded Ollama models"
  exit 1
}

wait_for_ollama() {
  echo "Waiting for Ollama to be ready..."
  local attempts=0
  until curl -sf http://localhost:"${OLLAMA_HOST_PORT:-11434}"/api/tags > /dev/null 2>&1; do
    attempts=$((attempts + 1))
    if [[ $attempts -ge 30 ]]; then
      echo "ERROR: Ollama did not become ready after 60s. Check: docker compose logs ollama"
      exit 1
    fi
    sleep 2
  done
  echo "Ollama is ready."
}

pull_models() {
  for model in "${MODELS[@]}"; do
    echo "Pulling $model..."
    docker exec ollama ollama pull "$model"
  done
  echo "All models pulled."
}

create_models() {
  local modelfiles_dir="$SCRIPT_DIR/modelfiles"
  for mf in "$modelfiles_dir"/*.Modelfile; do
    [[ -e "$mf" ]] || continue
    local name
    name="$(basename "$mf" .Modelfile)"
    echo "Creating custom model: $name from $(basename "$mf")..."
    docker cp "$mf" ollama:/tmp/"$(basename "$mf")"
    docker exec ollama ollama create "$name" -f /tmp/"$(basename "$mf")"
  done
  echo "All custom models created."
}

cmd="${1:-}"
case "$cmd" in
  start)
    echo "==> Creating host directories on NVMe (/mnt/m2-0)..."
    mkdir -p "$OLLAMA_DATA" "${DATA_HOST_VOLUME}" "${PROJECTS_HOST_VOLUME}"

    echo "==> Starting services..."
    docker compose up -d

    wait_for_ollama
    pull_models
    create_models

    echo ""
    echo "Stack is up:"
    echo "  Ollama API : http://localhost:${OLLAMA_HOST_PORT:-11434}"
    echo "  LiteLLM    : http://localhost:${LITELLM_HOST_PORT:-4000}"
    echo "  Open WebUI : http://localhost:${WEBUI_HOST_PORT:-3000}"
    ;;

  stop)
    echo "==> Stopping services..."
    docker compose down
    echo "Done."
    ;;

  pull)
    wait_for_ollama
    pull_models
    ;;

  create)
    wait_for_ollama
    create_models
    ;;

  status)
    echo "==> Containers:"
    docker compose ps
    echo ""
    echo "==> Loaded Ollama models:"
    docker exec ollama ollama list 2>/dev/null || echo "  (ollama not running)"
    ;;

  *)
    usage
    ;;
esac
