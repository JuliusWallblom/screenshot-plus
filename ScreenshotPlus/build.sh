#!/bin/bash
set -e

APP_NAME="Screenshot+"
BUNDLE_ID="com.screenshotplus.app"
VERSION="1.0.0"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"
DIST_DIR="dist"

echo "Building $APP_NAME v$VERSION..."

# Build for release
swift build -c release

# Create dist directory
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/$APP_BUNDLE/Contents/MacOS"
mkdir -p "$DIST_DIR/$APP_BUNDLE/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$DIST_DIR/$APP_BUNDLE/Contents/MacOS/"

# Copy Info.plist
cp "Sources/ScreenshotPlus/Info.plist" "$DIST_DIR/$APP_BUNDLE/Contents/"

# Create PkgInfo
echo -n "APPL????" > "$DIST_DIR/$APP_BUNDLE/Contents/PkgInfo"

echo ""
echo "Build complete!"
echo "App bundle: $DIST_DIR/$APP_BUNDLE"
echo ""

# Check if we should code sign
if [ "$1" == "--sign" ]; then
    if [ -z "$2" ]; then
        echo "Usage: ./build.sh --sign \"Developer ID Application: Your Name (TEAMID)\""
        exit 1
    fi
    IDENTITY="$2"
    echo "Code signing with: $IDENTITY"
    codesign --force --deep --sign "$IDENTITY" "$DIST_DIR/$APP_BUNDLE"
    echo "Code signing complete!"
elif [ "$1" == "--sign-local" ]; then
    echo "Ad-hoc signing for local use..."
    codesign --force --deep --sign - "$DIST_DIR/$APP_BUNDLE"
    echo "Ad-hoc signing complete!"
fi

echo ""
echo "To run: open $DIST_DIR/$APP_BUNDLE"
echo "To install: cp -r $DIST_DIR/$APP_BUNDLE /Applications/"
