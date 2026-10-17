# -*- coding: utf-8 -*-
"""行剖面：每 6px 一行，统计各类颜色像素数，输出连续同类行的区间（pt）。
用于反推参考图的垂直布局结构。"""
import sys
from PIL import Image

CATS = [
    ("白底",   lambda r, g, b: r > 248 and g > 248 and b > 248),
    ("米底",   lambda r, g, b: r > 245 and 235 < g < 252 and 200 < b < 240),
    ("黄光",   lambda r, g, b: r > 245 and 225 < g < 250 and 170 < b < 225),
    ("深蓝",   lambda r, g, b: b > 140 and r < 90 and g < 110),
    ("橙",     lambda r, g, b: r > 210 and 100 < g < 190 and b < 110),
    ("绿",     lambda r, g, b: g > 110 and r < 130 and b < 130),
    ("红",     lambda r, g, b: r > 170 and g < 110 and b < 110),
    ("灰",     lambda r, g, b: abs(r - g) < 12 and abs(g - b) < 12 and 180 < r < 245),
    ("深字",   lambda r, g, b: r < 80 and g < 80 and b < 100),
]


def classify(r, g, b):
    for name, fn in CATS:
        if fn(r, g, b):
            return name
    return None


def profile(path, step=6):
    im = Image.open(path).convert("RGB")
    W, H = im.size
    s = 402.0 / W
    px = im.load()
    out = []
    for y in range(0, H, step):
        counts = {}
        for x in range(0, W, 2):
            c = classify(*px[x, y][:3])
            if c:
                counts[c] = counts.get(c, 0) + 1
        if counts:
            dom = max(counts.items(), key=lambda kv: kv[1])
            out.append((y, dom[0], dom[1]))
        else:
            out.append((y, "-", 0))

    print(f"{'y(pt)':>8} {'主色':<6} {'占比':>6}")
    prev = None
    for (y, dom, n) in out:
        if dom != prev:
            print(f"{y*s:8.1f} {dom:<6} {n*2:5d}px   <-- 起始")
            prev = dom


if __name__ == "__main__":
    profile(sys.argv[1])
