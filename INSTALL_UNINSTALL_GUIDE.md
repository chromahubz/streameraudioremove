# Installation & Uninstall Guide

Complete guide for installing, testing, and removing the plugin safely.

---

## 🎯 Three Installation Methods

### Method 1: .EXE Installer (Recommended) ⭐

**For**: End users who want one-click installation

**Steps**:
1. Download `StreamAudioIsolator-Setup.exe`
2. Right-click → "Run as administrator"
3. Follow wizard (4 clicks)
4. Restart OBS

**Pros**:
- ✅ Easiest (30 seconds)
- ✅ Automatic OBS detection
- ✅ Includes uninstaller
- ✅ Registers in Windows

**Cons**:
- ⚠️ Requires building installer first

---

### Method 2: Manual Install Script

**For**: Developers testing the plugin

**Steps**:
```batch
REM 1. Build plugin
build.bat

REM 2. Install (as Administrator)
install.bat

REM 3. Restart OBS
```

**Pros**:
- ✅ Quick for testing
- ✅ No installer needed

**Cons**:
- ⚠️ Manual uninstall required
- ⚠️ Not registered in Windows

---

### Method 3: PowerShell Automation

**For**: Advanced users who want full automation

**Steps**:
```powershell
# Run as Administrator
.\setup-windows.ps1
```

**Pros**:
- ✅ Downloads ONNX Runtime automatically
- ✅ Builds and installs in one command

**Cons**:
- ⚠️ Requires PowerShell execution policy

---

## 🔧 Building the .EXE Installer

### Prerequisites

**One-time setup**:
```batch
REM Install NSIS
choco install nsis

REM Or download from:
REM https://nsis.sourceforge.io/Download
```

### Build Process

```batch
REM 1. Build plugin first
build.bat

REM 2. Download ONNX Runtime (if not done)
curl -L https://github.com/microsoft/onnxruntime/releases/download/v1.16.0/onnxruntime-win-x64-1.16.0.zip -o onnx.zip
tar -xf onnx.zip

REM 3. (Optional) Download models to models\

REM 4. Build installer
build-installer.bat
```

**Output**: `StreamAudioIsolator-Setup.exe`

### Customizing Installer

Edit `installer.nsi` to change:
- Product name
- Version number
- Publisher info
- Files to include
- Custom messages

---

## 🗑️ Four Uninstall Methods

### Method 1: Windows Settings (Easiest)

**For**: Normal users

1. Press **Windows key**
2. Type: `add or remove programs`
3. Search: `Stream Audio Isolator`
4. Click: **Uninstall**
5. Confirm: **Yes**

**Time**: 10 seconds

---

### Method 2: Uninstaller Program

**For**: Quick removal

1. Navigate to: `C:\Program Files\obs-studio\`
2. Run: `Uninstall-StreamAudioIsolator.exe`
3. Confirm: **Yes**

**What it removes**:
- Plugin DLL
- ONNX Runtime DLL
- Data files
- Models
- Registry entries

---

### Method 3: Manual Removal

**For**: If uninstaller fails

```batch
REM Run as Administrator

REM Remove plugin files
del "C:\Program Files\obs-studio\obs-plugins\64bit\stream-audio-isolator.dll"
del "C:\Program Files\obs-studio\obs-plugins\64bit\onnxruntime.dll"

REM Remove data files
rmdir /s /q "C:\Program Files\obs-studio\data\obs-plugins\stream-audio-isolator"

REM Remove uninstaller
del "C:\Program Files\obs-studio\Uninstall-StreamAudioIsolator.exe"

REM Remove registry key (optional)
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\StreamAudioIsolator" /f
```

---

### Method 4: Developer Clean Uninstall

**For**: Complete removal including cached data

```batch
REM Run Method 3 (manual removal) first, then:

REM Remove OBS config for this plugin (user data)
del "%APPDATA%\obs-studio\plugin_config\stream-audio-isolator\*.*"

REM Clear logs
del "%APPDATA%\obs-studio\logs\*.txt"

REM Restart OBS with clean state
```

---

## 🔄 Reinstallation Scenarios

### Scenario 1: Installation Failed

**Problem**: Installer stopped with error

**Solution**:
```batch
REM 1. Uninstall (if partially installed)
Uninstall-StreamAudioIsolator.exe

REM 2. Check error:
REM - OBS not found? → Install OBS first
REM - Not admin? → Right-click installer → "Run as administrator"
REM - 32-bit Windows? → Not supported (need 64-bit)

REM 3. Fix issue, then reinstall
StreamAudioIsolator-Setup.exe
```

---

### Scenario 2: Plugin Not Appearing in OBS

**Problem**: Installed but plugin not in filter list

**Solution**:
```batch
REM 1. Check installation
dir "C:\Program Files\obs-studio\obs-plugins\64bit\stream-audio-isolator.dll"

REM If missing:
install.bat

REM If present, check dependencies:
dir "C:\Program Files\obs-studio\obs-plugins\64bit\onnxruntime.dll"

REM 2. Check OBS log
REM OBS → Help → Log Files → View Current Log
REM Search for: "stream-audio-isolator" or "error"

REM 3. Reinstall
Uninstall-StreamAudioIsolator.exe
StreamAudioIsolator-Setup.exe
```

---

### Scenario 3: Plugin Crashes OBS

**Problem**: OBS crashes when adding filter

**Solution**:
```batch
REM 1. Safe mode: Remove plugin DLL
del "C:\Program Files\obs-studio\obs-plugins\64bit\stream-audio-isolator.dll"

REM 2. Start OBS (should work now)

