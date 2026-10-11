# HEIC to JPG

<img src="Resources/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" alt="HEIC to JPG app icon" width="128" height="128">

A small native macOS app for turning iPhone HEIC/HEIF photos into JPGs beside the originals. All conversion happens on your Mac using Apple ImageIO. No accounts, uploads, or third-party dependencies.

**macOS 13+ · Swift + SwiftUI · MIT license**

The source and Xcode project are prepared for their first release in [XiupengMa/HEIC_2_JPEG_MacOS](https://github.com/XiupengMa/HEIC_2_JPEG_MacOS). No downloadable signed release or App Store listing has been published yet.

## Use the app

1. Clone this repository and build with `bash scripts/build.sh` (Xcode or the Xcode Command Line Tools with Swift 5.9+ required).
2. Open `dist/HEIC to JPG.app`. For everyday use, drag the app into your Applications folder and open it once there.
3. Click **Choose photos…**, select one or more HEIC/HEIF files, and click **Convert to JPG**. You can also drag files onto the window or app icon.

In Finder, select photos and choose **Open With → HEIC to JPG** to convert immediately using the last quality and metadata settings. If it is not listed yet, choose **Open With → Other…** and select the app. There is no need to change the default app for HEIC files.

You can launch it directly with `open "dist/HEIC to JPG.app"` from this project. Once moved to Applications, launch it from Finder's Applications folder or search **HEIC to JPG** in Spotlight.

Use **Show in Finder** to select the resulting JPGs. **⌘O** opens the photo picker. Closing the window keeps conversions running; **⌘Q** quits. **Stop after current** skips waiting photos and lets the active conversion finish.

## Conversion behavior

- Saves `IMG_1234.HEIC` as `IMG_1234.jpg` in the same folder.
- Keeps originals and existing files. If a name is taken, uses `IMG_1234 (1).jpg`, `(2)`, etc. Filename reservation is atomic, including across simultaneous conversions.
- Keeps full pixel dimensions, orientation, and the decoded image’s color profile. JPG is lossy, including at Maximum quality.
- Defaults to High quality (90%). Good is 80%; Maximum is 100%. Settings apply to files added after the change.
- **Keep photo metadata** defaults to on. Copies supported EXIF, TIFF, GPS, and IPTC fields, including capture time and location when available. Turn it off to omit these fields; display orientation and color information remain.
- Exports the primary still photo. Live Photo videos, depth maps, bursts, and HEIF auxiliary images are not exported. On macOS 14+, decoding explicitly requests SDR output for standard JPEG sharing.
- Converts serially in the background to limit memory use. A failed file is reported individually; other files continue.
- Checks that the JPG decodes before saving the final filename, and cleans up temporary files on failure.
- Requires a writable source folder and locally readable photos. Export files from the Photos app first; this app does not browse or modify your Photos library. Download iCloud files before converting.

## Development

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

For occasional conversions without an app, Finder also has [Quick Actions → Convert Image](https://support.apple.com/guide/mac-help/mchl97ff9142/mac).

## Release and contribution

- [Contributing](CONTRIBUTING.md) — setup and change guidelines.
- [Release guide](docs/RELEASING.md) — open-source publication and release checks.
- [App Store preparation](docs/APP_STORE.md) — signing, listing draft, privacy answers, and remaining work.
- [Privacy policy](docs/PRIVACY.md) · [Security reporting](SECURITY.md) · [Changelog](CHANGELOG.md).
- [MIT license](LICENSE) covers the source and included project artwork.

GitHub Actions is configured to run the full Swift tests and build the standalone and Xcode variants on macOS; see the [latest checks](https://github.com/XiupengMa/HEIC_2_JPEG_MacOS/actions) after pushing. See [preparation validation](docs/VALIDATION.md) for local results and limitations. The preparation machine's Xcode needs its missing CoreSimulator/first-launch components installed before local Xcode project/archive validation can finish; the standalone Swift builds are usable now.
