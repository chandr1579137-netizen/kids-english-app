#!/usr/bin/env python3
"""song_007「Clap Your Hands」真唱样品：从乐谱生成 OpenUtau 工程、MIDI 和时间轴。

曲调：传统法国曲调 "Ah! vous dirai-je, maman"（1761 年在巴黎首次刊印，作曲者不详；
即《小星星》"Twinkle, Twinkle, Little Star" 的曲调，公有领域）。
按 install-and-songs.md §5 Q-S1：C 大调、4/4、84 BPM、音域 C4–A4，
每个四分音符一个音节，句末二分音符；前奏 1 小节，最后一个音延长 1 小节。

用法：python make_song007.py <输出目录> [singer-id] [--bpm 84] [--tag ""]
      --bpm 只改速度（音高、调号不变）；--tag 加在文件名上，例如 --bpm 101 --tag _A_101bpm
      → song_007_A_101bpm.ustx / .mid / _timing.json。默认 84 BPM、无 tag，输出与原样品完全相同。
输出：song_007.ustx（人声工程）、song_007.mid（人声旋律 + 歌词 + 伴奏，三轨）、
      song_007_accomp.mid（只有伴奏，给 FluidSynth）、song_007_timing.json
"""
import argparse
import json
import struct
import sys
from pathlib import Path

BPM = 84
PPQ = 480                    # OpenUtau 固定 480 tick / 四分音符
BAR = 4 * PPQ
SEC_PER_TICK = 60.0 / BPM / PPQ
BREATH = PPQ // 4            # 句末二分音符留 1/16 拍… 实际留一个十六分音符换气
C4, D4, E4, F4, G4, A4 = 60, 62, 64, 65, 67, 69

# 每句 7 个音（四分 ×6 + 二分），歌词 token 与音一一对应；"+" = 上一个词延长（hands 跨 G–G）
LINES = [
    ("Clap your hands, one two three,",   ["clap", "your", "hands", "+", "one", "two", "three"], [C4, C4, G4, G4, A4, A4, G4]),
    ("Stomp your feet along with me.",    ["stomp", "your", "feet", "a", "long", "with", "me"],  [F4, F4, E4, E4, D4, D4, C4]),
    ("Nod your head and blink your eyes,", ["nod", "your", "head", "and", "blink", "your", "eyes"], [G4, G4, F4, F4, E4, E4, D4]),
    ("Now we reach up to the skies!",     ["now", "we", "reach", "up", "to", "the", "skies"],    [G4, G4, F4, F4, E4, E4, D4]),
    ("Clap your hands, one two three,",   ["clap", "your", "hands", "+", "one", "two", "three"], [C4, C4, G4, G4, A4, A4, G4]),
    ("Stomp your feet along with me.",    ["stomp", "your", "feet", "a", "long", "with", "me"],  [F4, F4, E4, E4, D4, D4, C4]),
]
# 和声（每半小节一个和弦），与《小星星》常见配法一致
CHORDS = {
    "A1": ["C", "C", "F", "C"],
    "A2": ["F", "C", "G", "C"],
    "B":  ["C", "F", "C", "G"],
}
LINE_CHORDS = ["A1", "A2", "B", "B", "A1", "A2"]
TRIADS = {"C": [48, 60, 64, 67], "F": [41, 60, 65, 69], "G": [43, 59, 62, 67]}


def build_notes():
    """返回 [(start_tick, dur_tick, tone, lyric, line_index)] 和每句起止 tick"""
    notes, spans = [], []
    t = BAR                                   # 前奏 1 小节
    for li, (_, lyr, tones) in enumerate(LINES):
        start = t
        for k, (w, tone) in enumerate(zip(lyr, tones)):
            last = k == len(lyr) - 1
            dur = 2 * PPQ if last else PPQ
            if last and li == len(LINES) - 1:
                dur += BAR                    # 最后一个音延长 1 小节收尾
            sing = dur - (BREATH if last and li < len(LINES) - 1 else 0)
            notes.append((t, sing, tone, w, li))
            t += dur
        spans.append((start, t if li == len(LINES) - 1 else t - BREATH))
    return notes, spans, t


def ustx(notes, total, singer):
    def note_yaml(n):
        pos, dur, tone, lyric, _ = n
        exps = "\n".join(f"    - {{index: {i}, abbr: clr, value: 2}}" for i in range(4))  # 2 = Nectar（柔和）
        return f"""  - position: {pos}
    duration: {dur}
    tone: {tone}
    lyric: {lyric}
    pitch:
      data:
      - {{x: -25, y: 0, shape: io}}
      - {{x: 25, y: 0, shape: io}}
      snap_first: true
    vibrato: {{length: 0, period: 175, depth: 25, in: 10, out: 10, shift: 0, drift: 0, vol_link: 0}}
    tuning: 0
    phoneme_expressions:
{exps}
    phoneme_overrides: []"""
    body = "\n".join(note_yaml(n) for n in notes)
    return f"""name: song_007 Clap Your Hands
comment: 'Tune: Ah! vous dirai-je, maman (traditional French, first printed 1761, public domain). Lyrics: KidsEnglish original.'
output_dir: Vocal
cache_dir: UCache
ustx_version: '0.9'
expressions: {{}}
key: 0
time_signatures:
- {{bar_position: 0, beat_per_bar: 4, beat_unit: 4}}
tempos:
- {{position: 0, bpm: {BPM}}}
tracks:
- singer: {singer}
  phonemizer: OpenUtau.Core.DiffSinger.DiffSingerEnglishPhonemizer
  renderer_settings:
    renderer: DIFFSINGER
  track_name: Hanami (Nectar)
  track_color: Pink
  mute: false
  solo: false
  volume: 0
  pan: 0
voice_parts:
- name: song_007
  comment: ''
  track_no: 0
  position: 0
  duration: {total}
  notes:
{body}
  curves: []
wave_parts: []
"""


