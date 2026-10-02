"""Generate original, abstract demo graphics; requires Pillow. No source photos."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[1] / 'assets' / 'demo'
root.mkdir(parents=True, exist_ok=True)
palettes = [('#F2B880', '#D85B46'), ('#85C7BC', '#176B75'), ('#B4A5DC', '#6654A2'),
            ('#F1CE68', '#CB7840'), ('#A7C9E8', '#34658B'), ('#EDABC1', '#AB4468')]
# Pillow's bundled bitmap font keeps generation independent of system fonts.
for index, (background, foreground) in enumerate(palettes, 1):
    image = Image.new('RGB', (480, 640), background)
    draw = ImageDraw.Draw(image)
    for y in range(-80, 720, 120):
        if index % 2:
            draw.ellipse((-120, y, 310, y + 210), fill=foreground)
        else:
            draw.polygon([(0, y), (480, y + 180), (480, y + 230), (0, y + 50)], fill=foreground)
    draw.rounded_rectangle((166, 246, 314, 394), radius=32, fill='#FFFFFF')
    number = Image.new('RGBA', (16, 18))
    ImageDraw.Draw(number).text((4, 2), str(index), font=ImageFont.load_default(), fill=foreground)
    number = number.resize((128, 144), Image.Resampling.NEAREST)
    image.paste(number, (176, 248), number)
    image.save(root / f'demo_{index}.png', optimize=True)
