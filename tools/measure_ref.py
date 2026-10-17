# -*- coding: utf-8 -*-
"""从参考图量出各色块 bbox，换算成 pt。

参考图 1072px 宽，与 iPhone 16 Pro 截图 1206px 宽同比例(0.4621 vs 0.4600)，
因此参考图逻辑宽 = 402pt，1 ref px = 0.375pt。
"""
import sys
from PIL import Image

REF_W = 1072
PT = 402.0 / REF_W


def bbox_of(im, pred, region=None):
    W, H = im.size
    x0, y0, x1, y1 = region or (0, 0, W, H)
    px = im.load()
    minx, miny, maxx, maxy = W, H, -1, -1
    for y in range(y0, y1):
        for x in range(x0, x1):
            r, g, b = px[x, y][:3]
            if pred(r, g, b):
                if x < minx:
                    minx = x
                if x > maxx:
                    maxx = x
                if y < miny:
                    miny = y
                if y > maxy:
                    maxy = y
    if maxx < 0:
        return None
    return minx, miny, maxx, maxy


def report(name, bb):
    if not bb:
        print(f"{name:12s} 未找到")
        return
    x0, y0, x1, y1 = bb
    w, h = x1 - x0 + 1, y1 - y0 + 1
    print(
        f"{name:12s} px=({x0},{y0})-({x1},{y1}) {w}x{h}  "
        f"pt: x={x0*PT:.1f} y={y0*PT:.1f} w={w*PT:.1f} h={h*PT:.1f} "
        f"mL={x0*PT:.1f} mR={(REF_W-x1-1)*PT:.1f}"
    )


path = sys.argv[1]
im = Image.open(path).convert("RGB")
W, H = im.size
print("图:", path.split("/")[-1], im.size)

# 橙色计划卡（渐变橙）
report("计划卡", bbox_of(im, lambda r, g, b: r > 200 and 90 < g < 195 and b < 95, (0, 90, W, 900)))
# 绿色「开始学习」
report("开始学习", bbox_of(im, lambda r, g, b: g > 120 and r < 120 and b < 120, (0, 850, W, 1750)))
# 蓝色「巩固练习」
report("巩固练习", bbox_of(im, lambda r, g, b: b > 200 and r < 150 and g > 105, (0, 1050, W, 1950)))
