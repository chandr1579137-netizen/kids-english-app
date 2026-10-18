# -*- coding: utf-8 -*-
"""扫描 L1–L6：标记超龄内容（神话/死亡/暴力/抽象寓意）与难度。"""
import json
import pathlib
import re
import sys

RES = pathlib.Path(r"C:\Users\Administrator\Documents\deepseek-harness\default-workspace\kids-english-app\KidsEnglish\KidsEnglish\Resources")

FLAGS = {
    "神话/神": ["god", "gods", "goddess", "spirit", "constellation", "legend", "myth",
             "orion", "zephyr", "ancient", "warrior", "hero of", "olympus"],
    "死亡/伤害": ["died", "death", "kill", "killed", "blood", "sting", "sword", "war", "battle", "poison"],
    "抽象寓意": ["pride", "wisdom", "destiny", "fate", "soul", "eternity", "means that",
             "reminds us", "lesson", "moral", "greed", "jealous"],
    "成人/商业": ["money", "boss", "salary", "office", "company", "business", "market price"],
}


def main():
    rows = []
    for level in range(1, 7):
        lessons = json.loads((RES / f"lessons-l{level}.json").read_text(encoding="utf-8"))
        for lesson in lessons:
            text = " ".join(p["text"] for p in lesson["content"]).lower()
            hits = {}
            for label, keys in FLAGS.items():
                found = [k for k in keys if re.search(rf"\b{re.escape(k)}\b", text)]
                if found:
                    hits[label] = found
            if hits:
                rows.append((level, lesson["id"], hits,
                             (lesson.get("titleEn") or lesson.get("title") or "")[:40]))

    print(f"命中超龄关键词的课文：{len(rows)} / 82")
    by_level = {}
    for level, lid, hits, title in rows:
        by_level.setdefault(level, []).append(lid)
        print(f"L{level} {lid} {title} -> " + "; ".join(f"{k}:{','.join(v)}" for k, v in hits.items()))
    print()
    for level in sorted(by_level):
        print(f"L{level}: {len(by_level[level])} 篇 -> {by_level[level]}")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
