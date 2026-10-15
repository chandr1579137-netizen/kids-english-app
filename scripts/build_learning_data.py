#!/usr/bin/env python3
"""Build dictionary rows, theme membership, and word books.

Sources (downloaded while generating; the JSON in Resources is what the app ships):
- Existing words-a..d.json in this repo.
- IPA: https://github.com/open-dict-data/ipa-dict (data/en_US.txt)
- Chinese glosses: PEP textbook rows when the headword matches, otherwise
  ECDICT (https://github.com/skywind3000/ECDICT), with hand glosses for
  textbook phrases ECDICT does not contain.
- PEP volumes: 人民教育出版社《义务教育教科书·英语（一年级起点）》三至六年级
  上下册, from billyjr/pep-english-vocabulary pep_english_vocabulary_full.csv
  (edition 1, grades 3–6). Punctuation variants are aligned to icon filenames.
"""

from __future__ import annotations

import csv
import json
import os
import re
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RES_DIRS = [
    ROOT / "KidsEnglish" / "Resources",
    ROOT / "KidsEnglish" / "KidsEnglish" / "Resources",
]
ICON_DIRS = [d / "word-icons" for d in RES_DIRS]
ECDICT = Path("/tmp/ecdict.csv")
IPA_FILE = Path("/tmp/en_US.txt")
PEP_CSV = Path("/tmp/pep.csv")
ASSETS_ZIP = Path("/tmp/assets-bundle-v3.zip")
MISSING = ROOT / "scripts" / "missing-words.txt"

# 14 picture themes, same order as the book picker.
THEME_BOOKS = [
    "fruits", "animals", "colors", "numbers", "vehicles", "foods", "family",
    "body", "stationery", "toys", "nature", "home", "places", "time",
]

PEP_ALIAS = {
    "what about...?": "What about ...?",
    "excuse me.": "Excuse me",
    "cl climb on the window ledge": "climb on the window ledge",
    "show...around": "show ... around",
}

# Phrases and headwords ECDICT does not gloss, or glosses badly for children.
MANUAL_CN = {
    "10th": "第十",
    "12th": "第十二",
    "15th": "第十五",
    "25th": "第二十五",
    "5th": "第五",
    "Chinese book": "语文书",
    "English book": "英语书",
    "English class": "英语课",
    "PE class": "体育课",
    "Papa Westray": "帕帕韦斯特雷岛",
    "What about ...?": "……怎么样",
    "are not": "不是",
    "art room": "美术教室",
    "baby brother": "弟弟",
    "be careful": "当心",
    "clean my room": "打扫我的房间",
    "climb on the window ledge": "爬上窗台",
    "count to ten": "数到十",
    "do kung fu": "练功夫",
    "do morning exercises": "做早操",
    "doing morning exercises": "正在做早操",
    "draw cartoons": "画漫画",
    "eating lunch": "正在吃午饭",
    "go cycling": "去骑自行车",
    "go swimming": "去游泳",
    "good job": "做得好",
    "green beans": "四季豆",
    "had a cold": "感冒了",
    "have ... class": "上……课",
    "having ... class": "正在上……课",
    "keep to the right": "靠右行",
    "keep your desk clean": "保持课桌干净",
    "maths book": "数学书",
    "music class": "音乐课",
    "music room": "音乐教室",
    "pick apples": "摘苹果",
    "play basketball": "打篮球",
    "play ping-pong": "打乒乓球",
    "play the pipa": "弹琵琶",
    "reading a book": "正在看书",
    "show ... around": "带……参观",
    "sing English songs": "唱英文歌",
    "speak English": "说英语",
    "take a dancing class": "上舞蹈课",
    "take a deep breath": "深呼吸",
    "talk quietly": "小声讲话",
    "teacher's desk": "讲台",
    "teacher's office": "教师办公室",
    "took pictures": "拍照了",
    "wash my clothes": "洗我的衣服",
    "we will": "我们将要",
    "went camping": "去露营了",
    "went fishing": "去钓鱼了",
    "word book": "单词本",
    "Ms": "女士",
    "Mrs": "太太",
    "Mr": "先生",
    "Internet": "互联网",
    "faster": "更快的",
    "ate": "吃了",
    "computer room": "电脑教室",
    "fat": "胖的",
    "type": "打字",
    "off": "关掉",
    "table": "桌子",
    "key": "钥匙",
    "lamp": "灯",
    "robot": "机器人",
    "pilot": "飞行员",
    "shadow": "影子",
    "sled": "雪橇",
    "traffic": "交通",
    "magazine": "杂志",
    "fork": "叉子",
    "join": "加入",
    "pack": "一包",
    "feature": "特点",
    "attention": "注意",
    "look up": "查阅",
    "dictionary": "词典",
    "computer": "电脑",
    "ice-cream": "冰淇淋",
    "ice cream": "冰淇淋",
    "OK": "好的",
    "ok": "好的",
    "Dear": "亲爱的",
    "dear": "亲爱的",
    "bus": "公共汽车",
    "kung fu": "功夫",
    "a.m.": "上午",
    "p.m.": "下午",
    "TV": "电视",
    "GPS": "全球定位系统",
    "RSVP": "请回复",
    "UK": "英国",
    "USA": "美国",
    "the UK": "英国",
    "the USA": "美国",
}

