# -*- coding: utf-8 -*-
"""
把参考图与实现截图都换算到 pt，逐项对比。
参考图 1072px 宽 -> 402pt；截图 1206px 宽 -> 402pt。
"""
import sys
from PIL import Image


def pt_scale(w):
    return 402.0 / w


def load(p):
    return Image.open(p).convert("RGB")


def bbox(im, pred, region=None):
    W, H = im.size
    x0, y0, x1, y1 = region or (0, 0, W, H)
    px = im.load()
    mnx, mny, mxx, mxy = W, H, -1, -1
    for y in range(y0, y1):
        for x in range(x0, x1):
            if pred(*px[x, y][:3]):
                if x < mnx: mnx = x
                if x > mxx: mxx = x
                if y < mny: mny = y
                if y > mxy: mxy = y
    if mxx < 0:
        return None
    return mnx, mny, mxx, mxy


def to_pt(bb, s):
    if not bb:
        return None
    x0, y0, x1, y1 = bb
    return dict(x=x0 * s, y=y0 * s, w=(x1 - x0 + 1) * s, h=(y1 - y0 + 1) * s)


def find_bands(im, pred, thresh_ratio=0.45, region=None):
    """按行扫描找连续色带，阈值 = 宽度比例"""
    W, H = im.size
    x0, y0, x1, y1 = region or (0, 0, W, H)
    px = im.load()
    need = int((x1 - x0) * thresh_ratio)
    res, start = [], None
    for y in range(y0, y1):
        c = sum(1 for x in range(x0, x1) if pred(*px[x, y][:3]))
        if c >= need and start is None:
            start = y
        elif c < need and start is not None:
            if y - start > 8:
                res.append((start, y - 1))
            start = None
    if start is not None:
        res.append((start, y1 - 1))
    return res


def xspan(im, pred, y0, y1):
    W, _ = im.size
    px = im.load()
    mnx, mxx = W, -1
    for y in range(y0, y1 + 1):
        for x in range(W):
            if pred(*px[x, y][:3]):
                if x < mnx: mnx = x
                if x > mxx: mxx = x
    return mnx, mxx


def measure_home(path, label):
    im = load(path)
    W, H = im.size
    s = pt_scale(W)
    print(f"\n--- {label}  {W}x{H} ---")

    orange = lambda r, g, b: r > 195 and 80 < g < 200 and b < 105
    green = lambda r, g, b: g > 115 and r < 125 and b < 125
    blue = lambda r, g, b: b > 190 and r < 150 and 100 < g < 200

    for name, pred in (("计划卡", orange), ("开始学习", green), ("巩固练习", blue)):
        bands = find_bands(im, pred, 0.30, (0, int(H * 0.04), W, H))
        for (a, b) in bands:
            xa, xb = xspan(im, pred, a, b)
            print(f"  {name:8s} y={a*s:6.1f} h={(b-a+1)*s:6.1f}pt  "
                  f"x={xa*s:6.1f} w={(xb-xa+1)*s:6.1f}pt  "
                  f"mL={xa*s:5.1f} mR={(W-1-xb)*s:5.1f}")


if __name__ == "__main__":
    ref, shot = sys.argv[1], sys.argv[2]
    measure_home(ref, "参考图")
    measure_home(shot, "实现")
