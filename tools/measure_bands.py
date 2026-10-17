# -*- coding: utf-8 -*-
"""按行扫描找色带，量出每个色块的精确 y 范围与 x 范围。

参考图 1072px 宽 = 402pt 逻辑宽 => 1 ref px = 0.375pt
"""
import sys
from PIL import Image

PT = 402.0 / 1072


def rowcounts(im, pred, x0=0, x1=None):
    W, H = im.size
    x1 = x1 or W
    px = im.load()
    out = []
    for y in range(H):
        c = 0
        for x in range(x0, x1):
            r, g, b = px[x, y][:3]
            if pred(r, g, b):
                c += 1
        out.append(c)
    return out


def bands(counts, thresh):
    res, start = [], None
    for y, c in enumerate(counts):
        if c >= thresh and start is None:
            start = y
        elif c < thresh and start is not None:
            if y - start > 6:
                res.append((start, y - 1))
            start = None
    if start is not None:
        res.append((start, len(counts) - 1))
    return res


def xspan(im, pred, y0, y1):
    W, _ = im.size
    px = im.load()
    minx, maxx = W, -1
    for y in range(y0, y1 + 1):
        for x in range(W):
            r, g, b = px[x, y][:3]
            if pred(r, g, b):
                if x < minx:
                    minx = x
                if x > maxx:
                    maxx = x
    return minx, maxx


def show(label, im, pred, thresh, note=""):
    counts = rowcounts(im, pred)
    bs = bands(counts, thresh)
    print(f"\n== {label} {note}")
    for y0, y1 in bs:
        x0, x1 = xspan(im, pred, y0, y1)
        h = y1 - y0 + 1
        w = x1 - x0 + 1
        print(
            f"  y {y0}-{y1} (h={h}px/{h*PT:.1f}pt)  "
            f"x {x0}-{x1} (w={w}px/{w*PT:.1f}pt)  mL={x0*PT:.1f} mR={(1071-x1)*PT:.1f}"
        )


path = sys.argv[1]
im = Image.open(path).convert("RGB")
print("图:", path.split("/")[-1], im.size)

show("橙色计划卡", im, lambda r, g, b: r > 200 and 95 < g < 195 and b < 95, 500)
show("绿色开始学习", im, lambda r, g, b: g > 130 and r < 110 and b < 110, 400)
show("蓝色巩固练习", im, lambda r, g, b: b > 205 and r < 130 and 110 < g < 190, 400)
