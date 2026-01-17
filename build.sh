#!/bin/bash
# Build script for Stream Audio Isolator OBS Plugin

set -e  # Exit on error

echo "================================"
echo "Stream Audio Isolator - Build Script"
echo "================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    OS="windows"
fi

echo "Detected OS: $OS"
echo ""

# Check for dependencies
echo "Checking dependencies..."

# Check CMake
if ! command -v cmake &> /dev/null; then
    echo -e "${RED}ERROR: CMake not found!${NC}"
    echo "Install CMake: https://cmake.org/download/"
    exit 1
fi
echo -e "${GREEN}✓ CMake found${NC}"

# Check for ONNX Runtime
if [ -z "$ONNXRUNTIME_DIR" ]; then
    echo -e "${YELLOW}WARNING: ONNXRUNTIME_DIR not set${NC}"
    echo "Attempting to find ONNX Runtime..."

    # Try common locations
    if [ -f "/usr/lib/libonnxruntime.so" ]; then
        export ONNXRUNTIME_DIR="/usr"
        echo -e "${GREEN}✓ Found ONNX Runtime at /usr${NC}"
    elif [ -f "/usr/local/lib/libonnxruntime.so" ]; then
        export ONNXRUNTIME_DIR="/usr/local"
        echo -e "${GREEN}✓ Found ONNX Runtime at /usr/local${NC}"
    elif [ -d "./onnxruntime-linux-x64-1.16.0" ]; then
        export ONNXRUNTIME_DIR="./onnxruntime-linux-x64-1.16.0"
        echo -e "${GREEN}✓ Found ONNX Runtime in current directory${NC}"
    else
        echo -e "${RED}ERROR: ONNX Runtime not found!${NC}"
        echo ""
        echo "Download ONNX Runtime:"
        echo "  wget https://github.com/microsoft/onnxruntime/releases/download/v1.16.0/onnxruntime-linux-x64-1.16.0.tgz"
        echo "  tar -xzf onnxruntime-linux-x64-1.16.0.tgz"
        echo "  export ONNXRUNTIME_DIR=\$(pwd)/onnxruntime-linux-x64-1.16.0"
        exit 1
    fi
else
    echo -e "${GREEN}✓ ONNXRUNTIME_DIR set to: $ONNXRUNTIME_DIR${NC}"
fi

echo ""
echo "Starting build..."
echo ""

# Create build directory
mkdir -p build
cd build

# Configure
echo "Configuring with CMake..."
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DONNXRUNTIME_DIR="$ONNXRUNTIME_DIR"

# Build
echo ""
echo "Building plugin..."
cmake --build . --config Release -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Build completed successfully!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Check if models exist
echo "Checking for AI models..."
if [ ! -f "../models/sherpa-vocals.onnx" ]; then
    echo -e "${YELLOW}WARNING: AI models not found!${NC}"
    echo "Download models from: https://github.com/yourusername/streameraudioremove/releases"
    echo "Or see MODELS.md for conversion instructions"
    echo ""
fi

# Installation instructions
echo "Installation:"
echo ""
if [ "$OS" == "linux" ]; then
    echo "  sudo cmake --install ."
    echo ""
    echo "Or manually copy:"
    echo "  sudo cp stream-audio-isolator.so /usr/lib/obs-plugins/"
    echo "  sudo cp -r ../data /usr/share/obs/obs-plugins/stream-audio-isolator/"
elif [ "$OS" == "macos" ]; then
    echo "  sudo cmake --install ."
    echo ""
    echo "Or manually copy:"
    echo "  cp stream-audio-isolator.so ~/Library/Application\\ Support/obs-studio/plugins/"
else
    echo "  cmake --install . (as Administrator)"
fi

echo ""
echo "After installation, restart OBS Studio!"
echo ""
