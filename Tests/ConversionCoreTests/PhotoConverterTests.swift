import XCTest
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
@testable import ConversionCore

final class PhotoConverterTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("HEICToJPGTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws { try FileManager.default.removeItem(at: directory) }

    func testProducesFullResolutionJPEGAndLeavesOriginalUntouched() throws {
        let input = try fixture(name: "Holiday photo.HEIC")
        let original = try Data(contentsOf: input)
        let result = try PhotoConverter.convert(input)
        XCTAssertEqual(result.outputURL, directory.appendingPathComponent("Holiday photo.jpg"))
        XCTAssertEqual(try Data(contentsOf: input), original)
        let output = try XCTUnwrap(CGImageSourceCreateWithURL(result.outputURL as CFURL, nil))
        XCTAssertEqual(CGImageSourceGetType(output) as String?, UTType.jpeg.identifier)
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(output, 0, nil))
        XCTAssertEqual(image.width, 64)
        XCTAssertEqual(image.height, 48)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path).count, 2)
    }

    func testExistingFilesAndFoldersAreNeverOverwritten() throws {
        let input = try fixture()
        let sentinel = Data("existing JPG".utf8)
        try sentinel.write(to: directory.appendingPathComponent("photo.jpg"))
        try FileManager.default.createDirectory(at: directory.appendingPathComponent("photo (1).jpg"), withIntermediateDirectories: false)
        try FileManager.default.createSymbolicLink(atPath: directory.appendingPathComponent("photo (2).jpg").path,
                                                   withDestinationPath: directory.appendingPathComponent("missing.jpg").path)
        let result = try PhotoConverter.convert(input)
        XCTAssertEqual(result.outputURL.lastPathComponent, "photo (3).jpg")
        XCTAssertEqual(try Data(contentsOf: directory.appendingPathComponent("photo.jpg")), sentinel)
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("photo (1).jpg").path))
        XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: directory.appendingPathComponent("photo (2).jpg").path), directory.appendingPathComponent("missing.jpg").path)
    }

    func testConcurrentConversionsUseDifferentNames() async throws {
        let input = try fixture()
        let outputs = try await withThrowingTaskGroup(of: URL.self) { group in
            for _ in 0..<4 { group.addTask { try PhotoConverter.convert(input).outputURL } }
            var urls: [URL] = []
            for try await url in group { urls.append(url) }
            return urls
        }
        XCTAssertEqual(Set(outputs).count, 4)
        for url in outputs { XCTAssertNotNil(CGImageSourceCreateWithURL(url as CFURL, nil)) }
    }

    func testMetadataIsPreservedByDefault() throws {
        let input = try fixture()
        let result = try PhotoConverter.convert(input)
        let props = try properties(result.outputURL)
        let gps = try XCTUnwrap(props[kCGImagePropertyGPSDictionary as String] as? [String: Any])
        XCTAssertEqual(gps[kCGImagePropertyGPSLatitude as String] as? Double, 37.5)
        let exif = try XCTUnwrap(props[kCGImagePropertyExifDictionary as String] as? [String: Any])
        XCTAssertEqual(exif[kCGImagePropertyExifDateTimeOriginal as String] as? String, "2026:10:10 12:34:56")
    }

    func testMetadataCanBeRemovedWithoutLosingOrientation() throws {
        let input = try fixture(orientation: 6)
        let result = try PhotoConverter.convert(input, options: .init(preserveMetadata: false))
        let props = try properties(result.outputURL)
        XCTAssertNil(props[kCGImagePropertyGPSDictionary as String])
        let exif = props[kCGImagePropertyExifDictionary as String] as? [String: Any]
        XCTAssertNil(exif?[kCGImagePropertyExifDateTimeOriginal as String])
        let tiff = props[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        XCTAssertNil(tiff?[kCGImagePropertyTIFFMake as String])
        XCTAssertEqual(props[kCGImagePropertyOrientation as String] as? Int,
                       try properties(input)[kCGImagePropertyOrientation as String] as? Int)
    }

    func testAllEXIFOrientationsKeepDisplayedDimensions() throws {
        for orientation in 1...8 {
            let input = try fixture(name: "rotation-\(orientation).heic", orientation: orientation)
            let result = try PhotoConverter.convert(input)
            let original = try displayedImage(input)
            let converted = try displayedImage(result.outputURL)
            XCTAssertEqual(converted.width, original.width, "Orientation \(orientation)")
            XCTAssertEqual(converted.height, original.height, "Orientation \(orientation)")
            // Compare displayed pixels, so a mirrored or rotated image cannot pass on size alone.
            let before = pixels(original)
            let after = pixels(converted)
            let averageDifference = zip(before, after).reduce(0.0) { $0 + abs(Double($1.0) - Double($1.1)) } / Double(before.count)
            XCTAssertLessThan(averageDifference, 12, "Orientation \(orientation)")
        }
    }

    func testRejectsCorruptUnsupportedAndMissingFilesWithoutOutput() throws {
        let corrupt = directory.appendingPathComponent("broken.heic")
        try Data("not a photo".utf8).write(to: corrupt)
        XCTAssertThrowsError(try PhotoConverter.convert(corrupt))
        XCTAssertThrowsError(try PhotoConverter.convert(directory.appendingPathComponent("missing.heic")))
        let jpeg = directory.appendingPathComponent("photo.jpg")
        try Data("existing".utf8).write(to: jpeg)
        XCTAssertThrowsError(try PhotoConverter.convert(jpeg))
        let folder = directory.appendingPathComponent("folder.heic", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
        XCTAssertThrowsError(try PhotoConverter.convert(folder))
        XCTAssertEqual(Set(try FileManager.default.contentsOfDirectory(atPath: directory.path)), ["broken.heic", "photo.jpg", "folder.heic"])
    }

    func testHEIFExtensionAndUnicodeFilename() throws {
        let input = try fixture(name: "旅行 🏖️.heif")
        XCTAssertEqual(try PhotoConverter.convert(input).outputURL.lastPathComponent, "旅行 🏖️.jpg")
    }

    func testUnavailableImageServicesDoNotPublishIncompleteJPEG() throws {
        guard ProcessInfo.processInfo.environment["HEIC_TEST_SKIP_SYSTEM_CODEC"] == "1" else {
            throw XCTSkip("This regression check is for restricted environments with unavailable image services.")
        }
        let input = try fixture(skipSystemCodecCheck: true)
        XCTAssertThrowsError(try PhotoConverter.convert(input))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), ["photo.heic"])
    }

    private func fixture(name: String = "photo.heic", orientation: Int = 1, skipSystemCodecCheck: Bool = false) throws -> URL {
        if !skipSystemCodecCheck && ProcessInfo.processInfo.environment["HEIC_TEST_SKIP_SYSTEM_CODEC"] == "1" {
            throw XCTSkip("System codec tests explicitly disabled for this restricted environment. Run without HEIC_TEST_SKIP_SYSTEM_CODEC on a normal Mac for full coverage.")
        }
        // Use an original software-encoded fixture: Apple's HEIC encoder requires
        // hardware services that are unavailable in some CI/sandbox environments.
        let fixtureURL = try XCTUnwrap(Bundle.module.url(forResource: "photo", withExtension: "heic", subdirectory: "Fixtures"))
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(fixtureURL as CFURL, nil))
        let url = directory.appendingPathComponent(name)
        let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(url as CFURL, UTType.heic.identifier as CFString, 1, nil))
        let metadata = CGImageMetadataCreateMutable()
        XCTAssertTrue(CGImageMetadataSetValueMatchingImageProperty(metadata, kCGImagePropertyExifDictionary,
                      kCGImagePropertyExifDateTimeOriginal, "2026-10-10T12:34:56" as CFString))
        XCTAssertTrue(CGImageMetadataSetValueMatchingImageProperty(metadata, kCGImagePropertyTIFFDictionary,
                      kCGImagePropertyTIFFMake, "Test Camera" as CFString))
        XCTAssertTrue(CGImageMetadataSetValueMatchingImageProperty(metadata, kCGImagePropertyGPSDictionary,
                      kCGImagePropertyGPSLatitude, "37,30.0N" as CFString))
        XCTAssertTrue(CGImageMetadataSetValueMatchingImageProperty(metadata, kCGImagePropertyTIFFDictionary,
                      kCGImagePropertyTIFFOrientation, orientation as CFNumber))
        var error: Unmanaged<CFError>?
        guard CGImageDestinationCopyImageSource(destination, source, [kCGImageDestinationMetadata: metadata] as CFDictionary, &error) else {
            if let error { throw error.takeRetainedValue() }
            throw ConversionError.cannotEncode
        }
        return url
    }

    private func properties(_ url: URL) throws -> [String: Any] {
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
        return try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, CGImageSourceGetPrimaryImageIndex(source), nil) as? [String: Any])
    }

    private func displayedImage(_ url: URL) throws -> CGImage {
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
        return try XCTUnwrap(CGImageSourceCreateThumbnailAtIndex(source, CGImageSourceGetPrimaryImageIndex(source), [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 64
        ] as CFDictionary))
    }

    private func pixels(_ image: CGImage) -> [UInt8] {
        let context = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8,
                                bytesPerRow: image.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return Array(UnsafeBufferPointer(start: context.data!.assumingMemoryBound(to: UInt8.self), count: image.width * image.height * 4))
    }
}
