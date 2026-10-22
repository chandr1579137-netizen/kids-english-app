import sys, numpy as np
from PIL import Image
def analyze(path):
    im=Image.open(path).convert('RGB'); a=np.asarray(im).astype(int); h,w,_=a.shape
    m=max(4,h//100)
    border=np.concatenate([a[:m].reshape(-1,3),a[-m:].reshape(-1,3),a[:,:m].reshape(-1,3),a[:,-m:].reshape(-1,3)])
    bg=np.median(border,axis=0)
    diff=np.abs(a-bg).sum(2)>40
    rows=np.where(diff.mean(1)>0.01)[0]; cols=np.where(diff.mean(0)>0.01)[0]
    y0,y1,x0,x1=rows[0],rows[-1],cols[0],cols[-1]
    # straightness: fraction of non-bg along each bbox edge (few px inside)
    def frac(line): return line.mean()
    sides={'top':frac(diff[y0+2,x0:x1]),'bot':frac(diff[y1-2,x0:x1]),'left':frac(diff[y0:y1,x0+2]),'right':frac(diff[y0:y1,x1-2])}
    return im,a,bg,(x0,y0,x1,y1),sides
def process(src,dst,force=None):
    im,a,bg,(x0,y0,x1,y1),sides=analyze(src)
    straight=[k for k,v in sides.items() if v>0.9]
    framed = len(straight)>=3 if force is None else force
    if framed:
        crop=im.crop((x0+2,y0+2,x1-1,y1-1))
        cw,ch=crop.size; s=1024/max(cw,ch)
        crop=crop.resize((round(cw*s),round(ch*s)),Image.LANCZOS)
        out=Image.new('RGB',(1024,1024),tuple(int(v) for v in bg))
        out.paste(crop,((1024-crop.size[0])//2,(1024-crop.size[1])//2))
    else:
        out=im.resize((1024,1024),Image.LANCZOS) if im.size!=(1024,1024) else im
    out.save(dst,quality=90)
    return framed,straight,{k:round(v,2) for k,v in sides.items()},(x0,y0,x1,y1),im.size
if __name__=='__main__':
    for src,dst in zip(sys.argv[1::2],sys.argv[2::2]):
        print(src.split('/')[-1],process(src,dst))
