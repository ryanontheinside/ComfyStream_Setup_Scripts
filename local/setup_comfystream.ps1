# setup_comfy.ps1

param(
    [switch]$DownloadModels = $false
)

# Get NVIDIA GPU information
function Test-NvidiaGPU {
    $gpu = Get-WmiObject -Query "SELECT * FROM Win32_VideoController WHERE Name LIKE '%NVIDIA%'"
    return $null -ne $gpu
}

$ErrorActionPreference = "Stop"

try {
    $baseWorkspace = "$PWD"
    $comfyUIPath = "$baseWorkspace\ComfyUI"
    $realtimePath = "$baseWorkspace\comfyRealtime"

    Write-Host "
==========================================
Starting Dual ComfyUI and ComfyStream setup...
==========================================
Press Ctrl+C at any time to cancel

Download models: $DownloadModels
"

    # Create base directories
    Write-Host "
------------------------------------------
Creating workspaces...
------------------------------------------"
    New-Item -ItemType Directory -Force -Path $comfyUIPath
    New-Item -ItemType Directory -Force -Path $realtimePath

    # Clone repositories
    Write-Host "
------------------------------------------
Cloning repositories...
------------------------------------------"

    # Clone ComfyUI to both locations
    if (-not (Test-Path "$comfyUIPath\.git")) {
        git clone https://github.com/comfyanonymous/ComfyUI.git $comfyUIPath
    } else {
        Write-Host "ComfyUI already exists in main location, skipping clone..."
    }

    if (-not (Test-Path "$realtimePath\ComfyUI\.git")) {
        git clone https://github.com/comfyanonymous/ComfyUI.git "$realtimePath\ComfyUI"
    } else {
        Write-Host "ComfyUI already exists in realtime location, skipping clone..."
    }

    # Clone ComfyStream
    if (-not (Test-Path "$realtimePath\ComfyStream\.git")) {
        git clone https://github.com/yondonfu/comfystream.git "$realtimePath\ComfyStream"
    } else {
        Write-Host "ComfyStream already exists, skipping clone..."
    }

#Cloning repos as Admin is  suspicious to git.
#     # Create symbolic link for models
#     Write-Host "
# ------------------------------------------
# Setting up models symlink...
# ------------------------------------------"
#     if (Test-Path "$realtimePath\ComfyUI\models") {
#         Remove-Item "$realtimePath\ComfyUI\models" -Recurse -Force
#     }
#     New-Item -ItemType SymbolicLink -Path "$realtimePath\ComfyUI\models" -Target "$comfyUIPath\models"

    # Install ComfyUI-Manager to first install
    Write-Host "
------------------------------------------
Installing ComfyUI-Manager...
------------------------------------------"
    if (-not (Test-Path "$comfyUIPath\custom_nodes\ComfyUI-Manager\.git")) {
        git clone https://github.com/ltdrdata/ComfyUI-Manager.git "$comfyUIPath\custom_nodes\ComfyUI-Manager"
    } else {
        Write-Host "ComfyUI-Manager already exists in first installation, skipping clone..."
    }

    # Copy ComfyUI-Manager to second install
    Write-Host "
------------------------------------------
Copying ComfyUI-Manager to second installation...
------------------------------------------"
    if (-not (Test-Path "$realtimePath\ComfyUI\custom_nodes\ComfyUI-Manager")) {
        Copy-Item -Path "$comfyUIPath\custom_nodes\ComfyUI-Manager" -Destination "$realtimePath\ComfyUI\custom_nodes\" -Recurse
    } else {
        Write-Host "ComfyUI-Manager already exists in second installation, skipping copy..."
    }

    # Install RealTimeNodes to first install
    Write-Host "
    ------------------------------------------
    Installing ComfyUI RealTimeNodes...
    ------------------------------------------"
    if (-not (Test-Path "$comfyUIPath\custom_nodes\ComfyUI_RealTimeNodes\.git")) {
        git clone https://github.com/ryanontheinside/ComfyUI_RealTimeNodes.git "$comfyUIPath\custom_nodes\ComfyUI_RealTimeNodes"
    } else {
        Write-Host "ComfyUI RealTimeNodes already exists in first installation, skipping clone..."
    }

    # Copy RealTimeNodes to second install
    Write-Host "
    ------------------------------------------
    Copying RealTimeNodes to second installation...
    ------------------------------------------"
    if (-not (Test-Path "$realtimePath\ComfyUI\custom_nodes\ComfyUI_RealTimeNodes")) {
        Copy-Item -Path "$comfyUIPath\custom_nodes\ComfyUI_RealTimeNodes" -Destination "$realtimePath\ComfyUI\custom_nodes\" -Recurse
    } else {
        Write-Host "ComfyUI RealTimeNodes already exists in second installation, skipping copy..."
    }

    # Download models if requested
    if ($DownloadModels) {
        Write-Host "
------------------------------------------
Downloading models...
------------------------------------------"
        $modelPath = "$comfyUIPath\models\checkpoints"
        New-Item -ItemType Directory -Force -Path $modelPath

        if (-not (Test-Path "$modelPath\kohaku-v2.1.safetensors")) {
            Write-Host "Downloading Kohaku model..."
            Invoke-WebRequest -Uri "https://huggingface.co/KBlueLeaf/kohaku-v2.1/resolve/main/kohaku-v2.1.safetensors?download=true" -OutFile "$modelPath\kohaku-v2.1.safetensors"
        }

        if (-not (Test-Path "$modelPath\sd_xl_turbo_1.0.safetensors")) {
            Write-Host "Downloading Turbo model..."
            Invoke-WebRequest -Uri "https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sd_xl_turbo_1.0.safetensors?download=true" -OutFile "$modelPath\sd_xl_turbo_1.0.safetensors"
        }
    }

    # Create and setup conda environments
    Write-Host "
------------------------------------------
Setting up Python environments...
------------------------------------------"
    # Create comfyui environment
    conda create -n comfyui python=3.11 -y
    & "$env:USERPROFILE\miniconda3\shell\condabin\conda-hook.ps1"
    conda activate comfyui
    conda run -n comfyui python -m pip install --upgrade pip
    conda run -n comfyui conda install pytorch torchvision torchaudio pytorch-cuda -c pytorch -c nvidia -y
    
    # Install ComfyUI requirements in main installation
    Write-Host "
------------------------------------------
Installing main ComfyUI requirements...
------------------------------------------"
    Set-Location $comfyUIPath

    # Check for NVIDIA GPU and install appropriate PyTorch version
    if (Test-NvidiaGPU) {
        Write-Host "NVIDIA GPU detected. Installing CUDA-enabled PyTorch..."
        & conda run -n comfyui conda install pytorch torchvision torchaudio pytorch-cuda -c pytorch -c nvidia -y
    } else {
        Write-Host "No NVIDIA GPU detected. Installing CPU-only PyTorch..."
        & conda run -n comfyui conda install pytorch torchvision torchaudio cpuonly -c pytorch -y
        Write-Host "
        WARNING: Running ComfyUI without an NVIDIA GPU will be significantly slower.
        Image generation may take several minutes or longer per image.
        " -ForegroundColor Yellow
    }
    conda run -n comfyui pip install -r requirements.txt

    conda deactivate
    & "$env:USERPROFILE\miniconda3\shell\condabin\conda-hook.ps1"

    Set-Location "custom_nodes\ComfyUI-Manager"
    # Install ComfyStream
    Write-Host "
------------------------------------------
Installing ComfyStream...
------------------------------------------"
    Set-Location "$realtimePath\ComfyStream"
    # Create and setup comfystream environment
    conda create -n comfystream python=3.11 -y
    & "$env:USERPROFILE\miniconda3\shell\condabin\conda-hook.ps1"
    conda activate comfystream
    conda run -n comfystream pip install .
    conda run -n comfystream pip install -r requirements.txt
    conda run -n comfystream pip install twilio aiortc
    conda run -n comfystream conda install pytorch-cuda -c pytorch -c nvidia -y
    conda run -n comfystream python install.py --workspace "$realtimePath\ComfyUI"

    # Copy tensor utils
    Write-Host "
------------------------------------------
Copying tensor utils...
------------------------------------------"
    if (-not (Test-Path "$realtimePath\ComfyUI\custom_nodes\tensor_utils")) {
        Copy-Item -Path "nodes\tensor_utils" -Destination "$realtimePath\ComfyUI\custom_nodes\" -Recurse -Force
    }

    conda deactivate
    & "$env:USERPROFILE\miniconda3\shell\condabin\conda-hook.ps1"

    # Downgrade huggingface-hub in both environments
    Write-Host "
------------------------------------------
Downgrading huggingface-hub...
------------------------------------------"
    
    # Downgrade in comfyui environment
    Write-Host "Downgrading huggingface-hub in comfyui environment..."
    conda activate comfyui
    conda run -n comfyui pip install huggingface-hub==0.25.0
    conda deactivate

    # Downgrade in comfystream environment
    Write-Host "Downgrading huggingface-hub in comfystream environment..."
    conda activate comfystream
    conda run -n comfystream pip install huggingface-hub==0.25.0
    conda deactivate

    Write-Host "
==========================================
Setup Complete!
Main ComfyUI: $comfyUIPath
Realtime workspace: $realtimePath
==========================================
"
}
catch {
    Write-Host "
==========================================
Setup cancelled or error occurred!
Error: $($_.Exception.Message)
==========================================
" -ForegroundColor Red
    
    # Cleanup if needed
    if ($CONDA_DEFAULT_ENV -eq "comfystream" -or $CONDA_DEFAULT_ENV -eq "comfyui") {
        conda deactivate
    }
    
    # Return to original directory
    Set-Location $PSScriptRoot
    
    exit 1
}

