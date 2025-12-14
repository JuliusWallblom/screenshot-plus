#!/bin/bash
set -e

APP_NAME="Screenshot+"
BUNDLE_ID="com.screenshotplus.app"
VERSION="1.0.0"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"
DIST_DIR="dist"
DMG_NAME="$APP_NAME.dmg"
DMG_TEMP="$DIST_DIR/dmg_temp"
DMG_RW="$DIST_DIR/temp.dmg"

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

# Copy app icon
if [ -f "Sources/ScreenshotPlus/Resources/AppIcon.icns" ]; then
    cp "Sources/ScreenshotPlus/Resources/AppIcon.icns" "$DIST_DIR/$APP_BUNDLE/Contents/Resources/"
    echo "App icon copied."
fi

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
    codesign --force --deep --sign "$IDENTITY" --options runtime --timestamp "$DIST_DIR/$APP_BUNDLE"
    echo "Code signing complete!"

    # Create DMG
    echo ""
    echo "Creating DMG..."

    # Clean up any previous temp files
    rm -rf "$DMG_TEMP"
    rm -f "$DMG_RW"
    rm -f "$DIST_DIR/$DMG_NAME"

    # Create temporary directory for DMG contents
    mkdir -p "$DMG_TEMP"

    # Copy app to temp directory
    cp -r "$DIST_DIR/$APP_BUNDLE" "$DMG_TEMP/"

    # Create Applications symlink
    ln -s /Applications "$DMG_TEMP/Applications"

    # Create a read-write DMG first
    hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_TEMP" -ov -format UDRW "$DMG_RW"

    # Mount the read-write DMG
    MOUNT_DIR=$(hdiutil attach -readwrite -noverify "$DMG_RW" | grep "/Volumes/$APP_NAME" | awk '{print $3}')

    # Wait for mount
    sleep 2

    # Use AppleScript to set up the DMG appearance
    osascript <<EOF
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {400, 100, 900, 400}
        set theViewOptions to icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 100
        set position of item "$APP_BUNDLE" of container window to {125, 150}
        set position of item "Applications" of container window to {375, 150}
        close
        open
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF

    # Unmount
    sync
    hdiutil detach "$MOUNT_DIR" -quiet

    # Convert to compressed read-only DMG
    hdiutil convert "$DMG_RW" -format UDZO -o "$DIST_DIR/$DMG_NAME"

    # Clean up
    rm -rf "$DMG_TEMP"
    rm -f "$DMG_RW"

    # Sign the DMG
    codesign --force --sign "$IDENTITY" --timestamp "$DIST_DIR/$DMG_NAME"

    echo "DMG created: $DIST_DIR/$DMG_NAME"

elif [ "$1" == "--sign-local" ]; then
    echo "Ad-hoc signing for local use..."
    codesign --force --deep --sign - "$DIST_DIR/$APP_BUNDLE"
    echo "Ad-hoc signing complete!"
fi

echo ""
echo "To run: open $DIST_DIR/$APP_BUNDLE"
echo "To install: cp -r $DIST_DIR/$APP_BUNDLE /Applications/"
