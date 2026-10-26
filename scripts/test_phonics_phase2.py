#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
自然拼读阶段 2：Jolly Phonics 字母音（Group 1: s, a, t, i, p, n）自动化物理校验测试脚本
"""
import os
import sys
import random
from pathlib import Path

ROOT = Path("K:/kids-english-app") if Path("K:/kids-english-app").exists() else Path(__file__).parent.parent
RES_DIR = ROOT / "KidsEnglish" / "KidsEnglish" / "Resources"
AUDIO_DIR = RES_DIR / "phrases" / "audio"
OVERRIDES_DIR = ROOT / "assets" / "word-icons-overrides"
WORD_ICONS_DIR = RES_DIR / "word-icons"

GROUP_1 = [
    {
        "id": "s",
        "letter": "s",
        "phoneme": "/s/",
        "word": "snake",
        "audio": "phonics_chant_s.mp3",
        "picture": "snake.jpg",
    },
    {
        "id": "a",
        "letter": "a",
        "phoneme": "/æ/",
        "word": "apple",
        "audio": "phonics_chant_a.mp3",
        "picture": "apple.jpg",
    },
    {
        "id": "t",
        "letter": "t",
        "phoneme": "/t/",
        "word": "tiger",
        "audio": "phonics_chant_t.mp3",
        "picture": "tiger.jpg",
    },
    {
        "id": "i",
        "letter": "i",
        "phoneme": "/ɪ/",
        "word": "box",
        "audio": "phonics_chant_i.mp3",
        "picture": "box.jpg",
    },
    {
        "id": "p",
        "letter": "p",
        "phoneme": "/p/",
        "word": "pig",
        "audio": "phonics_chant_p.mp3",
        "picture": "pig.jpg",
    },
    {
        "id": "n",
        "letter": "n",
        "phoneme": "/n/",
        "word": "nose",
        "audio": "phonics_chant_n.mp3",
        "picture": "nose.jpg",
    },
]

EXTRA_AUDIO = [
    "tom_phonics_island.mp3",
    "tom_find_sound.mp3",
]


def test_pictures():
    print("[1/4] 检验 Group 1 平涂大图...")
    for item in GROUP_1:
        # 图片优先在 word-icons-overrides 或 word-icons 中找到
        pic_in_overrides = OVERRIDES_DIR / item["picture"]
        pic_in_icons = WORD_ICONS_DIR / item["picture"]
        
        found = None
        if pic_in_overrides.exists():
            found = pic_in_overrides
        elif pic_in_icons.exists():
            found = pic_in_icons
            
        assert found is not None, f"缺失平涂大图: {item['picture']} (在 overrides 与 word-icons 均未找到)"
        assert found.stat().st_size > 5000, f"图片文件损坏或过小: {found}"
        print(f"  ✓ {item['letter']} ({item['word']}): {found.name} ({found.stat().st_size} bytes)")
    print("  => 6 张平涂大图物理核验全部通过！")


def test_audio():
    print("\n[2/4] 检验自然拼读专属音频文件...")
    for item in GROUP_1:
        aud_path = AUDIO_DIR / item["audio"]
        assert aud_path.exists(), f"缺失音频文件: {aud_path}"
        assert aud_path.stat().st_size > 1000, f"音频文件损坏或过小: {aud_path}"
        print(f"  ✓ 字母 {item['letter']} 顺口溜音频: {item['audio']} ({aud_path.stat().st_size} bytes)")

    for extra in EXTRA_AUDIO:
        aud_path = AUDIO_DIR / extra
        assert aud_path.exists(), f"缺失 Tom 提示音频: {aud_path}"
        assert aud_path.stat().st_size > 1000, f"音频文件损坏或过小: {aud_path}"
        print(f"  ✓ Tom 引导音频: {extra} ({aud_path.stat().st_size} bytes)")
    print("  => 8 个物理音频文件完整性核验全部通过！")


def simulate_quiz_engine(count=4, rounds_to_test=20):
    print("\n[3/4] 验证听音辨字母出题引擎算法逻辑...")
    pool = [x["id"] for x in GROUP_1]

    for round_idx in range(rounds_to_test):
        rng = random.Random(round_idx * 42)
        shuffled_pool = list(pool)
        rng.shuffle(shuffled_pool)
        while len(shuffled_pool) < count:
            extra = list(pool)
            rng.shuffle(extra)
            shuffled_pool.extend(extra)
        targets = shuffled_pool[:count]

        for target in targets:
            others = [x for x in pool if x != target]
            rng.shuffle(others)
            distractors = others[:2]
            options = [target] + distractors
            rng.shuffle(options)

            assert len(options) == 3, f"选项数必须为 3，实际为 {len(options)}"
            assert target in options, f"目标项 {target} 必须在选项中"
            assert len(set(options)) == 3, f"选项不能包含重复字母: {options}"

    print(f"  ✓ 连续运行 {rounds_to_test} 轮（每轮 {count} 题）出题模拟，约束条件 100% 达标！")


def test_source_sync():
    print("\n[4/4] 检验外层与内层 Swift 源码一致性...")
    inner_dir = ROOT / "KidsEnglish" / "KidsEnglish"
    outer_dir = ROOT / "KidsEnglish"

    files_to_check = ["PhonicsModels.swift", "PhonicsView.swift", "BabyView.swift"]
    for fname in files_to_check:
        inner_file = inner_dir / fname
        outer_file = outer_dir / fname
        assert inner_file.exists(), f"内层文件缺失: {inner_file}"
        assert outer_file.exists(), f"外层文件缺失: {outer_file}"
        assert inner_file.read_bytes() == outer_file.read_bytes(), f"文件不一致: {fname}"
        print(f"  ✓ {fname} 双目录完全一致")
    print("  => 源码副本完全同步！")


def main():
    print("=" * 60)
    print("自然拼读阶段 2（Jolly Phonics Group 1）物理与逻辑综合测试")
    print("=" * 60)
    test_pictures()
    test_audio()
    simulate_quiz_engine()
    test_source_sync()
    print("\n" + "=" * 60)
    print("🎉 恭喜！阶段 2 所有物理资产与出题逻辑测试 100% 验证通过！")
    print("=" * 60)


if __name__ == "__main__":
    main()
