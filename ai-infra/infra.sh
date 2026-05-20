#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load .env so we can read volume paths
set -a; source .env; set +a

OLLAMA_DATA="${OLLAMA_DATA_HOST_VOLUME:-/data/ollama}"
AI_DATA="${DATA_HOST_VOLUME:-/data/ai-infra}"

# Models to pull after Ollama starts — edit this list to add/remove models
MODELS=(
  "qwen2.5-coder:32b"
  "llama3.3:70b"
  "deepseek-r1:70b"
)

usage() {
  echo "Usage: $0 {start|stop|pull|status}"
  echo ""
  echo "  start   Create volumes, start all services, pull models"
  echo "  stop    Stop all services"
  echo "  pull    Pull/update models (stack must be running)"
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

cmd="${1:-}"
case "$cmd" in
  start)
    echo "==> Creating host directories on NVMe (/mnt/m2-0)..."
    sudo mkdir -p "$OLLAMA_DATA" "$AI_DATA"
    sudo chown "$USER" "$OLLAMA_DATA" "$AI_DATA"

    echo "==> Starting services..."
    docker compose up -d

    wait_for_ollama
    pull_models

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
