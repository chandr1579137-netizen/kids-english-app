#!/usr/bin/env python3
"""App 儿歌真唱：从 song_specs.py 的旋律谱生成 OpenUtau 工程（.ustx）、MIDI 和每句时间轴。

做法和 song_007 C 版（samples/songs 的 113 BPM clear）一样：
  - 前奏 1 小节钢琴主和弦；整段唱 repeat 遍；最后一个音照谱唱完（end_hold 可加长），再加 1 小节钢琴收尾。
  - 句末留八分音符换气，下一句开头的辅音有地方放（C 版的经验）。
  - 每个音素都用 Hanami 的 Nectar（柔和）唱法。
  - diction.json 里的吐字表：显式 ARPAbet 音素（写成 lyric[音素]）和辅音位置偏移。
  - 伴奏：钢琴每半小节一个和弦（按旋律自动配 C/F/G/Am/Dm），钢片琴轻轻跟一遍旋律。

用法：python make_song.py song_001 <输出目录> [--songs-json <songs.json>] [--diction diction.json] [--specs song_specs.py]
输出：<id>.ustx、<id>.mid（指挥轨 + 人声带歌词 + 钢琴 + 钢片琴）、<id>_accomp.mid、<id>_timing.json
"""
import argparse, json, re, struct
from pathlib import Path

HERE = Path(__file__).resolve().parent
PPQ = 480
BAR = 4 * PPQ
BREATH = PPQ // 2
NOTE = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
TRIADS = {"C": [48, 60, 64, 67], "F": [41, 60, 65, 69], "G": [43, 59, 62, 67],
          "Am": [45, 60, 64, 69], "Dm": [38, 62, 65, 69]}
PCS = {"C": {0, 4, 7}, "F": {5, 9, 0}, "G": {7, 11, 2}, "Am": {9, 0, 4}, "Dm": {2, 5, 9}}
PREF = {"C": 0.3, "F": 0.2, "G": 0.2, "Am": 0.0, "Dm": 0.0}
SINGER = "Hoshino Hanami ~AIdol~ for DiffSinger v1.0"


def midi_no(s):
    m = re.fullmatch(r"([A-G])(#?)(\d)", s)
    return 12 * (int(m.group(3)) + 1) + NOTE[m.group(1)] + (1 if m.group(2) else 0)


def parse_line(text, notes):
    """返回 [(lyric, tone, ticks)]：每个词的第一个音节写整词，后面的音节和拖腔写 "+"。"""
    words = [w for w in re.split(r"[ \-]+", text) if w]
    syl = []
    for w in words:
        clean = re.sub(r"[^A-Za-z'|]", "", w)
        parts = clean.split("|")
        word = "".join(parts).lower()
        syl.append(word)
        syl += ["+"] * (len(parts) - 1)
    toks = notes.split()
    out, i = [], 0
    for t in toks:
        melis = t.startswith("~")
        p, d = t.lstrip("~").split(":")
        ticks = round(float(d) * PPQ)
        if p == "R":                      # 休止（逗号处的小停顿，让词尾辅音和下一个词分开）
            out.append((None, None, ticks))
        elif melis:
            out.append(("+", midi_no(p), ticks))
        else:
            out.append((syl[i], midi_no(p), ticks)); i += 1
    assert out[-1][0] is not None, f"句末不能是休止：{text}"
    assert i == len(syl), f"音节数 {len(syl)} 和音符数 {i} 不一致：{text}"
    assert sum(n[2] for n in out) == 2 * BAR, f"每句应为 8 拍：{text}"
    return out


def build(spec, lyrics_en):
    """音符 [(pos, dur, tone, lyric, line_no)]、每句时间 [(start, end, text)]、总长"""
    notes, spans = [], []
    t = BAR
    # 最后一个音拖多少 tick（默认 0：照谱唱完，后面一小节只有钢琴收尾。
    # 拖一整小节的长元音会让语音识别把词尾听错，比如 light → world）
    hold = round(spec.get("end_hold", 0) * PPQ)
    lines = spec["lines"] * spec.get("repeat", 2)
    texts = lyrics_en * spec.get("repeat", 2)
    for li, ((text, ns), en) in enumerate(zip(lines, texts)):
        parsed = parse_line(text, ns)
        start = t
        last_line = li == len(lines) - 1
        for k, (lyr, tone, d) in enumerate(parsed):
            if lyr is None:
                t += d; continue
            last = k == len(parsed) - 1
            dur = d + (hold if last and last_line else 0)
            sing = dur - (BREATH if last and not last_line else 0)
            notes.append((t, sing, tone, lyr, li))
            t += dur
        spans.append((start, t if last_line else t - BREATH, en))
    return notes, spans, t + (BAR - hold)   # 最后一小节钢琴收尾


