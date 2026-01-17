; NSIS Installer Script for Stream Audio Isolator
; Creates a Windows .exe installer for easy installation

!include "MUI2.nsh"
!include "x64.nsh"

; ================================
; Installer Configuration
; ================================

!define PRODUCT_NAME "Stream Audio Isolator"
!define PRODUCT_VERSION "1.0.0"
!define PRODUCT_PUBLISHER "Stream Audio Isolator Team"
!define PRODUCT_WEB_SITE "https://github.com/yourusername/streameraudioremove"
!define INSTALLER_NAME "StreamAudioIsolator-Setup.exe"

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "${INSTALLER_NAME}"
InstallDir "$PROGRAMFILES64\obs-studio"
InstallDirRegKey HKLM "Software\OBS Studio" "InstallPath"

RequestExecutionLevel admin
ShowInstDetails show
ShowUnInstDetails show

; ================================
; Modern UI Configuration
; ================================

!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

!define MUI_WELCOMEPAGE_TITLE "Welcome to ${PRODUCT_NAME} Setup"
!define MUI_WELCOMEPAGE_TEXT "This will install the Stream Audio Isolator plugin for OBS Studio.$\r$\n$\r$\nRemove background music from your streams in real-time!$\r$\n$\r$\nClick Next to continue."

!define MUI_FINISHPAGE_TITLE "Installation Complete!"
!define MUI_FINISHPAGE_TEXT "${PRODUCT_NAME} has been installed successfully.$\r$\n$\r$\nNext steps:$\r$\n1. Restart OBS Studio$\r$\n2. Add filter to your microphone$\r$\n3. Start streaming DMCA-free!$\r$\n$\r$\nClick Finish to close this wizard."

!define MUI_FINISHPAGE_LINK "Visit our website for models and documentation"
!define MUI_FINISHPAGE_LINK_LOCATION "${PRODUCT_WEB_SITE}"

; ================================
; Pages
; ================================

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

; ================================
; Version Information
; ================================

VIProductVersion "1.0.0.0"
VIAddVersionKey "ProductName" "${PRODUCT_NAME}"
VIAddVersionKey "CompanyName" "${PRODUCT_PUBLISHER}"
VIAddVersionKey "FileVersion" "${PRODUCT_VERSION}"
VIAddVersionKey "FileDescription" "Real-time audio isolation plugin for OBS Studio"
VIAddVersionKey "LegalCopyright" "GPL-3.0 License"

; ================================
; Installer Sections
; ================================

Section "Main Application" SEC01
  SectionIn RO

  ; Check if OBS Studio is installed
  ${If} ${RunningX64}
    SetRegView 64
  ${EndIf}

  ReadRegStr $0 HKLM "Software\OBS Studio" ""
  ${If} $0 == ""
    MessageBox MB_OK|MB_ICONEXCLAMATION "OBS Studio not found!$\r$\n$\r$\nPlease install OBS Studio first from https://obsproject.com"
    Abort
  ${EndIf}

  DetailPrint "Found OBS Studio at: $INSTDIR"

  ; Set output path for plugin DLL
  SetOutPath "$INSTDIR\obs-plugins\64bit"

  ; Copy plugin DLL
  File "build\Release\stream-audio-isolator.dll"
  DetailPrint "Installed plugin DLL"

  ; Copy ONNX Runtime DLL
  File "onnxruntime-win-x64-*\lib\onnxruntime.dll"
  DetailPrint "Installed ONNX Runtime"

  ; Set output path for data files
  SetOutPath "$INSTDIR\data\obs-plugins\stream-audio-isolator"

  ; Copy data files
  File /r "data\*.*"
  DetailPrint "Installed data files"

  ; Create models directory
  CreateDirectory "$INSTDIR\data\obs-plugins\stream-audio-isolator\models"
  DetailPrint "Created models directory"

  ; Copy models (REQUIRED - installer will fail if missing)
  SetOutPath "$INSTDIR\data\obs-plugins\stream-audio-isolator\models"

  ; Check if models directory exists
  IfFileExists "models\sherpa-vocals.onnx" +3 0
    MessageBox MB_OK|MB_ICONEXCLAMATION "AI models not found!$\r$\n$\r$\nRun download-all-models.bat first to download models.$\r$\n$\r$\nInstaller will continue but plugin will not work without models."
    Goto skip_models

  ; Install all models
  File "models\*.onnx"
  DetailPrint "Installed AI models"

  ; Count and display installed models
  FindFirst $0 $1 "$INSTDIR\data\obs-plugins\stream-audio-isolator\models\*.onnx"
  DetailPrint "Models ready for use!"
  FindClose $0

  skip_models:

  ; Write uninstaller
  WriteUninstaller "$INSTDIR\Uninstall-StreamAudioIsolator.exe"

  ; Write registry keys for uninstaller
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\StreamAudioIsolator" "DisplayName" "${PRODUCT_NAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\StreamAudioIsolator" "UninstallString" "$INSTDIR\Uninstall-StreamAudioIsolator.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\StreamAudioIsolator" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\StreamAudioIsolator" "Publisher" "${PRODUCT_PUBLISHER}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\StreamAudioIsolator" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\StreamAudioIsolator" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\StreamAudioIsolator" "NoRepair" 1

  DetailPrint "Installation complete!"

SectionEnd

; ================================
; Uninstaller Section
; ================================

Section "Uninstall"

  ; Remove plugin files
  Delete "$INSTDIR\obs-plugins\64bit\stream-audio-isolator.dll"
  Delete "$INSTDIR\obs-plugins\64bit\onnxruntime.dll"

  ; Remove data files
  RMDir /r "$INSTDIR\data\obs-plugins\stream-audio-isolator"

  ; Remove uninstaller
  Delete "$INSTDIR\Uninstall-StreamAudioIsolator.exe"

  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\StreamAudioIsolator"

  MessageBox MB_OK "Stream Audio Isolator has been uninstalled.$\r$\n$\r$\nPlease restart OBS Studio."

SectionEnd

; ================================
; Functions
; ================================

Function .onInit
  ; Check if running as admin
  UserInfo::GetAccountType
  Pop $0
  ${If} $0 != "admin"
    MessageBox MB_OK|MB_ICONEXCLAMATION "This installer requires Administrator privileges.$\r$\n$\r$\nPlease right-click and select 'Run as administrator'."
    Abort
  ${EndIf}

  ; Check for 64-bit Windows
  ${IfNot} ${RunningX64}
    MessageBox MB_OK|MB_ICONSTOP "This plugin requires 64-bit Windows.$\r$\n$\r$\n32-bit Windows is not supported."
    Abort
  ${EndIf}
FunctionEnd

Function .onInstSuccess
  MessageBox MB_YESNO "Installation successful!$\r$\n$\r$\nDo you want to view the Quick Start guide?" IDNO +2
    ExecShell "open" "${PRODUCT_WEB_SITE}/blob/main/QUICKSTART.md"
FunctionEnd
