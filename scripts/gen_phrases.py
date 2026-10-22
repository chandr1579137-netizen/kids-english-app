#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""「说一说」口语课资源生成：数据 + 配图 + 配音。

输入（都在仓库里）：
  docs/daily-phrases/phrases-levels.json   7 级 / 38 场景 / 249 句（产品经理定稿）
  docs/daily-phrases/images-plan.json      每句配图怎么来：new / reuse / code
输入（不在仓库里，--art 指定目录）：
  L1-x-yy.jpg            新画的句子图（assets/daily-phrases 分支 qoder-art/L1）；有就优先用
  avatar_<speaker>.jpg   说话人头像
  bg_<name>.webp         场景背景

输出（两份 phrases.json 保持一致，CI 会校验）：
  KidsEnglish/KidsEnglish/Resources/phrases/phrases.json
  KidsEnglish/Resources/phrases/phrases.json
  KidsEnglish/KidsEnglish/Resources/phrases/img/<line id>.jpg   新图 / 背景（768×768 JPEG q85）
  KidsEnglish/KidsEnglish/Resources/phrases/avatars/<speaker>.jpg（256×256）
  KidsEnglish/KidsEnglish/Resources/phrases/audio/<line id>.mp3  每句一条，按说话人分声音
  KidsEnglish/KidsEnglish/Resources/phrases/audio/prompt_*.mp3   旁白（Aria）：轮到你、表扬

音量和单词发音对齐：平均 -27.5 dB，24 kHz 单声道 48 kbps。慢速不另生成，
App 里和单词一样用 AVPlayer 变速（0.75 倍）。

