@echo off
REM Build Windows .exe installer using NSIS

echo ================================
echo Building Windows Installer
echo ================================
echo.

REM Check for NSIS
where makensis >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: NSIS not found!
    echo.
    echo Install NSIS from: https://nsis.sourceforge.io/Download
    echo.
    echo Or with Chocolatey:
    echo   choco install nsis
    echo.
    pause
    exit /b 1
)

echo [OK] NSIS found
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

REM Check for ONNX Runtime
if not exist "onnxruntime-win-x64-*\lib\onnxruntime.dll" (
    echo ERROR: ONNX Runtime DLL not found!
    echo.
    echo Download ONNX Runtime first:
    echo https://github.com/microsoft/onnxruntime/releases/download/v1.16.0/onnxruntime-win-x64-1.16.0.zip
    echo.
    pause
    exit /b 1
)

echo [OK] ONNX Runtime found
echo.

REM Build installer
echo Building installer with NSIS...
echo.

makensis /V2 installer.nsi

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Installer build failed!
    pause
    exit /b 1
)

echo.
echo ================================
echo Installer built successfully!
echo ================================
echo.

REM Check output
if exist "StreamAudioIsolator-Setup.exe" (
    echo Installer created: StreamAudioIsolator-Setup.exe
    echo.

    REM Get file size
    for %%A in (StreamAudioIsolator-Setup.exe) do (
        set size=%%~zA
        set /A sizeMB=!size!/1048576
    )

    echo Size: ~%sizeMB% MB
    echo.
    echo You can now distribute this installer to users!
    echo.
    echo Users simply:
    echo 1. Download StreamAudioIsolator-Setup.exe
    echo 2. Right-click and "Run as administrator"
    echo 3. Follow the wizard
    echo 4. Restart OBS
    echo.
) else (
    echo WARNING: Installer file not found!
)

pause
