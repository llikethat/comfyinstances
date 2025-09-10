#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# ──────────────────────────────────────────────
# Configuration flags
# ──────────────────────────────────────────────
INSTALL_SAGEATTENTION=true   # Set to false to skip installing sageattention

# ──────────────────────────────────────────────
# Environment setup
# ──────────────────────────────────────────────
source /venv/main/bin/activate

if [ "$INSTALL_SAGEATTENTION" = true ]; then
    echo "Installing sageattention..."
    /venv/main/bin/python -m pip install sageattention
else
    echo "Skipping sageattention installation."
fi

COMFYUI_DIR="${WORKSPACE}/ComfyUI"
VOLUME_PATH="/data"

# ──────────────────────────────────────────────
# Package and Node definitions
# ──────────────────────────────────────────────
APT_PACKAGES=(
    # "package-1"
    # "package-2"
)

PIP_PACKAGES=(
    # "package-1"
    # "package-2"
)

# Custom ComfyUI nodes to be installed
NODES=(
    # "https://github.com/ltdrdata/ComfyUI-Manager"
    "https://github.com/cubiq/ComfyUI_essentials"
    "https://github.com/cubiq/ComfyUI_IPAdapter_plus"
    "https://github.com/city96/ComfyUI-GGUF"
    "https://github.com/rgthree/rgthree-comfy"
    "https://github.com/yolain/ComfyUI-Easy-Use"
    "https://github.com/kijai/ComfyUI-KJNodes"
    "https://github.com/kijai/ComfyUI-Florence2"
    "https://github.com/crystian/ComfyUI-Crystools"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
    "https://github.com/kijai/ComfyUI-FluxTrainer"
    "https://github.com/shiimizu/ComfyUI-TiledDiffusion"
    "https://github.com/lquesada/ComfyUI-Inpaint-CropAndStitch"
    "https://github.com/Acly/comfyui-inpaint-nodes"
    "https://github.com/kijai/ComfyUI-WanVideoWrapper"
)

WORKFLOWS=()
CHECKPOINT_MODELS=()
UNET_MODELS=()
LORA_MODELS=()
VAE_MODELS=()
ESRGAN_MODELS=()
CONTROLNET_MODELS=()

# ──────────────────────────────────────────────
# Provisioning Functions
# ──────────────────────────────────────────────
# ... (all your functions stay unchanged here)
# ──────────────────────────────────────────────

# Run provisioning (unless disabled)
if [[ ! -f /.noprovisioning ]]; then
    provisioning_start
fi

# ──────────────────────────────────────────────
# Clear default paths and rebuild symlinks
# ──────────────────────────────────────────────
rm -rf "$COMFYUI_DIR/models" \
       "$COMFYUI_DIR/input" \
       "$COMFYUI_DIR/output" \
       "$COMFYUI_DIR/custom_nodes" \
       "$WORKSPACE/.hf_home"

# Ensure persistent directories exist
for dir in models custom_nodes input output; do
    mkdir -p "$VOLUME_PATH/$dir"
done

# Create symlinks (auto-create sources if missing)
for pair in \
  "models:$COMFYUI_DIR" \
  "custom_nodes:$COMFYUI_DIR" \
  "input:$COMFYUI_DIR" \
  "output:$COMFYUI_DIR" \
  "workflows:$COMFYUI_DIR/user/default" \
  ".cache/.hf_home:$WORKSPACE"
do
    src="${pair%%:*}"   # before :
    dst="${pair##*:}"   # after :
    mkdir -p "$VOLUME_PATH/$src"
    ln -sfn "$VOLUME_PATH/$src" "$dst"
    printf "  %s -> %s\n" "$dst" "$VOLUME_PATH/$src"
done

# ──────────────────────────────────────────────
# Update ComfyUI and all custom nodes
# ──────────────────────────────────────────────
if [ -d "$COMFYUI_DIR/.git" ]; then
    printf "Updating ComfyUI core...\n"
    git -C "$COMFYUI_DIR" pull
fi

if [ -d "$VOLUME_PATH/custom_nodes/ComfyUI-Manager/.git" ]; then
    printf "Updating ComfyUI-Manager...\n"
    git -C "$VOLUME_PATH/custom_nodes/ComfyUI-Manager" pull
fi

printf "Updating all custom nodes...\n"
for d in "$VOLUME_PATH/custom_nodes"/*/; do
    if [ -d "$d/.git" ]; then
        printf "  -> Updating %s\n" "$(basename "$d")"
        git -C "$d" pull || printf "  !! Failed to update %s\n" "$(basename "$d")"
    fi
done

# ──────────────────────────────────────────────
# (Optional) Start AItoolkit service
# ──────────────────────────────────────────────
# printf "Starting AItoolkit...\n"
# cd /data/ai-toolkit
# python3 -m venv venv
# source venv/bin/activate
# cd ui
# nohup /opt/nvm/versions/node/v22.17.0/bin/npm run build_and_start \
#   > /data/logs/aitoolkit.log 2>&1 &
