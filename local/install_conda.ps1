# install_conda.ps1
$condaPath = "$env:USERPROFILE\miniconda3"

Write-Host "
========================================
Checking Conda Installation...
========================================"

# Check if conda exists in PATH or in default location
if (-not (Get-Command conda -ErrorAction SilentlyContinue) -and -not (Test-Path "$condaPath\Scripts\conda.exe")) {
    Write-Host "Conda not found. Installing Miniconda..."
    
    # Download Miniconda
    $installerPath = "$env:TEMP\Miniconda3-latest-Windows-x86_64.exe"
    if (-not (Test-Path $installerPath)) {
        Write-Host "Downloading Miniconda installer..."
        Invoke-WebRequest -Uri "https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe" -OutFile $installerPath
    } else {
        Write-Host "Miniconda installer already exists. Skipping download."
    }
    
    # Install Miniconda silently
    Start-Process -FilePath $installerPath -ArgumentList "/S /D=$condaPath" -Wait
    
    # Add to PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    Write-Host "Conda is already installed"
}