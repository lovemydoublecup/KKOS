# ==============================================================================
# KKOS Unified Bundle Makefile
# Supports v2 canonical target and optional v4.3 sharded runtime.
# ==============================================================================

CXX := g++
CXXFLAGS := -std=c++17 -O3 -march=native -g -Wall -Wextra -pthread
BIN_DIR := bin
LOG_DIR := logs

V2_SRC := src/kkos_v2_unified.cpp
V2_TARGET := $(BIN_DIR)/kkos_v2

V43_SRC := src/kkos_v43_sharded.cpp
V43_TARGET := $(BIN_DIR)/kkos_v43
V45_TARGET := $(BIN_DIR)/kkos_v45

ifeq ($(OS),Windows_NT)
    V2_TARGET := $(BIN_DIR)/kkos_v2.exe
    V43_TARGET := $(BIN_DIR)/kkos_v43.exe
    V45_TARGET := $(BIN_DIR)/kkos_v45.exe
    LDFLAGS := -lws2_32 -static-libgcc -static-libstdc++ -static
    MKDIR := if not exist $(BIN_DIR) mkdir $(BIN_DIR) && if not exist $(LOG_DIR) mkdir $(LOG_DIR)
    CLEAN_CMD := if exist $(BIN_DIR) rmdir /s /q $(BIN_DIR) && if exist $(LOG_DIR) rmdir /s /q $(LOG_DIR)
else
    UNAME_S := $(shell uname -s)
    LDFLAGS := -pthread -static-libgcc -static-libstdc++
    ifeq ($(UNAME_S),Darwin)
        LDFLAGS := -pthread
    else
        LDFLAGS += -static
    endif
    MKDIR := mkdir -p $(BIN_DIR) $(LOG_DIR)
    CLEAN_CMD := rm -rf $(BIN_DIR) $(LOG_DIR)
endif

.PHONY: all v43 v45 preflight clean run run-v43 run-v45

all: preflight $(V2_TARGET)

v43: preflight $(V43_TARGET)

v45: preflight $(V45_TARGET)

preflight:
	@$(MKDIR)

$(V2_TARGET): $(V2_SRC)
	@echo "[COMPILING KKOS v2] Linking: $(V2_TARGET)"
	@$(CXX) $(CXXFLAGS) $(V2_SRC) -o $(V2_TARGET)
	@echo "[✓] KKOS v2 built successfully"

$(V43_TARGET): $(V43_SRC)
	@echo "[COMPILING KKOS v4.3] Linking: $(V43_TARGET)"
	@$(CXX) $(CXXFLAGS) $(V43_SRC) -o $(V43_TARGET) $(LDFLAGS)
	@echo "[✓] KKOS v4.3 built successfully"

$(V45_TARGET): $(V43_SRC)
	@echo "[COMPILING KKOS v4.5] Linking: $(V45_TARGET)"
	@$(CXX) $(CXXFLAGS) $(V43_SRC) -o $(V45_TARGET) $(LDFLAGS)
	@echo "[✓] KKOS v4.5 built successfully"

run: all
	@echo "[LAUNCHING KKOS v2]"
	@./$(V2_TARGET)

run-v43: v43
	@echo "[LAUNCHING KKOS v4.3]"
	@./$(V43_TARGET)

run-v45: v45
	@echo "[LAUNCHING KKOS v4.5]"
	@./$(V45_TARGET)

clean:
	@echo "[PURGING ARTIFACT FILE DIRECTORIES]"
	@$(CLEAN_CMD)
