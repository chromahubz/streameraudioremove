#!/bin/bash
# Test code logic and structure

echo "╔═══════════════════════════════════════════════════╗"
echo "║     DEEP CODE LOGIC VERIFICATION                  ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""

# Test 1: Check for memory leaks (malloc/free balance)
echo "1. Checking memory allocation patterns..."
for file in src/*.c src/engines/*.c src/utils/*.c; do
    if [ -f "$file" ]; then
        mallocs=$(grep -c "malloc\|calloc\|bzalloc" "$file")
        frees=$(grep -c "bfree\|free" "$file")
        
        if [ $mallocs -gt 0 ]; then
            echo "  $file: mallocs=$mallocs, frees=$frees"
            if [ $frees -lt $mallocs ]; then
                echo "    ⚠️  Warning: Possible memory leak"
            else
                echo "    ✅ OK"
            fi
        fi
    fi
done

echo ""
echo "2. Checking mutex lock/unlock balance..."
for file in src/*.c; do
    if [ -f "$file" ]; then
        locks=$(grep -c "pthread_mutex_lock" "$file")
        unlocks=$(grep -c "pthread_mutex_unlock" "$file")
        
        if [ $locks -gt 0 ]; then
            echo "  $file: locks=$locks, unlocks=$unlocks"
            if [ $locks -ne $unlocks ]; then
                echo "    ⚠️  Warning: Unbalanced locks"
            else
                echo "    ✅ OK"
            fi
        fi
    fi
done

echo ""
echo "3. Checking ONNX cleanup..."
for file in src/engines/*.c; do
    if [ -f "$file" ]; then
        creates=$(grep -c "Create.*Session\|Create.*Env" "$file")
        releases=$(grep -c "Release.*Session\|Release.*Env" "$file")
        
        echo "  $file: creates=$creates, releases=$releases"
        if [ $creates -ne $releases ]; then
            echo "    ⚠️  Warning: Possible ONNX resource leak"
        else
            echo "    ✅ OK"
        fi
    fi
done

echo ""
echo "4. Checking error handling..."
error_checks=$(grep -r "if.*NULL\|if.*status.*!=" src/ | wc -l)
echo "  Found $error_checks error checks"
if [ $error_checks -gt 20 ]; then
    echo "    ✅ Good error handling"
else
    echo "    ⚠️  May need more error checks"
fi

echo ""
echo "5. Checking string safety..."
unsafe=$(grep -r "strcpy\|sprintf\|gets" src/ | wc -l)
safe=$(grep -r "strncpy\|snprintf\|strdup" src/ | wc -l)
echo "  Unsafe functions: $unsafe"
echo "  Safe functions: $safe"
if [ $unsafe -eq 0 ]; then
    echo "    ✅ No unsafe string functions"
else
    echo "    ⚠️  Found unsafe string functions"
fi

echo ""
echo "═══════════════════════════════════════════════════"
echo "LOGIC VERIFICATION COMPLETE"
echo "═══════════════════════════════════════════════════"
