# PowerShell Setup Script for Stream Audio Isolator (Windows)
# Automates: Download ONNX Runtime → Build Plugin → Install to OBS

param(
    [switch]$SkipModels = $false,
    [switch]$GPU = $false
)

$ErrorActionPreference = "Stop"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Stream Audio Isolator - Windows Setup" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "WARNING: Not running as Administrator" -ForegroundColor Yellow
    Write-Host "Installation will require admin rights later" -ForegroundColor Yellow
    Write-Host ""
}

# Function to check command exists
function Test-Command {
    param($Command)
    try {
        if (Get-Command $Command -ErrorAction Stop) {
            return $true
        }
    } catch {
        return $false
    }
}

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Green

# Check CMake
if (-not (Test-Command "cmake")) {
    Write-Host "[ERROR] CMake not found!" -ForegroundColor Red
    Write-Host "Download from: https://cmake.org/download/" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] CMake found" -ForegroundColor Green

# Check Visual Studio
if (-not (Test-Command "cl")) {
    Write-Host "[ERROR] Visual Studio compiler not found!" -ForegroundColor Red
    Write-Host "Please run from 'Developer PowerShell for VS' or 'Developer Command Prompt for VS'" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] Visual Studio compiler found" -ForegroundColor Green

# Check OBS installation
$obsPath = "C:\Program Files\obs-studio"
if (-not (Test-Path $obsPath)) {
    $obsPath = "C:\Program Files (x86)\obs-studio"
    if (-not (Test-Path $obsPath)) {
        Write-Host "[ERROR] OBS Studio not found!" -ForegroundColor Red
        Write-Host "Install OBS Studio from: https://obsproject.com/download" -ForegroundColor Yellow
        exit 1
    }
}
Write-Host "[OK] OBS found at: $obsPath" -ForegroundColor Green

Write-Host ""

# Download ONNX Runtime
$onnxVersion = "1.16.0"
if ($GPU) {
    $onnxFile = "onnxruntime-win-x64-gpu-$onnxVersion"
    $onnxUrl = "https://github.com/microsoft/onnxruntime/releases/download/v$onnxVersion/$onnxFile.zip"
    Write-Host "Downloading ONNX Runtime (GPU version)..." -ForegroundColor Green
} else {
    $onnxFile = "onnxruntime-win-x64-$onnxVersion"
    $onnxUrl = "https://github.com/microsoft/onnxruntime/releases/download/v$onnxVersion/$onnxFile.zip"
    Write-Host "Downloading ONNX Runtime..." -ForegroundColor Green
}

if (-not (Test-Path $onnxFile)) {
    Write-Host "Downloading from: $onnxUrl" -ForegroundColor Cyan
    Invoke-WebRequest -Uri $onnxUrl -OutFile "$onnxFile.zip"
    Write-Host "Extracting..." -ForegroundColor Cyan
    Expand-Archive -Path "$onnxFile.zip" -DestinationPath "." -Force
    Remove-Item "$onnxFile.zip"
    Write-Host "[OK] ONNX Runtime downloaded" -ForegroundColor Green
} else {
    Write-Host "[OK] ONNX Runtime already downloaded" -ForegroundColor Green
}

$env:ONNXRUNTIME_DIR = Join-Path $PWD $onnxFile
Write-Host "ONNXRUNTIME_DIR set to: $env:ONNXRUNTIME_DIR" -ForegroundColor Cyan
Write-Host ""

# Download models (optional)
if (-not $SkipModels) {
    Write-Host "Checking for AI models..." -ForegroundColor Green

    if (-not (Test-Path "models")) {
        New-Item -ItemType Directory -Path "models" | Out-Null
    }

    # Check if models exist
    $modelExists = Test-Path "models\sherpa-vocals.onnx"

    if (-not $modelExists) {
        Write-Host "[WARNING] Models not found" -ForegroundColor Yellow
        Write-Host "Download models manually from:" -ForegroundColor Yellow
        Write-Host "https://github.com/yourusername/streameraudioremove/releases/tag/models-v1.0" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Or run: .\download-models.ps1" -ForegroundColor Cyan
        Write-Host ""
    } else {
        Write-Host "[OK] Models found" -ForegroundColor Green
    }
}

