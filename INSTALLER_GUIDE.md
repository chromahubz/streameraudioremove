# Windows Installer Guide

How to create and use the Windows .exe installer.

## 🎯 For Users (Installing)

### Download and Install

1. **Download** the installer:
   - Get `StreamAudioIsolator-Setup.exe` from [Releases](https://github.com/yourusername/streameraudioremove/releases)
   - Size: ~30-60 MB (includes plugin + ONNX Runtime)

2. **Run as Administrator**:
   - Right-click `StreamAudioIsolator-Setup.exe`
   - Select **"Run as administrator"**
   - Click **"Yes"** on the UAC prompt

3. **Follow the wizard**:
   - Click **"Next"** on Welcome screen
   - Accept the license (GPL-3.0)
   - Confirm OBS installation path
   - Click **"Install"**

4. **Restart OBS Studio**

5. **Add the filter**:
   - Right-click your Microphone → **Filters**
   - Click **+** → **Audio Isolation (Music Removal)**
   - Select AI engine and adjust strength
   - Done! 🎉

### What Gets Installed

The installer automatically copies:

```
C:\Program Files\obs-studio\
├── obs-plugins\64bit\
│   ├── stream-audio-isolator.dll     ✅ Plugin
│   └── onnxruntime.dll                ✅ AI Runtime
│
└── data\obs-plugins\stream-audio-isolator\
    ├── locale\
    │   └── en-US.ini                  ✅ UI Text
    └── models\
        └── *.onnx                     ✅ AI Models (if included)
```

### Uninstalling

**Option 1**: Windows Settings
- Settings → Apps → Search "Stream Audio Isolator"
- Click **Uninstall**

**Option 2**: Control Panel
- Control Panel → Programs and Features
- Find "Stream Audio Isolator"
- Click **Uninstall**

**Option 3**: Uninstaller
- Navigate to `C:\Program Files\obs-studio\`
- Run `Uninstall-StreamAudioIsolator.exe`

---

## 🛠️ For Developers (Building Installer)

### Prerequisites

**Required Software:**

1. **NSIS** (Nullsoft Scriptable Install System)
   - Download: https://nsis.sourceforge.io/Download
   - Or via Chocolatey: `choco install nsis`
   - Version: 3.08 or later

2. **Compiled Plugin** (from build.bat)
   - `build\Release\stream-audio-isolator.dll`

3. **ONNX Runtime**
   - `onnxruntime-win-x64-1.16.0\lib\onnxruntime.dll`

4. **AI Models** (optional but recommended)
   - `models\*.onnx`

### Quick Build

```batch
REM 1. Build the plugin first
build.bat

REM 2. Download ONNX Runtime (if not already done)
curl -L https://github.com/microsoft/onnxruntime/releases/download/v1.16.0/onnxruntime-win-x64-1.16.0.zip -o onnx.zip
tar -xf onnx.zip

REM 3. (Optional) Download AI models to models\

REM 4. Build installer
build-installer.bat
```

Output: `StreamAudioIsolator-Setup.exe`

### Manual Build with NSIS

```batch
REM Compile installer script
"C:\Program Files (x86)\NSIS\makensis.exe" installer.nsi

REM Or if NSIS is in PATH
makensis installer.nsi
```

### Customizing the Installer

Edit `installer.nsi` to customize:

**Product Information:**
```nsis
!define PRODUCT_NAME "Stream Audio Isolator"
!define PRODUCT_VERSION "1.0.0"
!define PRODUCT_PUBLISHER "Your Name"
!define PRODUCT_WEB_SITE "https://yourwebsite.com"
```

**Files to Include:**
```nsis
; Add more models
File "models\*.onnx"

; Add documentation
File "README.md"
File "QUICKSTART.md"
```

**Custom Messages:**
```nsis
!define MUI_WELCOMEPAGE_TEXT "Your custom welcome message here"
```

### Installer Features

**What the installer does:**

✅ Checks for Administrator privileges
✅ Verifies 64-bit Windows
✅ Detects OBS Studio installation path
✅ Installs plugin DLL to correct location
✅ Installs ONNX Runtime dependency
✅ Copies data files and models
✅ Creates uninstaller
✅ Registers in Windows Apps & Features
✅ Shows quick start guide on completion

**Safety Features:**

- Admin check (prevents installation errors)
- 64-bit check (prevents incompatibility)
- OBS detection (prevents installation without OBS)
- Uninstaller registration (easy removal)

---

## 📦 Alternative: MSI Installer (WiX)

For enterprise deployments, you can create an MSI installer using WiX Toolset.

### Prerequisites

Install WiX Toolset:
- Download: https://wixtoolset.org/
- Or via Chocolatey: `choco install wixtoolset`

### WiX Product File (product.wxs)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="*"
           Name="Stream Audio Isolator"
           Language="1033"
           Version="1.0.0"
           Manufacturer="Stream Audio Isolator Team"
           UpgradeCode="YOUR-GUID-HERE">

    <Package InstallerVersion="200" Compressed="yes" InstallScope="perMachine" />

    <MajorUpgrade DowngradeErrorMessage="A newer version is already installed." />
    <MediaTemplate EmbedCab="yes" />

    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFiles64Folder">
        <Directory Id="OBSDIR" Name="obs-studio">
          <Directory Id="PLUGINSDIR" Name="obs-plugins">
            <Directory Id="PLUGINS64DIR" Name="64bit">
              <Component Id="PluginDLL" Guid="YOUR-GUID-HERE">
                <File Source="build\Release\stream-audio-isolator.dll" />
                <File Source="onnxruntime-win-x64-1.16.0\lib\onnxruntime.dll" />
              </Component>
            </Directory>
          </Directory>
        </Directory>
      </Directory>
    </Directory>

    <Feature Id="ProductFeature" Title="Stream Audio Isolator" Level="1">
      <ComponentRef Id="PluginDLL" />
    </Feature>
  </Product>
</Wix>
```

### Build MSI

```batch
REM Compile WiX source
candle product.wxs

REM Link to create MSI
light -ext WixUIExtension product.wixobj -o StreamAudioIsolator.msi
```

### MSI vs NSIS

| Feature | NSIS (.exe) | WiX (.msi) |
|---------|-------------|------------|
| **Size** | Smaller (~30 MB) | Larger (~35 MB) |
| **Enterprise** | ❌ No | ✅ Yes (Group Policy) |
| **Customization** | ✅ Very flexible | ⚠️ More rigid |
| **Silent Install** | ✅ `/S` flag | ✅ `msiexec /i /quiet` |
| **Unattended** | ✅ Easy | ✅ Enterprise-ready |
| **Rollback** | ❌ Manual | ✅ Automatic |
| **Recommended For** | Gamers, streamers | IT admins, enterprises |

---

## 🎨 Creating Custom Installer UI

### Add Custom Icon

1. Create or download an icon: `icon.ico` (256x256)
2. Edit `installer.nsi`:

```nsis
!define MUI_ICON "icon.ico"
!define MUI_UNICON "icon.ico"
```

### Add Splash Screen

1. Create image: `splash.bmp` (164x314 pixels)
2. Add to installer:

```nsis
!define MUI_WELCOMEFINISHPAGE_BITMAP "splash.bmp"
```

### Add Header Image

1. Create image: `header.bmp` (150x57 pixels)
2. Add to installer:

```nsis
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "header.bmp"
```

---

## 📊 Installer Size Optimization

### Compression

NSIS already uses LZMA compression (best). To customize:

```nsis
; Use best compression
SetCompressor /SOLID lzma
SetCompressorDictSize 64

; Or use faster compression
SetCompressor /SOLID zlib
```

### Exclude Models (Download Later)

To reduce installer size, don't include models:

```nsis
; Remove this line
File "models\*.onnx"

; Add download helper
CreateShortcut "$SMPROGRAMS\Download Models.lnk" "https://github.com/.../models"
```

Users download models separately (~50 MB).

**Result**: Installer drops from 60 MB to 10 MB!

---

## 🧪 Testing the Installer

### Test Checklist

- [ ] Install on clean Windows 10
- [ ] Install on clean Windows 11
- [ ] Install without OBS (should fail gracefully)
- [ ] Install without admin (should prompt)
- [ ] Install on 32-bit Windows (should fail with message)
- [ ] Verify plugin appears in OBS
- [ ] Test all 4 AI engines
- [ ] Uninstall and verify cleanup
- [ ] Reinstall over existing installation

### Automated Testing

Use VirtualBox or Hyper-V:

```powershell
# Create test VM
New-VM -Name "OBS-Test" -MemoryStartupBytes 4GB -Generation 2

# Install Windows
# Install OBS Studio
# Run installer
# Test plugin
# Snapshot VM for repeated tests
```

---

## 📚 Resources

### NSIS Documentation
- Official Docs: https://nsis.sourceforge.io/Docs/
- Modern UI Guide: https://nsis.sourceforge.io/Docs/Modern%20UI%202/Readme.html
- Examples: https://nsis.sourceforge.io/Category:Code_Examples

### WiX Documentation
- Official Docs: https://wixtoolset.org/documentation/
- Tutorial: https://www.firegiant.com/wix/tutorial/

### Tools
- **NSIS Quick Setup**: https://nsis.sourceforge.io/NSIS_Quick_Setup_Script_Generator
- **WiX Edit**: https://github.com/WixEdit/WixEdit
- **InstallForge** (Alternative): https://installforge.net/

---

## 🎉 Success!

Once built, your installer:

1. ✅ Works on any Windows 10/11 PC
2. ✅ Detects OBS automatically
3. ✅ Installs everything in correct locations
4. ✅ Registers for easy uninstall
5. ✅ Shows helpful messages
6. ✅ Ready for distribution!

**Users can now install your plugin in 30 seconds!** 🚀

---

**Questions?** See [WINDOWS_SETUP.md](WINDOWS_SETUP.md) or open an issue!
