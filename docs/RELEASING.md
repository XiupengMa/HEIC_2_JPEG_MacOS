# Releasing HEIC to JPG

Nothing in the build scripts uploads, publishes, creates a repository, or installs into Applications. Local output is under `dist/`. Keep publication as a separate deliberate step after review.

## Open-source publication

1. Choose the GitHub owner and repository name. Review the source, MIT license, artwork, and synthetic fixture. The repository contains no external runtime packages and does not need image-generation credentials.
2. Review the actual files to be committed. Exclude `.build`, `dist`, local signing configuration, app containers/bookmarks, credentials, and personal photos. The `.gitignore` covers generated builds and common signing files.
3. Create the public repository and push only after publication is authorized. Set a concise description, enable Issues and private vulnerability reporting, and add the final repository/support URLs to the documentation.
4. Let CI run before tagging a release. CI has read-only repository permissions, no signing secrets, and no automatic publishing step.
5. Host `docs/PRIVACY.md` at a stable public URL and provide a public support page/contact before App Store submission. Update `SECURITY.md` with the actual private reporting URL.

## Local validation

```sh
bash scripts/test.sh
bash scripts/build.sh
bash scripts/build.sh --sandbox
git diff --check
```

Run the complete codec suite outside a restricted command-execution sandbox. `HEIC_TEST_SKIP_SYSTEM_CODEC=1` explicitly skips seven tests and is only a limited diagnostic mode; never use that mode for release CI. See [VALIDATION.md](VALIDATION.md) for the checks performed during preparation and their limits.

After Xcode's required components are installed:

```sh
xcodebuild -project HEICToJPG.xcodeproj -scheme "HEIC to JPG" \
  -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath .build/xcode-local CODE_SIGNING_ALLOWED=NO build
xcodebuild -project HEICToJPG.xcodeproj -scheme "HEIC to JPG App Store" \
  -configuration AppStore -destination 'generic/platform=macOS' \
  -derivedDataPath .build/xcode-store CODE_SIGNING_ALLOWED=NO build
```

These unsigned checks validate compilation/resources only. Use your real developer team for a signed archive and distribution validation. Both release configurations use the standard Mac architectures; confirm the archived executable includes the architectures you intend to support.

## Manual release scenarios

- Open one HEIC, select several files, drag files onto the window/Dock icon, and use Finder Open With both when the app is already running and from a cold launch.
- Convert real iPhone portrait, mirrored, landscape, HDR, and large-resolution images. Compare displayed orientation/color and dimensions. The synthetic suite covers all eight EXIF orientations, but is not a replacement for device-image checks.
- Verify metadata preservation and removal, including GPS and capture dates. Verify all quality options.
- Repeat conversion and use existing JPG names, directories, and dangling symlinks as collision cases. Preserve originals and all previous outputs.
- Include an unreadable, corrupt, unsupported, or not-yet-downloaded file among valid photos. Verify failures are individual and leave no partial JPG.
- Add files while converting, stop a long queue, close/reopen the window, and quit while a conversion is active.
- In the sandbox preview, grant the exact containing folder, repeat conversion, quit/relaunch, and repeat again without a folder prompt.
- Try selecting the wrong folder: it must be rejected. Cancel permission for a batch: that folder's photos should be skipped without repeated prompts. Other authorized folders should continue.
- Forget saved folder access, then confirm the next conversion requests it again. Try a renamed/moved folder and an external drive; stale or unavailable bookmarks should fall back to asking again.
- Check Finder reveal, keyboard navigation, VoiceOver labels, dark mode, and the smallest window size. Check the new icon in Finder and the Dock.

## Release packaging

Update `Configuration/Version.xcconfig` and `CHANGELOG.md` for each release. Generate icons only when artwork changes with `bash scripts/generate-icons.sh`, then commit the complete catalog and ICNS alongside the master.

For the Mac App Store, follow [APP_STORE.md](APP_STORE.md). A successful local build is not an App Review approval. Final screenshots, account/team settings, the App Store record, policy/support hosting, archive validation, and review are still required.

For a downloadable release outside the store, use a Developer ID-signed, notarized build and staple the notarization ticket before packaging. The default build script's ad-hoc signature is for the machine where it was built; do not advertise it as a notarized download. Keep signing and publishing out of pull-request CI.