# ---------- 最小 MIDI 写入（不依赖第三方库） ----------
def vlq(n):
    out = [n & 0x7F]
    n >>= 7
    while n:
        out.insert(0, (n & 0x7F) | 0x80)
        n >>= 7
    return bytes(out)


def track(events):
    """events: [(abs_tick, bytes)]"""
    events = sorted(events, key=lambda e: (e[0], e[1][0] & 0xF0 == 0x90))  # 同一时刻先 note-off
    data, last = b"", 0
    for t, ev in events:
        data += vlq(t - last) + ev
        last = t
    data += vlq(0) + b"\xFF\x2F\x00"
    return b"MTrk" + struct.pack(">I", len(data)) + data


def meta(t, typ, payload):
    return (t, b"\xFF" + bytes([typ]) + vlq(len(payload)) + payload)


def conductor():
    us = int(60_000_000 / BPM)
    return track([meta(0, 0x51, us.to_bytes(3, "big")), meta(0, 0x58, bytes([4, 2, 24, 8])),
                  meta(0, 0x03, b"Conductor")])


def vocal_track(notes):
    ev = [meta(0, 0x03, b"Vocal (lyrics)")]
    for pos, dur, tone, lyric, _ in notes:
        ev.append(meta(pos, 0x05, lyric.encode()))
        ev.append((pos, bytes([0x90, tone, 96])))
        ev.append((pos + dur, bytes([0x80, tone, 0])))
    return track(ev)


def accomp_tracks(notes, end):
    # ch0 钢琴：每半小节一个柔和柱式和弦（低音 + 三和弦）；ch1 钢片琴：轻轻跟一遍旋律
    piano = [meta(0, 0x03, b"Piano"), (0, b"\xC0\x00")]
    def chord(t, d, name, vel):
        for i, k in enumerate(TRIADS[name]):
            piano.append((t, bytes([0x90, k, vel - (6 if i else 0)])))
            piano.append((t + d - 10, bytes([0x80, k, 0])))
    chord(0, BAR, "C", 58)                                   # 前奏：C 和弦
    t = BAR
    for key in LINE_CHORDS:
        for c in CHORDS[key]:
            chord(t, BAR // 2, c, 52)
            t += BAR // 2
    chord(t, end - t, "C", 50)                               # 收尾延长小节
    celesta = [meta(0, 0x03, b"Celesta"), (0, b"\xC1\x08")]
    for pos, dur, tone, _, _ in notes:
        celesta.append((pos, bytes([0x91, tone + 12, 34])))
        celesta.append((pos + min(dur, PPQ) - 10, bytes([0x81, tone + 12, 0])))
    return track(piano), track(celesta)


def midi(tracks):
    return b"MThd" + struct.pack(">IHHH", 6, 1, len(tracks), PPQ) + b"".join(tracks)


def main():
    global BPM, SEC_PER_TICK
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("singer", nargs="?", default="Hoshino Hanami ~AIdol~ for DiffSinger v1.0")
    ap.add_argument("--bpm", type=float, default=84, help="tempo only; pitch/key unchanged")
    ap.add_argument("--tag", default="", help="file-name suffix, e.g. _A_101bpm")
    a = ap.parse_args()
    BPM = int(a.bpm) if a.bpm == int(a.bpm) else a.bpm
    SEC_PER_TICK = 60.0 / BPM / PPQ
    out = Path(a.out); out.mkdir(parents=True, exist_ok=True)
    singer, tag = a.singer, a.tag
    notes, spans, end = build_notes()
    total = end
    (out / f"song_007{tag}.ustx").write_text(ustx(notes, total, json.dumps(singer)), encoding="utf-8", newline="\n")
    piano, celesta = accomp_tracks(notes, end)
    (out / f"song_007{tag}.mid").write_bytes(midi([conductor(), vocal_track(notes), piano, celesta]))
    (out / f"song_007_accomp{tag}.mid").write_bytes(midi([conductor(), piano, celesta]))
    timing = [{"line": i, "text": LINES[i][0],
               "start": round(s * SEC_PER_TICK, 2), "end": round(e * SEC_PER_TICK, 2)}
              for i, (s, e) in enumerate(spans)]
    (out / f"song_007{tag}_timing.json").write_text(json.dumps(timing, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"bpm={BPM} notes={len(notes)} words={sum(1 for n in notes if n[3] != '+')} total={end * SEC_PER_TICK:.2f}s")
    for t in timing:
        print(t)


if __name__ == "__main__":
    main()
