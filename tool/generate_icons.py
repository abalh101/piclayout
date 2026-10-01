"""Regenerate PicLayout launcher assets: python3 tool/generate_icons.py (Pillow)."""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
BRAND = ROOT / 'assets/branding'
BRAND.mkdir(parents=True, exist_ok=True)
BLUE = '#356BE8'
# Geometry is authored at 1024 px and downsampled for crisp small icons.
def artwork(background=True, adaptive=False):
    image = Image.new('RGBA', (1024, 1024), BLUE if background else (0, 0, 0, 0))
    tiles = Image.new('RGBA', (1024, 1024))
    d = ImageDraw.Draw(tiles)
    d.rounded_rectangle((190, 190, 494, 494), 56, fill='#FFFFFF')
    d.rounded_rectangle((530, 190, 834, 494), 56, fill='#B9E9E4')
    d.rounded_rectangle((190, 530, 494, 834), 56, fill='#C9D8FF')
    d.rounded_rectangle((530, 530, 834, 834), 56, fill='#FFFFFF')
    d.ellipse((688, 575, 744, 631), fill=BLUE)
    d.polygon([(567, 777), (658, 658), (713, 719), (755, 679), (800, 777)], fill=BLUE)
    if adaptive:
        tiles = tiles.resize((736, 736), Image.Resampling.LANCZOS)
        image.alpha_composite(tiles, (144, 144))
    else:
        image.alpha_composite(tiles)
    return image

master = artwork().convert('RGB')
master.save(BRAND / 'app_icon.png')
logo = artwork()
mask = Image.new('L', (1024, 1024))
ImageDraw.Draw(mask).rounded_rectangle((0, 0, 1023, 1023), 220, fill=255)
logo.putalpha(mask)
logo.save(BRAND / 'app_logo.png')
foreground = artwork(False, True)
foreground.save(BRAND / 'adaptive_foreground.png')
(BRAND / 'app_logo.svg').write_text('''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">
<rect width="1024" height="1024" rx="220" fill="#356BE8"/>
<rect x="190" y="190" width="304" height="304" rx="56" fill="white"/>
<rect x="530" y="190" width="304" height="304" rx="56" fill="#B9E9E4"/>
<rect x="190" y="530" width="304" height="304" rx="56" fill="#C9D8FF"/>
<rect x="530" y="530" width="304" height="304" rx="56" fill="white"/>
<circle cx="716" cy="603" r="28" fill="#356BE8"/>
<path d="M567 777L658 658L713 719L755 679L800 777Z" fill="#356BE8"/></svg>''')
res = ROOT / 'android/app/src/main/res'
for density, size in [('mdpi',48), ('hdpi',72), ('xhdpi',96), ('xxhdpi',144), ('xxxhdpi',192)]:
    folder = res / f'mipmap-{density}'
    folder.mkdir(exist_ok=True)
    logo.resize((size,size), Image.Resampling.LANCZOS).save(folder / 'ic_launcher.png')
    fgsize = round(size * 108 / 48)
    foreground.resize((fgsize,fgsize), Image.Resampling.LANCZOS).save(folder / 'ic_launcher_foreground.png')
folder = res / 'mipmap-anydpi-v26'
folder.mkdir(exist_ok=True)
(folder / 'ic_launcher.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
<background android:drawable="@color/icon_background"/>
<foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>''')
(res / 'values/icon_colors.xml').write_text('<?xml version="1.0" encoding="utf-8"?><resources><color name="icon_background">#356BE8</color></resources>')
icons = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for spec in json.loads((icons / 'Contents.json').read_text())['images']:
    size = round(float(spec['size'].split('x')[0]) * float(spec['scale'][:-1]))
    master.resize((size,size), Image.Resampling.LANCZOS).save(icons / spec['filename'])
print('Generated master/SVG/logo, Android launcher/adaptive assets and all iOS AppIcon sizes.')
