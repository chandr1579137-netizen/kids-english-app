#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""启蒙模式词包 v2：补齐前 10 包的句型/例句/家长提示，并在后面加 21 包（见 docs/pm/daily-lesson-v2.md 与 baby-packs-v2.md）。

- 每包一个句型 pattern、一句家长提示 tipZh，每个词一句完整的例句 sentences（冠词、复数都写死，不靠程序拼，见 daily-lesson-v2.md §3）
- 顺手修正两句（HANDOFF.md T4）：
  - fly: "I can fly." -> "Birds can fly."
  - teeth: "Touch your teeth." -> "Show me your teeth."
- 反义词两包标 pairs: true：词按「一对一对」排列，同一对同一天学，出题时互为干扰项
- 新包全部 locked: true，前面的包学完再按顺序打开
两份 baby-path.json 同时写，CI 会校验一致。用法：python scripts/add_baby_packs_v2.py
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).absolute().parent.parent
FILES = [ROOT / "KidsEnglish/KidsEnglish/Resources/baby-path.json", ROOT / "KidsEnglish/Resources/baby-path.json"]

# 前 10 包补齐句型、每词例句与「生活里这样用」家长提示
FIRST_TEN = {
    "family": (
        "This is my ___.",
        {
            "mom": "This is my mom.",
            "dad": "This is my dad.",
            "grandma": "This is my grandma.",
            "grandpa": "This is my grandpa.",
            "baby": "This is the baby.",
            "boy": "I'm a boy.",
            "girl": "I'm a girl.",
            "family": "This is my family.",
        },
        "翻全家福或见到家人时，指着跟孩子说：This is my mom! This is my dad!",
    ),
    "animals": (
        "I see a ___.",
        {w: f"I see a {w}." for w in ["cat", "dog", "bird", "fish", "duck", "rabbit", "pig", "cow", "horse", "bear"]},
        "散步或看绘本遇到小动物时问孩子：What do you see? I see a dog!",
    ),
    "colors": (
        "It's ___.",
        {w: f"It's {w}." for w in ["red", "blue", "yellow", "green", "black", "white", "pink", "orange"]},
        "选衣服或玩积木时指着颜色问：What color is it? It's red!",
    ),
    "numbers": (
        "I have ___ ___.",
        {
            "one": "I have one apple.",
            "two": "I have two apples.",
            "three": "I have three apples.",
            "four": "I have four apples.",
            "five": "I have five apples.",
        },
        "分水果或点心时和孩子一起边摆边数：One, two, three! I have three apples.",
    ),
    "food": (
        "I like ___.",
        {
            "apple": "I like apples.",
            "banana": "I like bananas.",
            "milk": "I like milk.",
            "water": "I like water.",
            "egg": "I like eggs.",
            "bread": "I like bread.",
            "rice": "I like rice.",
            "cake": "I like cake.",
        },
        "吃饭时问孩子：Apple or banana? 引导孩子说：I like apples.",
    ),
    "body": (
        "This is my ___.",
        {w: f"This is my {w}." for w in ["eye", "ear", "nose", "mouth", "hand", "foot", "head", "hair"]},
        "洗脸或照镜子时和孩子玩指部位游戏：Touch your nose! This is my nose.",
    ),
    "actions": (
        "I can ___.",
        {
            "run": "I can run.",
            "jump": "I can jump.",
            "eat": "I can eat.",
            "drink": "I can drink.",
            "sleep": "I can sleep.",
            "look": "Look at me!",
            "clap": "I can clap.",
            "wash": "I can wash my hands.",
        },
        "在家活动时边做动作边喊口令：Jump! I can jump! Clap your hands!",
    ),
    "numbers-2": (
        "I have ___ ___.",
        {
            "six": "I have six apples.",
            "seven": "I have seven apples.",
            "eight": "I have eight apples.",
            "nine": "I have nine apples.",
            "ten": "I have ten apples.",
        },
        "上下楼梯或收玩具时和孩子一起数到十：Six, seven, eight, nine, ten!",
    ),
    "clothes": (
        "I'm wearing a ___.",
        {
            "hat": "I'm wearing a hat.",
            "shoes": "I'm wearing shoes.",
            "clothes": "I'm wearing nice clothes.",
        },
        "出门穿鞋戴帽时对孩子说：I'm wearing a hat! I'm wearing shoes!",
    ),
    "weather": (
        "It's ___.",
        {
            "sun": "Look at the sun!",
            "rain": "Look at the rain!",
            "cloud": "Look at the cloud!",
            "hot": "It's hot.",
            "cold": "It's cold.",
        },
        "早上拉开窗帘看天气时对孩子说：Look at the sun! It's hot today.",
    ),
}

