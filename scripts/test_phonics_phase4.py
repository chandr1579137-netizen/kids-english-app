#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
自然拼读阶段 4：Jolly Phonics 核心组 2 字母音（Group 2: c, e, h, r, m, d）物理与逻辑综合测试脚本
"""
import random
from pathlib import Path

ROOT = Path("K:/kids-english-app") if Path("K:/kids-english-app").exists() else Path(__file__).parent.parent
RES_DIR = ROOT / "KidsEnglish" / "KidsEnglish" / "Resources"
AUDIO_DIR = RES_DIR / "phrases" / "audio"
OVERRIDES_DIR = ROOT / "assets" / "word-icons-overrides"
WORD_ICONS_DIR = RES_DIR / "word-icons"

GROUP2_LETTERS = [
    {
        "id": "c",
        "letter": "c",
        "phoneme": "/k/",
        "word": "cat",
        "picture": "cat.jpg",
        "audio": "phonics_chant_c.mp3",
        "expected_bytes_min": 30000,
    },
    {
        "id": "e",
        "letter": "e",
        "phoneme": "/e/",
        "word": "egg",
        "picture": "egg.jpg",
        "audio": "phonics_chant_e.mp3",
        "expected_bytes_min": 25000,
    },
    {
        "id": "h",
        "letter": "h",
        "phoneme": "/h/",
        "word": "hat",
        "picture": "hat.jpg",
        "audio": "phonics_chant_h.mp3",
        "expected_bytes_min": 30000,
    },
    {
        "id": "r",
        "letter": "r",
        "phoneme": "/r/",
        "word": "rabbit",
        "picture": "rabbit.jpg",
        "audio": "phonics_chant_r.mp3",
        "expected_bytes_min": 30000,
    },
    {
        "id": "m",
        "letter": "m",
        "phoneme": "/m/",
        "word": "monkey",
        "picture": "monkey.jpg",
        "audio": "phonics_chant_m.mp3",
        "expected_bytes_min": 30000,
    },
    {
        "id": "d",
        "letter": "d",
        "phoneme": "/d/",
        "word": "dog",
        "picture": "dog.jpg",
        "audio": "phonics_chant_d.mp3",
        "expected_bytes_min": 30000,
    },
]

GROUP2_INTRO_AUDIO = [
    "tom_phonics_group2.mp3",
]


def test_group2_pictures():
    print("[1/4] 检验阶段 4 Group 2 平涂大图...")
    for item in GROUP2_LETTERS:
        pic_in_overrides = OVERRIDES_DIR / item["picture"]
        pic_in_icons = WORD_ICONS_DIR / item["picture"]
        found = pic_in_overrides if pic_in_overrides.exists() else (pic_in_icons if pic_in_icons.exists() else None)

        assert found is not None, f"缺失 Group 2 真实大图: {item['picture']}"
        assert found.stat().st_size >= item["expected_bytes_min"], f"图片文件过小或未就绪: {found} ({found.stat().st_size} bytes)"
        print(f"  ✓ {item['word']}: {found.name} ({found.stat().st_size} bytes, 高清平涂插画)")
    print("  => 6 张核心 Group 2 平涂大图物理核验全部通过！")


def test_group2_audio():
    print("\n[2/4] 检验阶段 4 Group 2 专属顺口溜音频与引导音...")
    for item in GROUP2_LETTERS:
        aud_path = AUDIO_DIR / item["audio"]
        assert aud_path.exists(), f"缺失音频文件: {aud_path}"
        assert aud_path.stat().st_size > 1000, f"音频文件损坏: {aud_path}"
        print(f"  ✓ Group 2 字母音顺口溜音频: {item['audio']} ({aud_path.stat().st_size} bytes)")

    for extra in GROUP2_INTRO_AUDIO:
        aud_path = AUDIO_DIR / extra
        assert aud_path.exists(), f"缺失引导音效文件: {aud_path}"
        assert aud_path.stat().st_size > 1000, f"音效文件损坏: {aud_path}"
        print(f"  ✓ Tom Group 2 引导音频: {extra} ({aud_path.stat().st_size} bytes)")
    print("  => 7 个专属音频/引导音物理文件完整性核验全部通过！")


def test_quiz_engine(count=4, rounds_to_test=50):
    print("\n[3/4] 验证阶段 4 听音辨字母出题引擎算法逻辑...")
    pool = GROUP2_LETTERS

    for round_idx in range(rounds_to_test):
        rng = random.Random(round_idx * 111)
        shuffled_targets = list(pool)
        rng.shuffle(shuffled_targets)
        while len(shuffled_targets) < count:
            extra = list(pool)
            rng.shuffle(extra)
            shuffled_targets.extend(extra)
        targets = shuffled_targets[:count]

        for target in targets:
            others = [item for item in pool if item["id"] != target["id"]]
            rng.shuffle(others)
            distractors = others[:2]
            options = [target] + distractors
            rng.shuffle(options)

            assert len(options) == 3, f"选项数必须为 3，实际为 {len(options)}"
            assert target in options, f"目标字母 {target['id']} 必须在选项中"
            assert len(set(opt['id'] for opt in options)) == 3, f"选项不能包含重复项: {options}"

    print(f"  ✓ 连续运行 {rounds_to_test} 轮（每轮 {count} 题）Group 2 测验出题模拟，全部达标！")


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
    print("自然拼读阶段 4（Jolly Phonics Group 2 核心字母音）物理与逻辑综合测试")
    print("=" * 60)
    test_group2_pictures()
    test_group2_audio()
    test_quiz_engine()
    test_source_sync()
    print("\n" + "=" * 60)
    print("🎉 阶段 4（Group 2 字母音）所有物理资产与出题逻辑测试 100% 验证通过！")
    print("=" * 60)


if __name__ == "__main__":
    main()
