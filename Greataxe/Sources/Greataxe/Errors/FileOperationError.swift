import Foundation

/// Errors that can occur during image export operations.
enum ExportError: LocalizedError {
    case renderFailed
    case imageConversionFailed
    case writeFailed(Error)
    case clipboardFailed

    var errorDescription: String? {
        switch self {
        case .renderFailed:
            return "Failed to render image with annotations"
        case .imageConversionFailed:
            return "Failed to convert image to PNG format"
        case .writeFailed(let underlying):
            return "Failed to save image: \(underlying.localizedDescription)"
        case .clipboardFailed:
            return "Failed to copy image to clipboard"
        }
    }
}

/// Errors that can occur during file operations.
enum FileError: LocalizedError {
    case notFound(URL)
    case permissionDenied(URL)
    case readFailed(Error)
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .notFound(let url):
            return "File not found: \(url.lastPathComponent)"
        case .permissionDenied(let url):
            return "Permission denied: \(url.lastPathComponent)"
        case .readFailed(let underlying):
            return "Failed to read file: \(underlying.localizedDescription)"
        case .invalidFormat:
            return "Invalid file format"
        }
    }
}