# (id, 中文名, 句型, [(词, 例句)], pairs, 家长提示)
PACKS = [
    ("fruits-2", "水果", "I like ___.", [
        ("pear", "I like pears."), ("grape", "I like grapes."), ("strawberry", "I like strawberries."),
        ("cherry", "I like cherries."), ("lemon", "I like lemons."), ("mango", "I like mangoes."),
        ("peach", "I like peaches."), ("pineapple", "I like pineapples."), ("watermelon", "I like watermelon."),
    ], False, "买水果或切果盘时问孩子：Do you like strawberries? I like pears."),
    ("farm", "农场动物", "It's a ___.", [
        ("hen", "It's a hen."), ("sheep", "It's a sheep."), ("goat", "It's a goat."), ("donkey", "It's a donkey."),
        ("mouse", "It's a mouse."), ("frog", "It's a frog."), ("bee", "It's a bee."),
    ], False, "看绘本或去农庄时指着动物问：What's this? It's a sheep!"),
    ("zoo", "动物园", "Look, a ___!", [
        ("elephant", "Look, an elephant!"), ("lion", "Look, a lion!"), ("tiger", "Look, a tiger!"),
        ("monkey", "Look, a monkey!"), ("giraffe", "Look, a giraffe!"), ("zebra", "Look, a zebra!"),
        ("panda", "Look, a panda!"), ("kangaroo", "Look, a kangaroo!"), ("hippo", "Look, a hippo!"),
        ("crocodile", "Look, a crocodile!"),
    ], False, "看动物图册时和孩子轮流指认：Look, an elephant! Look, a panda!"),
    ("sea", "海洋动物", "I see a ___.", [
        ("dolphin", "I see a dolphin."), ("whale", "I see a whale."), ("shark", "I see a shark."),
        ("octopus", "I see an octopus."), ("turtle", "I see a turtle."), ("crab", "I see a crab."),
        ("starfish", "I see a starfish."), ("jellyfish", "I see a jellyfish."), ("seal", "I see a seal."),
    ], False, "洗澡玩水或看海洋绘本时说：I see a dolphin! I see a turtle!"),
    ("bugs-birds", "小虫和鸟", "Where is the ___?", [
        ("butterfly", "Where is the butterfly?"), ("ant", "Where is the ant?"), ("spider", "Where is the spider?"),
        ("owl", "Where is the owl?"), ("eagle", "Where is the eagle?"), ("swan", "Where is the swan?"),
        ("peacock", "Where is the peacock?"),
    ], False, "在公园草地散步时和孩子一起找：Where is the butterfly?"),
    ("food-2", "好吃的", "___, please!", [
        ("cheese", "Cheese, please!"), ("cookie", "A cookie, please!"), ("juice", "Juice, please!"),
        ("noodles", "Noodles, please!"), ("soup", "Soup, please!"), ("meat", "Meat, please!"),
        ("pizza", "Pizza, please!"), ("sandwich", "A sandwich, please!"), ("honey", "Honey, please!"),
    ], False, "点餐或拿点心时教孩子有礼貌地说：Juice, please! Noodles, please!"),
    ("toys", "玩具", "I have a ___.", [
        ("ball", "I have a ball."), ("kite", "I have a kite."), ("teddy", "I have a teddy."),
        ("balloon", "I have a balloon."), ("blocks", "I have blocks."), ("doll", "I have a doll."),
        ("puzzle", "I have a puzzle."), ("robot", "I have a robot."), ("drum", "I have a drum."),
        ("yoyo", "I have a yoyo."),
    ], False, "收拾玩具箱时让孩子拿起玩具说：I have a ball! I have a teddy!"),
    ("home", "家里的东西", "This is my ___.", [
        ("door", "This is my door."), ("window", "This is my window."), ("chair", "This is my chair."),
        ("table", "This is my table."), ("bed", "This is my bed."), ("lamp", "This is my lamp."),
        ("sofa", "This is my sofa."), ("clock", "This is my clock."), ("box", "This is my box."),
        ("key", "This is my key."),
    ], False, "在房间里指着家具和孩子一问一答：This is my bed! This is my chair!"),
    ("kitchen", "厨房", "Where's my ___?", [
        ("cup", "Where's my cup?"), ("spoon", "Where's my spoon?"), ("fork", "Where's my fork?"),
        ("plate", "Where's my plate?"), ("bowl", "Where's my bowl?"), ("fridge", "Where's the fridge?"),
    ], False, "准备开饭摆餐具时问孩子：Where's my spoon? Where's my cup?"),
    ("school-things", "文具", "Give me the ___.", [
        ("book", "Give me the book."), ("pen", "Give me the pen."), ("pencil", "Give me the pencil."),
        ("crayon", "Give me the crayon."), ("eraser", "Give me the eraser."), ("ruler", "Give me the ruler."),
        ("scissors", "Give me the scissors."), ("paper", "Give me the paper."), ("glue", "Give me the glue."),
    ], False, "画画或做手工时请孩子递工具：Give me the crayon, please!"),
    ("vehicles", "交通工具", "I can see a ___.", [
        ("car", "I can see a car."), ("bus", "I can see a bus."), ("train", "I can see a train."),
        ("plane", "I can see a plane."), ("boat", "I can see a boat."), ("bike", "I can see a bike."),
        ("taxi", "I can see a taxi."), ("truck", "I can see a truck."),
    ], False, "出门在路上看到车时和孩子比赛喊出来：I can see a bus! I can see a car!"),
    ("places", "地方", "Let's go to the ___.", [
        ("school", "Let's go to school."), ("park", "Let's go to the park."), ("zoo", "Let's go to the zoo."),
        ("farm", "Let's go to the farm."), ("shop", "Let's go to the shop."),
        ("hospital", "Let's go to the hospital."), ("library", "Let's go to the library."),
        ("playground", "Let's go to the playground."),
    ], False, "周末出门前跟孩子说今天去哪：Let's go to the park! Let's go to the zoo!"),
    ("nature-2", "大自然", "Look at the ___!", [
        ("tree", "Look at the tree!"), ("flower", "Look at the flower!"), ("leaf", "Look at the leaf!"),
        ("grass", "Look at the grass!"), ("moon", "Look at the moon!"), ("star", "Look at the star!"),
        ("snow", "Look at the snow!"), ("sea", "Look at the sea!"), ("mountain", "Look at the mountain!"),
        ("river", "Look at the river!"),
    ], False, "去公园散步或抬头看夜空时说：Look at the tree! Look at the moon!"),
    ("body-2", "身体 2", "Touch your ___.", [
        ("arm", "Touch your arm."), ("leg", "Touch your leg."), ("face", "Touch your face."),
        ("teeth", "Show me your teeth."), ("finger", "Touch your finger."), ("knee", "Touch your knee."),
    ], False, "洗澡或刷牙时发出指令：Touch your arm! Show me your teeth!"),
    ("family-2", "家人 2", "This is my ___.", [
        ("sister", "This is my sister."), ("brother", "This is my brother."), ("friend", "This is my friend."),
        ("aunt", "This is my aunt."), ("uncle", "This is my uncle."),
    ], False, "和哥哥姐姐或小伙伴玩时介绍：This is my sister! This is my friend!"),
    ("actions-2", "我会做 2", "I can ___.", [
        ("swim", "I can swim."), ("fly", "Birds can fly."), ("sit", "I can sit."), ("stand", "I can stand."),
        ("sing", "I can sing."), ("dance", "I can dance."), ("read", "I can read."), ("draw", "I can draw."),
        ("walk", "I can walk."), ("climb", "I can climb."),
    ], False, "在客厅地板上和孩子边做动作边说：I can dance! Birds can fly!"),
    ("actions-3", "我会做 3", "Let's ___!", [
        ("kick", "Let's kick the ball!"), ("throw", "Let's throw the ball!"), ("catch", "Let's catch the ball!"),
        ("hug", "Let's hug!"), ("kiss", "Give me a kiss!"), ("smile", "Let's smile!"), ("laugh", "Let's laugh!"),
        ("cry", "Don't cry!"), ("cook", "Let's cook!"), ("clean", "Let's clean up!"),
    ], False, "睡前或玩球时跟孩子互动：Let's kick the ball! Let's hug!"),
    ("opposites-1", "反义词 1", "It's ___.", [
        ("big", "It's big."), ("small", "It's small."), ("tall", "It's tall."), ("short", "It's short."),
        ("fast", "It's fast."), ("slow", "It's slow."), ("happy", "I'm happy."), ("sad", "I'm sad."),
    ], True, "拿一大一小两个东西对比给孩子看：It's big! It's small!"),
    ("opposites-2", "反义词 2", "It's ___.", [
        ("wet", "It's wet."), ("dry", "It's dry."), ("full", "It's full."), ("empty", "It's empty."),
        ("loud", "It's loud."), ("quiet", "It's quiet."), ("old", "It's old."), ("new", "It's new."),
    ], True, "洗手擦干或开关盒子时对比说：It's wet! It's dry! It's full!"),
    ("numbers-3", "数字 11–20", "I can count to ___!", [
        (w, f"I can count to {w}!") for w in
        ["eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen",
         "twenty"]
    ], False, "数积木或拍手游戏时从 11 数到 20：I can count to twenty!"),
    ("feelings", "我的感受", "I'm ___.", [
        ("hungry", "I'm hungry."), ("thirsty", "I'm thirsty."), ("angry", "I'm angry."), ("afraid", "I'm afraid."),
        ("sleepy", "I'm sleepy."), ("tired", "I'm tired."),
    ], False, "孩子饿了或困了时教他表达感受：I'm hungry! I'm sleepy!"),
]


def main() -> int:
    data = json.loads(FILES[0].read_text(encoding="utf-8"))
    old_ids = [p["id"] for p in data["packs"]]
    first_ten = []
    for p in data["packs"]:
        if p["id"] in old_ids[:10]:
            pattern, sentences, tip = FIRST_TEN[p["id"]]
            assert set(sentences.keys()) == set(p["words"]), f"{p['id']} 例句词表不匹配"
            p["pattern"] = pattern
            p["sentences"] = sentences
            p["tipZh"] = tip
            first_ten.append(p)
    data["packs"] = first_ten
    have = {w for p in data["packs"] for w in p["words"]}
    for pid, name, pattern, items, pairs, tip in PACKS:
        words = [w for w, _ in items]
        dup = [w for w in words if w in have]
        assert not dup, f"{pid}: 重复的词 {dup}"
        have.update(words)
        if pairs:
            assert len(words) % 2 == 0, f"{pid}: 反义词包要成对"
        pack = {"id": pid, "nameZh": name, "songId": None, "locked": True, "words": words,
                "pattern": pattern, "sentences": dict(items), "tipZh": tip}
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
