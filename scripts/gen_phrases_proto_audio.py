#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""「日常口语」原型（proto/daily-phrases）的句子音频。

读 KidsEnglish/KidsEnglish/Resources/phrases-proto.json，按每句的 voice / pitch
用 edge-tts 生成 Resources/phrase-audio/<audio>.mp3：
  Mom = en-US-AriaNeural，Dad = en-US-GuyNeural，Tom = en-US-AnaNeural 降 10% 音调。

edge-tts 自带的参数校验只接受 ±NHz；服务端 SSML 的 <prosody pitch> 本身支持 ±N%，
这里放行百分比写法。改音调是重新合成，不是重采样，所以语速不变。

用法：pip install edge-tts && python scripts/gen_phrases_proto_audio.py
"""
import asyncio
import json
import pathlib
import re
import sys

import edge_tts
from edge_tts import data_classes

_orig = data_classes.TTSConfig.validate_string_param


def _validate(name, value, pattern):
    if name == "pitch" and re.match(r"^[+-]\d+%$", value):
        return value
    return _orig(name, value, pattern)


data_classes.TTSConfig.validate_string_param = staticmethod(_validate)

ROOT = pathlib.Path(__file__).resolve().parent.parent
RES = ROOT / "KidsEnglish" / "KidsEnglish" / "Resources"


async def main() -> int:
    data = json.loads((RES / "phrases-proto.json").read_text(encoding="utf-8"))
    out_dir = RES / "phrase-audio"
    out_dir.mkdir(exist_ok=True)
    for line in data["scene"]["lines"]:
        out = out_dir / line["audio"]
        await edge_tts.Communicate(line["en"], line["voice"], pitch=line["pitch"]).save(str(out))
        print(f"{out.name}  {line['voice']} {line['pitch']}  {line['en']}")
    return 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    raise SystemExit(asyncio.run(main()))