MANUAL_EN = {
    "10th": "tenth",
    "12th": "twelfth",
    "15th": "fifteenth",
    "25th": "twenty-fifth",
    "5th": "fifth",
    "its": "belonging to it",
    "Papa Westray": "a small island in Scotland",
    "What about ...?": "used to ask for someone's idea",
    "have ... class": "to have a class in a subject",
    "show ... around": "to guide someone around a place",
    "word book": "a notebook for new words",
    "teacher's desk": "the desk at the front of a classroom",
    "green beans": "long green beans eaten as a vegetable",
    "do morning exercises": "to do morning exercises",
    "play the pipa": "to play a Chinese lute",
}

TOKEN_IPA = {
    "10th": "tenθ",
    "12th": "twelfθ",
    "15th": "ˌfɪfˈtinθ",
    "25th": "ˌtwenti ˈfɪfθ",
    "5th": "fɪfθ",
    "pe": "ˌpiː ˈiː",
    "westray": "ˈwestreɪ",
    "turpan": "ˈtʊrpæn",
    "maths": "mæθs",
    "sharpener": "ˈʃɑrpənər",
    "pipa": "ˈpiːpɑː",
    "cn": "ˌsiː ˈen",
    "terracotta": "ˌterəˈkɑːtə",
    "mogao": "ˈmoʊɡaʊ",
    "dc": "ˌdiː ˈsiː",
    "uk": "ˌjuː ˈkeɪ",
    "usa": "ˌjuː es ˈeɪ",
    "tv": "ˌtiː ˈviː",
    "gps": "ˌdʒiː piː ˈes",
    "rsvp": "ˌɑːr es viː ˈpiː",
    "kung": "kʌŋ",
    "fu": "fuː",
}

WHOLE_IPA = {
    "a.m.": "/ˌeɪ ˈem/",
    "p.m.": "/ˌpiː ˈem/",
    "ok": "/ˌoʊˈkeɪ/",
    "tv": "/ˌtiː ˈviː/",
    "uk": "/ˌjuː ˈkeɪ/",
    "usa": "/ˌjuː ˌes ˈeɪ/",
    "gps": "/ˌdʒiː ˌpiː ˈes/",
    "rsvp": "/ˌɑːr ˌes ˌviː ˈpiː/",
    "washington d.c.": "/ˈwɑʃɪŋtən ˌdiː ˈsiː/",
    "what about ...?": "/wʌt əˈbaʊt/",
    "have ... class": "/hæv klæs/",
    "having ... class": "/ˈhævɪŋ klæs/",
    "show ... around": "/ʃoʊ əˈraʊnd/",
}

VERB_STARTS = (
    "do ", "doing ", "go ", "going ", "play ", "played ", "eat ", "eating ",
    "clean ", "cleaned ", "wash ", "washed ", "draw ", "read ", "reading ",
    "sing ", "speak ", "take ", "took ", "talk ", "climb ", "climbed ",
    "pick ", "keep ", "show ", "have ", "having ", "went ", "watch ",
    "watched ", "watching ", "make ", "making ", "ride ", "row ", "rowed ",
    "run ", "sweep ", "visit ", "visited ", "walk ", "walking ", "water ",
    "watering ", "write ", "learned ", "started ", "stayed ", "send ", "see ",
    "saw ", "buy ", "bought ", "cook ", "cooking ", "count ", "fly ", "get ",
    "help ", "hurry ", "look ", "mail ", "pay ", "slow ", "try ", "turn ",
    "wait ", "wake ", "wear ", "be ", "are ", "come ", "drank ", "drink ",
    "felt ", "had ", "jump ", "jumped ", "listen ", "listened ", "tidy ",
    "collecting ", "feeding ", "was ", "ate ", "cleaned ", "woke ",
)

