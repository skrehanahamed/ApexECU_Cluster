# APEX SUV Digital Instrument Cluster Makefile
# Automatically detects Qt 6 environment or uses default path

QT_DIR ?= $(shell [ -d "/Users/reno/Qt/6.11.1/macos" ] && echo "/Users/reno/Qt/6.11.1/macos" || (which qmake >/dev/null 2>&1 && qmake -query QT_INSTALL_PREFIX || echo "/usr/local/Qt-6"))
CMAKE ?= $(shell [ -f "/Users/reno/Qt/Tools/CMake/CMake.app/Contents/bin/cmake" ] && echo "/Users/reno/Qt/Tools/CMake/CMake.app/Contents/bin/cmake" || which cmake)
BUILD_DIR ?= build
QML_BIN ?= $(QT_DIR)/bin/qml

.PHONY: all build run qml clean configure rebuild help

all: build

configure:
	@echo "==> Configuring CMake with Qt 6.11.1..."
	@mkdir -p $(BUILD_DIR)
	@$(CMAKE) -B $(BUILD_DIR) -S . -DCMAKE_PREFIX_PATH=$(QT_DIR) -GNinja

build: configure
	@echo "==> Building ApexCluster binary..."
	@$(CMAKE) --build $(BUILD_DIR)

run: build
	@echo "==> Launching ApexCluster Native Application..."
	@if [ -d "$(BUILD_DIR)/ApexCluster.app" ]; then \
		./$(BUILD_DIR)/ApexCluster.app/Contents/MacOS/ApexCluster; \
	else \
		./$(BUILD_DIR)/ApexCluster; \
	fi

qml:
	@echo "==> Running live QML preview..."
	@$(QML_BIN) qml/Main.qml

clean:
	@echo "==> Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
