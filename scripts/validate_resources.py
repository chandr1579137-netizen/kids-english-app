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


def check_word_audio(words):
    """每个词都要有发音：映射必须存在且指向真实 mp3。

    21–99 的数字音频不在资源目录里，由 CI 解压资源包后再并入映射，
    所以这里只校验增量映射覆盖了这些词，文件存在性交给合并步骤。
    """
    mapping = json.loads((ROOT / "word-audio-map.json").read_text(encoding="utf-8"))
    additions_path = ROOT.parents[2] / "assets" / "number-audio" / "word-audio-map-additions.json"
    additions = json.loads(additions_path.read_text(encoding="utf-8")) if additions_path.exists() else {}

    missing_map, missing_file = [], []
    for w in words:
        word = w["word"]
        key = word.lower()
        file = mapping.get(key)
        if file is None:
            if key not in additions:
                missing_map.append(word)
        elif not (ROOT / "audio" / file).exists():
            missing_file.append(f"{word} → {file}")

    if missing_map:
        errors.append(f"words: 无发音映射 {len(missing_map)} 个：{', '.join(missing_map[:10])}")
    if missing_file:
        errors.append(f"words: 映射指向的音频不存在 {len(missing_file)} 个：{', '.join(missing_file[:10])}")
    return len(words) - len(missing_map) - len(missing_file)


def check_phrases():
    """「说一说」口语课：每句都要有音频、配图（新图 / 现成词图 / 代码卡三选一）和说话人头像。"""
    folder = ROOT / "phrases"
    data = json.loads((folder / "phrases.json").read_text(encoding="utf-8"))
    overrides = ROOT.parents[2] / "assets" / "word-icons-overrides"
    avatars = {c["id"]: c["avatar"] for c in data["characters"]}
    lines = 0
    for level in data["levels"]:
        for scene in level["scenes"]:
            for ln in scene["lines"]:
                lines += 1
                lid = ln.get("id", "?")
                need(ln, ["id", "speaker", "en", "zh", "audio"], f"phrases/{lid}")
                if not (folder / "audio" / ln["audio"]).exists():
                    errors.append(f"phrases/{lid}: 缺音频 {ln['audio']}")
                pics = [k for k in ("image", "icon", "code") if ln.get(k)]
                if len(pics) != 1:
                    errors.append(f"phrases/{lid}: 配图要 image / icon / code 三选一，现在是 {pics}")
                if ln.get("image") and not (folder / "img" / ln["image"]).exists():
                    errors.append(f"phrases/{lid}: 缺图 {ln['image']}")
                for key in ("icon", "codeIcon"):
                    if ln.get(key) and not (overrides / f"{ln[key]}.jpg").exists():
                        errors.append(f"phrases/{lid}: 词图 {ln[key]} 不在 word-icons-overrides")
                avatar = avatars.get(ln["speaker"])
                if avatar is None or not (folder / "avatars" / avatar).exists():
                    errors.append(f"phrases/{lid}: 说话人 {ln['speaker']} 没有头像")
    return lines


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

    with_audio = check_word_audio(words)
    phrase_lines = check_phrases()

    print(f"课文 {total} 篇 / 词 {len(words)} 条（发音 {with_audio}） / 主题 {len(themes)} 个（{theme_words} 词）"
          f" / 口语 {phrase_lines} 句")
    if errors:
        print("\n".join(errors[:40]))
        print(f"共 {len(errors)} 处问题")
        sys.exit(1)
    print("资源结构校验通过")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
