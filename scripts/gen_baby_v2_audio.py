#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成启蒙模式 v2（「每天一课更好玩」）所需的预合成音频：

1. baby_sent_<word>.mp3：全量 243 个词的例句配音（Tom：en-US-AnaNeural 降调 8%）
2. baby_chant_<word>.mp3：每个词的节奏 chant（100 BPM 四拍鼓点 + Tom 读 "<Word>, <word>, <word>! <Sentence>"）
3. baby_cmd_<word>.mp3：「跟我做」游戏的动作/身体指令配音（Tom）
4. tom_*.mp3：Tom 向导每一步的开场语音

输出目录：KidsEnglish/KidsEnglish/Resources/phrases/audio/（Xcode 文件夹引用，自动进包）
音量标准：与全 App 一致，平均 -27.5 dB，24 kHz 单声道 48 kbps。
"""
import asyncio
import json
import math
import pathlib
import re
import struct
import subprocess
import sys
import tempfile
import wave

import edge_tts
from edge_tts import data_classes

ROOT = pathlib.Path(__file__).absolute().parent.parent
BABY_JSON = ROOT / "KidsEnglish" / "KidsEnglish" / "Resources" / "baby-path.json"
OUT_DIR = ROOT / "KidsEnglish" / "KidsEnglish" / "Resources" / "phrases" / "audio"

TARGET_MEAN_DB = -27.5
TOM_VOICE = "en-US-AnaNeural"
TOM_PITCH = "-8%"

_orig = data_classes.TTSConfig.validate_string_param


def _validate(name, value, pattern):
    if name == "pitch" and re.match(r"^[+-]\d+%$", value):
        return value
    return _orig(name, value, pattern)


data_classes.TTSConfig.validate_string_param = staticmethod(_validate)

TOM_GUIDE_PROMPTS = {
    "tom_lets_sing": "Let's sing!",
    "tom_lets_review": "Do you remember?",
    "tom_lets_learn": "Let's learn!",
    "tom_lets_play": "Let's play!",
    "tom_say_with_me": "Say it with me!",
    "tom_your_turn": "Your turn!",
    "tom_you_did_it": "You did it!",
    "tom_pick_bubble": "Pop a bubble!",
}

# 「跟我做」（G5）固定指令：身体包用 Touch your ___!（teeth 用 Show me your teeth!），动作包用祈使句
FOLLOW_ME_COMMANDS = {
    # body
    "eye": "Touch your eye!",
    "ear": "Touch your ear!",
    "nose": "Touch your nose!",
    "mouth": "Touch your mouth!",
    "hand": "Touch your hand!",
    "foot": "Touch your foot!",
    "head": "Touch your head!",
    "hair": "Touch your hair!",
    # body-2
    "arm": "Touch your arm!",
    "leg": "Touch your leg!",
    "face": "Touch your face!",
    "teeth": "Show me your teeth!",
    "finger": "Touch your finger!",
    "knee": "Touch your knee!",
    # actions
    "run": "Run!",
    "jump": "Jump!",
    "eat": "Eat!",
    "drink": "Drink!",
    "sleep": "Go to sleep!",
    "look": "Look at me!",
    "clap": "Clap your hands!",
    "wash": "Wash your hands!",
    # actions-2
    "swim": "Swim!",
    "fly": "Fly like a bird!",
    "sit": "Sit down!",
    "stand": "Stand up!",
    "sing": "Sing!",
    "dance": "Dance!",
    "read": "Read a book!",
    "draw": "Draw a picture!",
    "walk": "Walk!",
    "climb": "Climb!",
    # actions-3
    "kick": "Kick the ball!",
    "throw": "Throw the ball!",
    "catch": "Catch the ball!",
    "hug": "Give a big hug!",
    "kiss": "Blow a kiss!",
    "smile": "Smile!",
    "laugh": "Laugh!",
    "cry": "Don't cry!",
    "cook": "Let's cook!",
    "clean": "Clean up!",
}


def make_drum_loop_wav(path: pathlib.Path, duration_sec: float = 12.0, sr: int = 24000) -> None:
    """合成一段温和的 100 BPM 四拍幼儿园鼓点（1、3 拍软木鱼低音，2、4 拍清脆木梆子）。"""
    beat_sec = 60.0 / 100.0  # 0.6s 一拍
    total_samples = int(duration_sec * sr)
    samples = []
    for i in range(total_samples):
        t = i / sr
        beat_idx = int(t / beat_sec) % 4
        bt = t % beat_sec
        val = 0.0
        if beat_idx in (0, 2):
            # 温暖低音鼓点
            if bt < 0.14:
                freq = 135.0 * math.exp(-bt * 14.0) + 55.0
                env = math.exp(-bt * 24.0)
                val += 0.38 * env * math.sin(2 * math.pi * freq * bt)
        else:
            # 2、4 拍轻快木鱼/拍手质感
            if bt < 0.09:
                freq = 720.0 if beat_idx == 1 else 860.0
                env = math.exp(-bt * 45.0)
                val += 0.25 * env * math.sin(2 * math.pi * freq * bt)
        samples.append(int(max(-1.0, min(1.0, val)) * 32767))
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        wf.writeframes(struct.pack(f"<{len(samples)}h", *samples))


def mean_db(path: pathlib.Path) -> float:
    r = subprocess.run(
        ["ffmpeg", "-hide_banner", "-i", str(path), "-af", "volumedetect", "-f", "null", "-"],
        capture_output=True,
        text=True,
    )
    m = re.search(r"mean_volume: (-?[\d.]+) dB", r.stderr)
    return float(m.group(1)) if m else -27.5


async def synth_tom(text: str, out: pathlib.Path, drum_wav: pathlib.Path | None = None) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        raw = pathlib.Path(tmp) / "raw.mp3"
        await edge_tts.Communicate(text, TOM_VOICE, pitch=TOM_PITCH, rate="+0%").save(str(raw))
        if drum_wav is None:
            gain = TARGET_MEAN_DB - mean_db(raw)
            subprocess.run(
                [
                    "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
                    "-i", str(raw),
                    "-af", f"volume={gain:.2f}dB,alimiter=limit=0.89:level=false",
                    "-ar", "24000", "-ac", "1", "-b:a", "48k",
                    str(out),
                ],
                check=True,
            )
        else:
            # 鼓点垫底（前奏 0.6s 一拍 + 人声 + 尾音 0.6s），人声比伴奏响 8 dB 以上
            mixed = pathlib.Path(tmp) / "mixed.wav"
            subprocess.run(
                [
                    "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
                    "-i", str(raw),
                    "-i", str(drum_wav),
                    "-filter_complex",
                    "[0:a]adelay=600|600,apad=pad_dur=0.6[v];"
                    "[1:a]volume=0.35[d];"
                    "[v][d]amix=inputs=2:duration=first:dropout_transition=0",
                    "-ar", "24000", "-ac", "1",
                    str(mixed),
                ],
                check=True,
            )
            gain = TARGET_MEAN_DB - mean_db(mixed)
            subprocess.run(
                [
                    "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
                    "-i", str(mixed),
                    "-af", f"volume={gain:.2f}dB,alimiter=limit=0.89:level=false",
                    "-ar", "24000", "-ac", "1", "-b:a", "48k",
                    str(out),
                ],
                check=True,
            )


async def main() -> int:
    redo = "--redo" in sys.argv
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    data = json.loads(BABY_JSON.read_text(encoding="utf-8"))

    with tempfile.TemporaryDirectory() as tmp:
        drum_wav = pathlib.Path(tmp) / "drum.wav"
        make_drum_loop_wav(drum_wav, duration_sec=14.0)

        tasks = []
        sem = asyncio.Semaphore(12)

        async def job(text: str, out: pathlib.Path, with_drum: bool = False):
            if out.exists() and not redo:
                return
            async with sem:
                for attempt in range(3):
                    try:
                        await synth_tom(text, out, drum_wav if with_drum else None)
                        return
                    except Exception as e:
                        if attempt == 2:
                            raise
                        await asyncio.sleep(1.0)

        # 1. Tom 向导开场语音
        for name, text in TOM_GUIDE_PROMPTS.items():
            tasks.append(job(text, OUT_DIR / f"{name}.mp3", False))

        # 2. 「跟我做」指令语音
        for word, cmd in FOLLOW_ME_COMMANDS.items():
            tasks.append(job(cmd, OUT_DIR / f"baby_cmd_{word}.mp3", False))

        # 3. 243 个词的例句语音 & chant 语音
        for pack in data["packs"]:
            sentences = pack.get("sentences") or {}
            for w in pack["words"]:
                sent = sentences[w]
                cap = w.capitalize()
                tasks.append(job(sent, OUT_DIR / f"baby_sent_{w}.mp3", False))
                chant_text = f"{cap}, {w}, {w}! {sent}"
                tasks.append(job(chant_text, OUT_DIR / f"baby_chant_{w}.mp3", True))

        print(f"开始合成 {len(tasks)} 条音频...")
        await asyncio.gather(*tasks)

    print("全部启蒙模式 v2 音频生成完成！")
    return 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    raise SystemExit(asyncio.run(main()))
