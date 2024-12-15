# setup_comfy.ps1

param(
    [switch]$DownloadModels = $false
)

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

    # Create symbolic link for models
    Write-Host "
------------------------------------------
Setting up models symlink...
------------------------------------------"
    if (Test-Path "$realtimePath\ComfyUI\models") {
        Remove-Item "$realtimePath\ComfyUI\models" -Recurse -Force
    }
    New-Item -ItemType SymbolicLink -Path "$realtimePath\ComfyUI\models" -Target "$comfyUIPath\models"

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
    conda activate comfyui

    # Install ComfyUI requirements in main installation
    Write-Host "
------------------------------------------
Installing main ComfyUI requirements...
------------------------------------------"
    Set-Location $comfyUIPath
    pip install -r requirements.txt
    Set-Location "custom_nodes\ComfyUI-Manager"
    pip install -r requirements.txt

    conda deactivate

    # Create and setup comfystream environment
    conda create -n comfystream python=3.11 -y
    conda activate comfystream
    
    # Install ComfyStream
    Write-Host "
------------------------------------------
Installing ComfyStream...
------------------------------------------"
    Set-Location "$realtimePath\ComfyStream"
    pip install .
    pip install -r requirements.txt
    python install.py --workspace "$realtimePath\ComfyUI"

    # Copy tensor utils
    Write-Host "
------------------------------------------
Copying tensor utils...
------------------------------------------"
    if (-not (Test-Path "$realtimePath\ComfyUI\custom_nodes\tensor_utils")) {
        Copy-Item -Path "nodes\tensor_utils" -Destination "$realtimePath\ComfyUI\custom_nodes\" -Recurse -Force
    }

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