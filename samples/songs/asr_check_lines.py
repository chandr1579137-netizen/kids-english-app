#!/usr/bin/env python3
# song_007 语音识别核对：逐句识别（用纯人声 *_vocal.mp3 找句间换气点切句），依赖 faster-whisper + ffmpeg
"""usage: asr_check_lines.py <timing.json> <X_mix.mp3> [...] [--models=small.en,medium.en,large-v3]
旁边有纯人声 <名字>_vocal.wav/.mp3（render_song007.py --keep-vocal 生成）时，用它找切句点。"""
import sys, json, re, subprocess, numpy as np
from faster_whisper import WhisperModel
args=[a for a in sys.argv[1:] if not a.startswith("--")]
opts=dict(a[2:].split("=",1) if "=" in a else (a[2:],"1") for a in sys.argv[1:] if a.startswith("--"))
timing=json.load(open(args[0])); files=args[1:]
models=opts.get("models","small.en,medium.en").split(",")
NUM={"1":"one","2":"two","3":"three"}
def norm(t):
    t=t.lower().replace("-"," ")
    w=re.findall(r"[a-z0-9']+",t)
    return [NUM.get(x,x) for x in w]
def load(f):
    raw=subprocess.run(["ffmpeg","-v","error","-i",f,"-ac","1","-ar","16000","-f","f32le","-"],capture_output=True).stdout
    return np.frombuffer(raw,np.float32)
LYR=[norm(t["text"]) for t in timing]
tot_bad=0
for mn in models:
    m=WhisperModel(mn,device="cpu",compute_type="int8")
    for f in files:
        x=load(f); bad=[]
        rows=[]
        # 切句：在纯人声里找每句开头前的最安静处（句间换气），没有纯人声就用乐谱时间
        import os
        cand=[f.replace("_mix.mp3","_vocal.mp3"), f[:-4]+"_vocal.wav", f[:-4]+"_vocal.mp3"]
        vf=next((c for c in cand if c!=f and os.path.exists(c)), None)
        cuts=[]
        if vf:
            # 用 1 kHz 以下的能量（浊音）找上一句最后一个元音结束的位置，在那里切；s/k 等清辅音留给下一句
            v=load(vf); hop=160
            frames=np.lib.stride_tricks.sliding_window_view(v,640)[::hop]
            spec=np.abs(np.fft.rfft(frames*np.hanning(640),axis=1))**2
            lf=10*np.log10(spec[:,:41].sum(1)+1e-12)          # 0–1 kHz
            for i,t in enumerate(timing):
                if i==0: cuts.append(max(0,t["start"]-0.6)); continue
                lo,hi=int((t["start"]-0.6)*100),int((t["start"]-0.02)*100)
                seg=lf[lo:hi]; thr=seg.max()-25
                k=int(np.argmax(seg>thr))                 # 先找到上一句的元音
                j=k+int(np.argmax(seg[k:]<thr))           # 再找元音结束
                # 元音结束到本句音符开始之间，找最长的一段静音，在中间切（句尾 z/s 和句首 s/k 各归各句）
                tot=10*np.log10(spec[lo+j:hi+2].sum(1)+1e-12)
                sil=tot < (lf[lo:hi].max()-33)
                best=(0,0); run=0
                for q,b in enumerate(sil):
                    run = run+1 if b else 0
                    if run>best[0]: best=(run,q)
                cut = lo+j+best[1]-best[0]//2 if best[0]>=2 else lo+j
                cuts.append(cut/100)
        else:
            cuts=[max(0,t["start"]-0.15) for t in timing]
        cuts.append(timing[-1]["end"]+0.4)
        for t,ref in zip(timing,LYR):
            a=int(cuts[t["line"]]*16000); b=int(cuts[t["line"]+1]*16000)
            segs,_=m.transcribe(x[a:b],language="en",beam_size=5,temperature=0.0,condition_on_previous_text=False,
                                initial_prompt=None,vad_filter=False)
            txt=" ".join(s.text for s in segs).strip(); hyp=norm(txt)
            ok = hyp==ref
            if not ok: bad.append(t["line"])
            rows.append(f"   L{t['line']} {'OK ' if ok else 'BAD'} [{a/16000:5.2f}-{b/16000:5.2f}] {' '.join(ref):34s} | {txt}")
        full=""
        if "full" in opts:
            segs,_=m.transcribe(x,language="en",beam_size=5,temperature=0.0,condition_on_previous_text=False)
            full=" ".join(s.text for s in segs).strip()
            fh=norm(full); fr=sum(LYR,[])
            full=f"   FULL {'OK ' if fh==fr else 'BAD'} | {full}"
        print(f"[{mn}] {f.split('/')[-1]}: lines bad={bad}")
        print("\n".join(rows)); 
        if full: print(full)
        tot_bad+=len(bad)
print("TOTAL_BAD",tot_bad)
