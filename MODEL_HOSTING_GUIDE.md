# Model Hosting & Distribution Guide

How to get, convert, and distribute AI models with your installer.

---

## 🎯 Goal: Include Models in Installer

**Target installer size**: 60-90 MB (includes everything)
**User experience**: One-click install, works immediately

---

## 📦 Required Models

### Minimum (CPU-only users):
- `sherpa-vocals.onnx` (~15 MB) - **REQUIRED**

### Recommended (for all users):
- `sherpa-vocals.onnx` (~15 MB) - CPU engine
- `hstasnet.onnx` (~8 MB) - GPU low-latency
- `clearervoice.onnx` (~12 MB) - Best speech
- `spleeterrt.onnx` (~20 MB) - High quality

**Total**: ~55 MB (all 4 models)

---

## 🔧 How to Get Models

### Option 1: Use Pre-Converted Models (Easiest)

**If you find pre-converted ONNX models online:**

```batch
REM Download to models directory
curl -L [MODEL_URL] -o models/sherpa-vocals.onnx
curl -L [MODEL_URL] -o models/hstasnet.onnx
curl -L [MODEL_URL] -o models/clearervoice.onnx
curl -L [MODEL_URL] -o models/spleeterrt.onnx
```

**Sources to check:**
- Hugging Face: https://huggingface.co/models?pipeline_tag=audio-source-separation
- ONNX Model Zoo: https://github.com/onnx/models
- Sherpa-ONNX releases: https://github.com/k2-fsa/sherpa-onnx/releases
- Your own GitHub releases (after converting)

---

### Option 2: Convert Models Yourself

See `MODELS.md` for detailed conversion instructions.

**Quick summary:**

#### Sherpa-ONNX (Easiest)
```bash
# Already in ONNX format!
wget https://github.com/k2-fsa/sherpa-onnx/releases/download/[VERSION]/[MODEL].tar.bz2
tar -xjf [MODEL].tar.bz2
cp [MODEL]/model.onnx models/sherpa-vocals.onnx
```

#### HS-TasNet (Requires PyTorch)
```bash
# Convert from paper's implementation
git clone https://github.com/merlresearch/hs-tasnet
cd hs-tasnet

# Convert to ONNX
python convert_to_onnx.py --checkpoint best_model.pth --output ../models/hstasnet.onnx
```

#### ClearerVoice (Requires ModelScope)
```python
from modelscope import snapshot_download
import torch

model_dir = snapshot_download('modelscope/speech_mossformer_separation_temporal_8k')
# ... convert to ONNX ...
# Save as: models/clearervoice.onnx
```

#### SpleeterRT (Requires Spleeter + tf2onnx)
```bash
pip install spleeter tf2onnx

# Download Spleeter models
spleeter separate -h

# Convert to ONNX
python -m tf2onnx.convert \
    --saved-model ~/.spleeter/2stems \
    --output models/spleeterrt.onnx \
    --opset 13
```

---

## 📤 Hosting Models on GitHub Releases

### Step 1: Create a Release

```bash
# Tag your code
git tag models-v1.0
git push origin models-v1.0

# Create release on GitHub
# Go to: https://github.com/YOUR_USERNAME/streameraudioremove/releases/new
```

### Step 2: Upload Models

**Upload these files to the release:**
- `sherpa-vocals.onnx` (15 MB)
- `hstasnet.onnx` (8 MB)
- `clearervoice.onnx` (12 MB)
- `spleeterrt.onnx` (20 MB)

**Or create a zip:**
```bash
cd models
zip -r models-v1.0.zip *.onnx
# Upload models-v1.0.zip (55 MB)
```

### Step 3: Get Download URLs

After uploading, right-click each file → "Copy link address"

URLs will look like:
```
https://github.com/YOUR_USERNAME/streameraudioremove/releases/download/models-v1.0/sherpa-vocals.onnx
```

### Step 4: Update Download Script

Edit `download-all-models.bat` with your URLs:

```batch
REM Replace YOUR_REPO with your username/repo
set REPO=YOUR_USERNAME/streameraudioremove
set VERSION=models-v1.0

curl -L https://github.com/%REPO%/releases/download/%VERSION%/sherpa-vocals.onnx -o models\sherpa-vocals.onnx
curl -L https://github.com/%REPO%/releases/download/%VERSION%/hstasnet.onnx -o models\hstasnet.onnx
curl -L https://github.com/%REPO%/releases/download/%VERSION%/clearervoice.onnx -o models\clearervoice.onnx
curl -L https://github.com/%REPO%/releases/download/%VERSION%/spleeterrt.onnx -o models\spleeterrt.onnx
```

---

## 🏗️ Building Installer with Models

### Full Build Process:

```batch
REM Step 1: Download/convert models
download-all-models.bat
REM Or manually place *.onnx files in models\

REM Step 2: Verify models are present
dir models\*.onnx

REM Step 3: Build plugin
build.bat

REM Step 4: Build installer (includes models)
build-installer.bat
```

**Output**: `StreamAudioIsolator-Setup.exe` (60-90 MB)

---

## 📊 Installer Size Breakdown

With all models included:

