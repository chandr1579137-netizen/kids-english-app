#!/usr/bin/env python3
"""把 ui-icons 里 PNG 的白色外圈背景改成透明。

为什么要做这件事
----------------
参考设计里，3D 图标是直接压在彩色卡片上的，没有白底方块。
我们拿到的资源是不透明白底，直接放上去会出现一块「白方贴纸」。

为什么用「边缘泛洪」而不是「全图去白」
------------------------------------
熊猫这类图标本身就是白的：如果全图把白色变透明，熊猫的脸会变成卡片底色。
从四边向内泛洪，只会清掉与画布边缘连通的那圈背景；
被深色轮廓包住的内部白色（熊猫脸、兔子肚子）会保留下来。

用法：
    python3 scripts/make_icons_transparent.py <ui-icons 目录>
"""

import sys
from collections import deque
from pathlib import Path

from PIL import Image

# 判定为「背景白」的阈值：三个通道都足够亮，且足够接近纯白
WHITE_MIN = 238
CHANNEL_SPREAD = 12


def is_background(pixel):
    r, g, b, a = pixel
    if a < 8:
        return True  # 已经是透明的
    if r < WHITE_MIN or g < WHITE_MIN or b < WHITE_MIN:
        return False
    return max(r, g, b) - min(r, g, b) <= CHANNEL_SPREAD


def clear_background(path):
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    px = img.load()

    visited = bytearray(w * h)
    queue = deque()

    for x in range(w):
        queue.append((x, 0))
        queue.append((x, h - 1))
    for y in range(h):
        queue.append((0, y))
        queue.append((w - 1, y))

    cleared = 0
    while queue:
        x, y = queue.popleft()
        if x < 0 or y < 0 or x >= w or y >= h:
            continue
        idx = y * w + x
        if visited[idx]:
            continue
        visited[idx] = 1
        pixel = px[x, y]
        if not is_background(pixel):
            continue
        px[x, y] = (0, 0, 0, 0)
        cleared += 1
        queue.append((x + 1, y))
        queue.append((x - 1, y))
        queue.append((x, y + 1))
        queue.append((x, y - 1))

    # 半透明白边（抗锯齿残留）：紧邻透明像素、且足够亮的像素按亮度给一点 alpha，
    # 否则边缘会留一圈白毛
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if not (r > 200 and g > 200 and b > 200):
                continue
            neighbours = (
                px[x - 1, y][3] if x > 0 else 0,
                px[x + 1, y][3] if x < w - 1 else 0,
                px[x, y - 1][3] if y > 0 else 0,
                px[x, y + 1][3] if y < h - 1 else 0,
            )
            if min(neighbours) == 0:
                px[x, y] = (r, g, b, 90)

    img.save(path, "PNG", optimize=True)
    return cleared


def main():
    if len(sys.argv) < 2:
        print("usage: make_icons_transparent.py <ui-icons dir>")
        return 1
    root = Path(sys.argv[1])
    files = sorted(root.glob("*.png"))
    if not files:
        print(f"no png in {root}")
        return 1
    total = 0
    for f in files:
        try:
            total += clear_background(f)
        except Exception as exc:  # 单个图标失败不影响构建
            print(f"skip {f.name}: {exc}")
    print(f"ui-icons: {len(files)} files, {total} background pixels cleared")
    return 0


if __name__ == "__main__":
    sys.exit(main())
