# Windows Setup Guide

Complete guide to building and installing Stream Audio Isolator on Windows 10/11.

## 📋 Prerequisites

### Required Software

1. **OBS Studio** (28.0 or later)
   - Download: https://obsproject.com/download
   - Install the 64-bit version

2. **Visual Studio 2019 or 2022** (Community Edition is free)
   - Download: https://visualstudio.microsoft.com/downloads/
   - During installation, select:
     - ✅ **Desktop development with C++**
     - ✅ **Windows 10 SDK** (10.0.19041.0 or later)

3. **CMake** (3.16 or later)
   - Download: https://cmake.org/download/
   - During install, select: **"Add CMake to system PATH"**

4. **Git** (optional, for cloning)
   - Download: https://git-scm.com/download/win

### Quick Check

Open **Command Prompt** and verify:

```cmd
cmake --version
# Should show: cmake version 3.x.x

cl
# Should show: Microsoft (R) C/C++ Optimizing Compiler
```

If `cl` command fails, open **Developer Command Prompt for VS** instead.

---

## 🚀 Quick Installation (3 Methods)

### Method 1: Automated PowerShell Setup (Easiest)

```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force

# Download and run setup script
Invoke-WebRequest -Uri "https://github.com/yourusername/streameraudioremove/raw/main/setup-windows.ps1" -OutFile "setup.ps1"
.\setup.ps1
```

This will:
- ✅ Download ONNX Runtime
- ✅ Download AI models
- ✅ Build plugin
- ✅ Install to OBS

### Method 2: Manual Build (Recommended for developers)

**Step 1**: Download ONNX Runtime
```cmd
REM Download ONNX Runtime 1.16.0 for Windows
curl -L https://github.com/microsoft/onnxruntime/releases/download/v1.16.0/onnxruntime-win-x64-1.16.0.zip -o onnxruntime.zip

REM Extract
tar -xf onnxruntime.zip

REM Set environment variable
set ONNXRUNTIME_DIR=%cd%\onnxruntime-win-x64-1.16.0
```

**Step 2**: Clone or download repository
```cmd
git clone https://github.com/yourusername/streameraudioremove.git
cd streameraudioremove
```

**Step 3**: Build plugin
```cmd
REM Open Developer Command Prompt for VS 2019/2022
build.bat
```

**Step 4**: Install (as Administrator)
```cmd
install.bat
```

**Step 5**: Restart OBS

### Method 3: Pre-built Binary (Coming Soon)

1. Download `stream-audio-isolator-windows-x64.zip`
2. Extract to `C:\Program Files\obs-studio\obs-plugins\64bit\`
3. Download models (see below)
4. Restart OBS

---

## 📦 Downloading AI Models

### Option A: Automatic Download (PowerShell)

```powershell
# Run from plugin directory
.\download-models.ps1
```

### Option B: Manual Download

Visit: https://github.com/yourusername/streameraudioremove/releases/tag/models-v1.0

Download models you want:
- `sherpa-vocals.onnx` (15 MB) - **Recommended for CPU**
- `hstasnet.onnx` (8 MB) - For GPU (NVIDIA)
- `clearervoice.onnx` (12 MB) - Best speech quality
- `spleeterrt.onnx` (20 MB) - Highest quality

**Place models in:**
```
C:\Program Files\obs-studio\data\obs-plugins\stream-audio-isolator\models\
```

---

## 🛠️ Detailed Build Instructions

### Build with Visual Studio GUI (Alternative)

If you prefer Visual Studio IDE:

**Step 1**: Generate Visual Studio solution
```cmd
mkdir build
cd build
cmake .. -G "Visual Studio 16 2019" -A x64 -DONNXRUNTIME_DIR=%ONNXRUNTIME_DIR%
```

**Step 2**: Open in Visual Studio
```cmd
start stream-audio-isolator.sln
```

**Step 3**: Build
- Select **Release** configuration
- Build → Build Solution (Ctrl+Shift+B)

**Step 4**: Install
- Right-click solution → Run as Administrator
- Run `install.bat` from project root

### Build from PowerShell

```powershell
# Set environment
$env:ONNXRUNTIME_DIR = "C:\onnxruntime-win-x64-1.16.0"

