# PowerShell Script to Download AI Models for Stream Audio Isolator

param(
    [switch]$All = $false,
    [string]$Model = "sherpa"
)

$ErrorActionPreference = "Stop"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Model Downloader" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Model information
$models = @{
    "sherpa" = @{
        "name" = "Sherpa-ONNX (CPU)"
        "file" = "sherpa-vocals.onnx"
        "url" = "https://github.com/chromahubz/streameraudioremove/releases/download/models-v1.0/sherpa-vocals.onnx"
        "size" = "15 MB"
        "description" = "Fast CPU processing, works on any PC"
        "required" = $true
    }
    "hstasnet" = @{
        "name" = "HS-TasNet (GPU)"
        "file" = "hstasnet.onnx"
        "url" = "https://github.com/chromahubz/streameraudioremove/releases/download/models-v1.0/hstasnet.onnx"
        "size" = "8 MB"
        "description" = "Ultra-low latency with NVIDIA GPU"
        "required" = $false
    }
    "clearervoice" = @{
        "name" = "ClearerVoice"
        "file" = "clearervoice.onnx"
        "url" = "https://github.com/chromahubz/streameraudioremove/releases/download/models-v1.0/clearervoice.onnx"
        "size" = "12 MB"
        "description" = "Best speech clarity"
        "required" = $false
    }
    "spleeterrt" = @{
        "name" = "SpleeterRT"
        "file" = "spleeterrt.onnx"
        "url" = "https://github.com/chromahubz/streameraudioremove/releases/download/models-v1.0/spleeterrt.onnx"
        "size" = "20 MB"
        "description" = "Highest separation quality"
        "required" = $false
    }
}

# Create models directory
if (-not (Test-Path "models")) {
    New-Item -ItemType Directory -Path "models" | Out-Null
    Write-Host "Created models directory" -ForegroundColor Green
}

# Function to download a model
function Download-Model {
    param($ModelKey)

    $modelInfo = $models[$ModelKey]
    $outputPath = Join-Path "models" $modelInfo.file

    Write-Host "Downloading: $($modelInfo.name)" -ForegroundColor Cyan
    Write-Host "Description: $($modelInfo.description)" -ForegroundColor Gray
    Write-Host "Size: $($modelInfo.size)" -ForegroundColor Gray

    if (Test-Path $outputPath) {
        Write-Host "[SKIP] Model already exists: $outputPath" -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "Downloading from: $($modelInfo.url)" -ForegroundColor Gray
        Invoke-WebRequest -Uri $modelInfo.url -OutFile $outputPath -UseBasicParsing
        Write-Host "[OK] Downloaded: $outputPath" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to download $($modelInfo.name)" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red

        # Remove partial download
        if (Test-Path $outputPath) {
            Remove-Item $outputPath
        }
    }

    Write-Host ""
}

# Download models
if ($All) {
    Write-Host "Downloading all models..." -ForegroundColor Green
    Write-Host ""

    foreach ($key in $models.Keys) {
        Download-Model $key
    }
} else {
    if ($models.ContainsKey($Model)) {
        Download-Model $Model
    } else {
        Write-Host "[ERROR] Unknown model: $Model" -ForegroundColor Red
        Write-Host ""
        Write-Host "Available models:" -ForegroundColor Yellow
        foreach ($key in $models.Keys) {
            $info = $models[$key]
            Write-Host "  $key - $($info.name) ($($info.size))" -ForegroundColor White
        }
        Write-Host ""
        Write-Host "Usage examples:" -ForegroundColor Yellow
        Write-Host "  .\download-models.ps1 -Model sherpa" -ForegroundColor Cyan
        Write-Host "  .\download-models.ps1 -All" -ForegroundColor Cyan
        exit 1
    }
}

Write-Host "================================" -ForegroundColor Green
Write-Host "Download completed!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

# Check if models exist
$downloadedModels = Get-ChildItem "models\*.onnx" -ErrorAction SilentlyContinue

if ($downloadedModels) {
    Write-Host "Downloaded models:" -ForegroundColor Green
    foreach ($file in $downloadedModels) {
        $sizeMB = [math]::Round($file.Length / 1MB, 2)
        Write-Host "  $($file.Name) ($sizeMB MB)" -ForegroundColor White
    }
} else {
    Write-Host "[WARNING] No models downloaded" -ForegroundColor Yellow
    Write-Host "Models may not be available yet on GitHub releases" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternative: Convert models yourself" -ForegroundColor Cyan
    Write-Host "See MODELS.md for instructions" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Next: Build and install plugin" -ForegroundColor Yellow
Write-Host "  .\setup-windows.ps1" -ForegroundColor Cyan
Write-Host ""
