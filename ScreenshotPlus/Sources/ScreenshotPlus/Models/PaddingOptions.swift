import Foundation
import SwiftUI

struct GradientBackground: Equatable {
    var startColor: Color = .purple
    var endColor: Color = .blue
    var angle: Double = 45 // degrees
}

struct ShadowOptions: Equatable {
    var enabled: Bool = true
    var radius: CGFloat = 20
    var opacity: CGFloat = 0.3
    var offsetY: CGFloat = 10
}

struct PaddingOptions: Equatable {
    var enabled: Bool = false
    var amount: CGFloat = 40
    var cornerRadius: CGFloat = 12
    var gradient: GradientBackground = GradientBackground()
    var shadow: ShadowOptions = ShadowOptions()
}