# Configure
cmake -B build -G "Visual Studio 16 2019" -A x64 -DONNXRUNTIME_DIR=$env:ONNXRUNTIME_DIR

# Build
cmake --build build --config Release

# Install (requires admin)
Start-Process powershell -Verb RunAs -ArgumentList "-File install.bat"
```

---

## 📂 Installation Paths

After installation, files will be at:

```
C:\Program Files\obs-studio\
├── obs-plugins\64bit\
│   ├── stream-audio-isolator.dll     ← Plugin binary
│   └── onnxruntime.dll                ← ONNX Runtime
│
└── data\obs-plugins\stream-audio-isolator\
    ├── locale\
    │   └── en-US.ini                  ← UI text
    └── models\
        ├── sherpa-vocals.onnx         ← AI models
        ├── hstasnet.onnx
        ├── clearervoice.onnx
        └── spleeterrt.onnx
```

---

## ⚙️ Configuration in OBS

### Adding the Filter

1. Open **OBS Studio**
2. In **Audio Mixer**, find your **Microphone**
3. Click the **⚙️ gear icon** → **Filters**
4. Click **➕ (Add)** at bottom-left
5. Select **Audio Isolation (Music Removal)**
6. Click **OK**

### Recommended Settings

**For streaming (most users):**
```
Enable: ✅ Checked
AI Engine: Sherpa-ONNX (Fast, CPU)
Isolation Strength: 85%
Video Delay: 0 ms (auto)
Auto-detect: ❌ Unchecked
```

**For NVIDIA GPU users:**
```
Enable: ✅ Checked
AI Engine: HS-TasNet (Low Latency, GPU)
Isolation Strength: 85%
Video Delay: 0 ms (auto)
```

**For best quality (powerful PC):**
```
Enable: ✅ Checked
AI Engine: SpleeterRT (High Quality)
Isolation Strength: 90%
Video Delay: 0 ms (auto)
```

---

## 🐛 Troubleshooting

### Build Errors

**Error: "CMake not found"**
```
Solution: Add CMake to PATH
1. Search Windows for "Environment Variables"
2. Edit "Path" variable
3. Add: C:\Program Files\CMake\bin
4. Restart Command Prompt
```

**Error: "'cl' is not recognized"**
```
Solution: Use Developer Command Prompt
1. Search Windows for "Developer Command Prompt for VS"
2. Run build.bat from there
```

**Error: "Cannot open include file: 'obs-module.h'"**
```
Solution: Install OBS Studio development files
1. Download obs-studio source or dev package
2. Or build plugin on system with OBS installed
```

**Error: "ONNX Runtime not found"**
```
Solution: Set ONNXRUNTIME_DIR
set ONNXRUNTIME_DIR=C:\path\to\onnxruntime-win-x64-1.16.0
build.bat
```

### Runtime Errors

**Plugin doesn't appear in OBS**
```
Check OBS log file:
1. OBS → Help → Log Files → View Current Log
2. Search for "stream-audio-isolator" or "onnxruntime"

Common issues:
- Missing onnxruntime.dll → Copy to obs-plugins\64bit\
- Missing MSVCP140.dll → Install Visual C++ Redistributable
```

**"Failed to load ONNX model"**
```
Solution: Check model path
1. Verify models exist in:
   C:\Program Files\obs-studio\data\obs-plugins\stream-audio-isolator\models\

2. Check OBS log for exact error message

