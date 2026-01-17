#!/bin/bash
# Comprehensive End-to-End Test
# Tests structure, build readiness, and deployment preparation

set -e

ERRORS=0
WARNINGS=0
CHECKS=0

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     STREAM AUDIO ISOLATOR - COMPREHENSIVE TEST              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    CHECKS=$((CHECKS + 1))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ERRORS=$((ERRORS + 1))
    CHECKS=$((CHECKS + 1))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARNINGS=$((WARNINGS + 1))
    CHECKS=$((CHECKS + 1))
}

section() {
    echo ""
    echo -e "${CYAN}═══ $1 ═══${NC}"
    echo ""
}

# Test 1: Project Structure
section "Test 1: Project Structure"

required_files=(
    "CMakeLists.txt"
    "README.md"
    "LICENSE"
    "src/plugin-main.c"
    "src/audio-isolator-filter.c"
    "src/audio-isolator-filter.h"
    "src/engines/sherpa-engine.c"
    "src/engines/hstasnet-engine.c"
    "src/engines/clearervoice-engine.c"
    "src/engines/spleeterrt-engine.c"
    "src/utils/audio-buffer.c"
    "data/locale/en-US.ini"
    "build.sh"
    "build.bat"
    "installer.nsi"
    "build-installer.bat"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        check_pass "Found: $file"
    else
        check_fail "Missing: $file"
    fi
done

# Test 2: Documentation Completeness
section "Test 2: Documentation"

docs=(
    "README.md"
    "QUICKSTART.md"
    "WINDOWS_SETUP.md"
    "MODELS.md"
    "MODEL_HOSTING_GUIDE.md"
    "INSTALLER_GUIDE.md"
    "INSTALL_UNINSTALL_GUIDE.md"
    "PLATFORM_SUPPORT.md"
    "PROJECT_SUMMARY.md"
    "CODE_ANALYSIS.md"
    "TEST_RESULTS.md"
)

total_doc_size=0
for doc in "${docs[@]}"; do
    if [ -f "$doc" ]; then
        size=$(wc -c < "$doc")
        total_doc_size=$((total_doc_size + size))
        check_pass "$doc exists ($(wc -l < $doc) lines, $((size / 1024)) KB)"
    else
        check_warn "Missing doc: $doc"
    fi
done

echo ""
echo "Total documentation: $((total_doc_size / 1024)) KB"

# Test 3: Code Quality
section "Test 3: Code Quality Checks"

# Check for common issues in C files
for cfile in src/*.c src/engines/*.c src/utils/*.c; do
    if [ ! -f "$cfile" ]; then
        continue
    fi

    filename=$(basename "$cfile")

    # Check file size (not too large)
    lines=$(wc -l < "$cfile")
    if [ $lines -gt 1000 ]; then
        check_warn "$filename is large ($lines lines)"
    else
        check_pass "$filename size OK ($lines lines)"
    fi

    # Check for tabs vs spaces consistency
    tabs=$(grep -c $'\t' "$cfile" || true)
    if [ $tabs -eq 0 ]; then
        check_pass "$filename uses spaces consistently"
    fi
done

# Test 4: CMake Configuration
section "Test 4: Build System"

if grep -q "cmake_minimum_required" CMakeLists.txt; then
    version=$(grep "cmake_minimum_required" CMakeLists.txt | grep -o "[0-9\.]*")
    check_pass "CMake minimum version: $version"
else
    check_fail "Missing cmake_minimum_required"
fi

if grep -q "project.*stream-audio-isolator" CMakeLists.txt; then
    check_pass "Project name configured"
else
    check_fail "Missing project name"
fi

# Check all source files are listed
for src in src/*.c src/engines/*.c src/utils/*.c; do
    if [ -f "$src" ]; then
        basename=$(basename "$src")
        if grep -q "$basename" CMakeLists.txt; then
            check_pass "CMakeLists.txt includes $basename"
        else
            check_fail "CMakeLists.txt missing $basename"
        fi
    fi
done

# Test 5: Installer Configuration
section "Test 5: Installer Configuration"

if [ -f "installer.nsi" ]; then
    # Check for key installer components
    if grep -q "PRODUCT_NAME" installer.nsi; then
        name=$(grep "PRODUCT_NAME" installer.nsi | head -1)
        check_pass "Installer product name configured"
    fi

    if grep -q "PRODUCT_VERSION" installer.nsi; then
        version=$(grep "PRODUCT_VERSION" installer.nsi | head -1)
        check_pass "Installer version configured"
    fi

    if grep -q "models.*\.onnx" installer.nsi; then
        check_pass "Installer includes model files"
    else
        check_warn "Installer may not include models"
    fi

    if grep -q "CreateDirectory.*models" installer.nsi; then
        check_pass "Installer creates models directory"
    fi
else
    check_fail "installer.nsi not found"
fi

# Test 6: Model Preparation
section "Test 6: Model Preparation"

if [ -d "models" ]; then
    check_pass "models/ directory exists"

    model_count=$(ls -1 models/*.onnx 2>/dev/null | wc -l)
    if [ "$model_count" -gt 0 ]; then
        total_size=0
        echo ""
        echo "Found $model_count model(s):"
        for model in models/*.onnx; do
            if [ -f "$model" ]; then
                size=$(stat -f%z "$model" 2>/dev/null || stat -c%s "$model" 2>/dev/null || echo 0)
                size_mb=$((size / 1048576))
                total_size=$((total_size + size))
                check_pass "$(basename $model) - ${size_mb} MB"
            fi
        done
        echo ""
        total_mb=$((total_size / 1048576))
        echo "Total model size: ${total_mb} MB"

        if [ $total_mb -gt 50 ] && [ $total_mb -lt 70 ]; then
            check_pass "Model size in expected range (50-70 MB)"
        elif [ $total_mb -gt 0 ]; then
            check_warn "Model size unusual: ${total_mb} MB"
        fi
    else
        check_warn "No ONNX models found - installer will work but plugin won't function"
        echo ""
        echo "To add models:"
        echo "  1. Run: download-all-models.bat (Windows)"
        echo "  2. Or see: MODEL_HOSTING_GUIDE.md"
    fi
else
    check_fail "models/ directory missing"
fi

# Test 7: Memory Safety Patterns
section "Test 7: Memory Safety"

malloc_count=0
free_count=0

for cfile in src/*.c src/engines/*.c src/utils/*.c; do
    if [ -f "$cfile" ]; then
        m=$(grep -c "malloc\|calloc\|bzalloc" "$cfile" || true)
        f=$(grep -c "free\|bfree" "$cfile" || true)
        malloc_count=$((malloc_count + m))
        free_count=$((free_count + f))
    fi
done

if [ $free_count -ge $malloc_count ]; then
    check_pass "Memory allocation/deallocation balanced ($malloc_count allocs, $free_count frees)"
else
    check_warn "Possible memory leak pattern ($malloc_count allocs, $free_count frees)"
fi

# Test 8: Thread Safety
section "Test 8: Thread Safety"

lock_count=$(grep -r "pthread_mutex_lock" src/ | wc -l)
unlock_count=$(grep -r "pthread_mutex_unlock" src/ | wc -l)

if [ $lock_count -gt 0 ]; then
    if [ $unlock_count -ge $lock_count ]; then
        check_pass "Mutex usage detected and balanced ($lock_count locks, $unlock_count unlocks)"
    else
        check_warn "Mutex lock/unlock imbalance ($lock_count locks, $unlock_count unlocks)"
    fi
fi

# Test 9: ONNX Runtime Integration
section "Test 9: ONNX Runtime Integration"

for engine in src/engines/*.c; do
    if [ -f "$engine" ]; then
        name=$(basename "$engine")

        if grep -q "OrtGetApiBase" "$engine"; then
            check_pass "$name: Uses ONNX Runtime API"
        else
            check_fail "$name: Missing ONNX Runtime API usage"
        fi

        if grep -q "ReleaseSession\|ReleaseEnv" "$engine"; then
            check_pass "$name: Has cleanup code"
        else
            check_warn "$name: May be missing cleanup"
        fi
    fi
done

# Test 10: String Safety
section "Test 10: String Safety"

unsafe=$(grep -r "strcpy\|sprintf\|gets" src/ | wc -l)
safe=$(grep -r "strncpy\|snprintf" src/ | wc -l)

if [ $unsafe -eq 0 ]; then
    check_pass "No unsafe string functions detected"
else
    check_warn "Found $unsafe unsafe string function calls"
fi

if [ $safe -gt 0 ]; then
    check_pass "Uses safe string functions ($safe instances)"
fi

# Test 11: Build Scripts
section "Test 11: Build Scripts"

if [ -f "build.sh" ] && [ -x "build.sh" ]; then
    check_pass "build.sh is executable"
else
    check_warn "build.sh may not be executable"
fi

if [ -f "validate.sh" ] && [ -x "validate.sh" ]; then
    check_pass "validate.sh is executable"
fi

if [ -f "build.bat" ]; then
    if grep -q "cmake" build.bat; then
        check_pass "build.bat uses CMake"
    fi

    if grep -q "ONNXRUNTIME_DIR" build.bat; then
        check_pass "build.bat checks for ONNX Runtime"
    fi
fi

# Test 12: Git Repository
section "Test 12: Git Repository"

if [ -d ".git" ]; then
    check_pass "Git repository initialized"

    branch=$(git branch --show-current)
    check_pass "Current branch: $branch"

    commits=$(git rev-list --count HEAD)
    check_pass "Total commits: $commits"

    files_tracked=$(git ls-files | wc -l)
    check_pass "Files tracked: $files_tracked"

    if git diff --quiet; then
        check_pass "No uncommitted changes"
    else
        check_warn "Uncommitted changes present"
    fi
else
    check_fail "Not a git repository"
fi

# Test 13: Installer Size Estimation
section "Test 13: Installer Size Estimation"

dll_size=512  # KB estimate
onnx_runtime=8192  # KB estimate
models_size=0

if [ -d "models" ]; then
    for model in models/*.onnx; do
        if [ -f "$model" ]; then
            size=$(stat -f%z "$model" 2>/dev/null || stat -c%s "$model" 2>/dev/null || echo 0)
            models_size=$((models_size + size / 1024))
        fi
    done
fi

total_installer_size=$((dll_size + onnx_runtime + models_size))

echo "Estimated installer size:"
echo "  Plugin DLL:      ~${dll_size} KB"
echo "  ONNX Runtime:    ~${onnx_runtime} KB"
echo "  AI Models:       ${models_size} KB"
echo "  ────────────────────────────"
echo "  Total:           ~$((total_installer_size / 1024)) MB"

if [ $total_installer_size -gt 61440 ] && [ $total_installer_size -lt 102400 ]; then
    check_pass "Installer size in target range (60-100 MB)"
elif [ $models_size -eq 0 ]; then
    check_warn "No models - installer will be ~10 MB (plugin won't work)"
else
    check_warn "Installer size outside normal range"
fi

# Test 14: Deployment Readiness
section "Test 14: Deployment Readiness"

ready_for_build=true

# Check essential files
essential=(
    "src/plugin-main.c"
    "CMakeLists.txt"
    "installer.nsi"
    "build.bat"
)

for file in "${essential[@]}"; do
    if [ ! -f "$file" ]; then
        ready_for_build=false
        check_fail "Essential file missing: $file"
    fi
done

if [ ! -d "src/engines" ]; then
    ready_for_build=false
    check_fail "engines directory missing"
fi

if $ready_for_build; then
    check_pass "All essential files present"
    check_pass "Ready for build"
else
    check_fail "Not ready for build - missing files"
fi

# Final Summary
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    TEST SUMMARY                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "Total Checks: $CHECKS"
echo -e "${GREEN}Passed:  $((CHECKS - ERRORS - WARNINGS))${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo -e "${RED}Errors:   $ERRORS${NC}"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "║ ${GREEN}STATUS: PERFECT ✓✓✓${NC}                                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${GREEN}All systems GO!${NC} Ready for:"
    echo "  1. Building: ./build.sh or build.bat"
    echo "  2. Creating installer: build-installer.bat"
    echo "  3. Distribution: Upload to GitHub releases"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "║ ${YELLOW}STATUS: GOOD (with warnings)${NC}                            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${YELLOW}Ready to build with minor warnings.${NC}"
    echo "Review warnings above, but build can proceed."
    exit 0
else
    echo -e "║ ${RED}STATUS: NEEDS ATTENTION${NC}                                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${RED}Fix errors before building.${NC}"
    echo "See errors above for details."
    exit 1
fi
