# -*- coding: utf-8 -*-
"""量「选词书」卡片块：列分组、行高、边距，两图同口径。"""
import sys
from PIL import Image


def load(p):
    return Image.open(p).convert("RGB")


def sat(r, g, b):
    """饱和色：排除暖米/白/灰"""
    mx, mn = max(r, g, b), min(r, g, b)
    return (mx - mn) > 55 and mx > 120


def col_groups(im, y0, y1, thresh=30, minw=10):
    W, _ = im.size
    px = im.load()
    counts = []
    for x in range(W):
        c = sum(1 for y in range(y0, y1) if sat(*px[x, y][:3]))
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


def row_extent(im, x0, x1, y0, y1, thresh=8):
    px = im.load()
    rows = [y for y in range(y0, y1)
            if sum(1 for x in range(x0, x1) if sat(*px[x, y][:3])) >= thresh]
    return (rows[0], rows[-1]) if rows else None


def probe(path, label):
    im = load(path)
    W, H = im.size
    s = 402.0 / W
    print(f"\n--- {label} {W}x{H} 1px={s:.4f}pt ---")

    # 找卡片块：整幅按行扫饱和色，取最大的一段连续行（排除计划卡和 CTA）
    px = im.load()
    rows = []
    for y in range(int(H * 0.25), int(H * 0.85)):
        c = sum(1 for x in range(W) if sat(*px[x, y][:3]))
        rows.append((y, c))
    bands, start = [], None
    for y, c in rows:
        if c >= 40 and start is None:
            start = y
        elif c < 40 and start is not None:
            if y - start > 20:
                bands.append((start, y - 1))
            start = None
    if start is not None:
        bands.append((start, rows[-1][0]))

    for (a, b) in bands:
        groups = col_groups(im, a, b)
        if len(groups) < 3:
            continue
        print(f"  行带 y={a*s:.1f}..{b*s:.1f}  h={(b-a+1)*s:.1f}pt  列数={len(groups)}")
        for i, (gx0, gx1) in enumerate(groups):
            print(f"    卡{i+1}: x={gx0*s:.1f} w={(gx1-gx0+1)*s:.1f}pt  "
                  f"mL={gx0*s:.1f} mR={(W-1-gx1)*s:.1f}")


probe(sys.argv[1], "参考图")
probe(sys.argv[2], "实现")
