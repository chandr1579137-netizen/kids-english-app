#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成自然拼读阶段 4（Group 2: c, e, h, r, m, d）核心顺口溜音频与引导语音，并用 faster-whisper 双模型核验"""
import asyncio
import pathlib
import re
import subprocess
import tempfile
import edge_tts
from edge_tts import data_classes
from faster_whisper import WhisperModel

ROOT = pathlib.Path("K:/kids-english-app") if pathlib.Path("K:/kids-english-app").exists() else pathlib.Path(__file__).parent.parent
OUT = ROOT / "KidsEnglish" / "KidsEnglish" / "Resources" / "phrases" / "audio"
TARGET_MEAN_DB = -27.5
TOM_VOICE = "en-US-AnaNeural"
TOM_PITCH = "-8%"

_orig = data_classes.TTSConfig.validate_string_param
def _validate(name, value, pattern):
    if name == "pitch" and re.match(r"^[+-]\d+%$", value):
        return value
    return _orig(name, value, pattern)
data_classes.TTSConfig.validate_string_param = staticmethod(_validate)

def mean_db(path):
    r = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(path), "-af", "volumedetect", "-f", "null", "-"],
                       capture_output=True, text=True)
    return float(re.search(r"mean_volume: (-?[\d.]+) dB", r.stderr).group(1))

async def tts(text, out_path):
    with tempfile.TemporaryDirectory() as tmp:
        raw = pathlib.Path(tmp) / "raw.mp3"
        await edge_tts.Communicate(text, TOM_VOICE, pitch=TOM_PITCH).save(str(raw))
        gain = TARGET_MEAN_DB - mean_db(raw)
        subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(raw),
                        "-af", f"volume={gain:.2f}dB,alimiter=limit=0.89:level=false",
                        "-ar", "24000", "-ac", "1", "-b:a", "48k", str(out_path)], check=True)
    print(f"Generated {out_path.name}")

AUDIO_TASKS = [
    ("phonics_chant_c.mp3", "Cat, cat, cute little cat!"),
    ("phonics_chant_e.mp3", "Egg, egg, crack the egg!"),
    ("phonics_chant_h.mp3", "Hat, hat, put on your hat!"),
    ("phonics_chant_r.mp3", "Rabbit, rabbit, running rabbit!"),
    ("phonics_chant_m.mp3", "Monkey, monkey, merry little monkey!"),
    ("phonics_chant_d.mp3", "Dog, dog, dancing happy dog!"),
    ("tom_phonics_group2.mp3", "Welcome to Group 2! Let us learn more letter sounds!"),
]

async def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for filename, text in AUDIO_TASKS:
        out_file = OUT / filename
        await tts(text, out_file)

    print("\n--- 启动 faster-whisper 双模型识别核验 ---")
    models = {
        "small.en": WhisperModel("small.en", device="cpu", compute_type="int8"),
        "medium.en": WhisperModel("medium.en", device="cpu", compute_type="int8")
    }

    for filename, expected in AUDIO_TASKS:
        out_file = OUT / filename
        print(f"\n核验文件: {filename}")
        print(f"标称文本: {expected}")
        for mname, m in models.items():
            segs, _ = m.transcribe(str(out_file), temperature=0.0, beam_size=5)
            hyp = " ".join(s.text.strip() for s in segs)
            print(f"[{mname}]: {hyp}")

if __name__ == "__main__":
    asyncio.run(main())
