#!/bin/bash
# Build script for PopClick
# Uses swiftc directly since SPM can't find SwiftUIMacros plugin
# without full Xcode installation

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCES_DIR="$PROJECT_DIR/Sources"
BUILD_DIR="$PROJECT_DIR/.build/direct"
APP_DIR="$BUILD_DIR/PopClick.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🔨 Building PopClick..."

# Clean and create directories
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Collect all Swift source files
SWIFT_FILES=$(find "$SOURCES_DIR" -name "*.swift" -type f)

echo "📦 Compiling $(echo "$SWIFT_FILES" | wc -l | tr -d ' ') source files..."

# Compile
swiftc \
    $SWIFT_FILES \
    -o "$MACOS_DIR/PopClick" \
    -parse-as-library \
    -target arm64-apple-macosx13.0 \
    -framework AppKit \
    -framework SwiftUI \
    -framework ApplicationServices \
    -framework WebKit \
    -Osize \
    2>&1

echo "📋 Creating Info.plist and Resources..."

# Copy Info.plist
cp "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

# Copy all resources (including local KaTeX bundle)
cp -R "$PROJECT_DIR/Resources/"* "$RESOURCES_DIR/" 2>/dev/null || true

# Create PkgInfo
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Ad-hoc sign the app bundle so macOS TCC / Accessibility can recognize its bundle ID
codesign --force --deep -s - "$APP_DIR" 2>/dev/null || true

echo "✅ Build complete: $APP_DIR"
echo ""
echo "To run:"
echo "  open $APP_DIR"
echo ""
echo "Or from terminal:"
echo "  $MACOS_DIR/PopClick"
