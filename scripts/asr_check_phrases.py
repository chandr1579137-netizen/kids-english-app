#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""「说一说」句子音频的识别核对：用 faster-whisper 把每句 mp3 转成文字，和 phrases.json 里的原句逐词比。

两个模型都要逐词一致才算过（small.en + medium.en，int8，temperature 0，beam 5，不给提示词）。
比对前统一大小写、去标点，连字符当空格（Bye-bye = bye bye），数字转英文；
OK/okay、Goodnight/Good night 这类只是写法不同的算一致。

用法：pip install faster-whisper
      python scripts/asr_check_phrases.py [--levels 1] [--out docs/daily-phrases/asr-L1.md]
"""
import argparse
import json
import pathlib
import re
import sys

from faster_whisper import WhisperModel

ROOT = pathlib.Path(__file__).absolute().parent.parent
PH = ROOT / "KidsEnglish" / "KidsEnglish" / "Resources" / "phrases"
MODELS = ["small.en", "medium.en"]
NUM = {"0": "zero", "1": "one", "2": "two", "3": "three", "4": "four", "5": "five", "6": "six",
       "7": "seven", "8": "eight", "9": "nine", "10": "ten", "11": "eleven", "12": "twelve"}


# 只是写法不同、读音一样的词：识别成哪种都算对
SAME = {"okay": "ok", "goodnight": "good night"}


def words(text: str) -> list[str]:
    t = text.lower().replace("-", " ").replace("’", "'")
    t = re.sub(r"[^a-z0-9' ]+", " ", t)
    out = []
    for w in t.split():
        out += SAME.get(NUM.get(w, w), NUM.get(w, w)).split()
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--levels", default="1")
    ap.add_argument("--out", default=None)
    args = ap.parse_args()
    wanted = {int(x) for x in args.levels.split(",")}
    data = json.loads((PH / "phrases.json").read_text(encoding="utf-8"))
    lines = [ln for lv in data["levels"] if lv["level"] in wanted for sc in lv["scenes"] for ln in sc["lines"]]

    results = {ln["id"]: {} for ln in lines}
    for name in MODELS:
        model = WhisperModel(name, device="cpu", compute_type="int8")
        for ln in lines:
            segs, _ = model.transcribe(str(PH / "audio" / ln["audio"]), language="en", beam_size=5,
                                       temperature=0.0, condition_on_previous_text=False)
            heard = " ".join(s.text.strip() for s in segs).strip()
            results[ln["id"]][name] = (heard, words(heard) == words(ln["en"]))
            print(f"{name:9} {ln['id']} {'OK ' if results[ln['id']][name][1] else 'BAD'} {ln['en']!r} -> {heard!r}",
                  flush=True)

    bad = [ln for ln in lines if not all(ok for _, ok in results[ln["id"]].values())]
    rows = ["| 句子 | 原句 | " + " | ".join(MODELS) + " |", "|---|---|" + "---|" * len(MODELS)]
    for ln in lines:
        cells = []
        for name in MODELS:
            heard, ok = results[ln["id"]][name]
            cells.append(("✓ " if ok else "✗ ") + heard.replace("|", "/"))
        rows.append(f"| {ln['id']} | {ln['en']} | " + " | ".join(cells) + " |")
    summary = f"共 {len(lines)} 句，两个模型都逐词一致 {len(lines) - len(bad)} 句，不一致 {len(bad)} 句。"
    md = "\n".join([f"# 「说一说」音频识别核对（L{','.join(map(str, sorted(wanted)))}）", "",
                    f"模型：{' + '.join(MODELS)}（faster-whisper，int8，temperature 0，beam 5，无提示词）。",
                    "比对前统一大小写、去标点，连字符当空格，数字转英文；OK/okay、Goodnight/Good night 算一致。", "", summary, "", *rows, ""])
    if args.out:
        (ROOT / args.out).write_text(md, encoding="utf-8")
    print(summary)
    for ln in bad:
        print("不一致:", ln["id"], ln["en"], {k: v[0] for k, v in results[ln["id"]].items()})
    return 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    raise SystemExit(main())