STARTER = {
    "starter-l1": [
        "hello", "hi", "I", "you", "mom", "dad", "cat", "dog", "bird", "fish",
        "apple", "banana", "red", "blue", "green", "yellow", "one", "two",
        "three", "four", "five", "eye", "ear", "nose", "mouth", "hand",
        "milk", "water", "book", "yes", "no", "bye",
    ],
    "starter-l2": [
        "pink", "purple", "orange", "black", "white", "brown", "six", "seven",
        "eight", "nine", "ten", "sister", "brother", "family", "friend", "pig",
        "duck", "cow", "hen", "rabbit", "frog", "pear", "grape", "foot", "leg",
        "arm", "face", "head", "rice", "bread", "egg", "cake",
    ],
    "starter-l3": [
        "car", "bus", "bike", "house", "door", "window", "school", "park",
        "home", "ball", "toy", "tree", "flower", "sun", "moon", "star",
        "chair", "desk", "pen", "pencil", "bag", "morning", "night", "day",
        "today",
    ],
    "starter-l4": [
        "run", "jump", "eat", "drink", "read", "play", "sleep", "swim", "walk",
        "sing", "big", "small", "happy", "sad", "hot", "cold", "tall", "short",
        "fast", "slow", "good", "new", "old", "open", "close", "go", "come",
        "look", "see", "like",
    ],
}

STARTER_NAMES = {
    "starter-l1": "启蒙 L1",
    "starter-l2": "启蒙 L2",
    "starter-l3": "启蒙 L3",
    "starter-l4": "启蒙 L4",
}

THEME_EMOJI = {
    "fruits": "🍎", "animals": "🐾", "colors": "🎨", "numbers": "🔢",
    "vehicles": "🚌", "foods": "🍽️", "family": "👨‍👩‍👧", "body": "✋",
    "stationery": "✏️", "toys": "🧸", "nature": "🌳", "home": "🏠",
    "places": "📍", "time": "⏰", "actions": "🏃", "adjectives": "✨",
    "functions": "🔤", "others": "📘",
}


def stem_key(filename: str) -> str:
    base = os.path.basename(filename)
    root, ext = os.path.splitext(base)
    if ext.lower() not in {".png", ".jpg", ".jpeg", ".webp"}:
        return base.lower()
    return root.lower()


def icon_index() -> set[str]:
    keys: set[str] = set()
    for directory in ICON_DIRS:
        if not directory.is_dir():
            continue
        for path in directory.iterdir():
            if path.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}:
                keys.add(stem_key(path.name))
    if ASSETS_ZIP.is_file():
        with zipfile.ZipFile(ASSETS_ZIP) as archive:
            for name in archive.namelist():
                if "/word-icons/" in name and name.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
                    keys.add(stem_key(name))
    keys.add("chang'e")
    return keys


def load_ipa() -> dict[str, str]:
    ipa: dict[str, str] = {}
    for line in IPA_FILE.read_text(encoding="utf-8").splitlines():
        if "\t" not in line:
            continue
        word, phonetic = line.split("\t", 1)
        ipa.setdefault(word.lower(), phonetic.split(",")[0].strip())
    return ipa


def normalize_ipa(raw: str) -> str:
    text = raw.strip()
    if not text:
        return ""
    text = text.strip("/")
    text = text.replace("ɫ", "l").replace("ɹ", "r").replace(":", "ː").replace("ә", "ə")
    text = text.replace("'", "ˈ")
    text = re.sub(r"\s+", " ", text).strip()
    if not text:
        return ""
    return f"/{text}/"


FUNCTION_IPA = {
    "a": "ə", "an": "ən", "the": "ðə", "to": "tə", "of": "əv",
    "and": "ənd", "or": "ər", "for": "fər",
}


def phrase_ipa(word: str, ipa: dict[str, str]) -> str:
    key = word.lower().strip()
    if key in WHOLE_IPA:
        return WHOLE_IPA[key]
    if key in ipa and " " not in key and "..." not in word:
        return normalize_ipa(ipa[key])
    raw = key.replace("...", " ").replace(".", " ")
    tokens = re.findall(r"[a-z0-9']+", raw.replace("-", " "))
    parts: list[str] = []
    for token in tokens:
        if len(tokens) > 1 and token in FUNCTION_IPA:
            parts.append(FUNCTION_IPA[token])
        elif token in ipa:
            parts.append(normalize_ipa(ipa[token]).strip("/"))
        elif token in TOKEN_IPA:
            parts.append(TOKEN_IPA[token])
        else:
            return ""
    if not parts:
        return ""
    return "/" + " ".join(parts) + "/"


def clean_cn(translation: str) -> str:
    senses: list[str] = []
    for line in translation.replace("\\n", "\n").split("\n"):
        line = line.strip()
        if not line:
            continue
        line = re.sub(r"\[[^\]]*\]", "", line).strip()
        line = re.sub(r"^[a-zA-Z./]+\.?\s*", "", line).strip(" ；;，,")
        if line:
            senses.append(line)
    if not senses:
        return ""
    text = re.split(r"[；;]", senses[0])[0].strip()
    if len(text) > 18:
        text = re.split(r"[，,]", text)[0].strip()
    return text[:24]


