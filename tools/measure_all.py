# -*- coding: utf-8 -*-
"""
全量测量 6 张参考图的关键尺寸。
参考图 1072×2320 px，对应 iPhone 16 Pro 402pt 逻辑宽：1 px = 0.375 pt
"""
import sys
from PIL import Image
from collections import Counter

PT = 402.0 / 1072


def bbox_of(im, pred, region=None):
    W, H = im.size
    x0, y0, x1, y1 = region or (0, 0, W, H)
    px = im.load()
    minx, miny, maxx, maxy = W, H, -1, -1
    for y in range(y0, y1):
        for x in range(x0, x1):
            if pred(*px[x, y][:3]):
                if x < minx: minx = x
                if x > maxx: maxx = x
                if y < miny: miny = y
                if y > maxy: maxy = y
    if maxx < 0: return None
    return minx, miny, maxx, maxy


def band_rows(im, pred, thresh, region=None):
    """按行扫描，返回 (y0,y1) 列表，要求每行匹配像素 >= thresh"""
    W, H = im.size
    x0, y0, x1, y1 = region or (0, 0, W, H)
    px = im.load()
    out = []
    for y in range(y0, y1):
        c = sum(1 for x in range(x0, x1) if pred(*px[x, y][:3]))
        out.append(c)
    res, start = [], None
    for y, c in enumerate(out, y0):
        if c >= thresh and start is None:
            start = y
        elif c < thresh and start is not None:
            if y - start > 4:
                res.append((start, y - 1))
            start = None
    if start is not None:
        res.append((start, y1 - 1))
    return res


def xspan(im, pred, y0, y1):
    W, _ = im.size
    px = im.load()
    minx, maxx = W, -1
    for y in range(y0, y1 + 1):
        for x in range(W):
            if pred(*px[x, y][:3]):
                if x < minx: minx = x
                if x > maxx: maxx = x
    return minx, maxx


def bg_color(im):
    """取顶部(避开状态栏)非白/非黑区域的背景主色"""
    c = Counter()
    px = im.load()
    W, H = im.size
    for y in range(100, 220):
        for x in range(W):
            r, g, b = px[x, y][:3]
            # 排除纯白、纯黑、近黑(状态栏文字/刘海)
            if max(r, g, b) - min(r, g, b) < 22 and not (r > 245 and g > 245 and b > 245) and not (r < 35 and g < 35 and b < 35):
                c[(r, g, b)] += 1
    return c.most_common(1)[0][0] if c else None


def measure(path, name):
    im = Image.open(path).convert('RGB')
    W, H = im.size
    print(f"\n{'='*60}")
    print(f"{name}  {path.split('/')[-1]}  {W}×{H}")
    col = bg_color(im)
    print(f"  背景主色 (近顶部): {col} #{col[0]:02X}{col[1]:02X}{col[2]:02X}" if col else "  背景主色未识别")

    # 水平边距：找最左侧出现大量非背景像素的列（避开状态栏）
    if col:
        tol = 18
        bg = lambda r, g, b: abs(r - col[0]) < tol and abs(g - col[1]) < tol and abs(b - col[2]) < tol
    else:
        bg = lambda r, g, b: r > 245 and g > 245 and b > 245

    px = im.load()
    counts = []
    for x in range(W):
        c = sum(1 for y in range(140, 350) if not bg(*px[x, y][:3]))
        counts.append(c)
    left = next((x for x, c in enumerate(counts) if c > 15), 0)
    right = next((x for x in range(W - 1, -1, -1) if counts[x] > 15), W - 1)
    print(f"  水平内容边距: L={left*PT:.1f}pt  R={(W-right-1)*PT:.1f}pt  内容宽={(right-left+1)*PT:.1f}pt")

    # 页面标题（深色大字，避开状态栏）
    dark = lambda r, g, b: r < 70 and g < 70 and b < 90
    tbands = band_rows(im, dark, 20, (0, 140, W, 420))
    if tbands:
        ty0, ty1 = tbands[0]
        tx0, tx1 = xspan(im, dark, ty0, ty1)
        print(f"  页面标题 bbox: y={ty0}-{ty1} h={(ty1-ty0+1)*PT:.1f}pt  x={tx0}-{tx1} w={(tx1-tx0+1)*PT:.1f}pt")

    return im, col


paths = [
    ("01 首页", r"C:/Users/Administrator/Desktop/新建文件夹/微信图片_20261014172305_639_24.png"),
    ("02 学习页", r"C:/Users/Administrator/Desktop/新建文件夹/微信图片_20261014172305_640_24.png"),
    ("03 单词卡", r"C:/Users/Administrator/Desktop/新建文件夹/微信图片_20261014172306_641_24.png"),
    ("04 巩固练习", r"C:/Users/Administrator/Desktop/新建文件夹/微信图片_20261014172306_642_24.png"),
    ("05 读短文", r"C:/Users/Administrator/Desktop/新建文件夹/微信图片_20261014172306_643_24.png"),
    ("06 我的", r"C:/Users/Administrator/Desktop/新建文件夹/微信图片_20261014172306_644_24.png"),
]

for name, p in paths:
    measure(p, name)
