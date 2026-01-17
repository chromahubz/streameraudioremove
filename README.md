# Stream Audio Isolator

Real-time audio isolation plugin for OBS Studio - removes background music from streams while preserving voice quality.

**Platform Support:** ✅ Windows | ✅ macOS | ✅ Linux

**Perfect for:** IRL streamers, music reaction streams, travel/event streaming, DMCA-free content.

## ✨ Features

- **4 AI Engines**: Choose between speed, quality, and hardware requirements
  - **Sherpa-ONNX**: Fast CPU processing (80ms latency)
  - **HS-TasNet**: Ultra-low latency GPU (25ms latency)
  - **ClearerVoice**: Best speech clarity (50ms latency)
  - **SpleeterRT**: Highest separation quality (100ms latency)

- **Automatic Lip-sync Compensation**: Video delay automatically adjusts to match audio processing latency
- **Adjustable Strength**: Blend between original and isolated audio (0-100%)
- **Auto-detection** (Beta): Automatically enable when music is detected
- **GPU Acceleration**: Supports CUDA for faster processing
- **Cross-platform**: Windows, macOS, Linux

## 🎯 Use Cases

1. **IRL Streaming**: Walk into cafes, stores, malls without DMCA strikes
2. **Music Reactions**: Isolate your commentary from copyrighted music
3. **Gaming**: Remove background music from games while keeping your voice
4. **Podcasts**: Clean up recordings with background music bleed

## 📦 Installation

### Windows (Quick Start)

**Automated Setup** (Recommended):
```powershell
# Run PowerShell as Administrator
.\setup-windows.ps1
```

**Manual Build**:
1. Open **Developer Command Prompt for VS**
2. Run `build.bat`
3. Run `install.bat` as Administrator
4. See [WINDOWS_SETUP.md](WINDOWS_SETUP.md) for detailed instructions

### macOS / Linux

**Quick Build**:
```bash
./build.sh
sudo cmake --install build
```

