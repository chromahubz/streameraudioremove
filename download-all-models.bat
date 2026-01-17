@echo off
REM Download all AI models for Stream Audio Isolator
REM Run this before building the installer to include models

echo ================================================================
echo Downloading AI Models for Stream Audio Isolator
echo ================================================================
echo.

REM Create models directory
if not exist "models" mkdir models

REM Model URLs (you'll need to update these with actual URLs)
REM For now, using placeholder URLs - replace with actual model locations

echo This script will download ~60 MB of AI models
echo.
pause

REM ================================================================
REM Model 1: Sherpa-ONNX (~15 MB)
REM ================================================================

echo.
echo [1/4] Downloading Sherpa-ONNX model (15 MB)...

REM Option A: Download from Sherpa-ONNX releases
curl -L https://github.com/k2-fsa/sherpa-onnx/releases/download/audio-tagging-models/sherpa-onnx-zipformer-audio-tagging-2024-04-09.tar.bz2 -o models/sherpa-temp.tar.bz2

if exist models\sherpa-temp.tar.bz2 (
    echo Extracting Sherpa model...
    tar -xjf models\sherpa-temp.tar.bz2 -C models\

    REM Find and rename the model file
    for /r models %%f in (*.onnx) do (
        copy "%%f" models\sherpa-vocals.onnx
        goto :sherpa_done
    )
    :sherpa_done

    del models\sherpa-temp.tar.bz2
    echo [OK] Sherpa-ONNX downloaded
) else (
    echo [ERROR] Failed to download Sherpa-ONNX
    echo.
    echo Manual download:
    echo 1. Visit: https://github.com/k2-fsa/sherpa-onnx/releases
    echo 2. Download any audio separation model
    echo 3. Save as: models\sherpa-vocals.onnx
    echo.
)

REM ================================================================
REM Model 2: HS-TasNet (~8 MB)
REM ================================================================

echo.
echo [2/4] Downloading HS-TasNet model (8 MB)...

REM This model needs to be converted from PyTorch
REM For now, create a placeholder message

echo [INFO] HS-TasNet model requires conversion from source
echo.
echo To get this model:
echo 1. See MODELS.md for conversion instructions
echo 2. Or download pre-converted from your GitHub releases
echo 3. Save as: models\hstasnet.onnx
echo.

REM Placeholder for actual download (update URL when available)
REM curl -L https://github.com/YOUR_REPO/releases/download/models-v1.0/hstasnet.onnx -o models\hstasnet.onnx

REM ================================================================
REM Model 3: ClearerVoice (~12 MB)
REM ================================================================

echo.
echo [3/4] Downloading ClearerVoice model (12 MB)...

REM ClearerVoice from ModelScope
echo [INFO] ClearerVoice model requires ModelScope download
echo.
echo To get this model:
echo 1. See MODELS.md for download instructions
echo 2. Or download pre-converted from your GitHub releases
echo 3. Save as: models\clearervoice.onnx
echo.

REM Placeholder for actual download
REM curl -L https://github.com/YOUR_REPO/releases/download/models-v1.0/clearervoice.onnx -o models\clearervoice.onnx

REM ================================================================
REM Model 4: SpleeterRT (~20 MB)
REM ================================================================

echo.
echo [4/4] Downloading SpleeterRT model (20 MB)...

REM SpleeterRT model
echo [INFO] SpleeterRT model requires conversion from Spleeter
echo.
echo To get this model:
echo 1. See MODELS.md for conversion instructions
echo 2. Or download pre-converted from your GitHub releases
echo 3. Save as: models\spleeterrt.onnx
echo.

REM Placeholder for actual download
REM curl -L https://github.com/YOUR_REPO/releases/download/models-v1.0/spleeterrt.onnx -o models\spleeterrt.onnx

REM ================================================================
REM Summary
REM ================================================================

echo.
echo ================================================================
echo Model Download Summary
echo ================================================================
echo.

dir /b models\*.onnx 2>nul
if errorlevel 1 (
    echo [WARNING] No ONNX models found!
    echo.
    echo IMPORTANT: You need to provide models before building installer.
    echo.
    echo Quick solution:
    echo 1. Download pre-converted models from your GitHub releases
    echo 2. Or convert models yourself (see MODELS.md)
    echo 3. Place in models\ directory:
    echo    - models\sherpa-vocals.onnx
    echo    - models\hstasnet.onnx (optional)
    echo    - models\clearervoice.onnx (optional)
    echo    - models\spleeterrt.onnx (optional)
    echo.
    echo At minimum, include sherpa-vocals.onnx for CPU-only users.
    echo.
) else (
    echo Found models:
    for %%f in (models\*.onnx) do (
        echo   - %%~nxf (%%~zf bytes)
    )
    echo.
    echo [OK] Ready to build installer with models!
)

echo.
echo Next step: build-installer.bat
echo.

pause
