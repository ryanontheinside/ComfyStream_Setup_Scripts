# setup_comfy.ps1
# $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
# $workspacePath = "$scriptPath\comfyRealtime"

param(
    [switch]$DownloadModels = $false
)

$ErrorActionPreference = "Stop"

try {
    $workspacePath = "$PWD\comfyRealtime"

    Write-Host "
==========================================
Starting ComfyUI and ComfyStream setup...
==========================================
Press Ctrl+C at any time to cancel

Download models: $DownloadModels
"

    # Create base directory
    Write-Host "
------------------------------------------
Creating workspace at: $workspacePath
------------------------------------------"
    New-Item -ItemType Directory -Force -Path $workspacePath

    # Clone repositories
    Write-Host "
------------------------------------------
Cloning repositories...
------------------------------------------"

    # Clone ComfyUI
    if (-not (Test-Path "$workspacePath\ComfyUI\.git")) {
        git clone https://github.com/comfyanonymous/ComfyUI.git "$workspacePath\ComfyUI"
    } else {
        Write-Host "ComfyUI already exists, skipping clone..."
    }

    # Clone ComfyStream
    if (-not (Test-Path "$workspacePath\ComfyStream\.git")) {
        git clone https://github.com/yondonfu/comfystream.git "$workspacePath\ComfyStream"
    } else {
        Write-Host "ComfyStream already exists, skipping clone..."
    }

    # Install ComfyUI-Manager
    Write-Host "
------------------------------------------
Installing ComfyUI-Manager...
------------------------------------------"
    if (-not (Test-Path "$workspacePath\ComfyUI\custom_nodes\ComfyUI-Manager\.git")) {
        git clone https://github.com/ltdrdata/ComfyUI-Manager.git "$workspacePath\ComfyUI\custom_nodes\ComfyUI-Manager"
    } else {
        Write-Host "ComfyUI-Manager already exists, skipping clone..."
    }

    # Download models if requested
    if ($DownloadModels) {
        Write-Host "
------------------------------------------
Downloading models...
------------------------------------------"
        $modelPath = "$workspacePath\ComfyUI\models\checkpoints"
        New-Item -ItemType Directory -Force -Path $modelPath

        # if (-not (Test-Path "$modelPath\kohaku-v2.1.safetensors")) {
        #     Write-Host "Downloading Kohaku model..."
        #     Invoke-WebRequest -Uri "https://huggingface.co/KBlueLeaf/kohaku-v2.1/resolve/main/kohaku-v2.1.safetensors?download=true" -OutFile "$modelPath\kohaku-v2.1.safetensors"
        # }

        if (-not (Test-Path "$modelPath\sd_xl_turbo_1.0.safetensors")) {
            Write-Host "Downloading Turbo model..."
            Invoke-WebRequest -Uri "https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sd_xl_turbo_1.0.safetensors?download=true" -OutFile "$modelPath\sd_xl_turbo_1.0.safetensors"
        }
    } else {
        Write-Host "
------------------------------------------
Skipping model downloads...
------------------------------------------"
    }

    # Create and setup conda environment
    Write-Host "
------------------------------------------
Setting up Python environment...
------------------------------------------"
    conda create -n comfystream python=3.11 -y
    conda activate comfystream

    # Install ComfyUI requirements
    Write-Host "
------------------------------------------
Installing ComfyUI requirements...
------------------------------------------"
    Set-Location "$workspacePath\ComfyUI"
    pip install -r requirements.txt
    Set-Location "custom_nodes\ComfyUI-Manager"
    pip install -r requirements.txt

    conda deactivate
    
    # Install ComfyStream
    Write-Host "
------------------------------------------
Installing ComfyStream...
------------------------------------------"
    Set-Location "$workspacePath\ComfyStream"
    pip install .
    pip install -r requirements.txt
    python install.py --workspace "$workspacePath\ComfyUI"

    # Copy tensor utils
    Write-Host "
------------------------------------------
Copying tensor utils...
------------------------------------------"
    if (-not (Test-Path "$workspacePath\ComfyUI\custom_nodes\tensor_utils")) {
        Copy-Item -Path "nodes\tensor_utils" -Destination "$workspacePath\ComfyUI\custom_nodes\" -Recurse -Force
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

    # Install custom nodes
    Install-CustomNodes -EnvName "comfystream" -CustomNodesPath "$workspacePath\ComfyUI\custom_nodes"

    Write-Host "
==========================================
Setup Complete!
Your workspace is located at: $workspacePath
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
    if ($CONDA_DEFAULT_ENV -eq "comfystream") {
        conda deactivate
    }
    
    # Return to original directory
    Set-Location $PSScriptRoot
    
    exit 1
}