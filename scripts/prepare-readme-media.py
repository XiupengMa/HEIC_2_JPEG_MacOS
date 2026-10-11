#!/usr/bin/env python3
"""Crop actual app captures and assemble the README walkthrough (requires Pillow)."""

from pathlib import Path
import argparse

from PIL import Image, ImageDraw, ImageFont, ImageOps


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("captures", type=Path, help="Directory containing 01-ready.png through 05-open-with.png")
parser.add_argument("--output", type=Path, default=Path("docs/images"))
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)


def capture(name, box):
    with Image.open(args.captures / name) as source:
        return source.convert("RGB").crop(box)


ready = capture("01-ready.png", (0, 64, 1300, 1584))
picker = capture("02-picker.png", (410, 0, 1762, 896))
converted = capture("03-converted.png", (0, 64, 1300, 1584))
folder = capture("04-folder.png", (388, 100, 1820, 424))
shortcut = capture("05-open-with.png", (550, 180, 1440, 736))
options = capture("03-converted.png", (56, 780, 1244, 1020))

for name, picture, width in (
    ("app.png", ready, 1040),
    ("converted.png", converted, 1040),
    ("same-folder.png", folder, 1200),
    ("open-with.png", shortcut, 890),
    ("options.png", options, 1188),
):
    picture = ImageOps.contain(picture, (width, 2000), Image.Resampling.LANCZOS)
    picture.save(args.output / name, optimize=True)

font_path = "/System/Library/Fonts/Supplemental/Arial.ttf"
font = ImageFont.truetype(font_path, 26)
frames = []
for picture, caption in (
    (ready, "1. Choose photos"),
    (picker, "2. Select a batch and convert"),
    (converted, "3. Your JPGs are ready"),
    (folder, "4. JPGs appear beside the originals"),
):
    frame = Image.new("RGB", (840, 980), "#f4f6fb")
    draw = ImageDraw.Draw(frame)
    draw.text((32, 25), caption, fill="#18356d", font=font)
    picture = ImageOps.contain(picture, (776, 884), Image.Resampling.LANCZOS)
    x, y = (840 - picture.width) // 2, 76 + (884 - picture.height) // 2
    draw.rounded_rectangle((x - 2, y - 2, x + picture.width + 2, y + picture.height + 2), radius=12, fill="#dce2ed")
    frame.paste(picture, (x, y))
    frames.append(frame)

# One shared palette keeps text and the blue controls stable across frames.
sheet = Image.new("RGB", (840 * len(frames), 980))
for i, frame in enumerate(frames):
    sheet.paste(frame, (840 * i, 0))
palette = sheet.quantize(colors=256, method=Image.Quantize.MAXCOVERAGE)
frames = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
frames[0].save(args.output / "convert-demo.gif", save_all=True, append_images=frames[1:],
               duration=[2200, 2800, 3000, 3000], loop=0, optimize=True, disposal=2)
print(f"Saved README media to {args.output}")
