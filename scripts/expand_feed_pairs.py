import os
import json
import hashlib
import asyncio
import edge_tts

NEW_PAIRS = [
    # 保持前 9 个不变
    {"animal": "monkey", "food": "banana", "want": "I want a banana!", "yummy": "Yummy banana!"},
    {"animal": "rabbit", "food": "vegetable", "want": "I want some vegetables!", "yummy": "Yummy vegetables!"},
    {"animal": "cat", "food": "fish", "want": "I want a fish!", "yummy": "Yummy fish!"},
    {"animal": "dog", "food": "meat", "want": "I want some meat!", "yummy": "Yummy meat!"},
    {"animal": "mouse", "food": "cheese", "want": "I want some cheese!", "yummy": "Yummy cheese!"},
    {"animal": "bee", "food": "honey", "want": "I want some honey!", "yummy": "Yummy honey!"},
    {"animal": "bear", "food": "honey", "want": "I want some honey!", "yummy": "Yummy honey!"},
    {"animal": "horse", "food": "apple", "want": "I want an apple!", "yummy": "Yummy apple!"},
    {"animal": "kitten", "food": "milk", "want": "I want some milk!", "yummy": "Yummy milk!"},
    # 新增 15 组
    {"animal": "panda", "food": "watermelon", "want": "I want a watermelon!", "yummy": "Yummy watermelon!"},
    {"animal": "pig", "food": "tomato", "want": "I want a tomato!", "yummy": "Yummy tomato!"},
    {"animal": "duck", "food": "bread", "want": "I want some bread!", "yummy": "Yummy bread!"},
    {"animal": "chicken", "food": "rice", "want": "I want some rice!", "yummy": "Yummy rice!"},
    {"animal": "puppy", "food": "egg", "want": "I want an egg!", "yummy": "Yummy egg!"},
    {"animal": "fox", "food": "grape", "want": "I want some grapes!", "yummy": "Yummy grapes!"},
    {"animal": "koala", "food": "cake", "want": "I want some cake!", "yummy": "Yummy cake!"},
    {"animal": "penguin", "food": "peach", "want": "I want a peach!", "yummy": "Yummy peach!"},
    {"animal": "cow", "food": "pear", "want": "I want a pear!", "yummy": "Yummy pear!"},
    {"animal": "sheep", "food": "strawberry", "want": "I want a strawberry!", "yummy": "Yummy strawberry!"},
    {"animal": "squirrel", "food": "cookie", "want": "I want a cookie!", "yummy": "Yummy cookie!"},
    {"animal": "elephant", "food": "orange", "want": "I want an orange!", "yummy": "Yummy orange!"},
    {"animal": "frog", "food": "noodles", "want": "I want some noodles!", "yummy": "Yummy noodles!"},
    {"animal": "bird", "food": "cherry", "want": "I want a cherry!", "yummy": "Yummy cherry!"},
    {"animal": "lion", "food": "pizza", "want": "I want a pizza!", "yummy": "Yummy pizza!"}
]

VOICE = "en-US-AnaNeural" # 纯正美音可爱童声

async def generate_tts(text, out_path):
    communicate = edge_tts.Communicate(text, VOICE)
    await communicate.save(out_path)

async def main():
    audio_dir = "KidsEnglish/KidsEnglish/Resources/audio"
    os.makedirs(audio_dir, exist_ok=True)

    # 读取旧 map
    map_path = "KidsEnglish/KidsEnglish/Resources/custom-audio-map.json"
    with open(map_path, 'r', encoding='utf-8') as f:
        audio_map = json.load(f)

    # 找出需要生成的音频
    to_gen = []
    for p in NEW_PAIRS:
        food = p["food"]
        want_key = f"feed#want-{food}"
        yummy_key = f"feed#yummy-{food}"

        if want_key not in audio_map:
            h = hashlib.sha256(f"want_{food}".encode()).hexdigest()[:20]
            fname = f"{h}.mp3"
            audio_map[want_key] = fname
            to_gen.append((p["want"], os.path.join(audio_dir, fname)))

        if yummy_key not in audio_map:
            h = hashlib.sha256(f"yummy_{food}".encode()).hexdigest()[:20]
            fname = f"{h}.mp3"
            audio_map[yummy_key] = fname
            to_gen.append((p["yummy"], os.path.join(audio_dir, fname)))

    print(f"Generating {len(to_gen)} new feed audio files...")
    for text, path in to_gen:
        if not os.path.exists(path) or os.path.getsize(path) < 100:
            await generate_tts(text, path)

    # 保存 audio_map 到两份资源
    for p in ["KidsEnglish/KidsEnglish/Resources/custom-audio-map.json", "KidsEnglish/Resources/custom-audio-map.json"]:
        if os.path.exists(os.path.dirname(p)):
            with open(p, 'w', encoding='utf-8') as f:
                json.dump(audio_map, f, indent=1, ensure_ascii=False)

    # 保存 feed-pairs.json 到两份资源
    catalog_data = {
        "noThanks": "No, thank you!",
        "pairs": NEW_PAIRS
    }
    for p in ["KidsEnglish/KidsEnglish/Resources/feed-pairs.json", "KidsEnglish/Resources/feed-pairs.json"]:
        if os.path.exists(os.path.dirname(p)):
            with open(p, 'w', encoding='utf-8') as f:
                json.dump(catalog_data, f, indent=1, ensure_ascii=False)

    print("Successfully expanded feed-pairs.json and custom-audio-map.json!")

if __name__ == '__main__':
    asyncio.run(main())
