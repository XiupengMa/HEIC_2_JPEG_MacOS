# Using HEIC to JPG

Select HEIC/HEIF files with **Choose photos…**, drag them onto the window or Dock icon, or use Finder **Open With → HEIC to JPG**. JPGs are saved beside the originals.

If Finder does not list the app, choose **Open With → Other…** and select it. Export photos from the Photos app first, and download iCloud files before converting.

## Controls

**⌘O** opens the photo picker. **Show in Finder** reveals the saved JPGs. Closing the window keeps conversion running; **Stop after current** skips waiting photos and finishes the active one. **⌘Q** quits.

## Conversion details

- Saves `IMG_1234.HEIC` as `IMG_1234.jpg` in the same folder.
- Keeps originals and existing files. If a name is taken, uses `IMG_1234 (1).jpg`, `(2)`, etc. Filename reservation is atomic, including across simultaneous conversions.
- Keeps full pixel dimensions, orientation, and the decoded image’s color profile. JPG is lossy, including at Maximum quality.
- Defaults to High quality (90%). Good is 80%; Maximum is 100%. Settings apply to files added after the change.
- **Keep photo metadata** defaults to on. Copies supported EXIF, TIFF, GPS, and IPTC fields, including capture time and location when available. Turn it off to omit these fields; display orientation and color information remain.
- Exports the primary still photo. Live Photo videos, depth maps, bursts, and HEIF auxiliary images are not exported. On macOS 14+, decoding explicitly requests SDR output for standard JPEG sharing.
- Converts serially in the background to limit memory use. A failed file is reported individually; other files continue.
- Checks that the JPG decodes before saving the final filename, and cleans up temporary files on failure.
- Requires a writable source folder and locally readable photos. Export files from the Photos app first; this app does not browse or modify your Photos library. Download iCloud files before converting.

For occasional conversions without this app, Finder also has [Quick Actions → Convert Image](https://support.apple.com/guide/mac-help/mchl97ff9142/mac).

[Back to the visual walkthrough](../README.md)
