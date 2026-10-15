#!/usr/bin/env python3
"""JSON, icon, and word-book checks for the study data."""

from __future__ import annotations

import json
import os
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "KidsEnglish" / "Resources"
ICON_DIRS = [
    RES / "word-icons",
    ROOT / "KidsEnglish" / "KidsEnglish" / "Resources" / "word-icons",
]
EXTS = {".png", ".jpg", ".jpeg", ".webp"}
ASSETS = Path("/tmp/assets-bundle-v3.zip")


def stem(name: str) -> str:
    root, ext = os.path.splitext(os.path.basename(name))
    if ext.lower() not in EXTS:
        return os.path.basename(name).lower()
    return root.lower()


def main() -> int:
    failures: list[str] = []
    icons: set[str] = set()
    for directory in ICON_DIRS:
        if not directory.is_dir():
            failures.append(f"missing {directory}")
            continue
        for path in directory.iterdir():
            if path.suffix.lower() in EXTS:
                icons.add(stem(path.name))
    if ASSETS.is_file():
        with zipfile.ZipFile(ASSETS) as archive:
            for name in archive.namelist():
                if "/word-icons/" in name and name.lower().endswith(tuple(EXTS)):
                    icons.add(stem(name))

    words = []
    seen: dict[str, str] = {}
    for part in "abcde":
        path = RES / f"words-{part}.json"
        try:
            rows = json.loads(path.read_text())
        except json.JSONDecodeError as error:
            failures.append(f"{path.name} invalid JSON: {error}")
            continue
        if not isinstance(rows, list) or not rows:
            failures.append(f"{path.name} is empty")
            continue
        for row in rows:
            key = row["word"].lower()
            if key in seen:
                failures.append(f"duplicate {row['word']} and {seen[key]}")
            seen[key] = row["word"]
            words.append(row)
            if key not in icons:
                failures.append(f"no icon for {row['word']}")
            if not row.get("meaningCn"):
                failures.append(f"missing meaning {row['word']}")
            if part == "e" and not str(row.get("phonetic", "")).startswith("/"):
                failures.append(f"incomplete gloss {row['word']}")

    themes = json.loads((RES / "word-themes.json").read_text())
    catalog = json.loads((RES / "word-books.json").read_text())
    if "chang'e" not in icons:
        failures.append("chang'e icon missing")
    if "chang'e" not in seen:
        failures.append("chang'e missing from dictionary")

    missing = [
        line.strip()
        for line in (ROOT / "scripts" / "missing-words.txt").read_text().splitlines()
        if line.strip()
    ]
    uncovered = [word for word in missing if word.lower() not in seen]
    # Dear/dear and OK/ok share one dictionary row.
    real_gaps = [word for word in uncovered if word.lower() not in {"dear", "ok"} or word.lower() not in seen]
    if any(word.lower() not in seen for word in missing):
        failures.append(f"missing-words not in dictionary: {uncovered[:8]}")

    theme_words = {word.lower() for theme in themes for word in theme["words"]}
    new_keys = {row["word"].lower() for row in json.loads((RES / "words-e.json").read_text())}
    outside = sorted(new_keys - theme_words)
    if outside:
        failures.append(f"{len(outside)} new words are not in a theme")

    for group in catalog["groups"]:
        if not group["books"]:
            failures.append(f"empty group {group['id']}")
        for book in group["books"]:
            if book.get("themeId"):
                match = next((theme for theme in themes if theme["id"] == book["themeId"]), None)
                count = len(match["words"]) if match else 0
            else:
                count = len(book.get("words") or [])
                for word in book.get("words") or []:
                    if word.lower() not in seen:
                        failures.append(f"{book['id']} word not in dictionary: {word}")
                        break
            if count <= 0:
                failures.append(f"empty book {book['id']}")

    print(f"dictionary {len(words)} icons {len(icons)} new {len(new_keys)}")
    print(f"books {sum(len(group['books']) for group in catalog['groups'])}")
    if failures:
        print("FAILED")
        for item in failures[:30]:
            print(" -", item)
        return 1
    print("OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
