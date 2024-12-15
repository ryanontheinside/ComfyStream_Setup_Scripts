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

# Return to base environment
echo "🔄 Deactivating comfystream environment..."
conda deactivate
echo "✅ Successfully deactivated comfystream environment"
echo "✅ Setup complete!"
set +x  # Disable debug mode