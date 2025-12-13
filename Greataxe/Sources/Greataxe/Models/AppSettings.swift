import Foundation
import SwiftUI

/// Centralized application settings with Codable persistence.
struct AppSettings: Codable {
    // MARK: - Stroke settings
    var strokeColorR: Double = 1.0
    var strokeColorG: Double = 0.0
    var strokeColorB: Double = 0.0
    var strokeWidth: CGFloat = 2.0
    var fillShapes: Bool = false

    // MARK: - Tool settings
    var currentToolRaw: String = DrawingTool.rectangle.rawValue
    var showPaddingPanel: Bool = false

    // MARK: - Text settings
    var textAlignmentRaw: String = TextAlignment.left.rawValue
    var textFontSize: CGFloat = 16.0
    var textFontName: String = "SF Pro"

    // MARK: - Text background
    var textBackgroundEnabled: Bool = false
    var textBackgroundR: Double = 0.0
    var textBackgroundG: Double = 0.0
    var textBackgroundB: Double = 0.0
    var textBackgroundA: Double = 1.0
    var textBackgroundPaddingTop: CGFloat = 8.0
    var textBackgroundPaddingRight: CGFloat = 8.0
    var textBackgroundPaddingBottom: CGFloat = 8.0
    var textBackgroundPaddingLeft: CGFloat = 8.0
    var textBackgroundCornerRadius: CGFloat = 4.0

    // MARK: - Padding options
    var paddingEnabled: Bool = false
    var paddingAmount: CGFloat = 20.0
    var paddingCornerRadius: CGFloat = 0.0

    // MARK: - Gradient
    var gradientStartR: Double = 0.2
    var gradientStartG: Double = 0.2
    var gradientStartB: Double = 0.2
    var gradientEndR: Double = 0.4
    var gradientEndG: Double = 0.4
    var gradientEndB: Double = 0.4
    var gradientAngle: Double = 0.0

    // MARK: - Shadow
    var shadowEnabled: Bool = false
    var shadowRadius: CGFloat = 10.0
    var shadowOpacity: CGFloat = 0.3
    var shadowOffsetY: CGFloat = 5.0

    // MARK: - Persistence

    private static let settingsKey = "AppSettings"

    func save(to defaults: UserDefaults = .standard) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        defaults.set(data, forKey: Self.settingsKey)
    }

    static func load(from defaults: UserDefaults = .standard) throws -> AppSettings {
        guard let data = defaults.data(forKey: settingsKey) else {
            return AppSettings()
        }
        let decoder = JSONDecoder()
        return try decoder.decode(AppSettings.self, from: data)
    }
}

// MARK: - Enum convenience

extension AppSettings {
    var currentTool: DrawingTool {
        get { DrawingTool(rawValue: currentToolRaw) ?? .rectangle }
        set { currentToolRaw = newValue.rawValue }
    }

    var textAlignment: TextAlignment {
        get { TextAlignment(rawValue: textAlignmentRaw) ?? .left }
        set { textAlignmentRaw = newValue.rawValue }
    }
}

// MARK: - Color convenience

extension AppSettings {
    var strokeColor: Color {
        get { Color(red: strokeColorR, green: strokeColorG, blue: strokeColorB) }
        set {
            if let nsColor = NSColor(newValue).usingColorSpace(.deviceRGB) {
                strokeColorR = Double(nsColor.redComponent)
                strokeColorG = Double(nsColor.greenComponent)
                strokeColorB = Double(nsColor.blueComponent)
            }
        }
    }

    var textBackgroundColor: Color? {
        get {
            guard textBackgroundEnabled else { return nil }
            return Color(red: textBackgroundR, green: textBackgroundG, blue: textBackgroundB, opacity: textBackgroundA)
        }
        set {
            if let color = newValue, let nsColor = NSColor(color).usingColorSpace(.deviceRGB) {
                textBackgroundEnabled = true
                textBackgroundR = Double(nsColor.redComponent)
                textBackgroundG = Double(nsColor.greenComponent)
                textBackgroundB = Double(nsColor.blueComponent)
                textBackgroundA = Double(nsColor.alphaComponent)
            } else {
                textBackgroundEnabled = false
            }
        }
    }

    var gradientStartColor: Color {
        get { Color(red: gradientStartR, green: gradientStartG, blue: gradientStartB) }
        set {
            if let nsColor = NSColor(newValue).usingColorSpace(.deviceRGB) {
                gradientStartR = Double(nsColor.redComponent)
                gradientStartG = Double(nsColor.greenComponent)
                gradientStartB = Double(nsColor.blueComponent)
            }
        }
    }

    var gradientEndColor: Color {
        get { Color(red: gradientEndR, green: gradientEndG, blue: gradientEndB) }
        set {
            if let nsColor = NSColor(newValue).usingColorSpace(.deviceRGB) {
                gradientEndR = Double(nsColor.redComponent)
                gradientEndG = Double(nsColor.greenComponent)
                gradientEndB = Double(nsColor.blueComponent)
            }
        }
    }
}
