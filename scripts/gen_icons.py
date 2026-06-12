#!/usr/bin/env python3
"""Generate minimal 1x1 transparent PNG icons for AppIcon.appiconset."""
import struct, zlib, os, json

def make_png(path, w=128, h=128, color=(0, 122, 255, 255)):
    def chunk(chunk_type, data):
        return (struct.pack(">I", len(data)) + chunk_type + data +
                struct.pack(">I", zlib.crc32(chunk_type + data) & 0xffffffff))
    sig = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
    raw = b""
    for y in range(h):
        raw += b"\x00" + bytes(color) * w
    compressed = zlib.compress(raw)
    idat = chunk(b"IDAT", compressed)
    with open(path, "wb") as f:
        f.write(sig + chunk(b"IHDR", ihdr) + idat + chunk(b"IEND", b""))

here = os.path.dirname(os.path.abspath(__file__))
appicon_dir = os.path.join(here, "..", "Resources", "Assets.xcassets", "AppIcon.appiconset")
os.makedirs(appicon_dir, exist_ok=True)

sizes = [
    ("iPhone App - 20pt@2x", 40, "Icon-App-20x20@2x.png"),
    ("iPhone App - 20pt@3x", 60, "Icon-App-20x20@3x.png"),
    ("iPhone App - 29pt@2x", 58, "Icon-App-29x29@2x.png"),
    ("iPhone App - 29pt@3x", 87, "Icon-App-29x29@3x.png"),
    ("iPhone App - 40pt@2x", 80, "Icon-App-40x40@2x.png"),
    ("iPhone App - 40pt@3x", 120, "Icon-App-40x40@3x.png"),
    ("iPhone App - 60pt@2x", 120, "Icon-App-60x60@2x.png"),
    ("iPhone App - 60pt@3x", 180, "Icon-App-60x60@3x.png"),
    ("iPad Pro - 83.5pt@2x", 167, "Icon-App-83.5x83.5@2x.png"),
    ("iPad App - 76pt@1x", 76, "Icon-App-76x76@1x.png"),
    ("iPad App - 76pt@2x", 152, "Icon-App-76x76@2x.png"),
    ("iPad Pro - 1024pt@1x", 1024, "Icon-App-1024x1024@1x.png"),
]

images = []
for idiom, size, filename in sizes:
    size_int = int(size)
    make_png(os.path.join(appicon_dir, filename), w=size_int, h=size_int)
    scale = "1x" if "@1x" in filename else "2x" if "@2x" in filename else "3x"
    idiom_val = "iphone" if "iPhone" in idiom else "ipad" if "iPad" in idiom and "Pro" not in idiom or "iPad" in idiom else "ipad-mac" if "mac" in idiom else "ios-marketing"
    if "1024" in filename:
        idiom_val = "ios-marketing"
    entry = {
        "filename": filename,
        "idiom": idiom_val,
        "scale": scale,
        "size": f"{size}x{size}" if isinstance(size, int) else size,
    }
    images.append(entry)

contents = {
    "images": images,
    "info": {"version": 1, "author": "xcode"}
}
with open(os.path.join(appicon_dir, "Contents.json"), "w") as f:
    json.dump(contents, f, indent=2)

accent_dir = os.path.join(here, "..", "Resources", "Assets.xcassets", "AccentColor.colorset")
os.makedirs(accent_dir, exist_ok=True)
accent = {
    "colors": [{
        "idiom": "universal",
        "color": {"color-space": "srgb",
                  "components": {"alpha": "1.000", "blue": "0xFF", "green": "0x7A", "red": "0x00"}}
    }],
    "info": {"version": 1, "author": "xcode"}
}
with open(os.path.join(accent_dir, "Contents.json"), "w") as f:
    json.dump(accent, f, indent=2)

print(f"Generated {len(sizes)} PNG icons in {appicon_dir}")
