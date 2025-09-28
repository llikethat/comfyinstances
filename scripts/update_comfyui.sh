#!/usr/bin/env bash
set -e

echo "🔄 Starting ComfyUI auto-update..."

# --- CONFIG ---
COMFY_DIR="/workspace/ComfyUI"        # Adjust if needed
PYTHON_BIN="python"                   # or full path: /venv/main/bin/python
BRANCH="master"                       # or "main"
TAG=""                                # leave empty to pull latest main
TAG="v0.3.60"                       # uncomment to lock to specific version
#PORT=8188                             # Default port

cd "$COMFY_DIR"

# --- CHECK GIT STATUS ---
if [ ! -d ".git" ]; then
  echo "🚨 Not a Git repository. Skipping update."
  exit 1
fi

echo "📦 Fetching latest changes..."
git fetch --all --tags

# --- HANDLE MODEL FOLDER CONFLICT ---
MODELS_BACKUP_DIR=""
if [ -d "models" ]; then
  if git ls-files --error-unmatch models >/dev/null 2>&1; then
    echo "✅ 'models' is tracked by git, safe."
  else
    MODELS_BACKUP_DIR="models_backup_$(date +%Y%m%d_%H%M%S)"
    echo "⚠️  Detected local models folder conflict. Backing up to $MODELS_BACKUP_DIR..."
    mv models "$MODELS_BACKUP_DIR"
  fi
fi

# --- CHECKOUT TARGET ---
if [ -n "$TAG" ]; then
  echo "📌 Checking out tag $TAG"
  git checkout "tags/$TAG"
else
  echo "📌 Updating $BRANCH branch"
  git checkout "$BRANCH"
  git pull
fi

# --- SUBMODULES ---
echo "📦 Updating submodules..."
git submodule update --init --recursive

# --- PYTHON ENV ---
echo "🐍 Upgrading dependencies..."
$PYTHON_BIN -m pip install --upgrade pip
$PYTHON_BIN -m pip install -r requirements.txt --upgrade

# --- NUMPY COMPATIBILITY ---
echo "🔧 Ensuring NumPy compatibility..."
$PYTHON_BIN -m pip install numpy==2.2.2 --force-reinstall

# --- UPDATE CUSTOM NODES ---
if [ -d "custom_nodes/ComfyUI-Manager" ]; then
  echo "🧩 Updating custom nodes via ComfyUI-Manager..."
  $PYTHON_BIN main.py --update-all || echo "⚠️ Node update failed or skipped"
else
  echo "ℹ️  ComfyUI-Manager not found, skipping node update."
fi

# --- RESTORE MODELS FOLDER ---
if [ -n "$MODELS_BACKUP_DIR" ]; then
  echo "♻️  Restoring models folder from $MODELS_BACKUP_DIR..."
  if [ -d "models" ]; then
    echo "⚠️  'models' folder already exists after update. Merging content..."
    rsync -av "$MODELS_BACKUP_DIR"/ models/
    rm -rf "$MODELS_BACKUP_DIR"
  else
    mv "$MODELS_BACKUP_DIR" models
    echo "✅ Models folder restored."
  fi
fi

