@echo off
REM Validation script for Windows - Check for common issues before building

setlocal enabledelayedexpansion

set ERRORS=0
set WARNINGS=0

echo ================================================================
echo           STREAM AUDIO ISOLATOR - VALIDATION
echo ================================================================
echo.

REM Check file structure
echo Checking file structure...
echo.

call :check_file "CMakeLists.txt"
call :check_file "src\plugin-main.c"
call :check_file "src\audio-isolator-filter.c"
call :check_file "src\audio-isolator-filter.h"
call :check_file "src\engines\sherpa-engine.c"
call :check_file "src\engines\hstasnet-engine.c"
call :check_file "src\engines\clearervoice-engine.c"
call :check_file "src\engines\spleeterrt-engine.c"
call :check_file "src\utils\audio-buffer.c"
call :check_file "data\locale\en-US.ini"

echo.

REM Check for build tools
echo Checking build tools...
echo.

where cmake >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] CMake found
) else (
    echo [ERROR] CMake not found
    set /a ERRORS+=1
)

where cl >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Visual Studio compiler found
) else (
    echo [WARNING] Visual Studio compiler not found - run from Developer Command Prompt
    set /a WARNINGS+=1
)

where makensis >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] NSIS found (for building installer)
) else (
    echo [WARNING] NSIS not found - needed for building .exe installer
    set /a WARNINGS+=1
)

echo.

REM Check for ONNX Runtime
echo Checking dependencies...
echo.

if exist "onnxruntime-win-x64-*" (
    echo [OK] ONNX Runtime directory found
) else (
    echo [ERROR] ONNX Runtime not found
    echo        Download from: https://github.com/microsoft/onnxruntime/releases/download/v1.16.0/onnxruntime-win-x64-1.16.0.zip
    set /a ERRORS+=1
)

echo.

REM Check for models
echo Checking models directory...
echo.

if exist "models" (
    echo [OK] models\ directory exists

    dir /b models\*.onnx >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        echo [OK] ONNX models found:
        dir /b models\*.onnx
    ) else (
        echo [WARNING] No ONNX models found in models\ directory
        echo           Download models or see MODELS.md for conversion instructions
        set /a WARNINGS+=1
    )
) else (
    echo [ERROR] models\ directory missing
    set /a ERRORS+=1
)

echo.

REM Check CMakeLists.txt content
echo Checking CMakeLists.txt...
echo.

if exist "CMakeLists.txt" (
    findstr /C:"cmake_minimum_required" CMakeLists.txt >nul
    if !ERRORLEVEL! EQU 0 (
        echo [OK] Has cmake_minimum_required
    ) else (
        echo [ERROR] Missing cmake_minimum_required
        set /a ERRORS+=1
    )

    findstr /C:"project" CMakeLists.txt >nul
    if !ERRORLEVEL! EQU 0 (
        echo [OK] Has project^(^) declaration
    ) else (
        echo [ERROR] Missing project^(^) declaration
        set /a ERRORS+=1
    )

    findstr /C:"stream-audio-isolator" CMakeLists.txt >nul
    if !ERRORLEVEL! EQU 0 (
        echo [OK] Defines stream-audio-isolator library
    ) else (
        echo [ERROR] Missing add_library for stream-audio-isolator
        set /a ERRORS+=1
    )
)

echo.

REM Check C files for common issues
echo Checking C source files...
echo.

for %%f in (src\*.c src\engines\*.c src\utils\*.c) do (
    if exist "%%f" (
        findstr /C:"#include" "%%f" >nul
        if !ERRORLEVEL! EQU 0 (
            echo [OK] %%f has includes
        ) else (
            echo [WARNING] %%f may be missing includes
            set /a WARNINGS+=1
        )
    )
)

echo.

REM Check documentation
echo Checking documentation...
echo.

call :check_doc "README.md"
call :check_doc "QUICKSTART.md"
call :check_doc "WINDOWS_SETUP.md"
call :check_doc "MODELS.md"
call :check_doc "INSTALLER_GUIDE.md"

echo.

REM Summary
echo ================================================================
echo VALIDATION SUMMARY
echo ================================================================

if %ERRORS% EQU 0 if %WARNINGS% EQU 0 (
    echo [SUCCESS] All checks passed!
    echo.
    echo Next steps:
    echo 1. Download ONNX models ^(see MODELS.md^)
    echo 2. Open Developer Command Prompt for VS
    echo 3. Run: build.bat
    echo 4. Run: install.bat ^(as Administrator^)
    echo 5. Or run: build-installer.bat to create .exe
    echo.
    exit /b 0
) else if %ERRORS% EQU 0 (
    echo [WARNING] Passed with %WARNINGS% warning^(s^)
    echo.
    echo You can proceed with building, but check warnings above.
    echo.
    exit /b 0
) else (
    echo [FAILED] Found %ERRORS% error^(s^) and %WARNINGS% warning^(s^)
    echo.
    echo Please fix the errors above before building.
    echo.
    exit /b 1
)

REM Functions
:check_file
if exist "%~1" (
    echo [OK] Found: %~1
) else (
    echo [ERROR] Missing: %~1
    set /a ERRORS+=1
)
exit /b

:check_doc
if exist "%~1" (
    echo [OK] %~1 exists
) else (
    echo [WARNING] Missing documentation: %~1
    set /a WARNINGS+=1
)
exit /b