用法：python scripts/gen_phrases.py --art <素材目录> [--levels 1]
"""
import argparse
import asyncio
import json
import pathlib
import re
import subprocess
import sys
import tempfile

import edge_tts
from edge_tts import data_classes
from PIL import Image

# 不用 resolve()：在 subst 短盘符下运行时它会还原成超长路径（Windows 260 字符限制）
ROOT = pathlib.Path(__file__).absolute().parent.parent
DOCS = ROOT / "docs" / "daily-phrases"
RES = ROOT / "KidsEnglish" / "KidsEnglish" / "Resources" / "phrases"
MIRROR = ROOT / "KidsEnglish" / "Resources" / "phrases"
OVERRIDES = ROOT / "assets" / "word-icons-overrides"

TARGET_MEAN_DB = -27.5

# 说话人 → 名字、声音。Tom 用童声降 8% 音调，和 Amy 区分开（试听样音 tom_ana_pitch-8）。
CHARACTERS = {
    "tom": ("Tom", "汤姆", "en-US-AnaNeural", "-8%"),
    "amy": ("Amy", "艾米", "en-US-AnaNeural", "+0%"),
    "mom": ("Mom", "妈妈", "en-US-AriaNeural", "+0%"),
    "dad": ("Dad", "爸爸", "en-US-GuyNeural", "+0%"),
    "teacher": ("Teacher", "老师", "en-US-JennyNeural", "+0%"),
    "grandma": ("Grandma", "奶奶", "en-US-MichelleNeural", "+0%"),
    "grandpa": ("Grandpa", "爷爷", "en-US-ChristopherNeural", "+0%"),
    "farmer": ("Farmer", "农民叔叔", "en-US-EricNeural", "+0%"),
    "staff": ("Staff", "动物园阿姨", "en-US-EmmaNeural", "+0%"),
}

# 旁白：全 App 统一的 Aria。孩子不识字，提示全靠声音。
PROMPTS = {
    "prompt_listen": "Listen!",
    "prompt_say": "Your turn! Say it!",
    "prompt_again": "Say it with me!",
    "prompt_watch": "Let's watch!",
    "prompt_turn": "Now you say it!",
    "prompt_great": "Great job!",
    "prompt_well": "Well done!",
    "prompt_yay": "Yay!",
    "prompt_done": "You did it!",
}

# 代码画的卡片：images-plan 里的 code_kind + 句子 → App 里的画法名
CODE_CARDS = {
    "L1-2-01": "sunrise",
    "L1-5-01": "afternoon",
    "L1-5-06": "tomorrow",
    "L1-6-01": "evening",
    "L1-6-02": "night",
}

_orig = data_classes.TTSConfig.validate_string_param


def _validate(name, value, pattern):
    # edge-tts 只放行 ±NHz；服务端 SSML 本身支持 ±N%（重新合成，语速不变）
    if name == "pitch" and re.match(r"^[+-]\d+%$", value):
        return value
    return _orig(name, value, pattern)


data_classes.TTSConfig.validate_string_param = staticmethod(_validate)


def mean_db(path: pathlib.Path) -> float:
    r = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(path), "-af", "volumedetect", "-f", "null", "-"],
                       capture_output=True, text=True)
    return float(re.search(r"mean_volume: (-?[\d.]+) dB", r.stderr).group(1))


async def tts(text: str, voice: str, pitch: str, out: pathlib.Path) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        raw = pathlib.Path(tmp) / "raw.mp3"
        await edge_tts.Communicate(text, voice, pitch=pitch).save(str(raw))
        gain = TARGET_MEAN_DB - mean_db(raw)
        subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(raw),
                        "-af", f"volume={gain:.2f}dB,alimiter=limit=0.89:level=false",
                        "-ar", "24000", "-ac", "1", "-b:a", "48k", str(out)], check=True)


def square(src: pathlib.Path, out: pathlib.Path, side: int) -> None:
    with Image.open(src) as im:
        im = im.convert("RGB")
        w, h = im.size
        s = min(w, h)
        im = im.crop(((w - s) // 2, (h - s) // 2, (w - s) // 2 + s, (h - s) // 2 + s))
        im.resize((side, side), Image.LANCZOS).save(out, "JPEG", quality=85, optimize=True)


def picture_for(line_id: str, plan: dict, art: pathlib.Path) -> dict:
    """每句配图三选一：image（新图/背景，打包进 phrases/img）、icon（现成词图）、code（代码画）。"""
    if line_id in CODE_CARDS:
        icons = [i["word"] for i in plan.get("code_icons", [])]
        return {"code": CODE_CARDS[line_id], **({"codeIcon": icons[0]} if icons else {})}
    decision = plan["decision"]
    # 方案里「勉强能用」的复用图（juice 只画了果汁…），Qoder 另画了专属图的，优先用专属图
    if decision == "new" or (art / f"{line_id}.jpg").exists():
        src = art / f"{line_id}.jpg"
        if not src.exists():
            raise SystemExit(f"缺新图：{src}")
        square(src, RES / "img" / f"{line_id}.jpg", 768)
        return {"image": f"{line_id}.jpg"}
    if decision == "reuse":
        word = plan["reuse_word"]
        if word.startswith("bg_"):
            src = art / f"{word}.webp"
            if not src.exists():
                raise SystemExit(f"缺背景：{src}")
            square(src, RES / "img" / f"{line_id}.jpg", 768)
            return {"image": f"{line_id}.jpg"}
        if not (OVERRIDES / f"{word}.jpg").exists():
            raise SystemExit(f"{line_id}: 复用的词图 {word}.jpg 不在 word-icons-overrides 里")
        return {"icon": word}
    raise SystemExit(f"{line_id}: 未知配图方式 {decision}（code 卡要先写进 CODE_CARDS）")


async def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--art", required=True, type=pathlib.Path)
    ap.add_argument("--levels", default="1", help="逗号分隔，如 1 或 1,2")
    args = ap.parse_args()
    levels_wanted = {int(x) for x in args.levels.split(",")}

    src = json.loads((DOCS / "phrases-levels.json").read_text(encoding="utf-8"))
    plan = {p["line_id"]: p for p in json.loads((DOCS / "images-plan.json").read_text(encoding="utf-8"))["lines"]}
    for d in ("img", "avatars", "audio"):
        (RES / d).mkdir(parents=True, exist_ok=True)

    levels, speakers = [], set()
    for lv in src["levels"]:
        if lv["level"] not in levels_wanted:
            continue
        scenes = []
        for sc in lv["scenes"]:
            lines = []
            for i, ln in enumerate(sc["lines"], 1):
                line_id = f"{sc['id']}-{i:02d}"
                p = plan[line_id]
                assert p["en"] == ln["en"], f"{line_id}: images-plan 和 phrases-levels 的句子对不上"
                speakers.add(ln["speaker"])
                out = RES / "audio" / f"{line_id}.mp3"
                _, _, voice, pitch = CHARACTERS[ln["speaker"]]
                await tts(ln["en"], voice, pitch, out)
                lines.append({"id": line_id, "speaker": ln["speaker"], "en": ln["en"], "zh": ln["zh"],
                              "audio": out.name, **picture_for(line_id, p, args.art)})
                print(f"{line_id} {ln['speaker']:8} {ln['en']}")
            scenes.append({"id": sc["id"], "titleZh": sc["title_zh"], "titleEn": sc["title_en"], "lines": lines})
        levels.append({"level": lv["level"], "titleZh": lv["title_zh"], "scenes": scenes})

    characters = []
    for sid in sorted(speakers):
        en, zh, _, _ = CHARACTERS[sid]
        square(args.art / f"avatar_{sid}.jpg", RES / "avatars" / f"{sid}.jpg", 256)
        characters.append({"id": sid, "nameEn": en, "nameZh": zh, "avatar": f"{sid}.jpg"})

    for name, text in PROMPTS.items():
        await tts(text, "en-US-AriaNeural", "+0%", RES / "audio" / f"{name}.mp3")

    data = {"version": 1, "characters": characters, "levels": levels}
    text = json.dumps(data, ensure_ascii=False, indent=1) + "\n"
    (RES / "phrases.json").write_text(text, encoding="utf-8")
    MIRROR.mkdir(parents=True, exist_ok=True)
    (MIRROR / "phrases.json").write_text(text, encoding="utf-8")
    n = sum(len(s["lines"]) for lv in levels for s in lv["scenes"])
    print(f"phrases.json: {len(levels)} 级 / {sum(len(lv['scenes']) for lv in levels)} 场景 / {n} 句")
    return 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    raise SystemExit(asyncio.run(main()))
