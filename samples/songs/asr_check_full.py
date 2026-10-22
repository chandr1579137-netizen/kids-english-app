#!/usr/bin/env python3
# song_007 语音识别核对：整首识别（只听到人声结束后 0.25 秒），按歌词逐词对齐，依赖 faster-whisper + ffmpeg
"""usage: asr_check_full.py timing.json file1 [file2...] [--models=small.en,medium.en] [--quiet]
Whole-song transcription (temperature 0, beam 5, no conditioning), words assigned to lyric lines by time."""
import sys, json, re, subprocess, numpy as np, difflib
from faster_whisper import WhisperModel
args=[a for a in sys.argv[1:] if not a.startswith("--")]
opts=dict(a[2:].split("=",1) if "=" in a else (a[2:],"1") for a in sys.argv[1:] if a.startswith("--"))
timing=json.load(open(args[0])); files=args[1:]
models=opts.get("models","small.en,medium.en").split(",")
NUM={"1":"one","2":"two","3":"three"}
def norm(t):
    w=re.findall(r"[a-z0-9']+",t.lower().replace("-"," "))
    return [NUM.get(x,x) for x in w]
def load(f):
    raw=subprocess.run(["ffmpeg","-v","error","-i",f,"-ac","1","-ar","16000","-f","f32le","-"],capture_output=True).stdout
    return np.frombuffer(raw,np.float32)
REF=[norm(t["text"]) for t in timing]
bounds=[(t["start"],t["end"]) for t in timing]
def line_of(tm):
    for i,(s,e) in enumerate(bounds):
        nxt = bounds[i+1][0] if i+1<len(bounds) else 1e9
        if tm < nxt - 0.05: return i
    return len(bounds)-1
summary=[]
VAD = opts.get("vad","0")=="1"
TRIM = float(opts.get("trim","0.25"))
for mn in models:
    m=WhisperModel(mn,device="cpu",compute_type="int8")
    for f in files:
        x=load(f)
        if TRIM>0: x=x[:int((timing[-1]["end"]+TRIM)*16000)]   # 只听到人声结束后 0.25 秒，避免纯伴奏尾巴上的幻听（"thank you"）
        segs,_=m.transcribe(x,language="en",beam_size=5,temperature=0.0,condition_on_previous_text=False,word_timestamps=True,vad_filter=VAD)
        hyp=[]
        for s in segs:
            for w in s.words: hyp+=norm(w.word)
        ref=sum(REF,[]); lineof=[i for i,r in enumerate(REF) for _ in r]
        lines=[[] for _ in bounds]; raw=lines
        errs=[]
        sm=difflib.SequenceMatcher(a=ref,b=hyp,autojunk=False)
        for op,a1,a2,b1,b2 in sm.get_opcodes():
            if op!="equal": errs.append(f"{op}:{' '.join(ref[a1:a2])}->{' '.join(hyp[b1:b2])}")
            if op=="equal" or op=="replace" and a2-a1==b2-b1:
                for k in range(b2-b1): lines[lineof[a1+k]].append(hyp[b1+k] if op=="equal" else hyp[b1+k].upper())
            else:
                li=lineof[min(a1,len(ref)-1)] if a1<len(ref) else len(REF)-1
                if a2>a1 and b2==b1: lines[li].append("<missing:"+" ".join(ref[a1:a2])+">")
                else: lines[li].append("["+" ".join(hyp[b1:b2]).upper()+(" for "+" ".join(ref[a1:a2]) if a2>a1 else "")+"]")
        ok = hyp==ref
        summary.append((mn,f.split('/')[-1],ok,len(errs)))
        print(f"[{mn}] {f.split('/')[-1]}: {'MATCH' if ok else 'MISMATCH'} errors={errs}")
        if "quiet" not in opts or not ok:
            for i,(r,h) in enumerate(zip(REF,lines)):
                print(f"   L{i} {'OK ' if r==h else 'BAD'} lyric: {' '.join(r):34s} | heard: {' '.join(h)}")
print("SUMMARY"); [print("  ",*s) for s in summary]