def clean_en(definition: str) -> str:
    text = definition.replace("\n", " ").strip()
    text = re.sub(r"\s+", " ", text)
    if not text:
        return ""
    sentence = re.split(r"(?<=[.!?])\s", text)[0]
    return sentence[:90]


def pos_of(raw: str, word: str) -> str:
    if " " in word or "..." in word:
        return "phr."
    token = raw.split("/")[0].split(":")[0].strip().lower()
    mapping = {
        "n": "n.", "v": "v.", "vt": "v.", "vi": "v.", "adj": "adj.",
        "adv": "adv.", "prep": "prep.", "conj": "conj.", "pron": "pron.",
        "art": "art.", "num": "num.", "int": "interj.", "interj": "interj.",
        "phr": "phr.", "aux": "v.", "modal": "modal v.", "det": "det.",
        "abbr": "abbr.",
    }
    return mapping.get(token, "n.")


def lower_word_verb(word: str) -> bool:
    lower = word.lower()
    return lower.endswith(("ed", "ing")) or is_verb_phrase(word)


def is_verb_phrase(word: str) -> bool:
    lower = word.lower()
    return any(lower.startswith(prefix) for prefix in VERB_STARTS)


def tidy_cn(word: str, cn: str) -> str:
    fixed = MANUAL_CN.get(word) or MANUAL_CN.get(word.lower())
    if fixed:
        return fixed
    original = cn
    cn = re.sub(r"（[^）]*）", "", cn)
    cn = re.sub(r"\([^)]*\)", "", cn)
    cn = re.sub(r"[A-Za-z]{2,}", "", cn)
    parts = [part.strip(" ：:、 ") for part in re.split(r"[，,；;]", cn) if part.strip(" ：:、 ")]
    cn = parts[0] if parts else ""
    if len(cn) < 1:
        cn = re.split(r"[，,；;]", original)[0]
        cn = re.sub(r"（[^）]*）", "", cn)
        cn = re.sub(r"\([^)]*\)", "", cn).strip()
    return cn[:14] or "单词"


FIX_CN = {
    "coach": "教练",
    "club": "俱乐部",
    "comic": "漫画",
    "driver": "司机",
    "crossing": "十字路口",
    "helmet": "头盔",
    "sled": "雪橇",
    "robot": "机器人",
    "pilot": "飞行员",
    "bowl": "碗",
    "clubhouse": "俱乐部",
    "bark": "狗叫",
    "camp": "露营",
    "cheap": "便宜的",
    "cinema": "电影院",
    "contest": "比赛",
    "cartoon": "漫画",
    "dollar": "美元",
    "building": "建筑物",
    "businessman": "商人",
    "bottle": "瓶子",
    "basket": "篮子",
    "beef": "牛肉",
    "breath": "呼吸",
    "bike": "自行车",
    "bigger": "更大的",
    "ruler": "尺子",
    "phone": "电话",
    "lesson": "课",
    "season": "季节",
    "drinking": "喝",
    "eating": "吃",
    "cycling": "骑自行车",
    "climbing": "爬",
    "cleaned": "打扫了",
    "danced": "跳舞了",
    "laughed": "笑了",
    "degree": "度数",
    "dinner": "晚餐",
    "eighteen": "十八",
    "eighty": "八十",
    "else": "其他的",
    "aren't": "不是",
    "can't": "不能",
    "its": "它的",
    "Italian": "意大利语",
    "Spanish": "西班牙语",
    "T-shirt": "T恤",
    "Turpan": "吐鲁番",
    "a few": "几个",
    "dining hall": "食堂",
    "stomachache": "胃疼",
    "police officer": "警察",
    "a lot": "很多",
    "computer class": "电脑课",
    "rainy": "下雨的",
}


FORCE_THEME = {
    "kangaroo": "animals", "koala": "animals", "dinosaur": "animals", "mice": "animals",
    "moose": "animals", "mule": "animals", "insect": "animals", "body": "body",
    "bamboo": "nature", "jasmine": "nature", "maple leaves": "nature",
    "onion": "foods", "candy": "foods", "cola": "foods", "hot pot": "foods",
    "green beans": "foods", "father": "family", "mother": "family", "grandparent": "family",
    "fridge": "home", "living room": "home", "chopsticks": "home", "knife": "home", "fork": "home",
    "canberra": "places", "new york": "places", "turpan": "places", "washington d.c.": "places",
    "art gallery": "places", "bookshop": "places", "bookstore": "places", "countryside": "places",
    "factory": "places", "gym": "places", "neighbourhood": "places", "dining hall": "places",
    "dining room": "places", "classroom": "places", "crossroads": "places",
    "chinese book": "stationery", "english book": "stationery", "maths book": "stationery",
    "comic book": "stationery", "exercise book": "stationery", "diary": "stationery",
    "magazine": "stationery", "glue stick": "stationery",
    "holiday": "time", "every day": "time", "on the weekend": "time", "once a week": "time",
    "kung fu": "actions", "ice-skate": "actions", "jumping rope": "actions",
    "buy": "actions", "call": "actions", "enjoy": "actions", "guess": "actions",
    "hurt": "actions", "join": "actions", "kick": "actions", "keep": "actions",
}


