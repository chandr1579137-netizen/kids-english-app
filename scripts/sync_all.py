import shutil
import os
import glob
import sys

# 1. 运行原有的 sync_duplicated_sources.py
sys.path.append('scripts')
import sync_duplicated_sources
sync_duplicated_sources.main()

# 2. 同步资源文件
inner_res = "KidsEnglish/KidsEnglish/Resources"
outer_res = "KidsEnglish/Resources"

# feed-pairs.json & custom-audio-map.json
for f in ["feed-pairs.json", "custom-audio-map.json"]:
    src = os.path.join(inner_res, f)
    dst = os.path.join(outer_res, f)
    if os.path.exists(src):
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(src, dst)
        print(f"Synced {f} to outer resources")

# audio mp3
for mp3 in glob.glob(os.path.join(inner_res, "audio", "*.mp3")):
    name = os.path.basename(mp3)
    dst = os.path.join(outer_res, "audio", name)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    if not os.path.exists(dst):
        shutil.copy2(mp3, dst)

# phrases/audio zh_*.mp3
for mp3 in glob.glob(os.path.join(inner_res, "phrases", "audio", "zh_*.mp3")):
    name = os.path.basename(mp3)
    dst = os.path.join(outer_res, "phrases", "audio", name)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    if not os.path.exists(dst):
        shutil.copy2(mp3, dst)

print("All Swift and Resources mirror synced successfully!")
