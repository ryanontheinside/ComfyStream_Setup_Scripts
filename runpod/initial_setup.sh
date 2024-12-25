#!/bin/bash
#Runpod server setup

echo "
========================================
🚀 Starting ComfyUI and ComfyStream setup...
========================================
"

# Create base directories
echo "
----------------------------------------
📁 Creating base directories...
----------------------------------------"
mkdir -p /workspace/ComfyUI
mkdir -p /workspace/comfyRealtime
mkdir -p /workspace/miniconda3

# Clone ComfyUI to both locations
echo "
----------------------------------------
📥 Cloning repositories...
----------------------------------------"
# Clone all repos in parallel with their original checks
if [ ! -d "/workspace/ComfyUI/.git" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI &
else
    echo "ComfyUI already exists in /workspace/ComfyUI, skipping clone..."
fi

if [ ! -d "/workspace/comfyRealtime/ComfyUI/.git" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/comfyRealtime/ComfyUI &
else
    echo "ComfyUI already exists in /workspace/comfyRealtime/ComfyUI, skipping clone..."
fi

if [ ! -d "/workspace/comfyRealtime/ComfyStream/.git" ]; then
    git clone https://github.com/yondonfu/comfystream.git /workspace/comfyRealtime/ComfyStream &
else
    echo "ComfyStream already exists, skipping clone..."
fi

# Wait for all clones to complete
wait

# Create symlink for models directory
echo "
----------------------------------------
🔗 Setting up models symlink...
----------------------------------------"
if [ ! -L "/workspace/comfyRealtime/ComfyUI/models" ]; then
    rm -rf /workspace/comfyRealtime/ComfyUI/models  # Remove existing models dir
    ln -s /workspace/ComfyUI/models /workspace/comfyRealtime/ComfyUI/models
else
    echo "Models symlink already exists, skipping..."
fi

# Clone ComfyUI-Manager to first install
echo "
----------------------------------------
📥 Installing ComfyUI-Manager...
----------------------------------------"
if [ ! -d "/workspace/ComfyUI/custom_nodes/ComfyUI-Manager/.git" ]; then
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git /workspace/ComfyUI/custom_nodes/ComfyUI-Manager
else
    echo "ComfyUI-Manager already exists in first installation, skipping clone..."
fi

# Copy ComfyUI-Manager to second install
echo "
----------------------------------------
📋 Copying ComfyUI-Manager to second installation...
----------------------------------------"
if [ ! -d "/workspace/comfyRealtime/ComfyUI/custom_nodes/ComfyUI-Manager" ]; then
    cp -r /workspace/ComfyUI/custom_nodes/ComfyUI-Manager /workspace/comfyRealtime/ComfyUI/custom_nodes/
else
    echo "ComfyUI-Manager already exists in second installation, skipping copy..."
fi

# Clone RealTimeNodes to first install
echo "
----------------------------------------
📥 Installing ComfyUI RealTimeNodes...
----------------------------------------"
if [ ! -d "/workspace/ComfyUI/custom_nodes/ComfyUI_RealTimeNodes/.git" ]; then
    git clone https://github.com/ryanontheinside/ComfyUI_RealTimeNodes.git /workspace/ComfyUI/custom_nodes/ComfyUI_RealTimeNodes
else
    echo "ComfyUI RealTimeNodes already exists in first installation, skipping clone..."
fi

# Copy RealTimeNodes to second install
echo "
----------------------------------------
📋 Copying RealTimeNodes to second installation...
----------------------------------------"
if [ ! -d "/workspace/comfyRealtime/ComfyUI/custom_nodes/ComfyUI_RealTimeNodes" ]; then
    cp -r /workspace/ComfyUI/custom_nodes/ComfyUI_RealTimeNodes /workspace/comfyRealtime/ComfyUI/custom_nodes/
else
    echo "ComfyUI RealTimeNodes already exists in second installation, skipping copy..."
fi

# Download models in parallel with their original checks
echo "
----------------------------------------
📥 Downloading Kohaku model...
----------------------------------------"
if [ ! -f "/workspace/ComfyUI/models/checkpoints/kohaku-v2.1.safetensors" ]; then
    wget --content-disposition -P /workspace/ComfyUI/models/checkpoints https://huggingface.co/KBlueLeaf/kohaku-v2.1/resolve/main/kohaku-v2.1.safetensors?download=true &
else
    echo "Kohaku model already exists, skipping download..."
fi

echo "
----------------------------------------
📥 Downloading Turbo model...
----------------------------------------"
if [ ! -f "/workspace/ComfyUI/models/checkpoints/sd_xl_turbo_1.0.safetensors" ]; then
    wget --content-disposition -P /workspace/ComfyUI/models/checkpoints https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sd_xl_turbo_1.0.safetensors?download=true &
else
    echo "Turbo model already exists, skipping download..."
fi

# Wait for all downloads to complete
wait

# Download and install Miniconda
echo "
----------------------------------------
📥 Downloading and installing Miniconda...
----------------------------------------"
if [ ! -f "/workspace/miniconda3/bin/conda" ]; then
    cd /workspace/miniconda3
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    chmod +x Miniconda3-latest-Linux-x86_64.sh
    ./Miniconda3-latest-Linux-x86_64.sh -b -p /workspace/miniconda3 -f
else
    echo "Miniconda already installed, skipping..."
fi

# Initialize conda in the shell
echo "
----------------------------------------
🐍 Initializing conda...
----------------------------------------"
eval "$(/workspace/miniconda3/bin/conda shell.bash hook)"

# Create conda environments
echo "
----------------------------------------
🌟 Creating conda environments...
----------------------------------------"
if ! conda info --envs | grep -q "comfyui"; then
    conda create -n comfyui python=3.11 -y
else
    echo "comfyui environment already exists, skipping creation..."
fi

if ! conda info --envs | grep -q "comfystream"; then
    conda create -n comfystream python=3.11 -y
else
    echo "comfystream environment already exists, skipping creation..."
fi

# Setup comfystream environment
echo "
----------------------------------------
🔧 Setting up comfystream environment...
----------------------------------------"
echo "🔄 Activating comfystream environment..."
set -x  # Enable debug mode to see each command
conda activate comfystream
RESULT=$?
echo "Activation exit code: $RESULT"
if [ "$CONDA_DEFAULT_ENV" != "comfystream" ]; then
    echo "❌ Failed to activate comfystream environment! Current env: $CONDA_DEFAULT_ENV"
    exit 1
fi
echo "✅ Successfully activated comfystream environment"

pwd  # Print current directory
cd /workspace/comfyRealtime/ComfyStream
echo "Current directory: $(pwd)"

echo "📦 Installing ComfyStream package..."
pip install . 
PIP_RESULT=$?
echo "Pip install exit code: $PIP_RESULT"

echo "📦 Installing ComfyStream requirements..."
pip install -r requirements.txt
PIP_REQ_RESULT=$?
echo "Pip requirements install exit code: $PIP_REQ_RESULT"

echo "🔧 Running ComfyStream install script..."
python install.py --workspace /workspace/comfyRealtime/ComfyUI
INSTALL_RESULT=$?
echo "Install script exit code: $INSTALL_RESULT"

# Copy tensor utils to ComfyUI custom nodes
echo "
----------------------------------------
📋 Copying tensor utils...
----------------------------------------"
if [ ! -d "../ComfyUI/custom_nodes/tensor_utils" ]; then
    cp -r nodes/tensor_utils ../ComfyUI/custom_nodes/
else
    echo "Tensor utils already exist in custom_nodes, skipping copy..."
fi

# Return to base environment
echo "🔄 Deactivating comfystream environment..."
conda deactivate
echo "✅ Successfully deactivated comfystream environment"
echo "✅ Completed comfystream environment setup"
set +x  # Disable debug mode

# Copy tensor utils to ComfyUI custom nodes
echo "
----------------------------------------
📋 Copying tensor utils...
----------------------------------------"
if [ ! -d "../ComfyUI/custom_nodes/tensor_utils" ]; then
    cp -r nodes/tensor_utils ../ComfyUI/custom_nodes/
else
    echo "Tensor utils already exist in custom_nodes, skipping copy..."
fi

# Return to base environment
echo "🔄 Deactivating comfystream environment..."
conda deactivate
echo "✅ Successfully deactivated comfystream environment"
echo "✅ Completed comfystream environment setup"

# Setup comfyui environment
echo "
----------------------------------------
🔧 Setting up comfyui environment...
----------------------------------------"
echo "🔄 Activating comfyui environment..."
conda activate comfyui
if [ "$CONDA_DEFAULT_ENV" != "comfyui" ]; then
    echo "❌ Failed to activate comfyui environment! Exiting..."
    exit 1
fi
echo "✅ Successfully activated comfyui environment"

cd /workspace/ComfyUI
echo "📦 Installing ComfyUI requirements..."
pip install -r requirements.txt
cd custom_nodes/ComfyUI-Manager
echo "📦 Installing ComfyUI-Manager requirements..."
pip install -r requirements.txt

# Return to base environment
echo "🔄 Deactivating comfyui environment..."
conda deactivate
echo "✅ Successfully deactivated comfyui environment"

# Function to install custom nodes and dependencies
install_custom_nodes() {
    local ENV_NAME=$1
    echo "
    ----------------------------------------
    📥 Installing Additional Custom Nodes for $ENV_NAME environment...
    ----------------------------------------"

    # Activate the specified environment with verification
    echo "🔄 Activating $ENV_NAME environment..."
    conda activate $ENV_NAME
    if [ "$CONDA_DEFAULT_ENV" != "$ENV_NAME" ]; then
        echo "❌ Failed to activate $ENV_NAME environment! Current env: $CONDA_DEFAULT_ENV"
        exit 1
    fi
    echo "✅ Successfully activated $ENV_NAME environment"
    
    # Install additional packages first
    echo "Installing additional Python packages..."
    pip install torch==2.5.1 torchvision torchaudio tqdm nvidia-ml-py==12.560.30 diffusers==0.30.1

    # Define the base custom nodes path based on environment
    if [ "$ENV_NAME" == "comfyui" ]; then
        CUSTOM_NODES_PATH="/workspace/ComfyUI/custom_nodes"
    else
        CUSTOM_NODES_PATH="/workspace/comfyRealtime/ComfyUI/custom_nodes"
    fi

    # Install ComfyUI-Depth-Anything-Tensorrt
    if [ ! -d "$CUSTOM_NODES_PATH/ComfyUI-Depth-Anything-Tensorrt/.git" ]; then
        git clone https://github.com/yuvraj108c/ComfyUI-Depth-Anything-Tensorrt.git "$CUSTOM_NODES_PATH/ComfyUI-Depth-Anything-Tensorrt"
        cd "$CUSTOM_NODES_PATH/ComfyUI-Depth-Anything-Tensorrt"
        pip install -r requirements.txt
    fi

    # Install ComfyUI-Misc-Effects
    if [ ! -d "$CUSTOM_NODES_PATH/ComfyUI-Misc-Effects/.git" ]; then
        git clone https://github.com/ryanontheinside/ComfyUI-Misc-Effects.git "$CUSTOM_NODES_PATH/ComfyUI-Misc-Effects"
        cd "$CUSTOM_NODES_PATH/ComfyUI-Misc-Effects"
        git checkout c6b360c78611134c3723388170475eb4898ff6b7
    fi

    # Install ComfyUI-SAM2-Realtime
    if [ ! -d "$CUSTOM_NODES_PATH/ComfyUI-SAM2-Realtime/.git" ]; then
        git clone https://github.com/pschroedl/ComfyUI-SAM2-Realtime.git "$CUSTOM_NODES_PATH/ComfyUI-SAM2-Realtime"
        cd "$CUSTOM_NODES_PATH/ComfyUI-SAM2-Realtime"
        git checkout 4f587443fb2808c4b5b303afcd7ec3ec3e0fbd08
        pip install -r requirements.txt
    fi

    # Install ComfyUI-Florence2-Vision
    if [ ! -d "$CUSTOM_NODES_PATH/ComfyUI-Florence2-Vision/.git" ]; then
        git clone https://github.com/ad-astra-video/ComfyUI-Florence2-Vision.git "$CUSTOM_NODES_PATH/ComfyUI-Florence2-Vision"
        cd "$CUSTOM_NODES_PATH/ComfyUI-Florence2-Vision"
        git checkout 0c624e61b6606801751bd41d93a09abe9844bea7
        pip install -r requirements.txt
    fi

    # Install ComfyUI-StreamDiffusion
    if [ ! -d "$CUSTOM_NODES_PATH/ComfyUI-StreamDiffusion/.git" ]; then
        git clone https://github.com/pschroedl/ComfyUI-StreamDiffusion.git "$CUSTOM_NODES_PATH/ComfyUI-StreamDiffusion"
        cd "$CUSTOM_NODES_PATH/ComfyUI-StreamDiffusion"
        git checkout f93b98aa9f20ab46c23d149ad208d497cd496579
        pip install -r requirements.txt
    fi

    # Install ComfyUI-LivePortraitKJ
    if [ ! -d "$CUSTOM_NODES_PATH/ComfyUI-LivePortraitKJ/.git" ]; then
        git clone https://github.com/kijai/ComfyUI-LivePortraitKJ.git "$CUSTOM_NODES_PATH/ComfyUI-LivePortraitKJ"
        cd "$CUSTOM_NODES_PATH/ComfyUI-LivePortraitKJ"
        git checkout 4d9dc6205b793ffd0fb319816136d9b8c0dbfdff
        pip install -r requirements.txt
    fi

    # Install ComfyUI-load-image-from-url
    if [ ! -d "$CUSTOM_NODES_PATH/ComfyUI-load-image-from-url/.git" ]; then
        git clone https://github.com/tsogzark/ComfyUI-load-image-from-url.git "$CUSTOM_NODES_PATH/ComfyUI-load-image-from-url"
    fi

    # Return to base environment with verification
    echo "🔄 Deactivating $ENV_NAME environment..."
    conda deactivate
    if [ "$CONDA_DEFAULT_ENV" != "base" ]; then
        echo "❌ Failed to return to base environment! Current env: $CONDA_DEFAULT_ENV"
        exit 1
    fi
    echo "✅ Successfully deactivated $ENV_NAME environment"
}

# After setting up comfyui environment and its base requirements
echo "Installing custom nodes for comfyui environment..."
install_custom_nodes "comfyui"

# After setting up comfystream environment and its base requirements
echo "Installing custom nodes for comfystream environment..."
install_custom_nodes "comfystream"