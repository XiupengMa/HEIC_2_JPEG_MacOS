# Development

Requires macOS 13 or later. The build script produces an app for the current Mac’s architecture and signs it ad hoc for local use. Distribution to other Macs would need appropriate signing/notarization and architecture builds.

```sh
bash scripts/test.sh
bash scripts/build.sh
open "dist/HEIC to JPG.app"
```

Open **`HEICToJPG.xcodeproj`** to run and archive the application in Xcode. It has shared **HEIC to JPG** (local) and **HEIC to JPG App Store** (sandboxed) schemes. App Store signing is deliberately unconfigured until a developer team and final bundle ID are available. `Configuration/Version.xcconfig` is the version/build-number source for both build methods.

Open `Package.swift` to work with the converter library and its XCTest suite. The application schemes do not contain XCTest targets; use the package or `scripts/test.sh`. `swift run` alone does not assemble the bundle or provide Finder integration.

To test the sandbox without a paid account:

```sh
bash scripts/build.sh --sandbox
open "dist/HEIC to JPG Sandbox.app"
```

The sandbox preview has its own identifier and preferences. It requests the containing folder before saving JPGs and remembers access between launches. Use **HEIC to JPG → Forget Saved Folder Access** to reset it. This is an ad-hoc local preview, not an App Store upload. Use the ordinary app for everyday conversions.

- `Sources/ConversionCore`: image decoding, metadata handling, JPEG encoding, safe file creation.
- `Sources/HEICToJPG`: native SwiftUI interface, conversion queue, AppKit file-open events.
- `Resources/Info.plist`: app identity and HEIC/HEIF Open With support.
- `Resources/Artwork`: new icon master and generation prompt/provenance.
- `Resources/Assets.xcassets`: complete macOS app icon catalog.
- `Resources/PrivacyInfo.xcprivacy`: privacy manifest for app-owned settings.
- `Configuration`: local and App Store build settings; keep signing choices in ignored `Local.xcconfig`.
- `Tests/ConversionCoreTests`: actual HEIC/JPEG round trips, all eight orientations, metadata, errors, Unicode names, and concurrent filename collisions.

The tests include a small synthetic HEIC fixture. Run the test suite from a normal macOS Terminal session for full codec coverage. Some restricted execution environments cannot reliably access macOS image services. In that environment only, `HEIC_TEST_SKIP_SYSTEM_CODEC=1 bash scripts/test.sh` explicitly skips the seven codec tests and runs error/cleanup checks, including rejection of incomplete JPEG output. This limited run does not replace the full suite. To regenerate the fixture only, `python3 scripts/generate-test-fixture.py` requires ffmpeg with libx265.

For local verification results and limitations, see [VALIDATION.md](VALIDATION.md). For release checks and packaging, see [RELEASING.md](RELEASING.md) and [APP_STORE.md](APP_STORE.md).

[Back to the README](../README.md)
