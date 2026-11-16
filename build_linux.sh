#!/bin/sh
mkdir -p bin

VERSION="5.2.0"

# 0. Folder Relabeling
CURRENT_DIR=$(basename "$PWD")
if [ "$CURRENT_DIR" = "KKOS_v4.5_Unified_Bundle" ]; then
    echo "Relabeling root folder to KKOS_v5.2.0_Unified_Bundle..."
    cd .. && mv "KKOS_v4.5_Unified_Bundle" "KKOS_v5.2.0_Unified_Bundle" && cd "KKOS_v5.2.0_Unified_Bundle"
fi

LEGACY_SRC="src/kkos_v2_unified.cpp"
SRC="src/kkos_v520_unified.cpp"
OUT="bin/kkos_v520"

if [ -f "$LEGACY_SRC" ]; then
    echo "Relabeling $LEGACY_SRC to $SRC..."
    mv "$LEGACY_SRC" "$SRC"
fi

g++ -std=c++17 -O3 -flto -pthread "$SRC" -o "$OUT" -DKKOS_VERSION_STR=\"$VERSION\" -DKKOS_VERSION_MAJOR=5 -DKKOS_VERSION_MINOR=2
echo "Built $OUT"
