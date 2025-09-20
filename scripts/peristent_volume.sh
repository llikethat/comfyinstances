#!/bin/bash

source /venv/main/bin/activate
#/venv/main/bin/python -m pip install sageattention
COMFYUI_DIR=${WORKSPACE}/ComfyUI
VOLUME_PATH=/data
HUGGINGFACE_HUB_TOKEN="$HF_TOKEN"   # some libraries check this name
HF_HOME="$VOLUME_PATH/.cache/.hf_home"

#Create directories to be linked in the persistent storage - this has to be done only for the 1st time

mkdir -p "$VOLUME_PATH/custom_nodes" "$VOLUME_PATH/input" "$VOLUME_PATH/output" "$VOLUME_PATH/.cache/.hf_home" "$VOLUME_PATH/workflows"


# Packages are installed after nodes so we can fix them...

APT_PACKAGES=(
    #"package-1"
    #"package-2"
)

PIP_PACKAGES=(
    #"package-1"
    #"package-2"
)

NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager"
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

WORKFLOWS=(

)

CHECKPOINT_MODELS=(
    "https://huggingface.co/Comfy-Org/flux1-dev/resolve/main/flux1-dev-fp8.safetensors"
    #"https://huggingface.co/Comfy-Org/flux1-dev/resolve/main/flux1-dev.safetensors"
    #"https://huggingface.co/Comfy-Org/flux1-schnell/resolve/main/flux1-schnell.safetensors"
    #"https://huggingface.co/Comfy-Org/flux1-schnell/resolve/main/flux1-schnell-fp8.safetensors"
    #"https://huggingface.co/RunDiffusion/Juggernaut-XL/resolve/main/juggernautXL_version2.safetensors"
    "https://civitai.com/api/download/models/357609"
    
)

UNET_MODELS=(
)

LORA_MODELS=(
)

VAE_MODELS=(
)

ESRGAN_MODELS=(
)

CONTROLNET_MODELS=(
)

# Clear default Paths

cp -r "$COMFYUI_DIR/models" "$VOLUME_PATH/models" 
rm -rf $COMFYUI_DIR/models $COMFYUI_DIR/input $COMFYUI_DIR/output $COMFYUI_DIR/custom_nodes $WORKSPACE/.hf_home 

# Link models, checkpoints, custom nodes to persistent volume
# Creating symlinks
ln -sfn "$VOLUME_PATH/models" "$COMFYUI_DIR"
ln -sfn "$VOLUME_PATH/custom_nodes" "$COMFYUI_DIR"
ln -sfn "$VOLUME_PATH/input" "$COMFYUI_DIR"
ln -sfn "$VOLUME_PATH/output" "$COMFYUI_DIR"
ln -sfn "$VOLUME_PATH/workflows" "$COMFYUI_DIR/user/default"
ln -sfn "$VOLUME_PATH/.cache/.hf_home" "${WORKSPACE}/"

# Logging
printf "Symlinks created:\n"
printf "  %s -> %s\n" "$COMFYUI_DIR/models" "$VOLUME_PATH/models"
printf "  %s -> %s\n" "$COMFYUI_DIR/custom_nodes" "$VOLUME_PATH/custom_nodes"
printf "  %s -> %s\n" "$COMFYUI_DIR/input" "$VOLUME_PATH/input"
printf "  %s -> %s\n" "$COMFYUI_DIR/output" "$VOLUME_PATH/output"
printf "  %s -> %s\n" "$COMFYUI_DIR/user/default" "$VOLUME_PATH/workflows"
printf "  %s -> %s\n" "$WORKSPACE/.hf_home" "$VOLUME_PATH/.cache/.hf_home"


### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function provisioning_start() {
    provisioning_print_header
    provisioning_get_apt_packages
    provisioning_get_nodes
    provisioning_get_pip_packages
    provisioning_get_files \
        "${COMFYUI_DIR}/models/checkpoints" \
        "${CHECKPOINT_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/unet" \
        "${UNET_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/lora" \
        "${LORA_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/controlnet" \
        "${CONTROLNET_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/vae" \
        "${VAE_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/esrgan" \
        "${ESRGAN_MODELS[@]}"
    provisioning_print_end
}

function provisioning_get_apt_packages() {
    if [[ -n $APT_PACKAGES ]]; then
            sudo $APT_INSTALL ${APT_PACKAGES[@]}
    fi
}

