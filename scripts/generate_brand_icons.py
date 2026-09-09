#!/usr/bin/env python3
"""Generate IMFxTech Chat launcher icons from the branding source PNGs.

Source assets live outside this repo, in ~/HD3/botDon/branding/ (prepared by
the brand designer with the safe-zone recentering already done). Re-run this
script whenever those source PNGs are updated.
"""
import json
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[1]
BRANDING = Path.home() / "HD3/botDon/branding"

APPLE_SRC = BRANDING / "imfxtech-chat-icone-apple-appstore-1024.png"
ANDROID_LEGACY_SRC = BRANDING / "imfxtech-chat-icone-android-recentrado-1024.png"
ANDROID_FG_SRC = BRANDING / "imfxtech-chat-icone-android-adaptativo-frente-1024.png"

DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
LEGACY_BASE_DP = 48
FOREGROUND_BASE_DP = 108


def resize(src, size):
    return src.resize((size, size), Image.Resampling.LANCZOS)


def generate_ios_icons():
    src = Image.open(APPLE_SRC).convert("RGB")
    contents_path = (
        REPO / "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json"
    )
    contents = json.loads(contents_path.read_text())
    for entry in contents["images"]:
        size_pt = float(entry["size"].split("x")[0])
        scale = float(entry["scale"].rstrip("x"))
        px = round(size_pt * scale)
        out = contents_path.parent / entry["filename"]
        resize(src, px).save(out)
        print(f"iOS  {entry['filename']}: {px}x{px}")


def generate_android_legacy_icons():
    src = Image.open(ANDROID_LEGACY_SRC).convert("RGB")
    for density, mult in DENSITIES.items():
        px = round(LEGACY_BASE_DP * mult)
        out = REPO / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png"
        resize(src, px).save(out)
        print(f"Android legacy {density}: {px}x{px}")


def generate_android_foreground_icons():
    src = Image.open(ANDROID_FG_SRC).convert("RGBA")
    for density, mult in DENSITIES.items():
        px = round(FOREGROUND_BASE_DP * mult)
        out = (
            REPO
            / f"android/app/src/main/res/drawable-{density}/ic_launcher_foreground.png"
        )
        resize(src, px).save(out)
        print(f"Android foreground {density}: {px}x{px}")


def generate_android_monochrome_icons():
    src = Image.open(ANDROID_FG_SRC).convert("RGBA")
    alpha = src.getchannel("A")
    white_silhouette = Image.new("RGBA", src.size, (255, 255, 255, 0))
    white_silhouette.putalpha(alpha)
    for density, mult in DENSITIES.items():
        px = round(FOREGROUND_BASE_DP * mult)
        out = (
            REPO
            / f"android/app/src/main/res/drawable-{density}/ic_launcher_monochrome.png"
        )
        resize(white_silhouette, px).save(out)
        print(f"Android monochrome {density}: {px}x{px}")


def remove_old_background_pngs():
    for density in DENSITIES:
        f = (
            REPO
            / f"android/app/src/main/res/drawable-{density}/ic_launcher_background.png"
        )
        if f.exists():
            f.unlink()
            print(f"removed {f}")


MINI_LOGO_SIZE = 500


def generate_mini_logo():
    src = Image.open(APPLE_SRC).convert("RGB")
    out = REPO / "assets/logo/mini/logo_mini.png"
    resize(src, MINI_LOGO_SIZE).save(out)
    print(f"mini logo: {MINI_LOGO_SIZE}x{MINI_LOGO_SIZE}")


def generate_mini_logo_monochrome():
    src = Image.open(ANDROID_FG_SRC).convert("RGBA")
    alpha = src.getchannel("A")
    white_silhouette = Image.new("RGBA", src.size, (255, 255, 255, 0))
    white_silhouette.putalpha(alpha)
    out = REPO / "assets/logo/mini/logo_mono_mini.png"
    resize(white_silhouette, MINI_LOGO_SIZE).save(out)
    print(f"mini logo monochrome: {MINI_LOGO_SIZE}x{MINI_LOGO_SIZE}")


if __name__ == "__main__":
    generate_ios_icons()
    generate_android_legacy_icons()
    generate_android_foreground_icons()
    generate_android_monochrome_icons()
    remove_old_background_pngs()
    generate_mini_logo()
    generate_mini_logo_monochrome()
