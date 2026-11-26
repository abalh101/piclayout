"""Check genuine simulator captures for the supported Apple display sizes."""
from pathlib import Path
import sys

from validate_ios import png_header, require

folder = Path(sys.argv[1])
dimensions = tuple(int(value) for value in sys.argv[2:4])
images = sorted(folder.glob("*.png"))
require(len(images) == 10 and [path.name[:2] for path in images] ==
        [f"{index:02d}" for index in range(1, 11)], "Expected ten named screenshots.")
for path in images:
    require(png_header(path) == (*dimensions, 8, 2),
            f"Incorrect dimensions or non-RGB screenshot in {path.name}.")
print(f"Verified ten {dimensions[0]} × {dimensions[1]} simulator captures.")
