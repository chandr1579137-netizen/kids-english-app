#!/usr/bin/env python3
"""Check the age-4 child surface stays inside the approved 63 words."""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "KidsEnglish" / "Resources"
APP = (ROOT / "KidsEnglish" / "KidsEnglishApp.swift").read_text()
LEARN = (ROOT / "KidsEnglish" / "LearnWordsView.swift").read_text()
GAME = (ROOT / "KidsEnglish" / "ConsolidationGames1.swift").read_text()
WORKFLOW = (ROOT / ".github" / "workflows" / "build.yml").read_text()

failures = []


def fail(message):
    failures.append(message)


catalog = json.loads((RES / "age4-path.json").read_text())
words = []
for part in "abcde":
    words.extend(json.loads((RES / f"words-{part}.json").read_text()))
by_word = {row["word"].lower(): row for row in words}
lessons = []
for level in range(1, 8):
    lessons.extend(json.loads((RES / f"lessons-l{level}.json").read_text()))
songs = json.loads((RES / "songs.json").read_text())

unlocked = [pack for pack in catalog["packs"] if not pack["locked"]]
locked = [pack for pack in catalog["packs"] if pack["locked"]]
keys = []
for pack in unlocked:
    keys.extend(word.lower() for word in pack["words"])
if len(unlocked) != 8 or len(keys) != 63 or len(set(keys)) != 63:
    fail(f"expected 8 packs and 63 words, got {len(unlocked)} packs and {len(keys)} words")
if [pack["id"] for pack in locked] != ["numbers-2", "clothes", "weather"]:
    fail("locked round 2 is not clothes / weather / 6-10")
if catalog["childLessonIds"] != [
    "l1_002", "l1_003", "l1_004", "l1_006", "l1_007", "l1_008", "l1_009", "l1_010"
]:
    fail("child picture books changed")
if catalog["childSongIds"] != ["song_001", "song_002", "song_003", "song_004", "song_007", "song_010"]:
    fail("child songs changed")
if len(lessons) < 90:
    fail(f"lessons were deleted: {len(lessons)}")
if len(songs) < 10:
    fail(f"songs were deleted: {len(songs)}")

lesson_ids = {lesson["id"] for lesson in lessons}
for lesson_id in catalog["childLessonIds"]:
    if lesson_id not in lesson_ids:
        fail(f"missing child lesson {lesson_id}")
song_ids = {song["id"] for song in songs}
for song_id in catalog["childSongIds"]:
    if song_id not in song_ids:
        fail(f"missing child song {song_id}")

for key in keys:
    row = by_word.get(key)
    if row is None:
        fail(f"missing dictionary word {key}")
        continue
    phonetic = row.get("phonetic") or ""
    meaning = row.get("meaningCn") or ""
    if not phonetic.startswith("/") or not meaning:
        fail(f"bad gloss {key}: {phonetic} {meaning}")

for name in ("ReadView()", "PictureBookView()", "WordCardsView()", "ProfileView()"):
    if name in APP:
        fail(f"child root still shows {name}")
for name in ("Age4PicturesView()", "ParentRootView()", "SongsView(childMode: true)"):
    if name not in APP:
        fail(f"child root missing {name}")
if "case today, pictures, songs, parent" not in APP:
    fail("tab bar is not 今天/图画/儿歌/家长")
if "choicePool" not in GAME or "choicePool ?? store.words" not in GAME:
    fail("听音选图 still draws distractors from the whole dictionary")
if "store.age4UnlockedWords()" not in LEARN:
    fail("child game is not limited to the unlocked words")
if "parentLibrary ? store.reviewEntries() : store.age4Review()" not in LEARN:
    fail("child review is not filtered to the age-4 words")
if "var dailyNewWords: Int = 3" not in (ROOT / "KidsEnglish" / "DataStore.swift").read_text():
    fail("daily new words is not 3")
if "unzip -q -n assets-bundle-v3.zip" not in WORKFLOW:
    fail("asset unzip would overwrite the no-text icons")
for project in (
    ROOT / "KidsEnglish.xcodeproj" / "project.pbxproj",
    ROOT / "KidsEnglish" / "KidsEnglish.xcodeproj" / "project.pbxproj",
):
    text = project.read_text()
    if "age4-path.json" not in text:
        fail(f"{project} does not bundle age4-path.json")

nested = ROOT / "KidsEnglish" / "KidsEnglish"
for name in (
    "KidsEnglishApp.swift", "DataStore.swift", "Models.swift", "LearnWordsView.swift",
    "ConsolidationGames1.swift", "SongsView.swift", "ParentView.swift",
    "WordCardsView.swift", "PictureBookView.swift", "ReadView.swift",
):
    if (ROOT / "KidsEnglish" / name).read_bytes() != (nested / name).read_bytes():
        fail(f"nested copy drifted: {name}")

print(f"age4 words {len(set(keys))} lessons {len(lessons)} songs {len(songs)}")
if failures:
    print("FAILED")
    for item in failures:
        print(" -", item)
    sys.exit(1)
print("OK")