| Component | Size |
|-----------|------|
| Plugin DLL | 500 KB |
| ONNX Runtime | 8 MB |
| Sherpa model | 15 MB |
| HS-TasNet model | 8 MB |
| ClearerVoice model | 12 MB |
| SpleeterRT model | 20 MB |
| Data files + installer overhead | 5 MB |
| **Total** | **~70 MB** |

**This is acceptable!** Most installers today are 50-500 MB.

---

## 🎯 Distribution Strategy

### For GitHub Releases

**Create two installers:**

1. **Full Installer** (70 MB)
   - Includes all 4 models
   - Works immediately after install
   - Recommended for most users

2. **Lite Installer** (15 MB)
   - No models included
   - User downloads models separately
   - For advanced users with bandwidth limits

**Release naming:**
```
StreamAudioIsolator-Setup-Full-v1.0.0.exe (70 MB)
StreamAudioIsolator-Setup-Lite-v1.0.0.exe (15 MB)
```

---

## 🔄 Model Update Strategy

### When to Update Models

- Better model quality available
- Smaller model sizes
- Faster inference
- New engine added

### How to Update

```bash
# Create new release
git tag models-v1.1
git push origin models-v1.1

# Upload new models
# Users can:
# Option A: Reinstall full installer
# Option B: Download models manually and replace
```

---

## ⚖️ Model Licensing

**Important**: Respect model licenses!

### Sherpa-ONNX Models
- License: Apache 2.0
- Can redistribute: ✅ Yes
- Must include: Original license

### Spleeter Models
- License: MIT
- Can redistribute: ✅ Yes
- Must include: Copyright notice

### ClearerVoice Models
- License: Apache 2.0 (ModelScope)
- Can redistribute: ✅ Check terms
- Must include: License file

### HS-TasNet Models
- License: Check paper/repo
- Can redistribute: ⚠️ Verify first

**Always include**:
```
models/
├── sherpa-vocals.onnx
├── hstasnet.onnx
├── clearervoice.onnx
├── spleeterrt.onnx
└── LICENSES.txt  ← Include all model licenses here
```

---

## 🧪 Testing Models Before Distribution

### Validation Script

```batch
@echo off
echo Testing models...

REM Test each model exists and has reasonable size
for %%f in (sherpa-vocals.onnx hstasnet.onnx clearervoice.onnx spleeterrt.onnx) do (
    if exist "models\%%f" (
        echo [OK] %%f found
        for %%s in (models\%%f) do (
            if %%~zs LSS 1000000 (
                echo [ERROR] %%f is too small ^(%%~zs bytes^)
            ) else (
                echo [OK] %%f size: %%~zs bytes
            )
        )
    ) else (
        echo [WARNING] %%f not found
    )
)
```

---

## 📝 Checklist Before Building Installer

Before running `build-installer.bat`:

- [ ] All required *.onnx files in `models\` directory
- [ ] Models are valid ONNX format (not corrupted)
- [ ] Model licenses included (LICENSES.txt)
- [ ] Total models folder size is 50-60 MB
- [ ] Tested at least one model works
- [ ] Updated download-all-models.bat with URLs (if using)
- [ ] Plugin DLL compiled
- [ ] ONNX Runtime downloaded

---

## 🚀 Quick Start for Users

**After you create the full installer with models:**

Users just:
1. Download StreamAudioIsolator-Setup.exe (70 MB)
2. Run installer
3. Open OBS
4. Add filter
5. **It works immediately!** ✅

**No additional downloads needed!**

---

## 💡 Tips

### Reduce Model Sizes

Use quantization to reduce size:

```python
from onnxruntime.quantization import quantize_dynamic

quantize_dynamic(
    'models/sherpa-vocals.onnx',
    'models/sherpa-vocals-int8.onnx',
    weight_type=QuantType.QInt8
)
```

**Result**: 4x smaller, slightly lower quality

### Faster Downloads

Host models on a CDN:
- GitHub Releases (free, good speeds)
- Cloudflare R2 (free tier, very fast)
- Your own server

### Model Compression

Compress models in installer:

```nsis
; In installer.nsi
SetCompressor /SOLID lzma
SetCompressorDictSize 64
```

NSIS will compress the 55 MB models to ~40 MB in the installer!

---

## 📚 Resources

**Model Sources:**
- Hugging Face: https://huggingface.co/models
- ONNX Zoo: https://github.com/onnx/models
- Sherpa-ONNX: https://github.com/k2-fsa/sherpa-onnx/releases

**Conversion Tools:**
- tf2onnx: https://github.com/onnx/tensorflow-onnx
- PyTorch to ONNX: https://pytorch.org/docs/stable/onnx.html
- ONNX Runtime: https://onnxruntime.ai/docs/

**Model Optimization:**
- ONNX Optimizer: https://github.com/onnx/optimizer
- ONNX Quantization: https://onnxruntime.ai/docs/performance/model-optimizations/quantization.html

---

## ✅ Summary

**To include models in installer:**

1. Get/convert models → Place in `models/`
2. Run `download-all-models.bat` (or manual download)
3. Run `build.bat` (compile plugin)
4. Run `build-installer.bat` (creates 70 MB installer)
5. Distribute `StreamAudioIsolator-Setup.exe`

**Users get:**
- ✅ One 70 MB download
- ✅ One-click installation
- ✅ Works immediately
- ✅ All 4 AI engines ready
- ✅ No additional downloads needed

**Perfect user experience!** 🎉