# Function to install custom nodes and dependencies
function Install-CustomNodes {
    param (
        [string]$EnvName,
        [string]$CustomNodesPath
    )

    Write-Host "
------------------------------------------
Installing Additional Custom Nodes for $EnvName...
------------------------------------------"

    # Verify we're in the correct environment
    if ($env:CONDA_DEFAULT_ENV -ne $EnvName) {
        Write-Host "❌ Must be in $EnvName environment! Current env: $env:CONDA_DEFAULT_ENV" -ForegroundColor Red
        exit 1
    }

    # Install additional packages first
    Write-Host "Installing additional Python packages..."
    conda run -n $EnvName pip install torch==2.5.1 torchvision torchaudio tqdm nvidia-ml-py==12.560.30 diffusers==0.30.1

    # Install ComfyUI-Depth-Anything-Tensorrt
    if (-not (Test-Path "$CustomNodesPath\ComfyUI-Depth-Anything-Tensorrt\.git")) {
        git clone https://github.com/yuvraj108c/ComfyUI-Depth-Anything-Tensorrt.git "$CustomNodesPath\ComfyUI-Depth-Anything-Tensorrt"
        Set-Location "$CustomNodesPath\ComfyUI-Depth-Anything-Tensorrt"
        conda run -n $EnvName pip install -r requirements.txt
    }

    # Install ComfyUI-Misc-Effects
    if (-not (Test-Path "$CustomNodesPath\ComfyUI-Misc-Effects\.git")) {
        git clone https://github.com/ryanontheinside/ComfyUI-Misc-Effects.git "$CustomNodesPath\ComfyUI-Misc-Effects"
        Set-Location "$CustomNodesPath\ComfyUI-Misc-Effects"
        git checkout c6b360c78611134c3723388170475eb4898ff6b7
    }

    # Install ComfyUI-SAM2-Realtime
    if (-not (Test-Path "$CustomNodesPath\ComfyUI-SAM2-Realtime\.git")) {
        git clone https://github.com/pschroedl/ComfyUI-SAM2-Realtime.git "$CustomNodesPath\ComfyUI-SAM2-Realtime"
        Set-Location "$CustomNodesPath\ComfyUI-SAM2-Realtime"
        git checkout 4f587443fb2808c4b5b303afcd7ec3ec3e0fbd08
        conda run -n $EnvName pip install -r requirements.txt
    }

    # Install ComfyUI-Florence2-Vision
    if (-not (Test-Path "$CustomNodesPath\ComfyUI-Florence2-Vision\.git")) {
        git clone https://github.com/ad-astra-video/ComfyUI-Florence2-Vision.git "$CustomNodesPath\ComfyUI-Florence2-Vision"
        Set-Location "$CustomNodesPath\ComfyUI-Florence2-Vision"
        git checkout 0c624e61b6606801751bd41d93a09abe9844bea7
        conda run -n $EnvName pip install -r requirements.txt
    }

    # Install ComfyUI-StreamDiffusion
    if (-not (Test-Path "$CustomNodesPath\ComfyUI-StreamDiffusion\.git")) {
        git clone https://github.com/pschroedl/ComfyUI-StreamDiffusion.git "$CustomNodesPath\ComfyUI-StreamDiffusion"
        Set-Location "$CustomNodesPath\ComfyUI-StreamDiffusion"
        git checkout f93b98aa9f20ab46c23d149ad208d497cd496579
        conda run -n $EnvName pip install -r requirements.txt
    }

    # Install ComfyUI-LivePortraitKJ
    if (-not (Test-Path "$CustomNodesPath\ComfyUI-LivePortraitKJ\.git")) {
        git clone https://github.com/kijai/ComfyUI-LivePortraitKJ.git "$CustomNodesPath\ComfyUI-LivePortraitKJ"
        Set-Location "$CustomNodesPath\ComfyUI-LivePortraitKJ"
        git checkout 4d9dc6205b793ffd0fb319816136d9b8c0dbfdff
        conda run -n $EnvName pip install -r requirements.txt
    }

    # Install ComfyUI-load-image-from-url
    if (-not (Test-Path "$CustomNodesPath\ComfyUI-load-image-from-url\.git")) {
        git clone https://github.com/tsogzark/ComfyUI-load-image-from-url.git "$CustomNodesPath\ComfyUI-load-image-from-url"
    }
}