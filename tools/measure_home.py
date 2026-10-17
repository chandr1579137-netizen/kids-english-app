# -*- coding: utf-8 -*-
"""首页精量：词书卡 + 标题字高 + 各区块 y 位置"""
import sys
from PIL import Image

PT = 402.0 / 1072
W_REF = 1072


def xspan(im, pred, y0, y1, x0=0, x1=None):
    W, _ = im.size
    x1 = x1 or W
    px = im.load()
    minx, maxx = W, -1
    for y in range(y0, y1 + 1):
        for x in range(x0, x1):
            r, g, b = px[x, y][:3]
            if pred(r, g, b):
                if x < minx:
                    minx = x
                if x > maxx:
                    maxx = x
    return minx, maxx


def yspan(im, pred, x0, x1, y0=0, y1=None):
    W, H = im.size
    y1 = y1 or H
    px = im.load()
    miny, maxy = H, -1
    for y in range(y0, y1):
        for x in range(x0, x1):
            r, g, b = px[x, y][:3]
            if pred(r, g, b):
                if y < miny:
                    miny = y
                if y > maxy:
                    maxy = y
    return miny, maxy


def colbands(im, pred, y0, y1, thresh=6, minw=8):
    W, _ = im.size
    px = im.load()
    counts = []
    for x in range(W):
        c = 0
        for y in range(y0, y1 + 1):
            r, g, b = px[x, y][:3]
            if pred(r, g, b):
                c += 1
        counts.append(c)
    res, start = [], None
    for x, c in enumerate(counts):
        if c >= thresh and start is None:
            start = x
        elif c < thresh and start is not None:
            if x - start >= minw:
                res.append((start, x - 1))
            start = None
    if start is not None:
        res.append((start, len(counts) - 1))
    return res


path = sys.argv[1]
im = Image.open(path).convert("RGB")
print("图:", path.split("/")[-1])

# --- 1) 词书卡群：找饱和色块（蓝/粉/绿/紫）所在行带
sat = lambda r, g, b: (max(r, g, b) - min(r, g, b)) > 55 and max(r, g, b) > 110
y0, y1 = yspan(im, sat, 60, 1012, 840, 1500)
print(f"\n词书卡行带 y={y0}-{y1}  h={(y1-y0+1)*PT:.1f}pt")
groups = colbands(im, sat, y0, y1, thresh=20, minw=20)
print(f"  竖列分组 {len(groups)} 组:")
prev = None
for a, b in groups:
    gap = "" if prev is None else f" gap={(a-prev-1)*PT:.1f}pt"
    print(f"    x {a}-{b}  w={(b-a+1)*PT:.1f}pt  mL={a*PT:.1f}{gap}")
    prev = b

# --- 2) 「选词书」标题字高：深色像素
ink = lambda r, g, b: r < 90 and g < 90 and b < 110
ty0, ty1 = yspan(im, ink, 55, 500, 840, y0 - 1)
tx0, tx1 = xspan(im, ink, ty0, ty1, 0, 700)
print(f"\n「选词书」字形 bbox y={ty0}-{ty1} h={(ty1-ty0+1)*PT:.1f}pt  x={tx0}-{tx1} w={(tx1-tx0+1)*PT:.1f}pt  mL={tx0*PT:.1f}")

# --- 3) 计划卡内文字：白色像素
white = lambda r, g, b: r > 235 and g > 235 and b > 235
wy0, wy1 = yspan(im, white, 100, 640, 214, 830)
print(f"\n计划卡白字区 y={wy0}-{wy1} h={(wy1-wy0+1)*PT:.1f}pt")
# 按行切
px = im.load()
rows = []
for y in range(214, 831):
    c = sum(1 for x in range(100, 640) if white(*px[x, y][:3]))
    rows.append((y, c))
run, start = [], None
for y, c in rows:
    if c >= 3 and start is None:
        start = y
    elif c < 3 and start is not None:
        if y - start >= 8:
            run.append((start, y - 1))
        start = None
print("  文字行（高=>推算字号≈h*0.72）:")
for a, b in run:
    h = b - a + 1
    print(f"    y {a}-{b}  h={h*PT:.1f}pt  ≈字号 {h*PT*0.72:.0f}pt")