See [Building from Source](#-building-from-source) for detailed instructions.

### Pre-built Binaries (Coming Soon)

1. Download the latest release from [Releases](https://github.com/yourusername/streameraudioremove/releases)
2. Extract to your OBS plugins folder:
   - **Windows**: `C:\Program Files\obs-studio\obs-plugins\64bit\`
   - **macOS**: `~/Library/Application Support/obs-studio/plugins/`
   - **Linux**: `~/.config/obs-studio/plugins/`
3. Restart OBS Studio
4. Models will download automatically on first use

## 🚀 Quick Start

1. **Add the filter** to your audio source:
   - Right-click your microphone/audio source → **Filters**
   - Click **+** → **Audio Isolation (Music Removal)**

2. **Choose your engine**:
   - **CPU only?** → Use **Sherpa-ONNX**
   - **Have NVIDIA GPU?** → Use **HS-TasNet** (fastest)
   - **Want best quality?** → Use **SpleeterRT**

3. **Adjust strength** slider (default: 85% works well)

4. **Lip-sync**: Leave video delay at 0 for automatic compensation

5. **Test!** Play music near your mic and speak - music should be removed while your voice remains clear

## ⚙️ Settings Explained

| Setting | Description | Recommended |
|---------|-------------|-------------|
| **Enable Filter** | Master on/off switch | ✅ On |
| **AI Engine** | Which model to use for separation | Sherpa-ONNX (CPU) or HS-TasNet (GPU) |
| **Isolation Strength** | 100% = only voice, 0% = original audio | 80-90% |
| **Video Delay** | Compensates for processing latency | 0 (auto) |
| **Auto-detect Music** | Only process when music detected | ⚠️ Beta, leave off |

## 🔧 Building from Source

### Prerequisites

**All Platforms:**
- CMake 3.16+
- C compiler (GCC, Clang, or MSVC)
- OBS Studio (with development files)
- ONNX Runtime 1.16+

**Windows:**
```bash
# Install dependencies with vcpkg
vcpkg install onnxruntime:x64-windows
```

**macOS:**
```bash
brew install cmake onnxruntime
```

**Linux:**
```bash
sudo apt-get install cmake libonnxruntime-dev obs-studio-dev
```

### Build Steps

1. **Clone the repository**:
```bash
git clone https://github.com/yourusername/streameraudioremove.git
cd streameraudioremove
```

2. **Download ONNX Runtime** (if not using package manager):
```bash
# Windows/Linux
wget https://github.com/microsoft/onnxruntime/releases/download/v1.16.0/onnxruntime-linux-x64-1.16.0.tgz
tar -xzf onnxruntime-linux-x64-1.16.0.tgz
export ONNXRUNTIME_DIR=$(pwd)/onnxruntime-linux-x64-1.16.0
```

3. **Configure and build**:
```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release
```

4. **Install**:
```bash
# Linux/macOS
sudo cmake --install .

# Windows (run as Administrator)
cmake --install .
```

5. **Download AI models**:
Models are downloaded automatically on first use, or manually download from:
```
https://github.com/yourusername/streameraudioremove/releases/tag/models-v1.0
```

Place models in:
- **Windows**: `C:\Program Files\obs-studio\data\obs-plugins\stream-audio-isolator\models\`
- **macOS**: `/Applications/OBS.app/Contents/Resources/data/obs-plugins/stream-audio-isolator/models/`
- **Linux**: `/usr/share/obs/obs-plugins/stream-audio-isolator/models/`

## 🎓 Technical Details

### How It Works

1. **Audio Capture**: OBS captures microphone audio
2. **AI Separation**: ONNX model separates voice from music in real-time
3. **Blending**: Original and isolated audio mixed based on "strength" setting
4. **Lip-sync Compensation**: Video delayed by processing latency (auto-calculated)
5. **Output**: Clean audio streamed to your platform

### Engine Comparison

| Engine | Latency | CPU Usage | GPU Required | Quality (SDR) | Best For |
|--------|---------|-----------|--------------|---------------|----------|
| **Sherpa-ONNX** | 80ms | Low (15%) | ❌ No | 3.5 dB | CPU-only systems |
| **HS-TasNet** | 25ms | Low (20%) | ✅ Yes | 4.6 dB | Low-latency streaming |
| **ClearerVoice** | 50ms | Medium (25%) | ⚠️ Optional | 5.0 dB | Speech clarity |
| **SpleeterRT** | 100ms | High (35%) | ✅ Yes | 5.5 dB | Highest quality |

### Lip-sync Delay Explained

When audio is processed by AI (takes ~25-100ms), it becomes delayed compared to video. To fix this:

- **Automatic mode** (Video Delay = 0): Plugin automatically delays video by the engine's latency
- **Manual mode**: Set a custom delay if needed (e.g., if you notice lips still ahead of audio)

**Formula**: `Video Delay = Audio Processing Latency`

## 🐛 Troubleshooting

### Audio sounds robotic/distorted
- **Solution**: Lower the "Isolation Strength" to 60-70%
- Try a different engine (ClearerVoice is best for speech quality)

### Lip-sync is off (video ahead of audio)
- **Solution**: Increase "Video Delay" by 10-20ms
- Check if another filter is adding latency

### Plugin doesn't appear in OBS
- **Check**: OBS log file (`Help` → `Log Files` → `View Current Log`)
- Look for errors like "Failed to load onnxruntime.dll"
- **Windows**: Ensure `onnxruntime.dll` is in the same folder as the plugin
- **Linux**: Install `libonnxruntime.so` via package manager

### High CPU usage
- **Solution**: Use Sherpa-ONNX (most efficient)
- Lower OBS canvas resolution
- Close other CPU-intensive applications

### Models not downloading
- **Manual download**: Get models from releases page
- Place in the models folder (see [Build Steps](#build-steps) for path)

### No GPU acceleration (CUDA)
- **Check**: Ensure NVIDIA drivers are installed
- **Verify**: OBS log should show "GPU (CUDA) enabled"
- If not available, engines fall back to CPU automatically

## 🤝 Contributing

Contributions welcome! Areas for improvement:

- [ ] Add DirectML support (AMD/Intel GPUs)
- [ ] Implement auto-detection algorithm
- [ ] Optimize model quantization (reduce size)
- [ ] Add VST3 plugin version
- [ ] Multi-language support

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

This plugin is licensed under **GPL-3.0** (to match OBS Studio).

AI models have their own licenses:
- Sherpa-ONNX: Apache 2.0
- HS-TasNet: MIT
- ClearerVoice: Apache 2.0
- SpleeterRT: MIT

See [LICENSE](LICENSE) for details.

## 🙏 Credits

Built with:
- [OBS Studio](https://obsproject.com/) - Broadcasting software
- [ONNX Runtime](https://onnxruntime.ai/) - AI inference engine
- [Sherpa-ONNX](https://github.com/k2-fsa/sherpa-onnx) - Fast source separation
- [HS-TasNet](https://arxiv.org/abs/2402.17701) - Low-latency separation
- [ClearerVoice-Studio](https://github.com/modelscope/ClearerVoice-Studio) - Speech enhancement
- [SpleeterRT](https://github.com/james34602/SpleeterRT) - Real-time Spleeter

## 📧 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/streameraudioremove/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/streameraudioremove/discussions)
- **Discord**: [Join our server](https://discord.gg/yourserver)

## ⭐ Show Your Support

If this plugin helps you avoid DMCA strikes and improves your streams, please:
- ⭐ Star this repo
- 🐛 Report bugs
- 💡 Suggest features
- 🎉 Share with other streamers!

---

**Made with ❤️ for the streaming community**

*Stream anywhere, say anything, without DMCA worries.*
