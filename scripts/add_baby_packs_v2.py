#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""启蒙模式词包扩充 v2：在 baby-path.json 现有 10 包后面加 21 包（产品经理审过的候选清单）。

- 每包一个句型 pattern，每个词一句完整的例句 sentences（冠词、复数都写死，不靠程序拼，见 daily-lesson-v2.md §3）
- 反义词两包标 pairs: true：词按「一对一对」排列，同一对同一天学，出题时互为干扰项（BabyPlan 里实现）
- 新包全部 locked: true，前面的包学完再按顺序打开
两份 baby-path.json 同时写，CI 会校验一致。用法：python scripts/add_baby_packs_v2.py
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).absolute().parent.parent
FILES = [ROOT / "KidsEnglish/KidsEnglish/Resources/baby-path.json", ROOT / "KidsEnglish/Resources/baby-path.json"]

# (id, 中文名, 句型, [(词, 例句)], pairs)
PACKS = [
    ("fruits-2", "水果", "I like ___.", [
        ("pear", "I like pears."), ("grape", "I like grapes."), ("strawberry", "I like strawberries."),
        ("cherry", "I like cherries."), ("lemon", "I like lemons."), ("mango", "I like mangoes."),
        ("peach", "I like peaches."), ("pineapple", "I like pineapples."), ("watermelon", "I like watermelon."),
    ], False),
    ("farm", "农场动物", "It's a ___.", [
        ("hen", "It's a hen."), ("sheep", "It's a sheep."), ("goat", "It's a goat."), ("donkey", "It's a donkey."),
        ("mouse", "It's a mouse."), ("frog", "It's a frog."), ("bee", "It's a bee."),
    ], False),
    ("zoo", "动物园", "Look, a ___!", [
        ("elephant", "Look, an elephant!"), ("lion", "Look, a lion!"), ("tiger", "Look, a tiger!"),
        ("monkey", "Look, a monkey!"), ("giraffe", "Look, a giraffe!"), ("zebra", "Look, a zebra!"),
        ("panda", "Look, a panda!"), ("kangaroo", "Look, a kangaroo!"), ("hippo", "Look, a hippo!"),
        ("crocodile", "Look, a crocodile!"),
    ], False),
    ("sea", "海洋动物", "I see a ___.", [
        ("dolphin", "I see a dolphin."), ("whale", "I see a whale."), ("shark", "I see a shark."),
        ("octopus", "I see an octopus."), ("turtle", "I see a turtle."), ("crab", "I see a crab."),
        ("starfish", "I see a starfish."), ("jellyfish", "I see a jellyfish."), ("seal", "I see a seal."),
    ], False),
    ("bugs-birds", "小虫和鸟", "Where is the ___?", [
        ("butterfly", "Where is the butterfly?"), ("ant", "Where is the ant?"), ("spider", "Where is the spider?"),
        ("owl", "Where is the owl?"), ("eagle", "Where is the eagle?"), ("swan", "Where is the swan?"),
        ("peacock", "Where is the peacock?"),
    ], False),
    ("food-2", "好吃的", "___, please!", [
        ("cheese", "Cheese, please!"), ("cookie", "A cookie, please!"), ("juice", "Juice, please!"),
        ("noodles", "Noodles, please!"), ("soup", "Soup, please!"), ("meat", "Meat, please!"),
        ("pizza", "Pizza, please!"), ("sandwich", "A sandwich, please!"), ("honey", "Honey, please!"),
    ], False),
    ("toys", "玩具", "I have a ___.", [
        ("ball", "I have a ball."), ("kite", "I have a kite."), ("teddy", "I have a teddy."),
        ("balloon", "I have a balloon."), ("blocks", "I have blocks."), ("doll", "I have a doll."),
        ("puzzle", "I have a puzzle."), ("robot", "I have a robot."), ("drum", "I have a drum."),
        ("yoyo", "I have a yoyo."),
    ], False),
    ("home", "家里的东西", "This is my ___.", [
        ("door", "This is my door."), ("window", "This is my window."), ("chair", "This is my chair."),
        ("table", "This is my table."), ("bed", "This is my bed."), ("lamp", "This is my lamp."),
        ("sofa", "This is my sofa."), ("clock", "This is my clock."), ("box", "This is my box."),
        ("key", "This is my key."),
    ], False),
    ("kitchen", "厨房", "Where's my ___?", [
        ("cup", "Where's my cup?"), ("spoon", "Where's my spoon?"), ("fork", "Where's my fork?"),
        ("plate", "Where's my plate?"), ("bowl", "Where's my bowl?"), ("fridge", "Where's the fridge?"),
    ], False),
    ("school-things", "文具", "Give me the ___.", [
        ("book", "Give me the book."), ("pen", "Give me the pen."), ("pencil", "Give me the pencil."),
        ("crayon", "Give me the crayon."), ("eraser", "Give me the eraser."), ("ruler", "Give me the ruler."),
        ("scissors", "Give me the scissors."), ("paper", "Give me the paper."), ("glue", "Give me the glue."),
    ], False),
    ("vehicles", "交通工具", "I can see a ___.", [
        ("car", "I can see a car."), ("bus", "I can see a bus."), ("train", "I can see a train."),
        ("plane", "I can see a plane."), ("boat", "I can see a boat."), ("bike", "I can see a bike."),
        ("taxi", "I can see a taxi."), ("truck", "I can see a truck."),
    ], False),
    ("places", "地方", "Let's go to the ___.", [
        ("school", "Let's go to school."), ("park", "Let's go to the park."), ("zoo", "Let's go to the zoo."),
        ("farm", "Let's go to the farm."), ("shop", "Let's go to the shop."),
        ("hospital", "Let's go to the hospital."), ("library", "Let's go to the library."),
        ("playground", "Let's go to the playground."),
    ], False),
    ("nature-2", "大自然", "Look at the ___!", [
        ("tree", "Look at the tree!"), ("flower", "Look at the flower!"), ("leaf", "Look at the leaf!"),
        ("grass", "Look at the grass!"), ("moon", "Look at the moon!"), ("star", "Look at the star!"),
        ("snow", "Look at the snow!"), ("sea", "Look at the sea!"), ("mountain", "Look at the mountain!"),
        ("river", "Look at the river!"),
    ], False),
    ("body-2", "身体 2", "Touch your ___.", [
        ("arm", "Touch your arm."), ("leg", "Touch your leg."), ("face", "Touch your face."),
        ("teeth", "Touch your teeth."), ("finger", "Touch your finger."), ("knee", "Touch your knee."),
    ], False),
    ("family-2", "家人 2", "This is my ___.", [
        ("sister", "This is my sister."), ("brother", "This is my brother."), ("friend", "This is my friend."),
        ("aunt", "This is my aunt."), ("uncle", "This is my uncle."),
    ], False),
    ("actions-2", "我会做 2", "I can ___.", [
        ("swim", "I can swim."), ("fly", "I can fly."), ("sit", "I can sit."), ("stand", "I can stand."),
        ("sing", "I can sing."), ("dance", "I can dance."), ("read", "I can read."), ("draw", "I can draw."),
        ("walk", "I can walk."), ("climb", "I can climb."),
    ], False),
    ("actions-3", "我会做 3", "Let's ___!", [
        ("kick", "Let's kick the ball!"), ("throw", "Let's throw the ball!"), ("catch", "Let's catch the ball!"),
        ("hug", "Let's hug!"), ("kiss", "Give me a kiss!"), ("smile", "Let's smile!"), ("laugh", "Let's laugh!"),
        ("cry", "Don't cry!"), ("cook", "Let's cook!"), ("clean", "Let's clean up!"),
    ], False),
    ("opposites-1", "反义词 1", "It's ___.", [
        ("big", "It's big."), ("small", "It's small."), ("tall", "It's tall."), ("short", "It's short."),
        ("fast", "It's fast."), ("slow", "It's slow."), ("happy", "I'm happy."), ("sad", "I'm sad."),
    ], True),
    ("opposites-2", "反义词 2", "It's ___.", [
        ("wet", "It's wet."), ("dry", "It's dry."), ("full", "It's full."), ("empty", "It's empty."),
        ("loud", "It's loud."), ("quiet", "It's quiet."), ("old", "It's old."), ("new", "It's new."),
    ], True),
    ("numbers-3", "数字 11–20", "I can count to ___!", [
        (w, f"I can count to {w}!") for w in
        ["eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen",
         "twenty"]
    ], False),
    ("feelings", "我的感受", "I'm ___.", [
        ("hungry", "I'm hungry."), ("thirsty", "I'm thirsty."), ("angry", "I'm angry."), ("afraid", "I'm afraid."),
        ("sleepy", "I'm sleepy."), ("tired", "I'm tired."),
    ], False),
]


