#!/usr/bin/env python3
"""儿歌验收：用 faster-whisper 听成品混音，逐句 + 整首，和歌词逐词比对。

  python asr_check.py <id>_timing.json <id>_sung.mp3 [--vocal=<id>_sung_vocal.wav] [--models=small.en,medium.en,large-v3] [--json=out.json]

- 设置：int8，temperature 0，beam 5，不给提示词，不沿用上一段文字。
- 逐句：在纯人声里找每句前的换气点（上一句元音结束后最长的一段静音），在那里切开，每句单独识别。
  没给纯人声就按乐谱时间切。
- 整首：只听到最后一句结束后 0.25 秒（whisper 按 30 秒一段处理，零点几秒的纯伴奏尾巴会让它幻听出 "thank you"）。
- 比对前的统一：小写；连字符当空格；去掉撇号（rainbow's = rainbows，don't = dont，读音相同）；
  数字转英文（1 → one … 10 → ten）；goodnight → good night；英式拼写 colours → colors。
全部通过时退出码为 0。
"""
import sys, json, re, subprocess, difflib, os
import numpy as np
from faster_whisper import WhisperModel

args = [a for a in sys.argv[1:] if not a.startswith("--")]
opts = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in sys.argv[1:] if a.startswith("--"))
timing = json.load(open(args[0], encoding="utf-8")); f = args[1]
models = opts.get("models", "small.en,medium.en,large-v3").split(",")
NUM = {str(i): w for i, w in enumerate("zero one two three four five six seven eight nine ten".split())}
EQ = {"goodnight": ["good", "night"], "colours": ["colors"]}


def norm(t):
    t = t.lower().replace("-", " ").replace("'", "").replace("’", "")
    out = []
    for w in re.findall(r"[a-z0-9]+", t):
        w = NUM.get(w, w)
        out += EQ.get(w, [w])
    return out


def load(p):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", p, "-ac", "1", "-ar", "16000", "-f", "f32le", "-"],
                         capture_output=True).stdout
    return np.frombuffer(raw, np.float32)


def cuts_from_vocal(vf):
    v = load(vf); hop = 160
    frames = np.lib.stride_tricks.sliding_window_view(v, 640)[::hop]
    spec = np.abs(np.fft.rfft(frames * np.hanning(640), axis=1)) ** 2
    lf = 10 * np.log10(spec[:, :41].sum(1) + 1e-12)
    tot = 10 * np.log10(spec.sum(1) + 1e-12)
    cuts = []
    for i, t in enumerate(timing):
        if i == 0:
            cuts.append(max(0, t["start"] - 0.6)); continue
        lo, hi = int((t["start"] - 0.6) * 100), int((t["start"] - 0.02) * 100)
        seg = lf[lo:hi]; thr = seg.max() - 25
        k = int(np.argmax(seg > thr)); j = k + int(np.argmax(seg[k:] < thr))
        sil = tot[lo + j:hi + 2] < (seg.max() - 33)
        best, run = (0, 0), 0
        for q, b in enumerate(sil):
            run = run + 1 if b else 0
            if run > best[0]: best = (run, q)
        cuts.append((lo + j + best[1] - best[0] // 2 if best[0] >= 2 else lo + j) / 100)
    cuts.append(timing[-1]["end"] + 0.4)
    return cuts


REF = [norm(t["text"]) for t in timing]
x = load(f)
vf = opts.get("vocal")
cuts = cuts_from_vocal(vf) if vf and os.path.exists(vf) else \
    [max(0, t["start"] - 0.15) for t in timing] + [timing[-1]["end"] + 0.4]
results, allok = {}, True
for mn in models:
    m = WhisperModel(mn, device="cpu", compute_type="int8")
    kw = dict(language="en", beam_size=5, temperature=0.0, condition_on_previous_text=False)
    lines = []
    for i, ref in enumerate(REF):
        seg, _ = m.transcribe(x[int(cuts[i] * 16000):int(cuts[i + 1] * 16000)], **kw)
        txt = " ".join(s.text for s in seg).strip()
        lines.append({"line": i, "lyric": timing[i]["text"], "heard": txt, "ok": norm(txt) == REF[i]})
    seg, _ = m.transcribe(x[:int((timing[-1]["end"] + 0.25) * 16000)], **kw)
    full = " ".join(s.text for s in seg).strip()
    ref = sum(REF, []); hyp = norm(full)
    errs = [f"{op}: {' '.join(ref[a1:a2])} -> {' '.join(hyp[b1:b2])}"
            for op, a1, a2, b1, b2 in difflib.SequenceMatcher(a=ref, b=hyp, autojunk=False).get_opcodes() if op != "equal"]
    ok_lines = all(l["ok"] for l in lines); ok_full = not errs
    allok &= ok_lines and ok_full
    results[mn] = {"lines_ok": ok_lines, "full_ok": ok_full, "full_errors": errs, "full_text": full, "lines": lines}
    print(f"[{mn}] lines {'PASS' if ok_lines else 'FAIL'} | full {'PASS' if ok_full else 'FAIL ' + str(errs)}")
    for l in lines:
        print(f"   L{l['line']} {'OK ' if l['ok'] else 'BAD'} {l['lyric']:40s} | {l['heard']}")
if "json" in opts:
    json.dump({"file": os.path.basename(f), "cuts": cuts, "models": results, "pass": allok},
              open(opts["json"], "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("RESULT", "PASS" if allok else "FAIL")
sys.exit(0 if allok else 1)
