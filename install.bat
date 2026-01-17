@echo off
REM Automated installer for Stream Audio Isolator (Windows)
REM NOTE: Must run as Administrator!

echo ================================
echo Stream Audio Isolator - Installer
echo ================================
echo.

REM Check for admin rights
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: This script requires Administrator privileges!
    echo.
    echo Right-click install.bat and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo [OK] Running as Administrator
echo.

REM Find OBS installation
set OBS_DIR=C:\Program Files\obs-studio
if not exist "%OBS_DIR%" (
    set OBS_DIR=C:\Program Files (x86)\obs-studio
)

if not exist "%OBS_DIR%" (
    echo ERROR: OBS Studio not found!
    echo.
    echo Please install OBS Studio first: https://obsproject.com/download
    echo.
    pause
    exit /b 1
)

echo [OK] Found OBS at: %OBS_DIR%
echo.

REM Check if plugin was built
if not exist "build\Release\stream-audio-isolator.dll" (
    echo ERROR: Plugin not built!
    echo.
    echo Run build.bat first to compile the plugin
    echo.
    pause
    exit /b 1
)

echo [OK] Plugin DLL found
echo.

REM Install plugin
echo Installing plugin...

REM Copy plugin DLL
echo - Copying plugin DLL...
copy /Y build\Release\stream-audio-isolator.dll "%OBS_DIR%\obs-plugins\64bit\" >nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to copy plugin DLL!
    pause
    exit /b 1
)

REM Copy data files
echo - Copying data files...
xcopy /E /I /Y data "%OBS_DIR%\data\obs-plugins\stream-audio-isolator\" >nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to copy data files!
    pause
    exit /b 1
)

REM Copy ONNX Runtime DLL
if defined ONNXRUNTIME_DIR (
    echo - Copying ONNX Runtime DLL...
    if exist "%ONNXRUNTIME_DIR%\lib\onnxruntime.dll" (
        copy /Y "%ONNXRUNTIME_DIR%\lib\onnxruntime.dll" "%OBS_DIR%\obs-plugins\64bit\" >nul
    ) else (
        echo WARNING: onnxruntime.dll not found at %ONNXRUNTIME_DIR%\lib\
    )
)

REM Create models directory
if not exist "%OBS_DIR%\data\obs-plugins\stream-audio-isolator\models" (
    mkdir "%OBS_DIR%\data\obs-plugins\stream-audio-isolator\models"
)

REM Copy models if they exist
if exist "models\*.onnx" (
    echo - Copying AI models...
    copy /Y models\*.onnx "%OBS_DIR%\data\obs-plugins\stream-audio-isolator\models\" >nul
    echo [OK] Models installed
) else (
    echo.
    echo WARNING: No AI models found in models\ directory
    echo.
    echo Download models from:
    echo https://github.com/yourusername/streameraudioremove/releases
    echo.
    echo Or see MODELS.md for conversion instructions
    echo.
)

echo.
echo ================================
echo Installation completed!
echo ================================
echo.
echo Plugin installed to: %OBS_DIR%
echo.
echo Next steps:
echo 1. Restart OBS Studio
echo 2. Right-click Microphone ^> Filters
echo 3. Add "Audio Isolation (Music Removal)"
echo 4. Select AI engine and adjust strength
echo.
echo Enjoy DMCA-free streaming!
echo.

pause
