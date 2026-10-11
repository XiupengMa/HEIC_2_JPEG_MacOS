#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"
export CLANG_MODULE_CACHE_PATH="$PROJECT_DIR/.build/ModuleCache"
swift scripts/make-icon.swift Resources/Artwork/AppIcon-master.png \
    .build/AppIcon.iconset Resources/AppIcon.icns Resources/Assets.xcassets/AppIcon.appiconset
printf 'Generated the macOS icon catalog and Resources/AppIcon.icns.\n'
