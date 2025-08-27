#!/bin/bash

source /venv/main/bin/activate
COMFYUI_DIR=${WORKSPACE}/ComfyUI

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
    
)

WORKFLOWS=(
    # Example Google Drive link (replace with your own)
    #"https://drive.google.com/uc?id=FILE_ID_1"
    # Add more Google Drive links as needed
)

CLIP_MODELS=(
    # Example Google Drive link (replace with your own)
    #"https://drive.google.com/uc?id=FILE_ID_2"
    "https://drive.google.com/uc?id=1VgJPXCm3pCFf1mV3IaCwElP2Uw_M6TOk"
    "https://drive.google.com/uc?id=1emVNxXrqduOQn_dgRUXR3zdqh0FOQ8xi"
    "https://drive.google.com/uc?id=12u_vY2Djd9rZtQEoXkBJSkwNOPDDiIZ9"
    # Add more Google Drive links as needed
)

UNET_MODELS=(
    # Example Google Drive link (replace with your own)
    "https://drive.google.com/uc?id=169duNM6qbYToNwwBalU7ovujc2PZLa_0"
    #"https://drive.google.com/file/d/FILE_ID/view?usp=sharing"
)

VAE_MODELS=(
    # Example Google Drive link (replace with your own)
    "https://drive.google.com/uc?id=1_nKd5uF47ciVQv75fZmOxacirFM8NN9F"
    "https://drive.google.com/uc?id=1FuzzS9wslm-tB4-5xUxw7jAXJbvhyweX"
    "https://drive.google.com/uc?id=1oPKRPgcPxVMbT3WgMc0s8LovLk0a1B8Y"
)

DIFFUSION_MODELS=(
    # Example Google Drive link (replace with your own)
    #"https://drive.google.com/uc?id=FILE_ID_4"
    "https://drive.google.com/uc?id=1bC_CSovMda29guZU0KYreXCGcOxHs4qY"
    "https://drive.google.com/uc?id=1Y4uYKGjgthpvF1QSO9hAGObvRfGMvtD8"
    "https://drive.google.com/uc?id=1G9gvGy8O9zAqVVqAFZOn7KmNFswsfGxw"
    "https://drive.google.com/uc?id=1KJBIRZliQuxe-XYZCX-bqvUXSurFb6zC"
    "https://drive.google.com/uc?id=1dgywgcdKOUz4GtRAR-SVtHWWalhhc1m4"
)

IPADAPTER=(
    "https://drive.google.com/uc?id=167upVMfQY-8sSnCc5MAQyI2YJwCsxl7q"
)

CHECKPOINTS=(
    # Example Google Drive link (replace with your own)
    "https://drive.google.com/uc?id=1dCdtN9m01w-89jRGOaGQ0EqgQTFfVTqh"
    "https://drive.google.com/uc?id=15aXhKQrEHn0p4qxXFAAAVzrpXzTGiG0u"    
)

CONTROLNET=(
    # Example Google Drive link (replace with your own)
    "https://drive.google.com/uc?id=1Aqk2aguA2LtTOyPjP1FaUt42Xd-rVrfs"
    #"https://drive.google.com/uc?id=15aXhKQrEHn0p4qxXFAAAVzrpXzTGiG0u"    
)


### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function provisioning_start() {
    provisioning_print_header
    provisioning_get_apt_packages
    provisioning_get_nodes
    provisioning_get_pip_packages
    workflows_dir="${COMFYUI_DIR}/user/default/workflows"
    mkdir -p "${workflows_dir}"
    provisioning_get_files "${workflows_dir}" "${WORKFLOWS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/unet" "${UNET_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/vae"  "${VAE_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/clip" "${CLIP_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/checkpoints" "${CHECKPOINTS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/controlnet" "${CONTROLNET[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/diffusion_models" "${DIFFUSION_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/ipadapter" "${IPADAPTER[@]}"
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
        path="${COMFYUI_DIR}/custom_nodes/${dir}"
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
    printf "Downloading %s file(s) to %s...\n" "${#arr[@]}" "$dir"
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

# Download from $1 URL to $2 file path
function provisioning_download() {
    # If it's a Google Drive link, use gdown
    if [[ $1 == *"drive.google.com"* ]]; then
        file_id=$(echo "$1" | grep -o 'id=[^&]*' | cut -d'=' -f2)
        if [ -n "$file_id" ]; then
            # Ensure gdown is installed
            if ! command -v gdown &> /dev/null; then
                pip install gdown
            fi
            gdown "$1" --fuzzy -O "$2"
        else
            # If the link is in the format /file/d/FILE_ID
            file_id=$(echo "$1" | grep -o '/d/[^/]*' | cut -d'/' -f3)
            if [ -n "$file_id" ]; then
                if ! command -v gdown &> /dev/null; then
                    pip install gdown
                fi
                gdown "$1" --fuzzy -O "$2"
            else
                echo "Invalid Google Drive link format: $1"
            fi
        fi
    else
        wget -qnc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1"
    fi
}

if [[ ! -f /.noprovisioning ]]; then
    provisioning_start
fi
