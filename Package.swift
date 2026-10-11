// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HEICToJPG",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "HEICToJPG", targets: ["HEICToJPG"]),
        .library(name: "ConversionCore", targets: ["ConversionCore"])
    ],
    targets: [
        .target(name: "ConversionCore"),
        .executableTarget(name: "HEICToJPG", dependencies: ["ConversionCore"]),
        .testTarget(name: "ConversionCoreTests", dependencies: ["ConversionCore"], resources: [.copy("Fixtures")])
    ]
)

