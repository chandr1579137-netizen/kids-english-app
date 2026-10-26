import asyncio
import pathlib
import subprocess
import edge_tts

ROOT = pathlib.Path(__file__).parent.parent
OUT = ROOT / "docs" / "pm" / "phonics-samples"
OUT.mkdir(parents=True, exist_ok=True)

# 6 组核心字母：动作、锚点词、示范朗读文案
# 既有单独发音示范，又有孩子能直接模仿的趣味动作和锚点词
SAMPLES = [
    {
        "letter": "s",
        "sound": "/s/",
        "word": "snake",
        "action": "手臂像小蛇一样蜿蜒摆动",
        "texts": {
            "style_a_guide": "S makes the sound sss. Sss, sss, snake!",
            "style_b_rhyme": "The snake is in the grass. Sss, sss, sss!",
            "style_c_clean": "Snake. Sss, snake.",
        }
    },
    {
        "letter": "a",
        "sound": "/æ/",
        "word": "apple",
        "action": "手指在手臂上像小蚂蚁爬动",
        "texts": {
            "style_a_guide": "A makes the sound ah. Ah, ah, apple!",
            "style_b_rhyme": "Ants on my arm! Ah, ah, ants!",
            "style_c_clean": "Apple. Ah, apple.",
        }
    },
    {
        "letter": "t",
        "sound": "/t/",
        "word": "tiger",
        "action": "头左右转动像看网球比赛",
        "texts": {
            "style_a_guide": "T makes the sound tuh. Tiger, t-t-tiger!",
            "style_b_rhyme": "When I watch the tennis game. T, t, tennis!",
            "style_c_clean": "Tiger. T-t-tiger.",
        }
    },
    {
        "letter": "i",
        "sound": "/ɪ/",
        "word": "in",
        "action": "手指在脸颊动动模仿小老鼠胡须",
        "texts": {
            "style_a_guide": "I makes the sound ih. Ih, ih, in!",
            "style_b_rhyme": "Inky the mouse is in the house. Ih, ih, inky!",
            "style_c_clean": "In. Ih, in.",
        }
    },
    {
        "letter": "p",
        "sound": "/p/",
        "word": "pig",
        "action": "竖起手指像在吹生日蜡烛",
        "texts": {
            "style_a_guide": "P makes the sound puh. Pig, p-p-pig!",
            "style_b_rhyme": "Puff out the candles on the pink pig cake. P, p, puff!",
            "style_c_clean": "Pig. P-p-pig.",
        }
    },
    {
        "letter": "n",
        "sound": "/n/",
        "word": "nose",
        "action": "张开双臂学小飞机飞行发出嗯嗡声",
        "texts": {
            "style_a_guide": "N makes the sound nnn. Nose, n-n-nose!",
            "style_b_rhyme": "Hear the airplane, nnn, nnn, plane!",
            "style_c_clean": "Nose. Nnn, nose.",
        }
    },
]

async def generate():
    voice = "en-US-AriaNeural"
    for item in SAMPLES:
        let = item["letter"]
        for style_key, text in item["texts"].items():
            fn = OUT / f"{let}_{style_key}.mp3"
            c = edge_tts.Communicate(text, voice, rate="-5%")
            await c.save(str(fn))
            print(f"Generated {fn.name}: {text}")

if __name__ == "__main__":
    asyncio.run(generate())
