import json
import os

with open('KidsEnglish/KidsEnglish/Resources/feed-pairs.json', 'r', encoding='utf-8') as f:
    catalog = json.load(f)

with open('KidsEnglish/KidsEnglish/Resources/custom-audio-map.json', 'r', encoding='utf-8') as f:
    audio_map = json.load(f)

pairs = catalog['pairs']
print(f'Total pairs in feed-pairs.json: {len(pairs)}')

missing_audio = []
for p in pairs:
    food = p['food']
    want_key = f'feed#want-{food}'
    yummy_key = f'feed#yummy-{food}'
    for k in [want_key, yummy_key]:
        if k not in audio_map:
            missing_audio.append((k, 'not in map'))
        else:
            file_path = os.path.join('KidsEnglish/KidsEnglish/Resources/audio', audio_map[k])
            if not os.path.exists(file_path) or os.path.getsize(file_path) < 100:
                missing_audio.append((k, file_path, 'missing or empty file'))

print(f'Missing audio count: {len(missing_audio)}')
if not missing_audio:
    print('All feed audio files are verified and intact!')
