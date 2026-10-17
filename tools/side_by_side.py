#!/usr/bin/env python3
"""把参考图和实际渲染截图并排拼在一起，方便逐页对照。

用法：
    python3 tools/side_by_side.py <参考图目录> <截图目录> <输出目录>
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw

# 参考图文件名 → 截图文件名（顺序即展示顺序）
PAIRS = [
    ("微信图片_20261014172305_639_24.png", "01-learn.png", "01 首页"),
    ("微信图片_20261014172305_640_24.png", "06-study.png", "02 学习页"),
    ("微信图片_20261014172306_641_24.png", "02-cards.png", "03 单词卡"),
    ("微信图片_20261014172306_642_24.png", "07-games.png", "04 巩固练习"),
    ("微信图片_20261014172306_643_24.png", "03-read.png", "05 读短文"),
    ("微信图片_20261014172306_644_24.png", "05-profile.png", "06 我的"),
]

TARGET_H = 1400
GAP = 24
LABEL_H = 44


def fit(path, height):
    img = Image.open(path).convert("RGB")
    ratio = height / img.height
    return img.resize((int(img.width * ratio), height), Image.LANCZOS)


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        return 1
    ref_dir, shot_dir, out_dir = (Path(p) for p in sys.argv[1:4])
    out_dir.mkdir(parents=True, exist_ok=True)

    for ref_name, shot_name, label in PAIRS:
        ref_path = ref_dir / ref_name
        shot_path = shot_dir / shot_name
        if not ref_path.exists() or not shot_path.exists():
            print(f"skip {label}: missing file")
            continue

        left = fit(ref_path, TARGET_H)
        right = fit(shot_path, TARGET_H)
        width = left.width + GAP + right.width
        canvas = Image.new("RGB", (width, TARGET_H + LABEL_H), (250, 248, 245))
        canvas.paste(left, (0, LABEL_H))
        canvas.paste(right, (left.width + GAP, LABEL_H))

        draw = ImageDraw.Draw(canvas)
        draw.text((8, 14), f"{label}   LEFT = reference   RIGHT = current", fill=(40, 40, 60))
        draw.line(
            [(left.width + GAP // 2, LABEL_H), (left.width + GAP // 2, TARGET_H + LABEL_H)],
            fill=(210, 205, 198), width=2,
        )

        out = out_dir / f"{label.replace(' ', '-')}.png"
        canvas.save(out)
        print(f"wrote {out}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
