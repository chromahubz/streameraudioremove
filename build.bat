@echo off
REM Build script for Stream Audio Isolator OBS Plugin (Windows)
REM Requirements: Visual Studio 2019+, CMake, ONNX Runtime

echo ================================
echo Stream Audio Isolator - Windows Build
echo ================================
echo.

REM Check for CMake
where cmake >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: CMake not found!
    echo Download from: https://cmake.org/download/
    echo.
    pause
    exit /b 1
)
echo [OK] CMake found

REM Check for Visual Studio (look for cl.exe)
where cl >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Visual Studio compiler not found!
    echo.
    echo Please run this script from "Developer Command Prompt for VS"
    echo Or install Visual Studio 2019+ with C++ tools
    echo.
    pause
    exit /b 1
)
echo [OK] Visual Studio compiler found

REM Check for ONNX Runtime
if not defined ONNXRUNTIME_DIR (
    echo WARNING: ONNXRUNTIME_DIR not set
    echo.
    echo Checking common locations...

    if exist "onnxruntime-win-x64-1.16.0" (
        set ONNXRUNTIME_DIR=%cd%\onnxruntime-win-x64-1.16.0
        echo [OK] Found ONNX Runtime in current directory
    ) else if exist "C:\onnxruntime" (
        set ONNXRUNTIME_DIR=C:\onnxruntime
        echo [OK] Found ONNX Runtime at C:\onnxruntime
    ) else (
        echo ERROR: ONNX Runtime not found!
        echo.
        echo Download ONNX Runtime:
        echo 1. Visit: https://github.com/microsoft/onnxruntime/releases/tag/v1.16.0
        echo 2. Download: onnxruntime-win-x64-1.16.0.zip
        echo 3. Extract to current directory
        echo 4. Run this script again
        echo.
        pause
        exit /b 1
    )
) else (
    echo [OK] ONNXRUNTIME_DIR set to: %ONNXRUNTIME_DIR%
)

echo.
echo Starting build...
echo.

REM Create build directory
if not exist build mkdir build
cd build

REM Configure with CMake
echo Configuring with CMake...
cmake .. ^
    -G "Visual Studio 16 2019" ^
    -A x64 ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DONNXRUNTIME_DIR=%ONNXRUNTIME_DIR%

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: CMake configuration failed!
    echo.
    pause
    exit /b 1
)

REM Build
echo.
echo Building plugin (Release)...
cmake --build . --config Release

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Build failed!
    echo.
    pause
    exit /b 1
)

echo.
echo ================================
echo Build completed successfully!
echo ================================
echo.

REM Check for models
if not exist "..\models\sherpa-vocals.onnx" (
    echo WARNING: AI models not found!
    echo Download models from: https://github.com/yourusername/streameraudioremove/releases
    echo Or see MODELS.md for conversion instructions
    echo.
)

REM Installation instructions
echo Installation:
echo.
echo 1. Close OBS Studio if running
echo 2. Copy plugin to OBS:
echo    xcopy /Y Release\stream-audio-isolator.dll "C:\Program Files\obs-studio\obs-plugins\64bit\"
echo.
echo 3. Copy data files:
echo    xcopy /E /I ..\data "C:\Program Files\obs-studio\data\obs-plugins\stream-audio-isolator\"
echo.
echo 4. Copy ONNX Runtime DLL:
echo    copy "%ONNXRUNTIME_DIR%\lib\onnxruntime.dll" "C:\Program Files\obs-studio\obs-plugins\64bit\"
echo.
echo 5. Copy models to:
echo    "C:\Program Files\obs-studio\data\obs-plugins\stream-audio-isolator\models\"
echo.
echo 6. Restart OBS Studio
echo.
echo.
echo OR run: install.bat (as Administrator)
echo.

pause
