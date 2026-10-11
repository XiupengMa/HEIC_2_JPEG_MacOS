"""Regenerate our synthetic HEIC fixture. Requires ffmpeg with libx265 only here.

Tests and the app have no ffmpeg dependency. The fixture is a 64x48 blue image
with a red corner, wrapped as a single-image HEIF (hvc1) container. Metadata is
added losslessly by the tests using ImageIO.
"""
from pathlib import Path
import struct
import subprocess
import tempfile


def u16(value):
    return struct.pack(">H", value)


def u32(value):
    return struct.pack(">I", value)


def box(kind, payload):
    return u32(8 + len(payload)) + kind.encode() + payload


def full(kind, payload, version=0):
    return box(kind, bytes([version, 0, 0, 0]) + payload)


with tempfile.TemporaryDirectory() as temp:
    ppm, mp4 = Path(temp) / "photo.ppm", Path(temp) / "photo.mp4"
    pixels = b"".join(bytes((230, 77, 26) if x < 25 and y < 16 else (51, 128, 204))
                      for y in range(48) for x in range(64))
    ppm.write_bytes(b"P6\n64 48\n255\n" + pixels)
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(ppm),
                    "-frames:v", "1", "-c:v", "libx265", "-x265-params", "log-level=error:pools=none",
                    "-pix_fmt", "yuv420p", "-tag:v", "hvc1", str(mp4)], check=True)
    data = mp4.read_bytes()


def extract(kind):
    start = data.index(kind.encode()) - 4
    size = struct.unpack_from(">I", data, start)[0]
    return data[start:start + size]


hvcc = extract("hvcC")
sample = extract("mdat")[8:]
ftyp = box("ftyp", b"heic" + u32(0) + b"mif1heic")
hdlr = full("hdlr", u32(0) + b"pict" + bytes(12) + b"Picture\0")
pitm = full("pitm", u16(1))
iinf = full("iinf", u16(1) + full("infe", u16(1) + u16(0) + b"hvc1Photo\0", 2))
ipco = box("ipco", hvcc + full("ispe", u32(64) + u32(48)) + full("pixi", bytes([3, 8, 8, 8])))
ipma = full("ipma", u32(1) + u16(1) + bytes([3, 0x81, 0x82, 0x83]))
iprp = box("iprp", ipco + ipma)


def meta(offset):
    iloc = full("iloc", bytes([0x44, 0]) + u16(1) + u16(1) + u16(0) + u16(1)
                + u32(offset) + u32(len(sample)))
    return full("meta", hdlr + pitm + iloc + iinf + iprp)


metadata = meta(len(ftyp) + len(meta(0)) + 8)
output = Path(__file__).resolve().parents[1] / "Tests/ConversionCoreTests/Fixtures/photo.heic"
output.parent.mkdir(parents=True, exist_ok=True)
output.write_bytes(ftyp + metadata + box("mdat", sample))
print(output)
