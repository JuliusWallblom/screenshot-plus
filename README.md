# ScreenshotPlus

A native macOS screenshot annotation tool. When you take a screenshot, ScreenshotPlus opens it in an annotation window where you can draw shapes, add text, and export the result.

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15+ or Swift 5.9+ toolchain

## Building

```bash
swift build
```

To run:
```bash
swift run
```

## Running Tests

```bash
swift test
```

## Features

- **Screenshot Monitoring** - Automatically detects new screenshots in the configured directory
- **Drawing Tools** - Rectangle, oval, line, arrow, freehand pen
- **Text Annotations** - Add text labels to screenshots
- **Crop Tool** - Trim screenshots to a selected region
- **Color & Stroke** - Customizable stroke width and color picker
- **Undo/Redo** - Full undo/redo support for all annotations
- **Export** - Copy annotated image to clipboard or save to file
- **Menu Bar** - Runs as a menu bar application

## Architecture

The app is built with SwiftUI and uses Swift Package Manager:

```
├── Sources/ScreenshotPlus/
│   ├── App/                       # App entry point
│   ├── Views/                     # SwiftUI views
│   ├── Models/                    # Data models
│   ├── Services/                  # Business logic
│   ├── Controllers/               # View controllers
│   └── Utilities/                 # Helper utilities
└── Tests/ScreenshotPlusTests/
    └── ...                        # Unit tests
```

## License

MIT