# Build plugin
Write-Host "Building plugin..." -ForegroundColor Green
Write-Host ""

if (-not (Test-Path "build")) {
    New-Item -ItemType Directory -Path "build" | Out-Null
}

Set-Location build

Write-Host "Configuring with CMake..." -ForegroundColor Cyan
cmake .. `
    -G "Visual Studio 16 2019" `
    -A x64 `
    -DCMAKE_BUILD_TYPE=Release `
    -DONNXRUNTIME_DIR="$env:ONNXRUNTIME_DIR"

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] CMake configuration failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Building (Release)..." -ForegroundColor Cyan
cmake --build . --config Release

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Build failed!" -ForegroundColor Red
    exit 1
}

Set-Location ..

Write-Host ""
Write-Host "================================" -ForegroundColor Green
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

# Offer to install
Write-Host "Would you like to install the plugin now? (Requires Administrator)" -ForegroundColor Yellow
$install = Read-Host "Install? (Y/N)"

if ($install -eq "Y" -or $install -eq "y") {
    if (-not $isAdmin) {
        Write-Host "Restarting as Administrator..." -ForegroundColor Cyan
        Start-Process powershell -Verb RunAs -ArgumentList "-File install.bat"
    } else {
        # Install directly
        Write-Host "Installing plugin..." -ForegroundColor Green

        # Copy plugin DLL
        Copy-Item "build\Release\stream-audio-isolator.dll" "$obsPath\obs-plugins\64bit\" -Force
        Write-Host "[OK] Plugin DLL copied" -ForegroundColor Green

        # Copy data files
        if (Test-Path "$obsPath\data\obs-plugins\stream-audio-isolator") {
            Remove-Item "$obsPath\data\obs-plugins\stream-audio-isolator" -Recurse -Force
        }
        Copy-Item "data" "$obsPath\data\obs-plugins\stream-audio-isolator" -Recurse -Force
        Write-Host "[OK] Data files copied" -ForegroundColor Green

        # Copy ONNX Runtime DLL
        $onnxDll = Join-Path $env:ONNXRUNTIME_DIR "lib\onnxruntime.dll"
        if (Test-Path $onnxDll) {
            Copy-Item $onnxDll "$obsPath\obs-plugins\64bit\" -Force
            Write-Host "[OK] ONNX Runtime DLL copied" -ForegroundColor Green
        }

        # Copy models
        if (Test-Path "models\*.onnx") {
            if (-not (Test-Path "$obsPath\data\obs-plugins\stream-audio-isolator\models")) {
                New-Item -ItemType Directory -Path "$obsPath\data\obs-plugins\stream-audio-isolator\models" | Out-Null
            }
            Copy-Item "models\*.onnx" "$obsPath\data\obs-plugins\stream-audio-isolator\models\" -Force
            Write-Host "[OK] Models copied" -ForegroundColor Green
        }

        Write-Host ""
        Write-Host "================================" -ForegroundColor Green
        Write-Host "Installation completed!" -ForegroundColor Green
        Write-Host "================================" -ForegroundColor Green
    }
} else {
    Write-Host ""
    Write-Host "To install later, run: install.bat (as Administrator)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Restart OBS Studio" -ForegroundColor White
Write-Host "2. Right-click Microphone > Filters" -ForegroundColor White
Write-Host "3. Add 'Audio Isolation (Music Removal)'" -ForegroundColor White
Write-Host "4. Select AI engine and adjust strength" -ForegroundColor White
Write-Host ""
Write-Host "Enjoy DMCA-free streaming! 🎉" -ForegroundColor Cyan
Write-Host ""
