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