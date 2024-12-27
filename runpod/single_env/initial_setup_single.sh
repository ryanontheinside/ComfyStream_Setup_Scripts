#!/bin/bash
#Runpod server setup - Single ComfyUI + ComfyStream installation

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
mkdir -p /workspace/comfyRealtime
mkdir -p /workspace/miniconda3

# Clone ComfyUI
echo "
----------------------------------------
📥 Cloning ComfyUI repository...
----------------------------------------"
if [ ! -d "/workspace/comfyRealtime/ComfyUI/.git" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/comfyRealtime/ComfyUI
else
    echo "ComfyUI already exists in /workspace/comfyRealtime/ComfyUI, skipping clone..."
fi

# Clone ComfyStream
echo "
----------------------------------------
📥 Cloning ComfyStream repository...
----------------------------------------"
if [ ! -d "/workspace/comfyRealtime/ComfyStream/.git" ]; then
    git clone https://github.com/yondonfu/comfystream.git /workspace/comfyRealtime/ComfyStream
else
    echo "ComfyStream already exists, skipping clone..."
fi

# Clone ComfyUI-Manager
echo "
----------------------------------------
📥 Installing ComfyUI-Manager...
----------------------------------------"
if [ ! -d "/workspace/comfyRealtime/ComfyUI/custom_nodes/ComfyUI-Manager/.git" ]; then
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git /workspace/comfyRealtime/ComfyUI/custom_nodes/ComfyUI-Manager
else
    echo "ComfyUI-Manager already exists, skipping clone..."
fi

# Download model files
echo "
----------------------------------------
📥 Downloading Kohaku model...
----------------------------------------"
if [ ! -f "/workspace/comfyRealtime/ComfyUI/models/checkpoints/kohaku-v2.1.safetensors" ]; then
    wget --content-disposition -P /workspace/comfyRealtime/ComfyUI/models/checkpoints https://huggingface.co/KBlueLeaf/kohaku-v2.1/resolve/main/kohaku-v2.1.safetensors?download=true
else
    echo "Kohaku model already exists, skipping download..."
fi

echo "
----------------------------------------
📥 Downloading Turbo model...
----------------------------------------"
if [ ! -f "/workspace/comfyRealtime/ComfyUI/models/checkpoints/sd_xl_turbo_1.0.safetensors" ]; then
    wget --content-disposition -P /workspace/comfyRealtime/ComfyUI/models/checkpoints https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sd_xl_turbo_1.0.safetensors?download=true
else
    echo "Turbo model already exists, skipping download..."
fi

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

# Create conda environment
echo "
----------------------------------------
🌟 Creating conda environment...
----------------------------------------"
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

cd /workspace/comfyRealtime/ComfyStream
echo "Current directory: $(pwd)"

echo "📦 Installing ComfyStream package..."
pip install .
pip install -r requirements.txt

echo "🔧 Running ComfyStream install script..."
python install.py --workspace /workspace/comfyRealtime/ComfyUI

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

# Install ComfyUI requirements
echo "
----------------------------------------
📦 Installing ComfyUI requirements...
----------------------------------------"
cd ../ComfyUI
pip install -r requirements.txt
cd custom_nodes/ComfyUI-Manager
pip install -r requirements.txt

# Function to install custom nodes and dependencies
install_custom_nodes() {
    echo "
    ----------------------------------------
    📥 Installing Additional Custom Nodes...
    ----------------------------------------"

    # Verify we're in comfystream environment
    if [ "$CONDA_DEFAULT_ENV" != "comfystream" ]; then
        echo "❌ Must be in comfystream environment! Current env: $CONDA_DEFAULT_ENV"
        exit 1
    fi
    
    # Install additional packages first
    echo "Installing additional Python packages..."
    pip install torch==2.5.1 torchvision torchaudio tqdm nvidia-ml-py==12.560.30 diffusers==0.30.1

    CUSTOM_NODES_PATH="/workspace/comfyRealtime/ComfyUI/custom_nodes"

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
}

# Install custom nodes
install_custom_nodes

# Return to base environment
echo "🔄 Deactivating comfystream environment..."
conda deactivate
echo "✅ Successfully deactivated comfystream environment"
echo "✅ Setup complete!"
set +x  # Disable debug mode

# Downgrade huggingface-hub
echo "
----------------------------------------
🔧 Downgrading huggingface-hub...
----------------------------------------"
echo "Downgrading huggingface-hub in comfystream environment..."
conda activate comfystream
pip install huggingface-hub==0.25.0
conda deactivate

echo "✅ Completed huggingface-hub downgrade"

set +x  # Disable debug mode