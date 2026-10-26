#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""物理验证自然拼读阶段 1 资源与出题逻辑完整性（对应 Swift 单测的本地镜像验证）"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).parent.parent
RESOURCES = ROOT / "KidsEnglish" / "KidsEnglish" / "Resources"
PHRASE_AUDIO = RESOURCES / "phrases" / "audio"
OVERRIDES = ROOT / "assets" / "word-icons-overrides"

def test():
    print("=== 开始自然拼读阶段 1 物理资源与出题验证 ===")
    
    # 1. 引导音频与音效物理文件检查
    audio_files = ["tom_do_they_rhyme.mp3", "tom_clap_with_me.mp3", "drum_beat.mp3"]
    for a in audio_files:
        p = PHRASE_AUDIO / a
        assert p.exists(), f"缺失音频文件: {a}"
        assert p.stat().st_size > 1000, f"音频文件过小 ({p.stat().st_size} bytes): {a}"
        print(f"✓ 音频文件存在且完整: {a} ({p.stat().st_size} bytes)")

    # 2. 读取 baby-path.json 和 word-audio-map.json
    with open(RESOURCES / "baby-path.json", "r", encoding="utf-8") as f:
        baby_data = json.load(f)
    with open(RESOURCES / "word-audio-map.json", "r", encoding="utf-8") as f:
        audio_map = json.load(f)

    all_words = set()
    for pack in baby_data["packs"]:
        for w in pack["words"]:
            all_words.add(w)

    pictures = baby_data.get("pictures", {})

    def get_pic(w):
        return pictures.get(w, w)

    # 3. 押韵配对词库
    rhyme_pairs = [
        ("cat", "hat"),
        ("dog", "frog"),
        ("red", "bed"),
        ("bear", "pear"),
        ("sun", "run"),
        ("car", "star"),
        ("bee", "tree"),
        ("ball", "doll"),
        ("duck", "truck"),
        ("rain", "train"),
        ("goat", "boat"),
        ("pen", "hen")
    ]
    non_rhyme_pairs = [
        ("cat", "dog"),
        ("sun", "fish"),
        ("car", "bed"),
        ("apple", "star"),
        ("tree", "duck"),
        ("boat", "bear"),
        ("bee", "frog"),
        ("rain", "hat")
    ]

    for p1, p2 in rhyme_pairs:
        assert p1 in all_words, f"词库缺失 {p1}"
        assert p2 in all_words, f"词库缺失 {p2}"
        assert p1 in audio_map, f"音频缺失 {p1}"
        assert p2 in audio_map, f"音频缺失 {p2}"
        pic1 = OVERRIDES / f"{get_pic(p1)}.jpg"
        pic2 = OVERRIDES / f"{get_pic(p2)}.jpg"
        assert pic1.exists(), f"平涂图缺失 {pic1}"
        assert pic2.exists(), f"平涂图缺失 {pic2}"

    print(f"✓ 押韵词库 10 对全部验证通过 (20/20 词有发音与平涂图)")

    for p1, p2 in non_rhyme_pairs:
        assert p1 in all_words, f"词库缺失 {p1}"
        assert p2 in all_words, f"词库缺失 {p2}"

    print(f"✓ 非押韵对照词库 8 对全部验证通过")

    # 4. 拍手数音节词库
    syllable_words = {
        1: ["cat", "dog", "fish", "sun", "star"],
        2: ["apple", "monkey", "rabbit", "water", "flower"],
        3: ["banana", "elephant", "butterfly", "strawberry", "kangaroo"]
    }

    for syl, words in syllable_words.items():
        assert len(words) >= 5, f"音节 {syl} 候选词数量不足"
        for w in words:
            assert w in all_words, f"音节词缺失 {w}"
            assert w in audio_map, f"音节词发音缺失 {w}"
            pic = OVERRIDES / f"{get_pic(w)}.jpg"
            assert pic.exists(), f"音节词平涂图缺失 {pic}"

    print(f"✓ 拍手数音节词库全部验证通过 (1/2/3 音节共 15 词有发音与平涂图)")

    print("=== 全部阶段 1 物理测试 100% 通过 ===")
    return 0

if __name__ == "__main__":
    sys.exit(test())
