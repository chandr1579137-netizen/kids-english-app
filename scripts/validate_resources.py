# -*- coding: utf-8 -*-
"""按 Swift 模型的必填字段校验 Resource JSON。

DataStore.load() 用 `try?` 解码，字段缺失会静默变成空数组 —— 界面照常渲染，
只是课文/单词凭空少了一批。这个脚本把「静默丢数据」变成构建失败。
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "KidsEnglish/KidsEnglish/Resources")
errors = []


def need(obj, keys, where):
    for k in keys:
        if k not in obj:
            errors.append(f"{where}: 缺字段 {k}")


def check_options(q, qid):
    opts = q.get("options") or []
    if not opts:
        errors.append(f"{qid}: 选项为空")
    for o in opts:
        if "text" not in o and "value" not in o:
            errors.append(f"{qid}: 选项缺 text/value")
    if q.get("correctAnswer") not in [o.get("value") for o in opts]:
        errors.append(f"{qid}: 正确答案不在选项里")


def check_lessons(name, expected_min):
    path = ROOT / name
    data = json.loads(path.read_text(encoding="utf-8"))
    if len(data) < expected_min:
        errors.append(f"{name}: 只有 {len(data)} 篇（至少 {expected_min}）")
    for lesson in data:
        lid = lesson.get("id", "?")
        need(lesson, ["id", "level", "title", "titleCn", "content"], f"{name}/{lid}")
        for p in lesson.get("content", []):
            need(p, ["paragraphId", "text", "translation", "audioStart", "audioEnd", "words"],
                 f"{name}/{lid}/content")
            if not p.get("text"):
                errors.append(f"{name}/{lid}: 空段落")
        for q in lesson.get("quiz", []):
            qid = f"{name}/{lid}/quiz/{q.get('id', '?')}"
            need(q, ["id", "type", "question"], qid)
            qtype = q.get("type")
            if qtype == "fill_blank":
                need(q, ["blank", "options", "correctAnswer"], qid)
                check_options(q, qid)
            elif qtype == "image_choice":
                need(q, ["options", "correctAnswer"], qid)
                check_options(q, qid)
            elif qtype == "word_builder":
                need(q, ["shuffledWords", "correctAnswer"], qid)
                # 字母积木：correctAnswer 是拼好的单词，shuffledWords 是字母
                letters = "".join(q.get("shuffledWords") or []).lower()
                if sorted(letters) != sorted((q.get("correctAnswer") or "").lower()):
                    errors.append(f"{qid}: 字母积木与答案对不上")
            elif qtype == "sentence_order":
                need(q, ["shuffledWords", "correctOrder"], qid)
                if sorted(q.get("shuffledWords") or []) != sorted(q.get("correctOrder") or []):
                    errors.append(f"{qid}: 乱序词与正确语序不是同一组词")
            else:
                errors.append(f"{qid}: 未知题型 {qtype}")
    return len(data)


def main():
    total = 0
    for i in range(1, 8):
        total += check_lessons(f"lessons-l{i}.json", 1)

    words = []
    for f in ("words-a.json", "words-b.json", "words-c.json", "words-d.json"):
        words += json.loads((ROOT / f).read_text(encoding="utf-8"))
    for w in words:
        need(w, ["word", "meaningCn"], "words")
        if not (w.get("meaningCn") or "").strip():
            errors.append(f"words/{w.get('word')}: 空释义")

    themes = json.loads((ROOT / "word-themes.json").read_text(encoding="utf-8"))
    index = {w["word"].lower() for w in words}
    theme_words = 0
    for t in themes:
        need(t, ["id", "nameCn", "words"], "word-themes")
        theme_words += len(t["words"])
        for w in t["words"]:
            if w.lower() not in index:
                errors.append(f"word-themes/{t['id']}: {w} 不在词库")

    print(f"课文 {total} 篇 / 词 {len(words)} 条 / 主题 {len(themes)} 个（{theme_words} 词）")
    if errors:
        print("\n".join(errors[:40]))
        print(f"共 {len(errors)} 处问题")
        sys.exit(1)
    print("资源结构校验通过")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
