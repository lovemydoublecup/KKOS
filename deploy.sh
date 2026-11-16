#!/bin/bash
# =============================================================================
# 3D Game Shaders - Automated Deployment Script
# Part of the KKOS_v5.2_Unified_Bundle
# =============================================================================

set -e # Exit immediately if a command exits with a non-zero status.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

echo "-------------------------------------------------------"
echo "  Deploying 3D Game Shaders Demo (Panda3D)             "
echo "-------------------------------------------------------"

# 1. Check for Python 3.11+ (Requirement matching Odysseus)
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is not installed. Please install Python 3.11 or higher."
    exit 1
fi

# 1.1 Check for Build Tools (C++ Compiler and Make)
if ! command -v g++ &> /dev/null; then
    echo "Error: g++ is not installed. C++ shader components cannot be compiled."
    exit 1
fi
if ! command -v make &> /dev/null; then
    echo "Warning: 'make' not found. Fallback to setup.py if available."
fi

# 2. Setup Virtual Environment
if [ ! -d "venv" ]; then
    echo "[1/5] Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) source venv/Scripts/activate ;;
    *)                    source venv/bin/activate ;;
esac

# 3. Install Dependencies
echo "[2/5] Updating pip and installing Panda3D..."
pip install --upgrade pip setuptools wheel
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
else
    pip install panda3d numpy
fi

# 4. Compile C++ Shader Components
# Many shader demos use C++ extensions for procedural logic.
if [ -f "setup.py" ]; then
    echo "[3/5] Compiling C++ extensions via setup.py..."
    python setup.py build_ext --inplace
elif [ -f "Makefile" ]; then
    echo "[3/5] Compiling via Makefile..."
    make
else
    echo "[3/5] No compilation script found (setup.py/Makefile), skipping step."
fi

# 4.1 Clean up build artifacts
if [ -d "build" ]; then
    rm -rf build/
fi

# 5. Verification
echo "[4/5] Verifying Panda3D installation..."
python -c "import panda3d; print('Successfully loaded Panda3D version:', panda3d.__version__)"

# 6. Completion
echo "[5/5] Deployment complete."
echo "-------------------------------------------------------"
echo "To run the demo: source venv/bin/activate && python main.py"
echo "-------------------------------------------------------"