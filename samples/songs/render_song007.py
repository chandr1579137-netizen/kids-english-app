#!/usr/bin/env python3
"""一键渲染 song_007 真唱样品（Windows，全自动，无需点界面）。

  python render_song007.py --tools <qs1-tools 目录> --out <输出目录> [--bpm 84] [--tag ""]
    例：--bpm 101 --tag _A_101bpm → song_007_sung_A_101bpm.wav/.mp3（只改速度，重新合成，音高不变）

依赖（都装在 <tools> 下，不进仓库）：
  ou-build/OpenUtau.exe      由 OpenUtau PR #2162（headless render）编译
  Singers/<Hanami>           Hoshino Hanami ~AI❤dol~ for DiffSinger v1.0
  fluidsynth/.../fluidsynth.exe, soundfont/FluidR3_GM.sf2
  ffmpeg 在 PATH 里
"""
import argparse, json, os, re, shutil, subprocess, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
TARGET_MEAN_DB = -27.5      # 与 App 现有音频一致（commit 88ce0dc：统一到 -27.5 dBFS）
ACCOMP_BELOW_VOCAL_DB = 9   # 伴奏比人声低 9 dB（要求 ≥ 6 dB）


def run(cmd, **kw):
    print("+", " ".join(str(c) for c in cmd))
    return subprocess.run(cmd, check=True, **kw)


def mean_db(wav):
    r = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(wav), "-af", "volumedetect", "-f", "null", "-"],
                       capture_output=True, text=True)
    return float(re.search(r"mean_volume: (-?[\d.]+) dB", r.stderr).group(1))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tools", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--bpm", type=float, default=84)
    ap.add_argument("--tag", default="")
    ap.add_argument("--diction", default=None, help="吐字表 JSON，传给 make_song007.py")
    ap.add_argument("--keep-vocal", action="store_true", help="另存纯人声 <name>_vocal.wav（用来做语音识别核对）")
    ap.add_argument("--singer", default="Hoshino Hanami ~AIdol~ for DiffSinger v1.0")
    a = ap.parse_args()
    tools, out = Path(a.tools), Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    work = out / "_work"; work.mkdir(exist_ok=True)

    # 1. 乐谱 → .ustx / .mid / 伴奏 .mid / 时间轴
    tag = a.tag
    run([sys.executable, str(HERE / "make_song007.py"), str(out), a.singer, "--bpm", f"{a.bpm:g}", "--tag", tag]
        + (["--diction", a.diction] if a.diction else []))
    shutil.move(str(out / f"song_007_accomp{tag}.mid"), work / "song_007_accomp.mid")
    vocal_end = json.loads((out / f"song_007{tag}_timing.json").read_text(encoding="utf-8"))[-1]["end"]
    total = round(vocal_end + 2.0, 2)        # 84 BPM: 40.0 + 2 = 42 s（与原样品相同）
    fade_st = round(total - 1.5, 2)

    # 2. OpenUtau 命令行渲染人声（PR #2162）
    (tools / "ou-build" / "Cache").mkdir(exist_ok=True)   # headless 模式不会自己建缓存目录
    env = dict(os.environ, DOTNET_ROOT=os.environ.get("DOTNET_ROOT", str(Path.home() / ".dotnet")))
    run([str(tools / "ou-build" / "OpenUtau.exe"), "render",
         "--input", str(out / f"song_007{tag}.ustx"), "--output", str(work / "vocal.wav"),
         "--singers-path", str(tools / "Singers")], env=env)

    # 3. FluidSynth 伴奏（钢琴 + 钢片琴）
    fs = next((tools / "fluidsynth").rglob("fluidsynth.exe"))
    run([str(fs), "-ni", "-q", "-r", "44100", "-g", "0.5", "-R", "0", "-C", "0",
         "-F", str(work / "accomp.wav"), str(tools / "soundfont" / "FluidR3_GM.sf2"),
         str(work / "song_007_accomp.mid")])

    # 4. 混音：伴奏压到人声下 9 dB，整体对齐到 -27.5 dB 平均音量，限幅 -1 dBFS
    v, acc = mean_db(work / "vocal.wav"), mean_db(work / "accomp.wav")
    acc_gain = (v - ACCOMP_BELOW_VOCAL_DB) - acc
    run(["ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
         "-i", str(work / "vocal.wav"), "-i", str(work / "accomp.wav"),
         "-filter_complex",
         f"[0:a]aresample=44100,aformat=channel_layouts=stereo[v];"
         f"[1:a]aresample=44100,aformat=channel_layouts=stereo,volume={acc_gain:.2f}dB[a];"
         f"[v][a]amix=inputs=2:duration=longest:normalize=0,afade=t=out:st={fade_st}:d=1.5[m]",
         "-map", "[m]", "-t", f"{total}", str(work / "mix_raw.wav")])
    gain = TARGET_MEAN_DB - mean_db(work / "mix_raw.wav")
    run(["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-i", str(work / "mix_raw.wav"),
         "-af", f"volume={gain:.2f}dB,alimiter=limit=0.89:level=false",
         "-ar", "44100", "-c:a", "pcm_s16le", str(out / f"song_007_sung{tag}.wav")])
    run(["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-i", str(out / f"song_007_sung{tag}.wav"),
         "-c:a", "libmp3lame", "-b:a", "160k", "-ar", "44100", str(out / f"song_007_sung{tag}.mp3")])
    info = {"bpm": a.bpm, "total_s": total, "vocal_mean_db": v, "accomp_mean_db_before": acc, "accomp_gain_db": round(acc_gain, 2),
            "master_gain_db": round(gain, 2), "final_mean_db": mean_db(out / f"song_007_sung{tag}.wav")}
    print(json.dumps(info, indent=1))
    if a.keep_vocal:
        shutil.copy(work / "vocal.wav", out / f"song_007_sung{tag}_vocal.wav")
    shutil.rmtree(work)


if __name__ == "__main__":
    main()
