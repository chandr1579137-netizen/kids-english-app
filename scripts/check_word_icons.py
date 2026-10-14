#!/usr/bin/env python3
"""Confirm word-icon lookup matches DataStore.iconURL(forWord:).

The app indexes every file under word-icons/ and keys it by
URL.deletingPathExtension().lastPathComponent.lowercased().
iconURL(forWord:) returns that entry for word.lowercased().

So a word resolves when a file named "<word lowercased>.jpg"
(or .png/.jpeg/.webp) is in the word-icons folder. Extensions are
stripped the same way as Foundation: the suffix after the last dot.

Existing icons ship in the assets bundle (not git). Pass --assets-zip
to also prove those files were not replaced and every word that
resolved before still resolves to the same bytes.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ICON_DIRS = [
    ROOT / "KidsEnglish" / "KidsEnglish" / "Resources" / "word-icons",
    ROOT / "KidsEnglish" / "Resources" / "word-icons",
]
WORD_PARTS = ["a", "b", "c", "d"]
EXTS = {".png", ".jpg", ".jpeg", ".webp"}


def stem_key(filename: str) -> str:
    """Match URL.deletingPathExtension().lastPathComponent.lowercased()."""
    base = os.path.basename(filename)
    root, ext = os.path.splitext(base)
    if ext.lower() not in EXTS:
        return base.lower()
    return root.lower()


def index_files(paths: list[Path]) -> dict[str, Path]:
    """First file for each key wins, same as DataStore.ensureWordIconIndex."""
    index: dict[str, Path] = {}
    for path in paths:
        if not path.is_file():
            continue
        if path.suffix.lower() not in EXTS:
            continue
        if "/word-icons/" not in path.as_posix() and path.parent.name != "word-icons":
            continue
        key = stem_key(path.name)
        index.setdefault(key, path)
    return index


def load_dict_words() -> list[str]:
    words: list[str] = []
    for part in WORD_PARTS:
        path = ROOT / "KidsEnglish" / "Resources" / f"words-{part}.json"
        words.extend(item["word"] for item in json.loads(path.read_text()))
    return words


def load_missing(path: Path) -> list[str]:
    return [line.rstrip("\n") for line in path.read_text().splitlines() if line.strip()]


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--missing",
        type=Path,
        default=ROOT / "scripts" / "missing-words.txt",
    )
    parser.add_argument("--assets-zip", type=Path, default=None)
    args = parser.parse_args()

    failures: list[str] = []
    missing = load_missing(args.missing)
    dict_words = load_dict_words()
    print(f"missing words: {len(missing)}")
    print(f"dictionary words: {len(dict_words)}")

    dir_indexes = []
    for directory in ICON_DIRS:
        if not directory.is_dir():
            failures.append(f"missing icon directory: {directory}")
            dir_indexes.append({})
            continue
        files = [p for p in directory.iterdir() if p.is_file() and p.suffix.lower() in EXTS]
        dir_indexes.append(index_files(files))
        print(f"{directory.relative_to(ROOT)}: {len(files)} images, {len(dir_indexes[-1])} keys")

    if len(dir_indexes) == 2 and dir_indexes[0] and dir_indexes[1]:
        names_a = {p.name: sha256(p) for p in dir_indexes[0].values()}
        names_b = {p.name: sha256(p) for p in dir_indexes[1].values()}
        if names_a != names_b:
            failures.append("the two word-icons folders are not identical")

    repo_index = dir_indexes[0] if dir_indexes else {}

    unresolved = [word for word in missing if word.lower() not in repo_index]
    print(f"new words resolving: {len(missing) - len(unresolved)}/{len(missing)}")
    if unresolved:
        failures.append(f"{len(unresolved)} new words do not resolve")
        for word in unresolved[:20]:
            print("  unresolved:", repr(word), "->", repr(word.lower() + ".jpg"))

    # Case-only pairs share one file because the lookup lowercases the word.
    folded: dict[str, list[str]] = {}
    for word in missing:
        folded.setdefault(word.lower(), []).append(word)
    shared = {key: names for key, names in folded.items() if len(names) > 1}
    if shared:
        print("case-insensitive shared files:")
        for key, names in sorted(shared.items()):
            path = repo_index.get(key)
            print(f"  {names} -> {path.name if path else 'MISSING'}")

    if args.assets_zip:
        if not args.assets_zip.is_file():
            failures.append(f"assets zip not found: {args.assets_zip}")
        else:
            failures.extend(check_existing(args.assets_zip, repo_index, dict_words))

    if failures:
        print("FAILED")
        for item in failures:
            print(" -", item)
        return 1
    print("OK")
    return 0


def check_existing(zip_path: Path, repo_index: dict[str, Path], dict_words: list[str]) -> list[str]:
    failures: list[str] = []
    original: dict[str, tuple[str, str]] = {}
    with zipfile.ZipFile(zip_path) as archive:
        for info in archive.infolist():
            if not info.filename.endswith(tuple(EXTS)):
                continue
            if "/word-icons/" not in info.filename:
                continue
            name = os.path.basename(info.filename)
            if not name:
                continue
            key = stem_key(name)
            digest = hashlib.sha256(archive.read(info)).hexdigest()
            if key in original:
                failures.append(f"duplicate original key {key}")
            original[key] = (name, digest)

    print(f"original bundle icons: {len(original)}")
    overlap = sorted(set(original) & set(repo_index))
    if overlap:
        failures.append(f"{len(overlap)} new files reuse an existing icon name")
        for key in overlap[:20]:
            print("  overlap:", original[key][0])

    lost = []
    changed = []
    for word in dict_words:
        key = word.lower()
        if key not in original:
            continue
        name, digest = original[key]
        # Originals are not committed; they must still be absent or byte-identical.
        committed = repo_index.get(key)
        if committed is not None and sha256(committed) != digest:
            changed.append(word)
        if key not in original:
            lost.append(word)
    # Words that resolved before must still resolve to the original bytes
    # once the bundle is merged with the new files (no name collision).
    still = 0
    for word in dict_words:
        key = word.lower()
        if key not in original:
            continue
        if overlap and key in repo_index and sha256(repo_index[key]) != original[key][1]:
            continue
        still += 1
    before = sum(1 for word in dict_words if word.lower() in original)
    print(f"dictionary words that already resolved: {before}")
    print(f"still resolve to the original file: {still}/{before}")
    if still != before or changed:
        failures.append("an existing word lost or changed its image")
        for word in changed[:20]:
            print("  changed:", repr(word))

    # Pre-existing filename that does not match its dictionary spelling.
    unmatched = [word for word in dict_words if word.lower() not in original]
    if unmatched:
        print("dictionary words with no same-name icon in the original bundle:")
        for word in unmatched:
            print(" ", repr(word))
    return failures


if __name__ == "__main__":
    sys.exit(main())
