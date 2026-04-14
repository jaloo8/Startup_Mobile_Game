#!/usr/bin/env python3
"""Center-crop to target aspect ratio, then resize to exact WxH (RGBA PNG).

Used after Cursor image generation so assets match in-game dimensions.
"""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def crop_to_aspect(img: Image.Image, target_w: int, target_h: int) -> Image.Image:
	w, h = img.size
	tr = target_w / target_h
	cr = w / h
	if abs(cr - tr) < 1e-3:
		return img
	if cr > tr:
		nw = int(round(h * tr))
		x0 = max(0, (w - nw) // 2)
		return img.crop((x0, 0, x0 + nw, h))
	nh = int(round(w / tr))
	y0 = max(0, (h - nh) // 2)
	return img.crop((0, y0, w, y0 + nh))


def main() -> None:
	p = argparse.ArgumentParser(description=__doc__)
	p.add_argument("src", help="Source PNG from generator")
	p.add_argument("dst", help="Destination path under project")
	p.add_argument("width", type=int, help="Exact output width")
	p.add_argument("height", type=int, help="Exact output height")
	args = p.parse_args()

	img = Image.open(args.src).convert("RGBA")
	img = crop_to_aspect(img, args.width, args.height)
	img = img.resize((args.width, args.height), Image.Resampling.LANCZOS)
	dst = Path(args.dst)
	dst.parent.mkdir(parents=True, exist_ok=True)
	img.save(dst, "PNG")
	print(f"Wrote {dst} ({args.width}x{args.height})")


if __name__ == "__main__":
	main()
