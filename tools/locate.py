# -*- coding: utf-8 -*-
"""按语义色定位元素：每个预设色找到其行带 + x 范围（pt）。"""
import sys
from PIL import Image

PREDS = {
    "进度槽灰": lambda r, g, b: abs(r - 226) < 14 and abs(g - 226) < 14 and abs(b - 227) < 14,
    "进度橙":   lambda r, g, b: r > 235 and 130 < g < 200 and b < 95,
    "深蓝字":   lambda r, g, b: b > 150 and r < 70 and g < 100,
    "亮橙字":   lambda r, g, b: r > 235 and 85 < g < 165 and b < 70,
    "绿":       lambda r, g, b: g > 120 and r < 105 and b < 120,
    "红":       lambda r, g, b: r > 185 and g < 95 and b < 95,
    "浅灰键":   lambda r, g, b: abs(r - 200) < 22 and abs(g - 200) < 22 and abs(b - 202) < 22,
}


def run(path):
    im = Image.open(path).convert("RGB")
    W, H = im.size
    s = 402.0 / W
    px = im.load()
    print(f"\n=== {path.split('/')[-1]} {W}x{H} ===")
    for name, pred in PREDS.items():
        rows = []
        for y in range(H):
            c = sum(1 for x in range(0, W, 2) if pred(*px[x, y][:3]))
            rows.append(c)
        bands, start = [], None
        for y, c in enumerate(rows):
            if c >= 4 and start is None:
                start = y
            elif c < 4 and start is not None:
                if y - start > 6:
                    bands.append((start, y - 1))
                start = None
        if start is not None:
            bands.append((start, H - 1))
        for (a, b) in bands[:6]:
            mnx, mxx = W, -1
            for y in range(a, b + 1):
                for x in range(0, W, 2):
                    if pred(*px[x, y][:3]):
                        if x < mnx: mnx = x
                        if x > mxx: mxx = x
            print(f"  {name:6s} y={a*s:6.1f}..{(b+1)*s:6.1f} h={(b-a+1)*s:6.1f}pt "
                  f"x={mnx*s:6.1f} w={(mxx-mnx+1)*s:6.1f}pt")


for p in sys.argv[1:]:
    run(p)
