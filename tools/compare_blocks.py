# -*- coding: utf-8 -*-
"""通用：检测白卡块 / 色块的位置与尺寸（pt），两图同口径对比。"""
import sys
from PIL import Image


def load(p):
    return Image.open(p).convert("RGB")


def is_white(r, g, b):
    return r > 246 and g > 246 and b > 246


def is_colored(r, g, b):
    mx, mn = max(r, g, b), min(r, g, b)
    return (mx - mn) > 45 and mx > 110


def white_bands(im, thresh_ratio=0.30):
    W, H = im.size
    px = im.load()
    need = int(W * thresh_ratio)
    bands, start = [], None
    for y in range(int(H * 0.04), H):
        c = sum(1 for x in range(W) if is_white(*px[x, y][:3]))
        if c >= need and start is None:
            start = y
        elif c < need and start is not None:
            if y - start > 10:
                bands.append((start, y - 1))
            start = None
    if start is not None:
        bands.append((start, H - 1))
    return bands


def xspan(im, y0, y1, pred):
    W, _ = im.size
    px = im.load()
    mnx, mxx = W, -1
    for y in range(y0, y1 + 1):
        for x in range(W):
            if pred(*px[x, y][:3]):
                if x < mnx: mnx = x
                if x > mxx: mxx = x
    return mnx, mxx


def probe_white(path, label, ratio=0.30):
    im = load(path)
    W, H = im.size
    s = 402.0 / W
    print(f"\n--- {label} ---")
    for (a, b) in white_bands(im, ratio):
        xa, xb = xspan(im, a, b, is_white)
        print(f"  白块 y={a*s:6.1f} h={(b-a+1)*s:6.1f}pt  "
              f"x={xa*s:6.1f} w={(xb-xa+1)*s:6.1f}pt  "
              f"mL={xa*s:5.1f} mR={(W-1-xb)*s:5.1f}")


def probe_colored(path, label, ratio=0.20):
    im = load(path)
    W, H = im.size
    s = 402.0 / W
    px = im.load()
    need = int(W * ratio)
    bands, start = [], None
    for y in range(int(H * 0.04), H):
        c = sum(1 for x in range(W) if is_colored(*px[x, y][:3]))
        if c >= need and start is None:
            start = y
        elif c < need and start is not None:
            if y - start > 14:
                bands.append((start, y - 1))
            start = None
    print(f"\n--- {label} ---")
    for (a, b) in bands:
        xa, xb = xspan(im, a, b, is_colored)
        print(f"  色块 y={a*s:6.1f} h={(b-a+1)*s:6.1f}pt  "
              f"x={xa*s:6.1f} w={(xb-xa+1)*s:6.1f}pt  "
              f"mL={xa*s:5.1f} mR={(W-1-xb)*s:5.1f}")


if __name__ == "__main__":
    mode, ref, shot = sys.argv[1], sys.argv[2], sys.argv[3]
    fn = {"white": probe_white, "color": probe_colored}[mode]
    fn(ref, "参考图")
    fn(shot, "实现")
