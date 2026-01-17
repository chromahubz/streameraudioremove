# AI Models Directory

This directory contains the ONNX models for audio separation.

## 📦 Required Files

Place these ONNX model files here before building the installer:

### Minimum (Required):
- `sherpa-vocals.onnx` (~15 MB) - CPU engine, works on any PC

### Recommended (All 4 models):
- `sherpa-vocals.onnx` (~15 MB) - CPU engine
- `hstasnet.onnx` (~8 MB) - GPU low-latency engine
- `clearervoice.onnx` (~12 MB) - Best speech quality
- `spleeterrt.onnx` (~20 MB) - Highest quality separation

**Total size**: ~55 MB (all 4 models)

---

## 🔽 How to Get Models

### Option 1: Download Pre-Converted (Easiest)

Run the download script:

**Windows**:
```batch
..\download-all-models.bat
```

**PowerShell**:
```powershell
..\download-models.ps1 -All
```

### Option 2: Download from GitHub Releases

Visit: https://github.com/chromahubz/streameraudioremove/releases/tag/models-v1.0

Download all *.onnx files and place them in this directory.

### Option 3: Convert Yourself

See `../MODELS.md` for detailed conversion instructions from:
- Sherpa-ONNX releases
- HS-TasNet source
- ClearerVoice (ModelScope)
- Spleeter + tf2onnx

---

## ✅ Verification

After downloading, verify files:

```batch
dir /b *.onnx
```

Should show:
```
clearervoice.onnx
hstasnet.onnx
sherpa-vocals.onnx
spleeterrt.onnx
```

---

## 🏗️ Building Installer with Models

Once models are in this directory:

```batch
cd ..
build-installer.bat
```

The installer will automatically include all *.onnx files found here.

**Result**: `StreamAudioIsolator-Setup.exe` (~70 MB with all models)

---

## 📊 Model Information

| Model | Size | Engine | Latency | GPU Required |
|-------|------|--------|---------|--------------|
| sherpa-vocals.onnx | 15 MB | Sherpa-ONNX | 80ms | No |
| hstasnet.onnx | 8 MB | HS-TasNet | 25ms | Recommended |
| clearervoice.onnx | 12 MB | ClearerVoice | 50ms | Optional |
| spleeterrt.onnx | 20 MB | SpleeterRT | 100ms | Recommended |

---

## ⚖️ Licenses

Models have their own licenses:
- Sherpa-ONNX: Apache 2.0
- Spleeter: MIT
- ClearerVoice: Apache 2.0 (ModelScope)

See `../LICENSE` and model source repositories for details.

---

## 🚨 Important Notes

1. **Don't commit models to git** (too large!)
   - Models are in `.gitignore`
   - Only `.gitkeep` is tracked

2. **Download before building installer**
   - Installer includes models from this directory
   - Build will warn if models are missing

3. **At minimum, include sherpa-vocals.onnx**
   - Works on any PC (CPU-only)
   - Other models are optional but recommended

---

## 🆘 Troubleshooting

**"No models found" when building installer:**
```batch
REM Download models first
..\download-all-models.bat
```

**Models downloaded but installer still complains:**
```batch
REM Check files are in correct location
dir /b *.onnx

REM Should be in: /path/to/streameraudioremove/models/
REM NOT in a subdirectory
```

**Want to update models:**
```batch
REM Delete old models
del *.onnx

REM Download new ones
..\download-all-models.bat
```

---

**Need help?** See `../MODEL_HOSTING_GUIDE.md` for complete details.
