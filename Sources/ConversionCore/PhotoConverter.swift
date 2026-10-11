import Foundation
import ImageIO
import UniformTypeIdentifiers
import Darwin

public struct ConversionOptions: Sendable {
    public let quality: Double
    public let preserveMetadata: Bool

    public init(quality: Double = 0.9, preserveMetadata: Bool = true) {
        self.quality = quality.isFinite ? min(1, max(0, quality)) : 0.9
        self.preserveMetadata = preserveMetadata
    }
}

public struct ConversionResult: Sendable {
    public let sourceURL: URL
    public let outputURL: URL
}

public enum ConversionError: LocalizedError {
    case unsupportedFile
    case unreadableImage
    case cannotEncode

    public var errorDescription: String? {
        switch self {
        case .unsupportedFile: return "Choose a HEIC or HEIF photo."
        case .unreadableImage: return "This photo could not be read. It may be damaged or not downloaded yet."
        case .cannotEncode: return "The JPG could not be created. Check the folder’s permissions and available disk space."
        }
    }
}

public enum PhotoConverter {
    public static let supportedExtensions: Set<String> = ["heic", "heif"]

    /// Converts the primary still image, preserving the original file and pixel dimensions.
    /// The final filename is claimed atomically so simultaneous conversions never overwrite.
    public static func convert(_ input: URL, options: ConversionOptions = .init()) throws -> ConversionResult {
        try autoreleasepool {
            let sourceURL = input.standardizedFileURL
            guard sourceURL.isFileURL,
                  supportedExtensions.contains(sourceURL.pathExtension.lowercased()) else {
                throw ConversionError.unsupportedFile
            }
            let values = try sourceURL.resourceValues(forKeys: [.isRegularFileKey])
            guard values.isRegularFile == true else { throw ConversionError.unsupportedFile }

            guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
                  let identifier = CGImageSourceGetType(source) as String?,
                  let type = UTType(identifier),
                  type.conforms(to: .heic) || type.conforms(to: .heif) else {
                throw ConversionError.unreadableImage
            }

            let index = CGImageSourceGetPrimaryImageIndex(source)
            var decodeOptions: [CFString: Any] = [
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceShouldAllowFloat: false
            ]
            if #available(macOS 14, *) {
                decodeOptions[kCGImageSourceDecodeRequest] = kCGImageSourceDecodeToSDR
            }
            guard let image = CGImageSourceCreateImageAtIndex(source, index, decodeOptions as CFDictionary) else {
                throw ConversionError.unreadableImage
            }

            let originalProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any] ?? [:]
            var properties: [String: Any] = [:]
            if options.preserveMetadata {
                // Only copy metadata supported by JPEG, not HEIF container/auxiliary-image properties.
                for key in [kCGImagePropertyExifDictionary, kCGImagePropertyExifAuxDictionary,
                            kCGImagePropertyTIFFDictionary, kCGImagePropertyGPSDictionary,
                            kCGImagePropertyIPTCDictionary, kCGImagePropertyDPIWidth, kCGImagePropertyDPIHeight] {
                    properties[key as String] = originalProperties[key as String]
                }
            }
            // Keep orientation even when removing personal metadata. Color comes from the decoded image.
            properties[kCGImagePropertyOrientation as String] = originalProperties[kCGImagePropertyOrientation as String]
            properties[kCGImageDestinationLossyCompressionQuality as String] = options.quality

            let folder = sourceURL.deletingLastPathComponent()
            let temporaryFolder = folder.appendingPathComponent(".heic-to-jpg-\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: temporaryFolder, withIntermediateDirectories: false)
            defer { try? FileManager.default.removeItem(at: temporaryFolder) }
            let temporaryURL = temporaryFolder.appendingPathComponent("photo.jpg")
            guard let destination = CGImageDestinationCreateWithURL(temporaryURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
                throw ConversionError.cannotEncode
            }
            CGImageDestinationAddImage(destination, image, properties as CFDictionary)
            guard CGImageDestinationFinalize(destination) else { throw ConversionError.cannotEncode }

            // Some unavailable image services report successful encoding but only
            // write a JPEG header. Verify a decodable image before publishing it.
            guard let check = CGImageSourceCreateWithURL(temporaryURL as CFURL, nil),
                  let checkProperties = CGImageSourceCopyPropertiesAtIndex(check, 0, nil) as? [String: Any],
                  checkProperties[kCGImagePropertyPixelWidth as String] as? Int == image.width,
                  checkProperties[kCGImagePropertyPixelHeight as String] as? Int == image.height,
                  CGImageSourceCreateThumbnailAtIndex(check, 0, [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceThumbnailMaxPixelSize: 1
                  ] as CFDictionary) != nil,
                  CGImageSourceGetStatusAtIndex(check, 0) == .statusComplete else {
                throw ConversionError.cannotEncode
            }

            let stem = sourceURL.deletingPathExtension().lastPathComponent
            var suffix = 0
            while true {
                let name = suffix == 0 ? "\(stem).jpg" : "\(stem) (\(suffix)).jpg"
                let outputURL = folder.appendingPathComponent(name)
                // RENAME_EXCL handles files, directories, and even dangling symlinks at the target.
                let status = temporaryURL.withUnsafeFileSystemRepresentation { temporaryPath in
                    outputURL.withUnsafeFileSystemRepresentation { outputPath in
                        renameatx_np(AT_FDCWD, temporaryPath!, AT_FDCWD, outputPath!, UInt32(RENAME_EXCL))
                    }
                }
                if status == 0 { return ConversionResult(sourceURL: sourceURL, outputURL: outputURL) }
                let code = errno
                if code == EEXIST { suffix += 1; continue }
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(code), userInfo: [NSFilePathErrorKey: outputURL.path])
            }
        }
    }
}

