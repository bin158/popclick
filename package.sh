#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="$PROJECT_DIR/PopClick/.build/direct/PopClick.app"
DIST_DIR="$PROJECT_DIR/dist"
STAGING_DIR="$PROJECT_DIR/.build_dmg_staging"

echo "📦 Packaging PopClick for macOS..."

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: $APP_PATH does not exist. Please run build.sh first."
    exit 1
fi

rm -rf "$DIST_DIR" "$STAGING_DIR"
mkdir -p "$DIST_DIR" "$STAGING_DIR"

# 1. Prepare Staging directory for DMG
echo "💿 Creating DMG staging area..."
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

# 2. Build DMG disk image
echo "💿 Building PopClick-1.0.0.dmg..."
hdiutil create \
    -volname "PopClick" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DIST_DIR/PopClick-1.0.0.dmg"

cp "$DIST_DIR/PopClick-1.0.0.dmg" "$DIST_DIR/PopClick.dmg"

# 3. Build ZIP archive
echo "🗜️ Creating PopClick-1.0.0.zip..."
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$DIST_DIR/PopClick-1.0.0.zip"
cp "$DIST_DIR/PopClick-1.0.0.zip" "$DIST_DIR/PopClick.zip"

# Clean up staging
rm -rf "$STAGING_DIR"

# 4. Generate Checksums
cd "$DIST_DIR"
shasum -a 256 *.dmg *.zip > SHA256SUMS.txt
cd "$PROJECT_DIR"

echo "✅ Packaging complete! Artifacts in $DIST_DIR:"
ls -lh "$DIST_DIR"