def main() -> int:
    data = json.loads(FILES[0].read_text(encoding="utf-8"))
    old_ids = [p["id"] for p in data["packs"]]
    data["packs"] = [p for p in data["packs"] if p["id"] in old_ids[:10]]  # 重跑时只保留原来的 10 包
    have = {w for p in data["packs"] for w in p["words"]}
    for pid, name, pattern, items, pairs in PACKS:
        words = [w for w, _ in items]
        dup = [w for w in words if w in have]
        assert not dup, f"{pid}: 重复的词 {dup}"
        have.update(words)
        if pairs:
            assert len(words) % 2 == 0, f"{pid}: 反义词包要成对"
        pack = {"id": pid, "nameZh": name, "songId": None, "locked": True, "words": words,
                "pattern": pattern, "sentences": dict(items)}
        if pairs:
            pack["pairs"] = True
        data["packs"].append(pack)
    data["version"] = 2
    data["note"] = ("启蒙模式词包（原名宝宝模式；孩子 5 岁）。前 10 包来自 PR #3 的 4 岁路线；"
                    "后面 21 包是 v2 扩充（产品经理审过，见 docs/pm/baby-packs-v2.md），每词一句完整例句。")
    text = json.dumps(data, ensure_ascii=False, indent=1) + "\n"
    for f in FILES:
        f.write_text(text, encoding="utf-8")
    n = sum(len(p["words"]) for p in data["packs"])
    print(f"{len(data['packs'])} 包 {n} 个词")
    return 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    raise SystemExit(main())
