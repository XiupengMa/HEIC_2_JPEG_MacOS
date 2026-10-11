import AppKit

guard CommandLine.arguments.count == 5,
      let image = NSImage(contentsOfFile: CommandLine.arguments[1]) else {
    fatalError("Usage: swift make-icon.swift master.png output.iconset output.icns AppIcon.appiconset")
}
let iconset = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
let catalog = URL(fileURLWithPath: CommandLine.arguments[4], isDirectory: true)
for url in [iconset, catalog] { try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true) }

func render(size: Int) -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                  isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size), from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}

var images: [[String: String]] = []
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let filename = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        let png = render(size: size * scale)
        try png.write(to: iconset.appendingPathComponent(filename))
        try png.write(to: catalog.appendingPathComponent(filename))
        images.append(["filename": filename, "idiom": "mac", "scale": "\(scale)x", "size": "\(size)x\(size)"])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: catalog.appendingPathComponent("Contents.json"))

// Modern ICNS representations are PNG chunks. Direct packaging also works in
// build environments where iconutil's image-conversion services are unavailable.
func uint32(_ value: Int) -> Data {
    var number = UInt32(value).bigEndian
    return withUnsafeBytes(of: &number) { Data($0) }
}
var chunks = Data()
for (type, size) in [("icp4", 16), ("icp5", 32), ("icp6", 64), ("ic07", 128),
                     ("ic08", 256), ("ic09", 512), ("ic10", 1024),
                     ("ic11", 32), ("ic12", 64), ("ic13", 256), ("ic14", 512)] {
    let png = render(size: size)
    chunks.append(Data(type.utf8))
    chunks.append(uint32(png.count + 8))
    chunks.append(png)
}
var icns = Data("icns".utf8)
icns.append(uint32(chunks.count + 8))
icns.append(chunks)
try icns.write(to: URL(fileURLWithPath: CommandLine.arguments[3]))