function provisioning_get_pip_packages() {
    if [[ -n $PIP_PACKAGES ]]; then
            pip install --no-cache-dir ${PIP_PACKAGES[@]}
    fi
}

function provisioning_get_nodes() {
    for repo in "${NODES[@]}"; do
        dir="${repo##*/}"
        path="${VOLUME_PATH}/custom_nodes/${dir}"
        requirements="${path}/requirements.txt"
        if [[ -d $path ]]; then
            if [[ ${AUTO_UPDATE,,} != "false" ]]; then
                printf "Updating node: %s...\n" "${repo}"
                ( cd "$path" && git pull )
                if [[ -e $requirements ]]; then
                   pip install --no-cache-dir -r "$requirements"
                fi
            fi
        else
            printf "Downloading node: %s...\n" "${repo}"
            git clone "${repo}" "${path}" --recursive
            if [[ -e $requirements ]]; then
                pip install --no-cache-dir -r "${requirements}"
            fi
        fi
    done
}

function provisioning_get_files() {
    if [[ -z $2 ]]; then return 1; fi
    
    dir="$1"
    mkdir -p "$dir"
    shift
    arr=("$@")
    printf "Downloading %s model(s) to %s...\n" "${#arr[@]}" "$dir"
    for url in "${arr[@]}"; do
        printf "Downloading: %s\n" "${url}"
        provisioning_download "${url}" "${dir}"
        printf "\n"
    done
}

function provisioning_print_header() {
    printf "\n##############################################\n#                                            #\n#          Provisioning container            #\n#                                            #\n#         This will take some time           #\n#                                            #\n# Your container will be ready on completion #\n#                                            #\n##############################################\n\n"
}

function provisioning_print_end() {
    printf "\nProvisioning complete:  Application will start now\n\n"
}

function provisioning_has_valid_hf_token() {
    [[ -n "$HF_TOKEN" ]] || return 1
    url="https://huggingface.co/api/whoami-v2"

    response=$(curl -o /dev/null -s -w "%{http_code}" -X GET "$url" \
        -H "Authorization: Bearer $HF_TOKEN" \
        -H "Content-Type: application/json")

    # Check if the token is valid
    if [ "$response" -eq 200 ]; then
        return 0
    else
        return 1
    fi
}

function provisioning_has_valid_civitai_token() {
    [[ -n "$CIVITAI_TOKEN" ]] || return 1
    url="https://civitai.com/api/v1/models?hidden=1&limit=1"

    response=$(curl -o /dev/null -s -w "%{http_code}" -X GET "$url" \
        -H "Authorization: Bearer $CIVITAI_TOKEN" \
        -H "Content-Type: application/json")

    # Check if the token is valid
    if [ "$response" -eq 200 ]; then
        return 0
    else
        return 1
    fi
}

# Download from $1 URL to $2 file path
function provisioning_download() {
    if [[ -n $HF_TOKEN && $1 =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co(/|$|\?) ]]; then
        auth_token="$HF_TOKEN"
    elif 
        [[ -n $CIVITAI_TOKEN && $1 =~ ^https://([a-zA-Z0-9_-]+\.)?civitai\.com(/|$|\?) ]]; then
        auth_token="$CIVITAI_TOKEN"
    fi
    if [[ -n $auth_token ]];then
        wget --header="Authorization: Bearer $auth_token" -nc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1"
    else
        wget -nc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1"
    fi
}

# Allow user to disable provisioning if they started with a script they didn't want
if [[ ! -f /.noprovisioning ]]; then
    provisioning_start
fi

#update Comfy-Core, Custom_nodes & Comfy-Manager

# Update ComfyUI core
if [ -d "$COMFYUI_DIR/.git" ]; then
    printf "Updating ComfyUI core...\n"
    git -C "$COMFYUI_DIR" pull
fi

# Update ComfyUI-Manager
if [ -d "$VOLUME_PATH/custom_nodes/ComfyUI-Manager/.git" ]; then
    printf "Updating ComfyUI-Manager...\n"
    git -C "$VOLUME_PATH/custom_nodes/ComfyUI-Manager" pull
fi

# Update all custom nodes
printf "Updating all custom nodes...\n"
for d in "$VOLUME_PATH/custom_nodes"/*/; do
    if [ -d "$d/.git" ]; then
        printf "  -> Updating %s\n" "$(basename "$d")"
        git -C "$d" pull || printf "  !! Failed to update %s\n" "$(basename "$d")"
    fi
done
