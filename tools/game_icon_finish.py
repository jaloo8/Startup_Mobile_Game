#!/usr/bin/env python3
"""Edge-flood background removal, tight alpha bbox → square, NEAREST resize.

For chunky pixel UI icons from AI generators (often opaque plates).
"""
from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image


def _edge_flood_mask(rgb: np.ndarray, tol: float) -> np.ndarray:
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
		c = rgb[int(y), int(x)]
		for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
			nx, ny = x + dx, y + dy
			if nx < 0 or nx >= w or ny < 0 or ny >= h or vis[ny, nx]:
				continue
			if float(np.linalg.norm(rgb[ny, nx].astype(np.float32) - c.astype(np.float32))) <= tol:
				vis[ny, nx] = True
				q.append((nx, ny))
	return vis


def _square_around_bbox(x0: int, y0: int, x1: int, y1: int, w: int, h: int) -> tuple[int, int, int, int]:
	"""Return (l, t, r, b) square crop coords inclusive-exclusive right/bottom."""
	cw = x1 - x0 + 1
	ch = y1 - y0 + 1
	side = max(cw, ch)
	# center the square on the bbox
	cx = (x0 + x1) // 2
	cy = (y0 + y1) // 2
	half = side // 2
	l = max(0, cx - half)
	t = max(0, cy - half)
	r = min(w, l + side)
	b = min(h, t + side)
	# if clamped, shift back if possible
	l = max(0, r - side)
	t = max(0, b - side)
	return l, t, r, b


def main() -> None:
	p = argparse.ArgumentParser(description=__doc__)
	p.add_argument("src")
	p.add_argument("dst")
	p.add_argument("size", type=int, help="Output width and height (square)")
	p.add_argument("--tol", type=float, default=24.0)
	p.add_argument("--alpha-cut", type=int, default=12, dest="alpha_cut")
	args = p.parse_args()

	im = Image.open(args.src).convert("RGBA")
	arr = np.asarray(im)
	rgb = arr[:, :, :3].copy()
	mask = _edge_flood_mask(rgb, args.tol)
	arr = arr.copy()
	arr[:, :, 3] = np.where(mask, 0, arr[:, :, 3])
	a = arr[:, :, 3]
	ys, xs = np.where(a > args.alpha_cut)
	if len(xs) == 0:
		out = Image.fromarray(arr).convert("RGBA")
	else:
		x0, x1 = int(xs.min()), int(xs.max())
		y0, y1 = int(ys.min()), int(ys.max())
		h, w = a.shape
		l, t, r, b = _square_around_bbox(x0, y0, x1, y1, w, h)
		crop = arr[t:b, l:r]
		out = Image.fromarray(crop).convert("RGBA")

	out = out.resize((args.size, args.size), Image.Resampling.NEAREST)
	dst = Path(args.dst)
	dst.parent.mkdir(parents=True, exist_ok=True)
	out.save(dst, "PNG")
	al = out.getchannel("A").getextrema()
	print(f"Wrote {dst} {args.size}x{args.size} alpha={al}")


if __name__ == "__main__":
	main()
