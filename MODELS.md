# AI Models Guide

This plugin requires ONNX models for audio separation. This guide explains how to obtain and prepare them.

## 📦 Quick Download (Pre-converted Models)

**Coming Soon**: We'll host pre-converted ONNX models on GitHub Releases.

For now, you'll need to convert models yourself (see below).

## 🔄 Converting Models to ONNX

### 1. Sherpa-ONNX (Easiest - Already ONNX!)

Sherpa-ONNX provides pre-trained models:

```bash
# Download pre-trained vocal separation model
wget https://github.com/k2-fsa/sherpa-onnx/releases/download/audio-tagging-models/sherpa-onnx-zipformer-audio-tagging-2024-04-09.tar.bz2

# Extract
tar -xjf sherpa-onnx-zipformer-audio-tagging-2024-04-09.tar.bz2

# Copy to models folder
cp sherpa-onnx-zipformer-audio-tagging-2024-04-09/model.onnx models/sherpa-vocals.onnx
```

**Alternative**: Use any Sherpa-ONNX compatible source separation model.

### 2. HS-TasNet (From PyTorch)

Convert from the paper's implementation:

```bash
# Clone the HS-TasNet repository
git clone https://github.com/merlresearch/hs-tasnet
cd hs-tasnet

# Install dependencies
pip install torch onnx

# Convert to ONNX (example script)
python convert_to_onnx.py --checkpoint best_model.pth --output hstasnet.onnx

# Copy to plugin models folder
cp hstasnet.onnx ../models/
```

**Note**: You may need to write a custom conversion script. See `scripts/convert_hstasnet.py` for a template.

### 3. ClearerVoice (From ModelScope)

```bash
# Install modelscope
pip install modelscope torch

# Download and convert
python << EOF
from modelscope import snapshot_download
from modelscope.pipelines import pipeline
import torch

# Download model
model_dir = snapshot_download('modelscope/speech_mossformer_separation_temporal_8k')

# Load pipeline
separator = pipeline(
    task='speech-separation',
    model=model_dir
)

# Export to ONNX
dummy_input = torch.randn(1, 16000)  # 1 second at 16kHz
torch.onnx.export(
    separator.model,
    dummy_input,
    'clearervoice.onnx',
    input_names=['input'],
    output_names=['output'],
    dynamic_axes={'input': {0: 'batch', 1: 'samples'}}
)
EOF

# Copy model
mv clearervoice.onnx models/
```

### 4. SpleeterRT (From Spleeter)

Convert Spleeter to ONNX:

```bash
# Install Spleeter
pip install spleeter

# Clone SpleeterRT
git clone https://github.com/james34602/SpleeterRT
cd SpleeterRT

# Download pre-trained Spleeter models
spleeter separate -h  # This downloads models to ~/.spleeter/

# Convert to ONNX (using tf2onnx)
pip install tf2onnx

python -m tf2onnx.convert \
    --saved-model ~/.spleeter/2stems \
    --output spleeterrt.onnx \
    --opset 13

# Copy model
cp spleeterrt.onnx ../models/
```

## 🎯 Model Requirements

Each ONNX model should:

### Input Specification
- **Format**: Float32 tensor
- **Shape**: `[batch_size, samples]` or `[batch_size, samples, channels]`
- **Sample Rate**: 16kHz, 22.05kHz, 44.1kHz, or 48kHz (plugin auto-resamples)
- **Channels**: Mono (1) or Stereo (2)

### Output Specification
- **Format**: Float32 tensor
- **Shape**: Same as input
- **Content**: Isolated vocals/speech

### Naming Convention
- **Input node**: `audio`, `input`, or `waveform`
- **Output node**: `vocals`, `output`, or `speech`

**Note**: If your model uses different names, update the engine source file accordingly.

## 🧪 Testing Your Models

Test a model before using in OBS:

```bash
# Install test dependencies
pip install onnxruntime numpy soundfile

# Run test script
python scripts/test_model.py \
    --model models/sherpa-vocals.onnx \
    --input test_audio.wav \
    --output result.wav
```

The script will:
1. Load your model
2. Process a test audio file
3. Save the isolated vocals
4. Report processing time and quality

## 📊 Model Benchmarks

After conversion, verify performance:

```bash
python scripts/benchmark_models.py
```

Expected results:

| Model | Size | Inference (CPU) | Inference (GPU) |
|-------|------|-----------------|-----------------|
| Sherpa-ONNX | ~15 MB | ~80ms | N/A |
| HS-TasNet | ~8 MB | ~100ms | ~25ms |
| ClearerVoice | ~12 MB | ~120ms | ~50ms |
| SpleeterRT | ~20 MB | ~200ms | ~100ms |

## 🔧 Optimization Tips

### Quantization (Reduce Size)

Convert to INT8 for smaller models:

```bash
python -m onnxruntime.quantization.quantize \
    --model models/sherpa-vocals.onnx \
    --output models/sherpa-vocals-int8.onnx \
    --per_channel
```

**Benefits**: 4x smaller size, 2-3x faster inference
**Tradeoff**: Slight quality reduction (~0.5 dB SDR)

### Dynamic Shape Support

Ensure your model supports variable input lengths:

```python
import onnx
from onnx import shape_inference

# Load model
model = onnx.load('model.onnx')

# Infer shapes with dynamic dimensions
inferred_model = shape_inference.infer_shapes(model)

# Save
onnx.save(inferred_model, 'model_dynamic.onnx')
```

## 🐛 Troubleshooting

### "Model input/output mismatch"
- **Check**: Use Netron to visualize your model: https://netron.app
- Verify input/output tensor names match engine expectations
- Update engine source code if needed

### "Inference too slow"
- Try INT8 quantization
- Reduce model size (use fewer layers)
- Enable GPU acceleration

### "Audio quality is poor"
- Model may not be trained for your use case
- Try different models
- Adjust isolation strength in plugin settings

## 📚 Resources

- **ONNX Model Zoo**: https://github.com/onnx/models
- **Sherpa-ONNX Models**: https://github.com/k2-fsa/sherpa-onnx/releases
- **Hugging Face Audio Models**: https://huggingface.co/models?pipeline_tag=audio-source-separation
- **Model Conversion Guide**: https://onnxruntime.ai/docs/tutorials/

## 🎁 Pre-trained Model Links

Once we have tested, pre-converted models, they'll be available here:

**GitHub Releases**: https://github.com/yourusername/streameraudioremove/releases/tag/models-v1.0

Models will include:
- `sherpa-vocals.onnx` (15 MB)
- `hstasnet.onnx` (8 MB)
- `clearervoice.onnx` (12 MB)
- `spleeterrt.onnx` (20 MB)
- `sherpa-vocals-int8.onnx` (4 MB, quantized)

**Total download**: ~55 MB (or ~15 MB for quantized versions)

## ⚖️ Model Licenses

When using pre-trained models, respect their licenses:

- **Sherpa-ONNX models**: Apache 2.0
- **Spleeter models**: MIT
- **ClearerVoice models**: Apache 2.0 (ModelScope)
- **Custom models**: Check original repository

**Important**: Do not redistribute models without permission from original authors.

---

**Need help?** Open an issue: https://github.com/yourusername/streameraudioremove/issues
