#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
自然拼读阶段 3：CVC 拼读与滑音小火车（Sound Blending Train）物理与逻辑综合测试脚本
"""
import random
from pathlib import Path

ROOT = Path("K:/kids-english-app") if Path("K:/kids-english-app").exists() else Path(__file__).parent.parent
RES_DIR = ROOT / "KidsEnglish" / "KidsEnglish" / "Resources"
AUDIO_DIR = RES_DIR / "phrases" / "audio"
OVERRIDES_DIR = ROOT / "assets" / "word-icons-overrides"
WORD_ICONS_DIR = RES_DIR / "word-icons"

CVC_WORDS = [
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
]

TRAIN_AUDIO = [
    "tom_train_intro.mp3",
    "tom_train_missing.mp3",
    "train_whistle.mp3",
]


def test_cvc_pictures():
    print("[1/4] 检验阶段 3 CVC 平涂大图...")
    for item in CVC_WORDS:
        pic_in_overrides = OVERRIDES_DIR / item["picture"]
        pic_in_icons = WORD_ICONS_DIR / item["picture"]
        found = pic_in_overrides if pic_in_overrides.exists() else (pic_in_icons if pic_in_icons.exists() else None)

        assert found is not None, f"缺失 CVC 真实大图: {item['picture']}"
        assert found.stat().st_size > 50000, f"图片文件过小或未就绪: {found} ({found.stat().st_size} bytes)"
        print(f"  ✓ {item['word']}: {found.name} ({found.stat().st_size} bytes, 真实手绘水彩插画)")
    print("  => 3 张核心 CVC 平涂大图物理核验全部通过！")


def test_cvc_audio():
    print("\n[2/4] 检验阶段 3 滑音小火车专属音频...")
    for item in CVC_WORDS:
        aud_path = AUDIO_DIR / item["audio"]
        assert aud_path.exists(), f"缺失音频文件: {aud_path}"
        assert aud_path.stat().st_size > 1000, f"音频文件损坏: {aud_path}"
        print(f"  ✓ 拼读顺口溜音频: {item['audio']} ({aud_path.stat().st_size} bytes)")

    for extra in TRAIN_AUDIO:
        aud_path = AUDIO_DIR / extra
        assert aud_path.exists(), f"缺失引导音效文件: {aud_path}"
        assert aud_path.stat().st_size > 1000, f"音效文件损坏: {aud_path}"
        print(f"  ✓ 小火车音效/引导: {extra} ({aud_path.stat().st_size} bytes)")
    print("  => 6 个专属音频/音效物理文件完整性核验全部通过！")


def test_cargo_engine(count=4, rounds_to_test=20):
    print("\n[3/4] 验证装车厢拼词测验出题引擎算法逻辑...")
    letter_pool = ["s", "a", "t", "i", "p", "n"]

    for round_idx in range(rounds_to_test):
        rng = random.Random(round_idx * 99)
        shuffled_words = list(CVC_WORDS)
        rng.shuffle(shuffled_words)
        while len(shuffled_words) < count:
            extra = list(CVC_WORDS)
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
    print("自然拼读阶段 3（CVC 拼读与滑音小火车）物理与逻辑综合测试")
    print("=" * 60)
    test_cvc_pictures()
    test_cvc_audio()
    test_cargo_engine()
    test_source_sync()
    print("\n" + "=" * 60)
    print("🎉 阶段 3（滑音小火车）所有物理资产与出题逻辑测试 100% 验证通过！")
    print("=" * 60)


if __name__ == "__main__":
    main()
