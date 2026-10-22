#!/usr/bin/env python3
"""一键渲染一首 App 儿歌（Windows，全自动，不用点界面）。

  python render_song.py song_001 --tools <qs1-tools 目录> --out <输出目录> [--keep-vocal] [--install]

步骤：make_song.py（乐谱 → ustx/mid/时间轴）→ OpenUtau 命令行唱人声（PR #2162 编译）
      → FluidSynth 弹伴奏（FluidR3_GM：钢琴 + 钢片琴）→ ffmpeg 混音（伴奏比人声低 9 dB，
      整体平均音量 -27.5 dB，限幅）→ <id>_sung.wav / .mp3（44.1 kHz，160 kbps）。
--install：把 mp3 拷到 App 的 KidsEnglish/KidsEnglish/Resources/song-audio/<id>.mp3（CI 打包时会再拷到 audio/songs/）。
依赖（装在 <tools> 下，不进仓库）：ou-build/OpenUtau.exe、Singers/<Hanami>、fluidsynth/、soundfont/FluidR3_GM.sf2；ffmpeg 在 PATH 里。
"""
import argparse, json, os, re, shutil, subprocess, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
TARGET_MEAN_DB = -27.5
ACCOMP_BELOW_VOCAL_DB = 9


def run(cmd, **kw):
    print("+", " ".join(str(c) for c in cmd))
    return subprocess.run(cmd, check=True, **kw)


def mean_db(wav):
    r = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(wav), "-af", "volumedetect", "-f", "null", "-"],
                       capture_output=True, text=True)
    return float(re.search(r"mean_volume: (-?[\d.]+) dB", r.stderr).group(1))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("song_id")
    ap.add_argument("--tools", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--diction", default=str(HERE / "diction.json"))
    ap.add_argument("--keep-vocal", action="store_true", help="另存纯人声 <id>_sung_vocal.wav（语音识别切句用）")
    ap.add_argument("--install", action="store_true")
    a = ap.parse_args()
    sid, tools, out = a.song_id, Path(a.tools), Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    work = out / f"_work_{sid}"; work.mkdir(exist_ok=True)

    run([sys.executable, str(HERE / "make_song.py"), sid, str(out), "--diction", a.diction])
    shutil.move(str(out / f"{sid}_accomp.mid"), work / "accomp.mid")
    vocal_end = json.loads((out / f"{sid}_timing.json").read_text(encoding="utf-8"))[-1]["end"]
    total = round(vocal_end + 2.0, 2)
    fade_st = round(total - 1.5, 2)

    (tools / "ou-build" / "Cache").mkdir(exist_ok=True)
    env = dict(os.environ, DOTNET_ROOT=os.environ.get("DOTNET_ROOT", str(Path.home() / ".dotnet")))
    run([str(tools / "ou-build" / "OpenUtau.exe"), "render", "--input", str(out / f"{sid}.ustx"),
         "--output", str(work / "vocal.wav"), "--singers-path", str(tools / "Singers")], env=env)

    fs = next((tools / "fluidsynth").rglob("fluidsynth.exe"))
    run([str(fs), "-ni", "-q", "-r", "44100", "-g", "0.5", "-R", "0", "-C", "0",
         "-F", str(work / "accomp.wav"), str(tools / "soundfont" / "FluidR3_GM.sf2"), str(work / "accomp.mid")])

    v, acc = mean_db(work / "vocal.wav"), mean_db(work / "accomp.wav")
    acc_gain = (v - ACCOMP_BELOW_VOCAL_DB) - acc
    run(["ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
         "-i", str(work / "vocal.wav"), "-i", str(work / "accomp.wav"), "-filter_complex",
         f"[0:a]aresample=44100,aformat=channel_layouts=stereo[v];"
         f"[1:a]aresample=44100,aformat=channel_layouts=stereo,volume={acc_gain:.2f}dB[a];"
         f"[v][a]amix=inputs=2:duration=longest:normalize=0,afade=t=out:st={fade_st}:d=1.5[m]",
         "-map", "[m]", "-t", f"{total}", str(work / "mix_raw.wav")])
    gain = TARGET_MEAN_DB - mean_db(work / "mix_raw.wav")
    wav, mp3 = out / f"{sid}_sung.wav", out / f"{sid}_sung.mp3"
    run(["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-i", str(work / "mix_raw.wav"),
         "-af", f"volume={gain:.2f}dB,alimiter=limit=0.89:level=false", "-ar", "44100", "-c:a", "pcm_s16le", str(wav)])
    run(["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-i", str(wav),
         "-c:a", "libmp3lame", "-b:a", "160k", "-ar", "44100", str(mp3)])
    if a.keep_vocal:
        shutil.copy(work / "vocal.wav", out / f"{sid}_sung_vocal.wav")
    if a.install:
        shutil.copy(mp3, REPO / "KidsEnglish/KidsEnglish/Resources/song-audio" / f"{sid}.mp3")
    print(json.dumps({"song": sid, "total_s": total, "vocal_mean_db": v, "accomp_gain_db": round(acc_gain, 2),
                      "master_gain_db": round(gain, 2), "final_mean_db": mean_db(wav)}))
    shutil.rmtree(work)


if __name__ == "__main__":
    main()