REM 3. Check what went wrong:
REM - Missing ONNX Runtime? → Reinstall
REM - Missing models? → Download models first
REM - GPU issue? → Try CPU engine (Sherpa-ONNX)

REM 4. Fix issue and reinstall
install.bat
```

---

### Scenario 4: Want to Update to Newer Version

**Problem**: New version released, want to upgrade

**Solution**:
```batch
REM Option A: Install over existing (easiest)
StreamAudioIsolator-Setup-v2.0.exe
REM Installer will replace old files

REM Option B: Clean install (safest)
Uninstall-StreamAudioIsolator.exe
StreamAudioIsolator-Setup-v2.0.exe
```

---

## 🧪 Test Installation Checklist

After installing, verify:

### 1. Files Installed
```batch
REM Check plugin DLL
dir "C:\Program Files\obs-studio\obs-plugins\64bit\stream-audio-isolator.dll"

REM Check ONNX Runtime
dir "C:\Program Files\obs-studio\obs-plugins\64bit\onnxruntime.dll"

REM Check data files
dir "C:\Program Files\obs-studio\data\obs-plugins\stream-audio-isolator\locale\en-US.ini"

REM Check models (if included)
dir "C:\Program Files\obs-studio\data\obs-plugins\stream-audio-isolator\models\*.onnx"
```

### 2. Registry Entry
```batch
REM Check uninstall registry
reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\StreamAudioIsolator"
```

### 3. OBS Integration
1. Open OBS Studio
2. Right-click **Microphone** → **Filters**
3. Click **+** button
4. Look for **"Audio Isolation (Music Removal)"**

### 4. Plugin UI
1. Add the filter
2. Check settings appear:
   - ☑ Enable checkbox
   - Engine dropdown (4 options)
   - Strength slider (0-100%)
   - Video delay field

---

## 🛡️ Safe Testing Process

### Before Installing in Production

**Test environment**:
1. Install on test PC first
2. Test with OBS Studio
3. Record short video
4. Check audio quality
5. Verify no crashes
6. Test uninstall

**Then deploy**:
1. Uninstall from test PC
2. Install on production PC
3. Use in actual stream

---

## ⚠️ Troubleshooting

### Installation Issues

**Error: "OBS Studio not found"**
```
Solution: Install OBS Studio first
Download: https://obsproject.com/download
```

**Error: "Access denied"**
```
Solution: Run installer as Administrator
Right-click → "Run as administrator"
```

**Error: "MSVCP140.dll not found"**
```
Solution: Install Visual C++ Redistributable
Download: https://aka.ms/vs/17/release/vc_redist.x64.exe
```

---

### Uninstall Issues

**Uninstaller won't run**
```
Solution: Use manual removal (Method 3)
See above for commands
```

**Files remain after uninstall**
```
Solution: Delete manually
del "C:\Program Files\obs-studio\obs-plugins\64bit\stream-audio-isolator.dll"
rmdir /s "C:\Program Files\obs-studio\data\obs-plugins\stream-audio-isolator"
```

**OBS still shows the filter**
```
Solution: Restart OBS completely
Close OBS → Kill process if needed → Restart
```

---

## 📊 Installation Comparison

| Method | Time | Ease | Uninstall | Best For |
|--------|------|------|-----------|----------|
| **.EXE Installer** | 30s | ⭐⭐⭐⭐⭐ | Easy (Windows Settings) | End users |
| **install.bat** | 10s | ⭐⭐⭐⭐ | Manual | Developers |
| **setup-windows.ps1** | 5min | ⭐⭐⭐ | Manual | Automation |
| **Manual copy** | 2min | ⭐⭐ | Manual | Advanced users |

---

## 🎯 Recommended Workflow

### For End Users:
```
1. Download StreamAudioIsolator-Setup.exe
2. Run installer
3. Use plugin
4. If issues: Uninstall from Windows Settings
5. If needed: Reinstall
```

### For Developers:
```
1. build.bat
2. install.bat
3. Test in OBS
4. If changes needed: Rebuild
5. install.bat (overwrites)
```

---

## 🔐 Safe Uninstall Guarantee

**You can ALWAYS remove the plugin completely**:

1. **Safest**: Windows Settings → Uninstall
2. **Fast**: Run Uninstall-StreamAudioIsolator.exe
3. **Manual**: Delete 3 files/folders
4. **Nuclear**: Reinstall OBS (plugin won't survive)

**The plugin CANNOT**:
- Prevent Windows from booting
- Damage your system
- Corrupt OBS installation
- Hide itself from removal

**It's just files in a folder** - worst case, delete the folder!

---

## ✅ Installation Safety Checklist

Before installing:
- [ ] OBS Studio installed
- [ ] Running 64-bit Windows
- [ ] Administrator access available
- [ ] 100 MB free disk space
- [ ] Antivirus won't block installation

After installing:
- [ ] Plugin appears in OBS filters
- [ ] Can be enabled/disabled
- [ ] Settings UI works
- [ ] Can uninstall from Windows Settings

---

## 🎉 Summary

### Installation
- ✅ 3 methods available (EXE, script, manual)
- ✅ Takes 10-30 seconds
- ✅ Fully automated with .EXE installer
- ✅ Can reinstall anytime

### Uninstallation
- ✅ 4 removal methods
- ✅ Takes 10 seconds
- ✅ Shows in Windows Settings
- ✅ Can always remove manually if needed

### Reinstallation
- ✅ Just run installer again
- ✅ Overwrites old version
- ✅ Or uninstall first (cleaner)
- ✅ No system reboot needed

**Bottom line**: Safe to install, easy to remove, simple to reinstall! 🎯
