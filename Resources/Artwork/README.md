# App icon

`AppIcon-master.png` is the full-resolution transparent master. The icon was generated with OpenAI's built-in imagegen tool on 2026-10-10. No existing brand artwork or reference photographs were supplied.

The artwork is included under the project's MIT license. Keep the master in the repository; builds do not contact an image service.

Run `bash scripts/generate-icons.sh` after replacing the master. This resamples it with native AppKit, preserves transparency, and creates the committed macOS asset catalog and ICNS resource. The catalog includes all ten macOS icon sizes, up to 1024 × 1024.

## Generation prompt

Use case: logo-brand. Asset type: production macOS application icon for a local HEIC-to-JPG photo converter. Create one polished 1024x1024 square icon image, not a mockup or presentation. A beautiful native Mac app icon: a rich cobalt-to-azure rounded-square tile, inset about 70 pixels within the canvas, with softly chamfered luminous edges and restrained tactile depth. Center a stack of two large photo cards: the rear card is translucent periwinkle glass, slightly offset toward the upper left; the front card is warm porcelain white with a simple vivid miniature landscape, deep teal mountain silhouette, pale aqua sky, and one warm golden sun. Integrate one confident smooth white conversion arrow sweeping from the left photo card toward the lower right, visually suggesting a photo becoming a shareable copy. Keep the silhouette bold and clean, with at most three large visual elements. Straight-on view with only subtle depth, tasteful soft studio illumination. Make it distinctive, calm, friendly, and readable at 32 pixels. Generous clean spacing, no tiny details, no text, no letters, no file extensions, no Apple logos, no watermarks. The exterior beyond the rounded-square icon tile must be truly transparent, not white and not a checkerboard. Crisp premium materials; no extraneous objects, no background scene, no multiple variants.