def harmonize(notes, end):
    """每半小节选一个和弦：落在和弦里的旋律音按时值计分，半小节第一个音加权；最后半小节固定 C。"""
    chords = []
    for hb in range(BAR, end, BAR // 2):
        score = {c: PREF[c] for c in PCS}
        for pos, dur, tone, _, _ in notes:
            a, b = max(pos, hb), min(pos + dur, hb + BAR // 2)
            if b <= a:
                continue
            w = (b - a) / PPQ * (1.5 if pos <= hb < pos + dur else 1.0)
            for c in PCS:
                if tone % 12 in PCS[c]:
                    score[c] += w
        chords.append((hb, max(score, key=score.get)))
    chords[-1] = (chords[-1][0], "C")
    # 收尾小节也是 C
    return [(hb, c if hb < end - BAR else "C") for hb, c in chords]


def ustx(spec_id, title, tune, notes, total, diction, bpm, voice=2, velc=None):
    words = diction.get("words", {})
    words.update(diction.get("songs", {}).get(spec_id, {}))
    def note_yaml(n):
        pos, dur, tone, lyric, _ = n
        ovr = ""
        d = words.get(lyric)
        if d:
            lyric_out = json.dumps(f"{lyric}[{d['ph']}]")
            offs = d.get("off", {})
            if offs:
                ovr = "\n" + "\n".join(f"    - {{index: {int(i)}, offset: {int(v)}}}"
                                       for i, v in sorted(offs.items(), key=lambda kv: int(kv[0])))
        else:
            lyric_out = json.dumps(lyric) if not re.fullmatch(r"[a-z+]+", lyric) else lyric
        exps = "\n".join(f"    - {{index: {i}, abbr: clr, value: {voice}}}" for i in range(8))  # 2 = Nectar
        return f"""  - position: {pos}
    duration: {dur}
    tone: {tone}
    lyric: {lyric_out}
    pitch:
      data:
      - {{x: -25, y: 0, shape: io}}
      - {{x: 25, y: 0, shape: io}}
      snap_first: true
    vibrato: {{length: 0, period: 175, depth: 25, in: 10, out: 10, shift: 0, drift: 0, vol_link: 0}}
    tuning: 0
    phoneme_expressions:
{exps}
    phoneme_overrides:{ovr if ovr else " []"}"""
    body = "\n".join(note_yaml(n) for n in notes)
    # velc：DiffSinger 的咬字速度曲线（100 = 原速，小于 100 = 咬字更慢、更清楚）
    # CLI 渲染不会自动登记 velc，要在工程里声明，否则曲线会被丢掉
    exp_decl = " {}" if velc is None else ("\n  velc: {name: velocity (curve), abbr: velc, type: Curve, min: 0, max: 200, "
                                         "default_value: 100, is_flag: false}")
    curves = " []" if velc is None else f"\n  - xs: [0, {total}]\n    ys: [{int(velc)}, {int(velc)}]\n    abbr: velc"
    comment = json.dumps(f"Tune: {tune}. Lyrics: KidsEnglish songs.json (unchanged).")
    return f"""name: {json.dumps(spec_id + ' ' + title)}
comment: {comment}
output_dir: Vocal
cache_dir: UCache
ustx_version: '0.9'
expressions:{exp_decl}
key: 0
time_signatures:
- {{bar_position: 0, beat_per_bar: 4, beat_unit: 4}}
tempos:
- {{position: 0, bpm: {bpm}}}
tracks:
- singer: {json.dumps(SINGER)}
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
- name: {spec_id}
  comment: ''
  track_no: 0
  position: 0
  duration: {total}
  notes:
{body}
  curves:{curves}
wave_parts: []
"""


# ---------- 最小 MIDI 写入 ----------
def vlq(n):
    out = [n & 0x7F]; n >>= 7
    while n:
        out.insert(0, (n & 0x7F) | 0x80); n >>= 7
    return bytes(out)


def track(events):
    events = sorted(events, key=lambda e: (e[0], e[1][0] & 0xF0 == 0x90))
    data, last = b"", 0
    for t, ev in events:
        data += vlq(t - last) + ev; last = t
    data += vlq(0) + b"\xFF\x2F\x00"
    return b"MTrk" + struct.pack(">I", len(data)) + data


def meta(t, typ, payload):
    return (t, b"\xFF" + bytes([typ]) + vlq(len(payload)) + payload)


def midi(tracks):
    return b"MThd" + struct.pack(">IHHH", 6, 1, len(tracks), PPQ) + b"".join(tracks)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("song_id"); ap.add_argument("out")
    ap.add_argument("--songs-json", default=str(HERE.parents[1] / "KidsEnglish/KidsEnglish/Resources/songs.json"))
    ap.add_argument("--diction", default=str(HERE / "diction.json"))
    ap.add_argument("--specs", default=str(HERE / "song_specs.py"), help="旋律谱文件（试不同版本时用）")
    a = ap.parse_args()
    import importlib.util
    spec_mod = importlib.util.spec_from_file_location("song_specs", a.specs)
    m = importlib.util.module_from_spec(spec_mod); spec_mod.loader.exec_module(m)
    spec = m.SONGS[a.song_id]
    song = next(s for s in json.loads(Path(a.songs_json).read_text(encoding="utf-8")) if s["id"] == a.song_id)
    lyrics_en = [l["en"] for l in song["lines"]]
    for (text, _), en in zip(spec["lines"], lyrics_en):      # 歌词一字不改
        assert text.replace("|", "") == en, f"歌词和 songs.json 不一致：{text!r} vs {en!r}"
    assert len(spec["lines"]) == len(lyrics_en)
    diction = json.loads(Path(a.diction).read_text(encoding="utf-8"))
    bpm = spec["bpm"]
    global BREATH
    BREATH = int(spec.get("breath", diction.get("breath", BREATH)))
    notes, spans, end = build(spec, lyrics_en)
    out = Path(a.out); out.mkdir(parents=True, exist_ok=True)
    sid = a.song_id
    (out / f"{sid}.ustx").write_text(ustx(sid, song["title"], spec["tune"], notes, end, diction, bpm,
                                          spec.get("voice", 2), spec.get("velc")),
                                     encoding="utf-8", newline="\n")
    us = int(60_000_000 / bpm)
    cond = track([meta(0, 0x51, us.to_bytes(3, "big")), meta(0, 0x58, bytes([4, 2, 24, 8])), meta(0, 0x03, b"Conductor")])
    voc = [meta(0, 0x03, b"Vocal (lyrics)")]
    for pos, dur, tone, lyr, _ in notes:
        voc.append(meta(pos, 0x05, lyr.encode()))
        voc += [(pos, bytes([0x90, tone, 96])), (pos + dur, bytes([0x80, tone, 0]))]
    piano = [meta(0, 0x03, b"Piano"), (0, b"\xC0\x00")]
    def chord(t, d, name, vel):
        for i, k in enumerate(TRIADS[name]):
            piano.append((t, bytes([0x90, k, vel - (6 if i else 0)])))
            piano.append((t + d - 10, bytes([0x80, k, 0])))
    chord(0, BAR, "C", 58)
    harm = harmonize(notes, end)
    for hb, c in harm:
        chord(hb, BAR // 2, c, 50 if hb >= end - BAR else 52)
    cel = [meta(0, 0x03, b"Celesta"), (0, b"\xC1\x08")]
    for pos, dur, tone, _, _ in notes:
        cel += [(pos, bytes([0x91, tone + 12, 34])), (pos + min(dur, PPQ) - 10, bytes([0x81, tone + 12, 0]))]
    (out / f"{sid}.mid").write_bytes(midi([cond, track(voc), track(piano), track(cel)]))
    (out / f"{sid}_accomp.mid").write_bytes(midi([cond, track(piano), track(cel)]))
    spt = 60.0 / bpm / PPQ
    timing = [{"line": i, "text": txt, "start": round(s * spt, 2), "end": round(e * spt, 2)}
              for i, (s, e, txt) in enumerate(spans)]
    (out / f"{sid}_timing.json").write_text(json.dumps(timing, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"{sid} bpm={bpm} notes={len(notes)} total={end * spt:.2f}s chords="
          + " ".join(c for _, c in harm))


if __name__ == "__main__":
    main()
