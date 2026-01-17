#!/bin/bash
# Validation script - Check for common issues before building

set -e

ERRORS=0
WARNINGS=0

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           STREAM AUDIO ISOLATOR - VALIDATION                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ERRORS=$((ERRORS + 1))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check file structure
echo "Checking file structure..."
echo ""

required_files=(
    "CMakeLists.txt"
    "src/plugin-main.c"
    "src/audio-isolator-filter.c"
    "src/audio-isolator-filter.h"
    "src/engines/sherpa-engine.c"
    "src/engines/hstasnet-engine.c"
    "src/engines/clearervoice-engine.c"
    "src/engines/spleeterrt-engine.c"
    "src/utils/audio-buffer.c"
    "data/locale/en-US.ini"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_ok "Found: $file"
    else
        print_error "Missing: $file"
    fi
done

echo ""

# Check for common C syntax errors
echo "Checking C source files for common issues..."
echo ""

check_c_file() {
    local file=$1
    local issues=0

    # Check for unclosed braces
    open_braces=$(grep -o "{" "$file" | wc -l)
    close_braces=$(grep -o "}" "$file" | wc -l)

    if [ "$open_braces" != "$close_braces" ]; then
        print_error "$file: Mismatched braces (open=$open_braces, close=$close_braces)"
        issues=1
    fi

    # Check for missing includes
    if ! grep -q "#include.*obs-module.h" "$file" && [ "$file" != "src/audio-isolator-filter.h" ]; then
        if grep -q "obs_" "$file" || grep -q "blog" "$file"; then
            print_warning "$file: Uses OBS functions but may be missing obs-module.h"
        fi
    fi

    # Check for TODO/FIXME
    if grep -q "TODO\|FIXME" "$file"; then
        local count=$(grep -c "TODO\|FIXME" "$file")
        print_warning "$file: Contains $count TODO/FIXME comments"
    fi

    if [ $issues -eq 0 ]; then
        print_ok "$file: Basic syntax check passed"
    fi
}

for cfile in src/*.c src/engines/*.c src/utils/*.c; do
    if [ -f "$cfile" ]; then
        check_c_file "$cfile"
    fi
done

echo ""

# Check header guards
echo "Checking header files..."
echo ""

if [ -f "src/audio-isolator-filter.h" ]; then
    if grep -q "#pragma once" "src/audio-isolator-filter.h"; then
        print_ok "Header uses #pragma once"
    else
        print_warning "Header missing #pragma once"
    fi
fi

echo ""

# Check CMakeLists.txt
echo "Checking CMakeLists.txt..."
echo ""

if [ -f "CMakeLists.txt" ]; then
    # Check for required commands
    if grep -q "cmake_minimum_required" "CMakeLists.txt"; then
        print_ok "Has cmake_minimum_required"
    else
        print_error "Missing cmake_minimum_required"
    fi

    if grep -q "project" "CMakeLists.txt"; then
        print_ok "Has project() declaration"
    else
        print_error "Missing project() declaration"
    fi

    if grep -q "add_library.*stream-audio-isolator" "CMakeLists.txt"; then
        print_ok "Defines stream-audio-isolator library"
    else
        print_error "Missing add_library for stream-audio-isolator"
    fi

    # Check if all source files are listed
    for src in src/*.c src/engines/*.c src/utils/*.c; do
        if [ -f "$src" ]; then
            basename=$(basename "$src")
            if grep -q "$basename" "CMakeLists.txt"; then
                print_ok "CMakeLists.txt includes $basename"
            else
                print_error "CMakeLists.txt missing $basename"
            fi
        fi
    done
fi

echo ""

# Check for ONNX Runtime API usage
echo "Checking ONNX Runtime API usage..."
echo ""

for engine in src/engines/*.c; do
    if [ -f "$engine" ]; then
        if grep -q "OrtGetApiBase" "$engine"; then
            print_ok "$(basename $engine): Uses ONNX Runtime API"
        else
            print_warning "$(basename $engine): May not use ONNX Runtime properly"
        fi

        # Check for proper cleanup
        if grep -q "ReleaseSession\|ReleaseEnv" "$engine"; then
            print_ok "$(basename $engine): Has cleanup code"
        else
            print_warning "$(basename $engine): May be missing cleanup code"
        fi
    fi
done

echo ""

# Check documentation
echo "Checking documentation..."
echo ""

docs=(
    "README.md"
    "QUICKSTART.md"
    "WINDOWS_SETUP.md"
    "MODELS.md"
)

for doc in "${docs[@]}"; do
    if [ -f "$doc" ]; then
        lines=$(wc -l < "$doc")
        print_ok "$doc exists ($lines lines)"
    else
        print_warning "Missing documentation: $doc"
    fi
done

echo ""

# Check for models directory
echo "Checking models directory..."
echo ""

if [ -d "models" ]; then
    print_ok "models/ directory exists"

    model_count=$(ls -1 models/*.onnx 2>/dev/null | wc -l)
    if [ "$model_count" -gt 0 ]; then
        print_ok "Found $model_count ONNX model(s)"
        ls -lh models/*.onnx 2>/dev/null | awk '{print "  - " $9 " (" $5 ")"}'
    else
        print_warning "No ONNX models found in models/ directory"
        print_info "Download models or see MODELS.md for conversion instructions"
    fi
else
    print_error "models/ directory missing"
fi

echo ""

# Summary
echo "═══════════════════════════════════════════════════════════════"
echo "VALIDATION SUMMARY"
echo "═══════════════════════════════════════════════════════════════"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Download ONNX models (see MODELS.md)"
    echo "2. Install build dependencies"
    echo "3. Run build script:"
    echo "   Linux/macOS: ./build.sh"
    echo "   Windows: build.bat"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Passed with $WARNINGS warning(s)${NC}"
    echo ""
    echo "You can proceed with building, but check warnings above."
    exit 0
else
    echo -e "${RED}✗ Failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo ""
    echo "Please fix the errors above before building."
    exit 1
fi
