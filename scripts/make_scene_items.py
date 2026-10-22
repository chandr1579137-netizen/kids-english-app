#!/usr/bin/env python3
"""给「听音找一找」生成透明底物品图（Resources/scenes/items/<word>.png）。

做法与 make_icons_transparent.py 相同：从四边向内泛洪，只清掉与画布边缘连通的背景，
被深色描边包住的内部浅色（羊毛、杯子里面）保留。
区别：平涂词图的底是米白纸纹（约 248,242,228），不是纯白，
所以「是不是背景」按与四边中位色的距离判断，而不是按「接近纯白」。

用法：
    python3 scripts/make_scene_items.py <scenes.json> <word-icons 目录> <输出目录>
    python3 scripts/make_scene_items.py <feed-pairs.json> <word-icons 目录> <输出目录> 512
第一个参数也可以是「喂小动物」的 feed-pairs.json：此时把每组的 animal 和 food 都抠出来。
第四个参数可选，是输出边长（默认 256）。
"""
import json
import sys
from collections import deque
from pathlib import Path
from statistics import median

from PIL import Image

SIDE = 256          # 输出边长
TOLERANCE = 42      # 与背景色的 RGB 距离（三通道差之和）小于它就算背景
PAD = 0.04          # 裁到内容后四周留白比例


def border_color(px, w, h):
    samples = []
    for x in range(0, w, 4):
        samples.append(px[x, 0]); samples.append(px[x, h - 1])
    for y in range(0, h, 4):
        samples.append(px[0, y]); samples.append(px[w - 1, y])
    return tuple(int(median(c[i] for c in samples)) for i in range(3))


def cut(src: Path, dst: Path):
    img = Image.open(src).convert("RGBA")
    w, h = img.size
    px = img.load()
    bg = border_color(px, w, h)

    def is_bg(p):
        return abs(p[0] - bg[0]) + abs(p[1] - bg[1]) + abs(p[2] - bg[2]) < TOLERANCE

    seen = bytearray(w * h)
    q = deque()
    for x in range(w):
        q.append((x, 0)); q.append((x, h - 1))
    for y in range(h):
        q.append((0, y)); q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h:
            continue
        i = y * w + x
        if seen[i]:
            continue
        seen[i] = 1
        p = px[x, y]
        if not is_bg(p):
            continue
        px[x, y] = (p[0], p[1], p[2], 0)
        q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))

    # 抗锯齿：紧贴透明区的一圈浅色像素降半透明，避免白边
    alpha = img.getchannel("A")
    a = alpha.load()
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            if a[x, y] and (not a[x - 1, y] or not a[x + 1, y] or not a[x, y - 1] or not a[x, y + 1]):
                if is_bg(px[x, y]) or sum(px[x, y][:3]) > 690:
                    a[x, y] = 110
    img.putalpha(alpha)

    box = img.getchannel("A").point(lambda v: 255 if v > 0 else 0).getbbox()
    if box is None:
        raise RuntimeError(f"{src.name}: 整张都被当成背景")
    img = img.crop(box)
    cw, ch = img.size
    side = int(max(cw, ch) * (1 + 2 * PAD))
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(img, ((side - cw) // 2, side - ch - int(side * PAD)), img)  # 底对齐：物品「站」在格子底边
    canvas.resize((SIDE, SIDE), Image.LANCZOS).save(dst)


def main():
    scenes_json, icons, out = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
    out.mkdir(parents=True, exist_ok=True)
    global SIDE
    if len(sys.argv) > 4:
        SIDE = int(sys.argv[4])
    data = json.loads(scenes_json.read_text())
    if isinstance(data, dict) and "pairs" in data:      # 喂小动物 feed-pairs.json
        words = sorted({w for p in data["pairs"] for w in (p["animal"], p["food"])})
    else:                                               # 听音找一找 scenes.json
        words = sorted({item["word"] for s in data for item in s["items"]})
    missing = []
    for word in words:
        name = word.replace(" ", "_")
        src = next((icons / f"{name}.{ext}" for ext in ("jpg", "png") if (icons / f"{name}.{ext}").exists()), None)
        if src is None:
            missing.append(word)
            continue
        cut(src, out / f"{name}.png")
    print(f"scene items: {len(words) - len(missing)} / {len(words)}")
    if missing:
        print("缺少词图:", missing)
        sys.exit(1)


if __name__ == "__main__":
    main()