3. Re-download models if corrupted
```

**Audio sounds robotic/distorted**
```
Solution: Adjust settings
1. Lower "Isolation Strength" to 60-70%
2. Try different engine (ClearerVoice is best for speech)
3. Check CPU usage (high usage = artifacts)
```

**High CPU usage**
```
Solutions:
1. Use Sherpa-ONNX (most efficient)
2. Lower OBS video resolution
3. Use GPU engine if available (HS-TasNet)
4. Close other applications
```

**Lip-sync issues (video ahead of audio)**
```
Solution: Increase video delay
1. In filter settings, set "Video Delay" to 50-100ms
2. Adjust until lips match perfectly
3. Or leave at 0 for automatic compensation
```

### Installation Errors

**"Access denied" when installing**
```
Solution: Run as Administrator
1. Right-click install.bat
2. Select "Run as administrator"
```

**"OBS Studio not found"**
```
Solution: Manual installation
1. Find your OBS installation:
   - C:\Program Files\obs-studio
   - C:\Program Files (x86)\obs-studio

2. Copy manually:
   copy build\Release\stream-audio-isolator.dll "C:\Program Files\obs-studio\obs-plugins\64bit\"
```

---

## 🔧 Advanced Configuration

### GPU Acceleration (NVIDIA only)

**Prerequisites:**
- NVIDIA GPU (GTX 1060 or better)
- Latest NVIDIA drivers
- CUDA Toolkit 11.0+ (optional, but recommended)

**Enable GPU:**
1. Download CUDA-enabled ONNX Runtime:
   ```cmd
   curl -L https://github.com/microsoft/onnxruntime/releases/download/v1.16.0/onnxruntime-win-x64-gpu-1.16.0.zip -o onnxruntime-gpu.zip
   ```

2. Rebuild plugin with GPU support
3. In OBS, select **HS-TasNet** or **SpleeterRT** engine

**Verify GPU usage:**
- Open Task Manager → Performance → GPU
- Run OBS with filter enabled
- GPU usage should increase during streaming

### Building for Debug

```cmd
REM Build debug version
cd build
cmake --build . --config Debug

REM Debug symbols included for troubleshooting
```

### Custom ONNX Models

Place your custom models in:
```
C:\Program Files\obs-studio\data\obs-plugins\stream-audio-isolator\models\
```

Model requirements:
- Format: ONNX (opset 13+)
- Input: Float32 [batch, samples, channels]
- Output: Float32 [batch, samples, channels]
- Sample rate: 16kHz, 44.1kHz, or 48kHz

---

## 📊 System Requirements

### Minimum (Sherpa-ONNX engine)
- **OS**: Windows 10 64-bit (1903 or later)
- **CPU**: Intel i5-6600 / AMD Ryzen 5 1600
- **RAM**: 4 GB available
- **Disk**: 100 MB free space

### Recommended (HS-TasNet engine)
- **OS**: Windows 10/11 64-bit
- **CPU**: Intel i7-8700 / AMD Ryzen 7 2700
- **GPU**: NVIDIA GTX 1660 or better
- **RAM**: 8 GB available
- **Disk**: 200 MB free space

### Best (SpleeterRT engine)
- **OS**: Windows 11 64-bit
- **CPU**: Intel i9-9900K / AMD Ryzen 9 3900X
- **GPU**: NVIDIA RTX 2060 or better
- **RAM**: 16 GB available

---

## 🎬 Next Steps

After installation:
1. ✅ Restart OBS Studio
2. ✅ Add filter to microphone
3. ✅ Test with music playing
4. ✅ Adjust isolation strength
5. ✅ Verify lip-sync is correct
6. ✅ Start streaming DMCA-free!

**Need help?** See [QUICKSTART.md](QUICKSTART.md) for usage guide.

---

## 📚 Additional Resources

- **Main Documentation**: [README.md](README.md)
- **Model Guide**: [MODELS.md](MODELS.md)
- **Quick Start**: [QUICKSTART.md](QUICKSTART.md)
- **GitHub Issues**: https://github.com/yourusername/streameraudioremove/issues
- **OBS Forum Thread**: [Coming Soon]

---

**Windows build ready! Happy streaming! 🎬**
