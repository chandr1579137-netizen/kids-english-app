import os
import json
import asyncio
import edge_tts

JSON_PATH = 'KidsEnglish/KidsEnglish/Resources/phrases/phrases.json'
OUT_DIR = 'KidsEnglish/KidsEnglish/Resources/phrases/audio'

VOICE = 'zh-CN-XiaoxiaoNeural' # 微软高音质亲切女声/女教师

async def generate_audio(text: str, out_file: str):
    communicate = edge_tts.Communicate(text, VOICE, rate='+0%', volume='+0%')
    await communicate.save(out_file)

async def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    with open(JSON_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)

    tasks = []
    lines_to_gen = []

    for level in data.get('levels', []):
        for scene in level.get('scenes', []):
            for line in scene.get('lines', []):
                audio_file = line.get('audio')
                zh_text = line.get('zh')
                if audio_file and zh_text:
                    out_name = f"zh_{audio_file}"
                    out_path = os.path.join(OUT_DIR, out_name)
                    lines_to_gen.append((zh_text, out_path, out_name))

    print(f"Total lines to generate: {len(lines_to_gen)}")

    # 批处理生成，每批 10 个并发
    batch_size = 10
    success_count = 0
    for i in range(0, len(lines_to_gen), batch_size):
        batch = lines_to_gen[i:i+batch_size]
        batch_tasks = []
        for zh_text, out_path, out_name in batch:
            if not os.path.exists(out_path) or os.path.getsize(out_path) < 100:
                batch_tasks.append(generate_audio(zh_text, out_path))
            else:
                success_count += 1
        if batch_tasks:
            await asyncio.gather(*batch_tasks)
            success_count += len(batch_tasks)
        print(f"Progress: {min(i+batch_size, len(lines_to_gen))}/{len(lines_to_gen)} done.")

    print(f"Finished generating {success_count} Chinese phrase audio files!")

if __name__ == '__main__':
    asyncio.run(main())
