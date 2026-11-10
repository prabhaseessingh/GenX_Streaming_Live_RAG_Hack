#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$ROOT/backend"
FRONTEND_DIR="$ROOT/frontend"

if [[ ! -f "$ROOT/backend/.env" ]]; then
  cp "$BACKEND_DIR/.env.example" "$BACKEND_DIR/.env"
  echo "[GenX] Created backend/.env. Add GNANI_API_KEY for audio transcription and GROQ_API_KEY for LLM mode."
fi

PYTHON_BIN="${PYTHON_BIN:-python3}"
if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  PYTHON_BIN="python"
fi
if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  echo "[GenX] Python 3 is required."
  exit 1
fi

if [[ ! -x "$BACKEND_DIR/.venv/bin/python" ]]; then
  echo "[GenX] Creating backend virtual environment..."
  "$PYTHON_BIN" -m venv "$BACKEND_DIR/.venv"
  "$BACKEND_DIR/.venv/bin/python" -m pip install -r "$BACKEND_DIR/requirements.txt"
fi

if [[ ! -d "$FRONTEND_DIR/node_modules" ]]; then
  echo "[GenX] Installing frontend packages..."
  npm --prefix "$FRONTEND_DIR" install
fi

cleanup() {
  kill "${BACKEND_PID:-}" "${FRONTEND_PID:-}" 2>/dev/null || true
}
trap cleanup INT TERM EXIT

echo "[GenX] Backend:  http://127.0.0.1:8000"
echo "[GenX] Frontend: http://127.0.0.1:3000"

(
  cd "$BACKEND_DIR"
  .venv/bin/python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
) &
BACKEND_PID=$!

(
  cd "$FRONTEND_DIR"
  npm run dev
) &
FRONTEND_PID=$!

wait
