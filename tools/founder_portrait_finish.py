#!/usr/bin/env python3
"""Edge-connected flood → transparent, center square crop, 160×160 RGBA.

Used for AI-generated founder portraits where the model returns an opaque plate.
"""
from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image


def _edge_flood_mask(rgb: np.ndarray, tol: float) -> np.ndarray:
	"""True = connected to image border through steps with <=tol RGB distance."""
	h, w = rgb.shape[:2]
	vis = np.zeros((h, w), dtype=np.bool_)
	q: deque[tuple[int, int]] = deque()

	def try_add(x: int, y: int) -> None:
		if 0 <= x < w and 0 <= y < h and not vis[y, x]:
			vis[y, x] = True
			q.append((x, y))

	for x in range(w):
		try_add(x, 0)
		try_add(x, h - 1)
	for y in range(h):
		try_add(0, y)
		try_add(w - 1, y)

	while q:
		x, y = q.popleft()
		cy, cx = int(y), int(x)
		c = rgb[cy, cx]
		for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
			nx, ny = x + dx, y + dy
			if nx < 0 or nx >= w or ny < 0 or ny >= h or vis[ny, nx]:
				continue
			if float(np.linalg.norm(rgb[ny, nx].astype(np.float32) - c.astype(np.float32))) <= tol:
				vis[ny, nx] = True
				q.append((nx, ny))
	return vis


def _crop_square_center(img: Image.Image) -> Image.Image:
	w, h = img.size
	side = min(w, h)
	left = (w - side) // 2
	top = (h - side) // 2
	return img.crop((left, top, left + side, top + side))


def main() -> None:
	p = argparse.ArgumentParser(description=__doc__)
	p.add_argument("src")
	p.add_argument("dst")
	p.add_argument("--tol", type=float, default=26.0, help="RGB distance for edge flood (default 26)")
	p.add_argument("--size", type=int, default=160, help="Output square size")
	args = p.parse_args()

	im = Image.open(args.src).convert("RGBA")
	rgb = np.asarray(im)[:, :, :3]
	mask = _edge_flood_mask(rgb, args.tol)
	arr = np.asarray(im).copy()
	arr[:, :, 3] = np.where(mask, 0, arr[:, :, 3])
	out = Image.fromarray(arr).convert("RGBA")
	out = _crop_square_center(out)
	out = out.resize((args.size, args.size), Image.Resampling.NEAREST)

	dst = Path(args.dst)
	dst.parent.mkdir(parents=True, exist_ok=True)
	out.save(dst, "PNG")
	a = out.getchannel("A")
	print(f"Wrote {dst} alpha_range={a.getextrema()}")


if __name__ == "__main__":
	main()