def classify(word: str, cn: str, pos: str) -> str:
    lower = word.lower()
    if lower in FORCE_THEME:
        return FORCE_THEME[lower]
    if any(k in cn for k in ("妈妈", "爸爸", "哥哥", "姐姐", "弟弟", "妹妹", "家人", "爷爷", "奶奶", "叔叔", "阿姨", "舅舅", "姑姑")) or lower in {"aunt", "uncle", "cousin", "grandma", "grandpa", "grandmother", "grandfather", "mrs", "ms", "mr", "parents"}:
        return "family"
    if lower in {"eighteen", "eighty", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "nineteen", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "ninety", "hundred", "thousand", "first", "second", "third", "fourth", "fifth"} or re.fullmatch(r"\d+(st|nd|rd|th)", lower) or re.fullmatch(r"(twenty|thirty)-(first|second|third|fourth|fifth)", lower) or (len(cn) <= 3 and cn[:1].isdigit()) or cn in {"十八", "八十", "十一", "十二", "一百"}:
        return "numbers"
    if "节" in cn or "日" == cn[-1:] and any(k in cn for k in ("圣诞", "新年", "元旦", "母亲", "父亲", "劳动", "感恩", "复活", "教师", "儿童", "国庆", "春节", "中秋")) or lower in {"christmas", "easter", "thanksgiving", "a.m.", "p.m.", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday", "weekend", "yesterday", "tomorrow", "today", "morning", "afternoon", "evening", "night", "o'clock"} or cn in {"上午", "下午", "晚上", "今天", "明天", "昨天", "周末", "星期一", "星期五", "新年", "元旦"}:
        return "time"
    if any(k in cn for k in ("国", "市", "省", "州", "湖", "河", "岛", "宫", "塔", "博物馆", "机场", "图书馆", "公园", "医院", "商店", "中心", "广场")) or lower in {"london", "paris", "sydney", "toronto", "munich", "scotland", "singapore", "canada", "australia", "africa", "asia", "china", "america", "england", "france", "germany", "italy", "spain", "japan", "india", "disneyland", "airport", "bank", "shop", "store", "hospital", "library", "museum", "cinema", "zoo", "hotel"}:
        if "课" not in cn and not is_verb_phrase(word):
            return "places"
    if any(k in cn for k in ("房间", "卧室", "厨房", "卫生间", "浴室", "沙发", "灯", "床", "桌子", "椅子", "门", "窗", "钟", "篮子", "瓶子", "碗")) and "教室" not in cn and not is_verb_phrase(word):
        return "home"
    if any(k in lower for k in ("bus", "bike", "taxi", "train", "plane", "ship", "boat", "subway", "jeep", "sled", "bicycle", "motorbike")) and "driver" not in lower and not is_verb_phrase(word):
        return "vehicles"
    if any(k in cn for k in ("饭", "菜", "奶", "面包", "肉", "汤", "蛋糕", "茶", "米", "面条", "汉堡", "冰淇淋", "果汁", "蔬菜", "巧克力", "薯条", "早餐", "午餐", "晚餐")) and not is_verb_phrase(word):
        return "foods"
    if any(k in cn for k in ("笔", "橡皮", "尺子", "书包", "铅笔", "蜡笔", "词典", "字典", "黑板", "本子")) and not is_verb_phrase(word):
        return "stationery"
    if any(k in cn for k in ("玩具", "风筝", "娃娃", "积木", "气球")) and not is_verb_phrase(word):
        return "toys"
    if any(k == lower or f" {k}" in f" {lower}" for k in (
        "apple", "banana", "pear", "grape", "watermelon", "strawberry", "peach",
        "mango", "lemon", "cherry", "coconut", "pineapple", "orange",
    )) and "教室" not in cn:
        if lower != "orange" or "橙" in cn or "橘" in cn:
            if "色" not in cn:
                return "fruits"
    if any(k in cn for k in ("苹果", "香蕉", "梨", "葡萄", "西瓜", "草莓", "桃", "芒果")) and "摘" not in cn and "画" not in cn:
        return "fruits"
    if any(k in lower for k in (
        "cat", "dog", "bird", "fish", "tiger", "lion", "bear", "panda", "monkey",
        "elephant", "snake", "rabbit", "duck", "horse", "sheep", "cow", "pig",
        "frog", "bee", "ant", "whale", "shark", "deer", "fox", "wolf", "mouse",
        "chicken", "hen", "goose", "cheetah", "bunny", "kitten",
    )) and not is_verb_phrase(word):
        return "animals"
    if any(k in cn for k in ("动物", "鸟", "虎", "狮", "熊", "猫", "狗", "兔", "鸭", "鱼", "马", "牛", "羊", "蛇", "蛙", "鲸", "鲨", "鹿", "狐", "狼", "猴", "象", "鹅", "豹")) and not is_verb_phrase(word) and "房间" not in cn:
        return "animals"
    if lower in {"red", "blue", "green", "yellow", "black", "white", "pink", "purple", "brown", "orange", "grey", "gray"} or cn.endswith("色") and len(cn) <= 4:
        return "colors"
    if re.fullmatch(r"\d+(st|nd|rd|th)", lower) or lower in {
        "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
        "ten", "eleven", "twelve", "thirteen", "twenty", "thirty", "forty",
        "fifty", "hundred", "first", "second", "third",
    } or "第" in cn and len(cn) <= 5:
        return "numbers"
    if any(k in lower for k in ("bus", "bike", "taxi", "train", "plane", "ship", "boat", "car", "subway", "jeep")) and "driver" not in lower and not is_verb_phrase(word):
        return "vehicles"
    if any(k in cn for k in ("公共汽车", "自行车", "出租车", "火车", "飞机", "轮船", "船", "地铁", "汽车")) and "司机" not in cn and not is_verb_phrase(word):
        return "vehicles"
    if any(k in cn for k in ("妈妈", "爸爸", "哥哥", "姐姐", "弟弟", "妹妹", "家人", "爷爷", "奶奶", "叔叔", "阿姨")) and not is_verb_phrase(word):
        return "family"
    if any(k in cn for k in ("头", "眼", "耳", "鼻", "嘴", "手", "脚", "腿", "脸", "胳膊", "头发", "牙")) and len(cn) <= 4 and not is_verb_phrase(word):
        return "body"
    if any(k in cn for k in ("笔", "书", "橡皮", "尺子", "书包", "铅笔", "蜡笔", "字典")) and "英语书" not in cn and "语文" not in cn and "数学" not in cn and not is_verb_phrase(word):
        if "本" in cn or "笔" in cn or "橡皮" in cn or "尺子" in cn:
            return "stationery"
    if any(k in cn for k in ("玩具", "球", "风筝", "娃娃", "积木")) and not is_verb_phrase(word):
        return "toys"
    if any(k in cn for k in ("树", "花", "太阳", "月亮", "星星", "云", "雨", "雪", "风", "山", "河", "海", "草", "森林")) and not is_verb_phrase(word) and "花" != cn[-1:] or "花" in cn:
        if not any(k in cn for k in ("市", "湖", "宫", "塔", "博物馆")):
            return "nature"
    if any(k in cn for k in ("门", "窗", "床", "椅子", "桌子", "房间", "厨房", "沙发", "灯", "钟")) and "教室" not in cn and "办公" not in cn and not is_verb_phrase(word):
        return "home"
    if any(k in cn for k in ("学校", "公园", "医院", "商店", "图书馆", "博物馆", "市", "国", "湖", "河", "宫", "塔", "岛", "省", "州")) and not is_verb_phrase(word):
        return "places"
    if any(k in cn for k in ("早上", "下午", "晚上", "今天", "明天", "昨天", "星期", "点钟", "小时", "分钟", "年", "月")) and not is_verb_phrase(word) and len(cn) <= 8:
        return "time"
    if any(k in cn for k in ("饭", "菜", "奶", "水", "面包", "蛋", "肉", "汤", "水果汁", "蛋糕", "茶", "米", "面条", "汉堡", "冰淇淋", "西瓜")) and "教室" not in cn and not is_verb_phrase(word):
        return "foods"
    if is_verb_phrase(word) or pos.startswith("v"):
        return "actions"
    if pos.startswith("adj") or (cn.endswith("的") and len(cn) <= 8):
        return "adjectives"
    if pos in {"prep.", "conj.", "pron.", "art.", "det.", "interj."}:
        return "functions"
    return "others"


def example_for(word: str, pos: str) -> str:
    if " " in word or "..." in word or word.endswith("?"):
        text = word[0].upper() + word[1:]
        if text[-1] not in ".!?":
            text += "."
        return text
    if pos.startswith("pron"):
        return f"I know the word {word}."
    if pos.startswith("v"):
        return f"I can {word}."
    if pos.startswith("adj"):
        return f"It is {word}."
    if pos.startswith("num"):
        return f"Count: {word}."
    if pos.startswith("n") and " " not in word:
        article = "an" if word[:1].lower() in "aeiou" else "a"
        return f"This is {article} {word}."
    return f"This is {word}."


def load_existing() -> tuple[list[dict], dict[str, dict]]:
    rows: list[dict] = []
    by_key: dict[str, dict] = {}
    for part in "abcd":
        data = json.loads((RES_DIRS[0] / f"words-{part}.json").read_text())
        rows.extend(data)
        for item in data:
            by_key.setdefault(item["word"].lower(), item)
    return rows, by_key


def pep_rows() -> list[dict]:
    rows = []
    with PEP_CSV.open(encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            if row["grade"] in "3456" and row["term"] in "12":
                rows.append(row)
    return rows


def copy_change_icon() -> None:
    with zipfile.ZipFile(ASSETS_ZIP) as archive:
        data = archive.read("KidsEnglish/KidsEnglish/Resources/word-icons/chang_e.jpg")
    for directory in ICON_DIRS:
        directory.mkdir(parents=True, exist_ok=True)
        (directory / "chang'e.jpg").write_bytes(data)


def main() -> None:
    copy_change_icon()
    icons = icon_index()
    ipa = load_ipa()
    existing_rows, existing = load_existing()
    ecdict: dict[str, dict] = {}
    with ECDICT.open(encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            ecdict.setdefault(row["word"].lower(), row)
    pep_gloss: dict[str, dict] = {}
    for row in csv.DictReader(PEP_CSV.open(encoding="utf-8", newline="")):
        pep_gloss.setdefault(row["english"].lower().strip(), row)

    missing = [line.strip() for line in MISSING.read_text().splitlines() if line.strip()]
    new_rows: list[dict] = []
    seen: set[str] = set(existing)
    skipped_case: list[str] = []
    problems: list[str] = []

    grade_of: dict[str, int] = {}
    for row in pep_rows():
        grade_of.setdefault(row["english"].lower().strip(), int(row["grade"]))

    for word in missing:
        key = word.lower()
        if key in seen:
            skipped_case.append(word)
            continue
        if key not in icons:
            problems.append(f"no icon: {word}")
            continue
        pep = pep_gloss.get(key)
        manual = MANUAL_CN.get(word) or MANUAL_CN.get(key)
        if manual:
            cn = manual
        elif pep and (pep.get("chinese") or "").strip():
            cn = pep["chinese"].strip()
            if len(cn) > 18:
                cn = re.split(r"[；;，,]", cn)[0].strip()
        else:
            cn = clean_cn((ecdict.get(key) or {}).get("translation") or "")
        if not cn:
            problems.append(f"no chinese: {word}")
            continue
        cn = FIX_CN.get(word) or FIX_CN.get(key) or tidy_cn(word, cn)
        phonetic = phrase_ipa(word, ipa)
        if not phonetic and pep and (pep.get("phonetic") or "").strip():
            phonetic = normalize_ipa(pep["phonetic"])
        if not phonetic:
            problems.append(f"no phonetic: {word}")
            continue
        raw_pos = (ecdict.get(key) or {}).get("pos") or ""
        pos = pos_of(raw_pos, word)
        if key in {"its", "their", "our", "your", "my", "his", "her", "i", "you", "he", "she", "we", "they"}:
            pos = "pron."
        elif cn.endswith("的"):
            pos = "adj."
        elif lower_word_verb(word) and pos == "n.":
            pos = "v."
        en = MANUAL_EN.get(word) or MANUAL_EN.get(key) or clean_en((ecdict.get(key) or {}).get("definition") or "")
        if (not en) or en.lower().startswith("n ") or "engineering" in en.lower() or len(en) > 110:
            if pos.startswith("v"):
                en = f"to {word}"
            elif pos == "phr.":
                en = word
            else:
                en = f"the word {word}"
        theme = classify(word, cn, pos)
        level = 1 if theme in {"fruits", "animals", "colors", "numbers", "family", "body"} else grade_of.get(key, 3)
        if theme in {"actions", "adjectives"}:
            level = max(level, 2)
        new_rows.append({
            "word": word if key not in {s.lower() for s in skipped_case} else word,
            "phonetic": phonetic,
            "meaningCn": cn,
            "meaningEn": en,
            "partOfSpeech": pos,
            "examples": [example_for(word, pos)],
            "emoji": THEME_EMOJI.get(theme, "📘"),
            "level": level,
            "frequency": 60,
            "_theme": theme,
        })
        seen.add(key)

    if problems:
        print("PROBLEMS", len(problems))
        for item in problems[:40]:
            print(" ", item)
        raise SystemExit(1)

    # Themes
    themes = json.loads((RES_DIRS[0] / "word-themes.json").read_text())
    theme_by_id = {theme["id"]: theme for theme in themes}
    for theme in themes:
        theme["words"] = list(dict.fromkeys(theme["words"]))
    themed = {word.lower() for theme in themes for word in theme["words"]}
    added_theme = {theme_id: 0 for theme_id in theme_by_id}
    for row in new_rows:
        theme_id = row.pop("_theme")
        key = row["word"].lower()
        if key in themed:
            continue
        theme_by_id[theme_id]["words"].append(row["word"])
        themed.add(key)
        added_theme[theme_id] += 1

    # Books
    dictionary = dict(existing)
    for row in new_rows:
        dictionary[row["word"].lower()] = row

    def resolve(words: list[str]) -> list[str]:
        found = []
        missing_words = []
        for word in words:
            if word.lower() in dictionary and word.lower() in icons:
                found.append(word)
            else:
                missing_words.append(word)
        if missing_words:
            raise SystemExit(f"starter words missing: {missing_words}")
        return found

    starter_books = []
    for book_id, words in STARTER.items():
        resolved = resolve(words)
        starter_books.append({"id": book_id, "nameCn": STARTER_NAMES[book_id], "words": resolved})

    theme_books = []
    for theme_id in THEME_BOOKS:
        theme = theme_by_id[theme_id]
        theme_books.append({"id": theme_id, "nameCn": theme["nameCn"], "themeId": theme_id})

    pep_books = []
    grade_name = {"3": "三", "4": "四", "5": "五", "6": "六"}
    term_name = {"1": "上", "2": "下"}
    grouped: dict[tuple[str, str], list[str]] = {}
    skipped_pep: list[str] = []
    for row in pep_rows():
        raw = row["english"].strip()
        target = PEP_ALIAS.get(raw.lower(), raw)
        key = target.lower()
        bucket = grouped.setdefault((row["grade"], row["term"]), [])
        if key in dictionary and key in icons:
            if key not in {item.lower() for item in bucket}:
                bucket.append(dictionary[key]["word"])
        else:
            skipped_pep.append(raw)
    for grade in "3456":
        for term in "12":
            words = grouped.get((grade, term), [])
            if not words:
                raise SystemExit(f"empty pep book {grade}-{term}")
            pep_books.append({
                "id": f"pep-{grade}-{term}",
                "nameCn": f"{grade_name[grade]}年级{term_name[term]}",
                "words": words,
            })

    # 图标对齐（不写进给孩子看的 citation）：
    # What about...? → What about ...?；Excuse me. → Excuse me；
    # cl climb on the window ledge → climb on the window ledge；
    # show...around → show ... around。没有图标的词条不进词书。
    # 2012 年三年级起点短语留在词典和主题里，不单独编成这八册。
    catalog = {
        "citation": (
            "人教版词书来自人民教育出版社《义务教育教科书·英语（一年级起点）》"
            "三至六年级上下册词表，整理自 billyjr/pep-english-vocabulary 的 "
            "pep_english_vocabulary_full.csv（edition=1，三至六年级上下册）。"
        ),
        "groups": [
            {"id": "starter", "nameCn": "启蒙", "books": starter_books},
            {"id": "theme", "nameCn": "主题", "books": theme_books},
            {"id": "pep", "nameCn": "人教版", "books": pep_books},
        ],
    }

    for directory in RES_DIRS:
        directory.mkdir(parents=True, exist_ok=True)
        (directory / "words-e.json").write_text(
            json.dumps(new_rows, ensure_ascii=False, indent=1) + "\n",
            encoding="utf-8",
        )
        (directory / "word-themes.json").write_text(
            json.dumps(themes, ensure_ascii=False, indent=1) + "\n",
            encoding="utf-8",
        )
        (directory / "word-books.json").write_text(
            json.dumps(catalog, ensure_ascii=False, indent=1) + "\n",
            encoding="utf-8",
        )

    print(f"existing {len(existing_rows)} new {len(new_rows)} skipped_case {skipped_case}")
    print("theme additions", added_theme)
    print("pep books", [(book["nameCn"], len(book["words"])) for book in pep_books])
    print("starter", [(book["nameCn"], len(book["words"])) for book in starter_books])
    print("skipped pep without icon", len(set(skipped_pep)), sorted(set(skipped_pep))[:12])
    # spot-check sample
    import random
    random.seed(7)
    sample = random.sample(new_rows, 25)
    print("--- sample ---")
    for row in sample:
        print(f"{row['word']} | {row['phonetic']} | {row['meaningCn']} | {row['partOfSpeech']}")


if __name__ == "__main__":
    main()
