# Preparation validation

Checked on an Apple-silicon Mac running macOS 26.6.2 with Swift 6.2.3 on October 10, 2026. These results describe local preparation, not a store validation or public CI run.

## Passed

- Release compilation of the local application and the `APP_STORE` sandbox preview using the standalone Swift build scripts.
- Strict ad-hoc code-signature verification for both bundles. The preview contains only App Sandbox, user-selected read/write, and app-scoped bookmark entitlements.
- Bundle property-list parsing, substitution of version/identifier/executable settings, and inclusion of the privacy manifest.
- Xcode project property-list syntax, object references, app-source membership, resource paths, and both shared scheme references.
- All ten icon catalog sizes, including 1024 × 1024, with RGBA transparency preserved at the corners.
- Native GUI conversion of a synthetic HEIC using the sandbox preview after selecting its containing folder; the resulting JPG was decoded independently to verify dimensions and orientation.
- Quit/relaunch of the preview followed by conversion in the same folder without repeating the folder-permission prompt.
- Forget Saved Folder Access causing the next conversion to request the folder again.
- Canceling one folder prompt skipping all nine waiting files from that folder without repeated prompts or new JPG output.
- Shell syntax checks for the build/test/icon scripts and a clean whitespace check.

Earlier native GUI checks of the same conversion core verified all eight EXIF orientations by comparing decoded pixels, metadata preservation/removal, numbered filename collisions, mixed good/corrupt batches, and Finder Open With.

## Limited or outstanding

- The restricted command-execution environment cannot reliably access macOS image services. The explicit diagnostic run `HEIC_TEST_SKIP_SYSTEM_CODEC=1 bash scripts/test.sh` passed two error/cleanup tests and skipped seven codec tests. A complete ordinary Terminal/CI test run is still required before release.
- `xcodebuild -list` could not start because this Xcode installation is missing `/Library/Developer/PrivateFrameworks/CoreSimulator.framework`. Xcode's required components/first-launch setup must be completed before validating either native Xcode build or an archive. Project syntax/reference checks do not prove an Xcode build succeeds.
- GitHub CI is configured but has not run; no repository has been published.
- Developer-team signing, universal archive validation, TestFlight, App Store Connect privacy validation, final marketing screenshots, hosted policy/support pages, and App Review are pending.
- Real-device HDR/large-photo coverage, external-drive/moved-folder bookmark recovery, wrong-folder rejection, and the complete accessibility/release checklist remain release checks in [RELEASING.md](RELEASING.md).
