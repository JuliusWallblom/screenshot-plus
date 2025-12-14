import AppKit

struct TextMeasurementService {
    func font(name: String, size: CGFloat) -> NSFont {
        if name == "System" {
            return NSFont.systemFont(ofSize: size, weight: .medium)
        } else {
            return NSFont(name: name, size: size)
                ?? NSFont.systemFont(ofSize: size, weight: .medium)
        }
    }

    func measureText(_ text: String, font: NSFont) -> CGSize {
        let displayText = text.isEmpty ? "|" : text
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let lines = displayText.components(separatedBy: "\n")
        let lineHeight = font.ascender - font.descender + font.leading
        let height = lineHeight * CGFloat(max(lines.count, 1))
        let maxWidth = lines.map { ($0 as NSString).size(withAttributes: attributes).width }.max() ?? 10
        return CGSize(width: max(maxWidth, 10), height: height)
    }
}
