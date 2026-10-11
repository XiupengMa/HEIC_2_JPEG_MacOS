# App Store preparation

This is a prepared project, not an approved or uploaded App Store release. Enrollment, final signing, archive validation, screenshots, public support/privacy URLs, and submission remain outstanding.

## Project choices

| Item | Prepared value |
| --- | --- |
| App name | HEIC to JPG |
| Category | Photography |
| Minimum system | macOS 13 |
| Version / build | `Configuration/Version.xcconfig` |
| Proposed bundle ID | `com.matthewma.heic-to-jpg` — confirm or replace before registering |
| Scheme | HEIC to JPG App Store |
| Configuration | AppStore |
| Sandbox | User-selected read/write files and app-scoped bookmarks |
| Hardened runtime | Enabled |
| Icon | Complete macOS asset catalog, including 1024 × 1024 |
| Dependencies | Apple frameworks and the local ConversionCore package |

The App Store build asks you to select the containing folder before creating sibling JPGs. It remembers a security-scoped bookmark and balances access during each conversion. Declining skips that folder's waiting photos for the batch; it does not silently save them somewhere else. The nonsandboxed local build retains the immediate workflow.

Apple requires appropriate sandboxing for Mac App Store apps. See [App Review Guidelines, 2.4.5](https://developer.apple.com/app-store/review/guidelines/#hardware-compatibility) and [Enabling App Sandbox](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html).

## When your developer account is ready

1. Finish Xcode's first-launch setup and install any required components. The development Mac currently reports a missing CoreSimulator framework when running xcodebuild; that prevents project/archive validation even though the standalone Swift builds work.
2. Add the Apple ID to Xcode, select the enrolled team, and register the final bundle ID.
3. Copy `Configuration/Local.xcconfig.example` to `Configuration/Local.xcconfig` and set the team and bundle ID. This file is ignored by Git. Use Xcode's automatic signing for the AppStore configuration.
4. Run the sandbox scheme and complete the permission/relaunch checks in [RELEASING.md](RELEASING.md), including a real iPhone photo and an external drive. Build for both supported architectures, and test on real hardware where available.
5. Choose **Product → Archive** with **HEIC to JPG App Store**. Validate the archive in Organizer, review its privacy report, and use **Distribute App → App Store Connect** after the App Store record is created.
6. Supply the final listing, support contact, hosted privacy-policy URL, pricing/availability, age-rating questionnaire, screenshots, and review contact details. Use TestFlight before public submission.

Do not commit certificates, provisioning profiles, credentials, or team-local configuration. The ad-hoc sandbox preview produced by `build.sh --sandbox` has a separate bundle ID and is for local testing; it is not an uploadable App Store binary.

See Apple's current [distribution preparation guide](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution) before archiving, because submission requirements may change.

## Draft listing

**Name:** HEIC to JPG

**Subtitle:** Quick, private photo copies

**Promotional text:** Turn your iPhone photos into shareable JPGs, right beside the originals. Convert a batch with drag-and-drop or directly from Finder.

**Description:**

HEIC to JPG makes your iPhone photos easy to share. Select HEIC or HEIF files, drop them into the app, or choose HEIC to JPG from Finder's Open With menu. JPG copies are saved in the same folder, ready to use.

- Convert one photo or a whole batch.
- Keep full image dimensions and correct orientation.
- Choose Good, High, or Maximum JPEG quality.
- Keep capture dates and camera details, or remove photo metadata for sharing.
- Keep your original photos and existing files. Numbered filenames prevent overwrites.
- Find finished copies with one click.

Everything happens on your Mac. No uploads, accounts, or subscriptions. The app asks for permission to save in a folder and remembers your choice. Export files from Photos first; the app works with files in Finder rather than browsing your Photos library. JPEG is a lossy still-image format; Live Photo videos and HEIF depth data are not exported.

**Keywords:** heic,heif,jpg,jpeg,convert,photo,image,batch,iphone,offline

**Draft review notes:** No account or server is required. Select a local HEIC/HEIF photo or open it from Finder, then authorize its containing folder when prompted. JPGs appear beside the original. Repeat conversion creates numbered copies. The metadata switch controls whether supported EXIF/GPS/IPTC details are copied. To test permission prompting again, use the app menu's Forget Saved Folder Access action. Test images must be supplied separately; the bundled source-code fixture is synthetic.

## Privacy declarations

Proposed App Store answer: **Data Not Collected**, consistent with this build. Review the final binary and policy before submitting. Reading and writing a photo locally does not send it to the developer.

`Resources/PrivacyInfo.xcprivacy` declares no tracking or collected data and uses `CA92.1` for app-owned UserDefaults settings/bookmarks. See Apple's [required-reason API guidance](https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest). There are no third-party SDKs to declare. Add new declarations if future code introduces covered APIs or data collection.

`ITSAppUsesNonExemptEncryption` is false: the application implements no custom encryption or networking. Confirm this answer against the final build and Apple's questionnaire before submission.

## Screenshot plan

Capture the actual app with synthetic photos: (1) clean drop/selection screen, (2) successful batch with numbered copies, (3) quality and metadata options. Include an accurate caption about saving beside originals. Do not include personal filenames, location data, or unsupported features. Check current App Store Connect screenshot dimensions when uploading; final marketing screenshots are not yet prepared.
