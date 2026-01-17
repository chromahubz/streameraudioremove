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

echo This script will download ~243 MB of AI models from Hugging Face
echo Using UVR (Ultimate Vocal Remover) MDX-Net models
echo.
pause

REM ================================================================
REM Model 1: Sherpa-ONNX (64 MB) - UVR-MDX-NET-Inst_HQ_1
REM ================================================================

echo.
echo [1/4] Downloading Sherpa-ONNX model (64 MB)...

curl -L "https://huggingface.co/Blane187/all_public_uvr_models/resolve/main/UVR-MDX-NET-Inst_HQ_1.onnx" -o models\sherpa-vocals.onnx

if exist models\sherpa-vocals.onnx (
    echo [OK] Sherpa-ONNX downloaded (64 MB)
) else (
    echo [ERROR] Failed to download Sherpa-ONNX
    echo.
    echo Manual download:
    echo 1. Visit: https://huggingface.co/Blane187/all_public_uvr_models
    echo 2. Download UVR-MDX-NET-Inst_HQ_1.onnx
    echo 3. Save as: models\sherpa-vocals.onnx
    echo.
)

REM ================================================================
REM Model 2: HS-TasNet (64 MB) - UVR-MDX-NET-Inst_HQ_2
REM ================================================================

echo.
echo [2/4] Downloading HS-TasNet model (64 MB)...

curl -L "https://huggingface.co/seanghay/uvr_models/resolve/main/UVR-MDX-NET-Inst_HQ_2.onnx?download=true" -o models\hstasnet-vocals.onnx

if exist models\hstasnet-vocals.onnx (
    echo [OK] HS-TasNet downloaded (64 MB)
) else (
    echo [ERROR] Failed to download HS-TasNet
    echo.
    echo Manual download:
    echo 1. Visit: https://huggingface.co/seanghay/uvr_models
    echo 2. Download UVR-MDX-NET-Inst_HQ_2.onnx
    echo 3. Save as: models\hstasnet-vocals.onnx
    echo.
)

REM ================================================================
REM Model 3: ClearerVoice (64 MB) - UVR-MDX-NET-Inst_HQ_3
REM ================================================================

echo.
echo [3/4] Downloading ClearerVoice model (64 MB)...

curl -L "https://huggingface.co/seanghay/uvr_models/resolve/main/UVR-MDX-NET-Inst_HQ_3.onnx?download=true" -o models\clearervoice-vocals.onnx

if exist models\clearervoice-vocals.onnx (
    echo [OK] ClearerVoice downloaded (64 MB)
) else (
    echo [ERROR] Failed to download ClearerVoice
    echo.
    echo Manual download:
    echo 1. Visit: https://huggingface.co/seanghay/uvr_models
    echo 2. Download UVR-MDX-NET-Inst_HQ_3.onnx
    echo 3. Save as: models\clearervoice-vocals.onnx
    echo.
)

REM ================================================================
REM Model 4: SpleeterRT (51 MB) - UVR_MDXNET_KARA_2
REM ================================================================

echo.
echo [4/4] Downloading SpleeterRT model (51 MB)...

curl -L "https://huggingface.co/seanghay/uvr_models/resolve/main/UVR_MDXNET_KARA_2.onnx?download=true" -o models\spleeterrt-vocals.onnx

if exist models\spleeterrt-vocals.onnx (
    echo [OK] SpleeterRT downloaded (51 MB)
) else (
    echo [ERROR] Failed to download SpleeterRT
    echo.
    echo Manual download:
    echo 1. Visit: https://huggingface.co/seanghay/uvr_models
    echo 2. Download UVR_MDXNET_KARA_2.onnx
    echo 3. Save as: models\spleeterrt-vocals.onnx
    echo.
)

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
    echo 1. Run this script again to download models
    echo 2. Or download manually from Hugging Face
    echo 3. Place in models\ directory:
    echo    - models\sherpa-vocals.onnx (required)
    echo    - models\hstasnet-vocals.onnx (optional)
    echo    - models\clearervoice-vocals.onnx (optional)
    echo    - models\spleeterrt-vocals.onnx (optional)
    echo.
    echo Total size: ~243 MB
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
