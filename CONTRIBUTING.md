# Contributing

HEIC to JPG is a small native macOS utility. Contributions should keep the path from selecting a photo to finding its JPG short and predictable.

## Set up

- macOS 13 or newer; Swift 5.9 or newer. Full Xcode is required for the Xcode project; Command Line Tools can build the standalone app.
- Run `bash scripts/test.sh`, then `bash scripts/build.sh`.
- Open `HEICToJPG.xcodeproj` for the application or `Package.swift` for the converter library and its XCTest suite. Application schemes do not contain XCTest targets; run the package tests or the test script.
- No external Swift packages, services, API keys, or paid developer membership are required for the local build.

## Before sending a change

1. Explain the behavior being changed and provide a reproducible example.
2. Add a focused regression test for changes to image conversion or file safety. Never weaken a test just to accommodate an unavailable codec.
3. Run the test suite in a normal Terminal session. A run with `HEIC_TEST_SKIP_SYSTEM_CODEC=1` is explicitly incomplete and must be reported as such.
4. Build both `bash scripts/build.sh` and `bash scripts/build.sh --sandbox` after changing file access or the UI. Use the manual scenarios in [the release guide](docs/RELEASING.md).
5. Confirm `git diff --check` is clean. Keep generated app bundles, test output, signing identities, and personal photos out of commits.

Swift source uses four-space indentation, native frameworks, descriptive names, and short functions. Keep image work off the main actor. Balance every successful security-scope start with a stop, and preserve originals on every failure path.

For icon changes, replace `Resources/Artwork/AppIcon-master.png`, run `bash scripts/generate-icons.sh`, and include the resulting catalog/ICNS files and artwork provenance.

Contributions are made under the [MIT license](LICENSE). Please use synthetic or freely redistributable test images; remove location data and other personal metadata from attachments.
