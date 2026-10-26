import asyncio
import math
import pathlib
import re
import struct
import subprocess
import tempfile
import wave
import edge_tts
from edge_tts import data_classes

ROOT = pathlib.Path(__file__).absolute().parent.parent
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

def make_drum_beat(out_path):
    # 合成温和的小木鼓敲击音（80ms 快速衰减低频脉冲）
    sample_rate = 24000
    duration = 0.18
    num_samples = int(sample_rate * duration)
    with tempfile.TemporaryDirectory() as tmp:
        wav_path = pathlib.Path(tmp) / "drum.wav"
        with wave.open(str(wav_path), "w") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(sample_rate)
            frames = bytearray()
            for i in range(num_samples):
                t = i / sample_rate
                # 初始频率 160Hz 快速衰减至 80Hz
                freq = 80 + 80 * math.exp(-t * 25)
                amp = math.exp(-t * 18)
                val = int(32767 * 0.75 * amp * math.sin(2 * math.pi * freq * t))
                frames.extend(struct.pack("<h", max(-32767, min(32767, val))))
            w.writeframes(frames)
        subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(wav_path),
                        "-ar", "24000", "-ac", "1", "-b:a", "48k", str(out_path)], check=True)
    print(f"Generated {out_path.name}")

async def main():
    await tts("Do they sound the same?", OUT / "tom_do_they_rhyme.mp3")
    await tts("Clap with me!", OUT / "tom_clap_with_me.mp3")
    make_drum_beat(OUT / "drum_beat.mp3")

if __name__ == "__main__":
    asyncio.run(main())
