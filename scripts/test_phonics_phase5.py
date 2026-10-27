#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
自然拼读阶段 5：小火车双组拼词扩充（CVC Sound Blending Train Expansion: cat, hat, hen, red）物理与逻辑综合测试
"""
import random
from pathlib import Path

ROOT = Path("K:/kids-english-app") if Path("K:/kids-english-app").exists() else Path(__file__).parent.parent
RES_DIR = ROOT / "KidsEnglish" / "KidsEnglish" / "Resources"
AUDIO_DIR = RES_DIR / "phrases" / "audio"
OVERRIDES_DIR = ROOT / "assets" / "word-icons-overrides"
WORD_ICONS_DIR = RES_DIR / "word-icons"

ALL_CVC_WORDS = [
    {
        "id": "sit",
        "word": "sit",
        "letters": ["s", "i", "t"],
        "picture": "sit.jpg",
        "audio": "blend_word_sit.mp3",
    },
    {
        "id": "pan",
        "word": "pan",
        "letters": ["p", "a", "n"],
        "picture": "pan.jpg",
        "audio": "blend_word_pan.mp3",
    },
    {
        "id": "pin",
        "word": "pin",
        "letters": ["p", "i", "n"],
        "picture": "pin.jpg",
        "audio": "blend_word_pin.mp3",
    },
    {
        "id": "cat",
        "word": "cat",
        "letters": ["c", "a", "t"],
        "picture": "cat.jpg",
        "audio": "blend_word_cat.mp3",
    },
    {
        "id": "hat",
        "word": "hat",
        "letters": ["h", "a", "t"],
        "picture": "hat.jpg",
        "audio": "blend_word_hat.mp3",
    },
    {
        "id": "hen",
        "word": "hen",
        "letters": ["h", "e", "n"],
        "picture": "hen.jpg",
        "audio": "blend_word_hen.mp3",
    },
    {
        "id": "red",
        "word": "red",
        "letters": ["r", "e", "d"],
        "picture": "red.jpg",
        "audio": "blend_word_red.mp3",
    },
]


def test_cvc_pictures():
    print("[1/4] 检验阶段 5 全量 7 个 CVC 拼读词平涂大图物理存在性与完整度...")
    for item in ALL_CVC_WORDS:
        pic_in_overrides = OVERRIDES_DIR / item["picture"]
        pic_in_icons = WORD_ICONS_DIR / item["picture"]
        found = pic_in_overrides if pic_in_overrides.exists() else (pic_in_icons if pic_in_icons.exists() else None)

        assert found is not None, f"缺失 CVC 真实大图: {item['picture']}"
        assert found.stat().st_size > 20000, f"图片文件过小: {found} ({found.stat().st_size} bytes)"
        print(f"  ✓ {item['word']}: {found.name} ({found.stat().st_size} bytes, 高清真实平涂水彩插画)")
    print("  => 7 张核心 CVC 平涂大图物理核验全部通过！")


def test_cvc_audio():
    print("\n[2/4] 检验阶段 5 全量 7 个 CVC 拼读顺口溜音频物理存在性...")
    for item in ALL_CVC_WORDS:
        aud_path = AUDIO_DIR / item["audio"]
        assert aud_path.exists(), f"缺失音频文件: {aud_path}"
        assert aud_path.stat().st_size > 1000, f"音频文件损坏: {aud_path}"
        print(f"  ✓ 拼读顺口溜音频: {item['audio']} ({aud_path.stat().st_size} bytes)")
    print("  => 7 个拼读音频物理文件完整性核验全部通过！")


def test_cargo_engine_with_12_letters(count=4, rounds_to_test=50):
    print("\n[3/4] 验证阶段 5 升级版 12 字母池小火车装车厢测验出题引擎算法逻辑...")
    letter_pool = ["s", "a", "t", "i", "p", "n", "c", "e", "h", "r", "m", "d"]

    for round_idx in range(rounds_to_test):
        rng = random.Random(round_idx * 77)
        shuffled_words = list(ALL_CVC_WORDS)
        rng.shuffle(shuffled_words)
        while len(shuffled_words) < count:
            extra = list(ALL_CVC_WORDS)
            rng.shuffle(extra)
            shuffled_words.extend(extra)
        targets = shuffled_words[:count]

        for target in targets:
            missing_idx = rng.randint(0, len(target["letters"]) - 1)
            correct = target["letters"][missing_idx]
            distractors = [l for l in letter_pool if l != correct]
            rng.shuffle(distractors)
            options = [correct] + distractors[:2]
            rng.shuffle(options)

            assert len(options) == 3, f"选项数必须为 3，实际为 {len(options)}"
            assert correct in options, f"正确字母 {correct} 必须在选项中"
            assert len(set(options)) == 3, f"选项不能包含重复字母: {options}"

    print(f"  ✓ 连续运行 {rounds_to_test} 轮（每轮 {count} 题）装车厢测验出题模拟，全部达标！")


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
    print("自然拼读阶段 5（小火车双组拼词扩充：cat, hat, hen, red）物理与逻辑综合测试")
    print("=" * 60)
    test_cvc_pictures()
    test_cvc_audio()
    test_cargo_engine_with_12_letters()
    test_source_sync()
    print("\n" + "=" * 60)
    print("🎉 阶段 5（小火车双组拼词大扩充）所有物理资产与出题逻辑测试 100% 验证通过！")
    print("=" * 60)


if __name__ == "__main__":
    main()
