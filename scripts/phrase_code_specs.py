# -*- coding: utf-8 -*-
"""「说一说」L3–L7 代码画的卡片：每句用哪种画法、参数是什么。

画法和参数的含义见 KidsEnglish/KidsEnglish/Phrases.swift 的 PhraseCodeParams。
依据是 docs/daily-phrases/images-plan.json 里每句的 code_spec（产品经理定稿）；
小图都是现成词图（assets/word-icons-overrides），图里不写字、不写数字。

格子写法（slots）：一格里放什么，用 + 连起来
  bag   小书包（上学日）        play  风筝（周末玩）
  sun   代码画的无脸太阳        moon  弯月
  star  星星贴纸                icon:<词>  现成词图
"""

WEEK = ["bag"] * 5 + ["play"] * 2

CODE_SPECS = {
    # L4：对勾 / 叉、蜡笔盒
    "L4-1-04": ("no", {}, "school"),
    "L4-2-07": ("yes", {"think": True}, "bus"),
    "L4-5-02": ("yes", {}, "crayon"),
    "L4-5-03": ("crayons", {"glow": [5]}, None),
    # L5：一周、月历、12 个月、四季、天气
    "L5-3-01": ("week", {"slots": WEEK, "blink": [0]}, None),
    "L5-3-02": ("week", {"slots": WEEK, "glow": [0], "star": [0]}, None),
    "L5-3-04": ("week", {"slots": WEEK, "star": [0], "blink": [1]}, None),
    "L5-3-05": ("week", {"slots": WEEK, "glow": [1]}, None),
    "L5-3-06": ("week", {"slots": WEEK[:5] + ["icon:kite", "play"], "glow": [5]}, None),
    "L5-4-01": ("calendar", {"pulse": True}, "snow"),
    "L5-4-02": ("months", {"slots": [""] * 11 + ["icon:snow"], "glow": [11]}, None),
    "L5-4-03": ("quad", {"slots": ["icon:flower", "sun", "icon:leaf", "icon:snow"], "cycle": True}, None),
    "L5-5-01": ("quad", {"slots": ["sun", "icon:cloud", "icon:rain", "icon:wind"], "cycle": True}, None),
    # L6：钟表、生日、日期、一天的作息
    "L6-1-01": ("clock", {"time": "2:00", "face": "wall", "spin": True}, None),
    "L6-1-02": ("clock", {"time": "2:00", "bold": "hour"}, None),
    "L6-1-03": ("clock", {"time": "2:30", "cross": "4:00"}, None),
    "L6-1-04": ("clock", {"time": "9:30", "sun": True}, None),
    "L6-1-05": ("clock", {"time": "12:00"}, "rice"),
    "L6-1-06": ("clock", {"time": "5:15", "sweep": 15}, None),
    "L6-2-01": ("clock", {"time": "2:00", "face": "watch", "spin": True}, None),
    "L6-2-02": ("clock", {"time": "2:00", "face": "watch", "strap": True}, None),
    "L6-2-03": ("clock", {"time": "2:00", "face": "watch", "pair": "2:02"}, None),
    "L6-2-04": ("clock", {"time": "3:58", "bold": "minute", "pulse": True}, None),
    "L6-3-01": ("days", {"slots": ["star", "icon:cake"], "glow": [1]}, None),
    "L6-3-04": ("clock", {"time": "3:00", "face": "party", "spin": True}, "balloon"),
    "L6-3-05": ("clock", {"time": "3:00"}, None),
    "L6-3-06": ("days", {"slots": ["icon:boy+icon:girl", "sun"], "glow": [1]}, None),
    "L6-3-07": ("months", {"slots": [""] * 12, "cycle": True}, "cake"),
    "L6-3-08": ("months", {"slots": [""] * 4 + ["icon:flower"] + [""] * 7, "glow": [4]}, "cake"),
    "L6-4-01": ("calendar", {"blink": [10]}, None),
    "L6-4-02": ("calendar", {"star": [0]}, None),
    "L6-5-01": ("clock", {"time": "7:00"}, "wake"),
    "L6-5-02": ("clock", {"time": "8:00"}, "go"),
    "L6-5-03": ("clock", {"time": "12:00"}, "eat"),
    "L6-5-04": ("clock", {"time": "4:00"}, "playground"),
    "L6-5-05": ("clock", {"time": "8:30"}, "sleep"),
    "L6-6-02": ("calendar", {"sticker": [0]}, None),
    "L6-6-03": ("yes", {"base": "calendar", "sticker": [0]}, None),
    # L7：周末、几天以后、开门时间、多久、四季、准时
    "L7-1-01": ("week", {"slots": WEEK[:5] + ["icon:park", "icon:zoo"], "glow": [5, 6]}, None),
    "L7-1-03": ("days", {"slots": ["sun", "sun", "sun"], "glow": [2]}, None),
    "L7-1-05": ("week", {"slots": WEEK, "faded": [5, 6], "arrowBack": True}, None),
    "L7-1-07": ("row", {"count": 5}, "school"),
    "L7-2-01": ("clock", {"time": "9:00"}, "zoo"),
    "L7-2-02": ("clock", {"time": "8:00", "weekend": True}, "zoo"),
    "L7-2-06": ("clock", {"time": "12:10", "hourHand": False, "sweep": 10, "pulse": True}, "dolphin"),
    "L7-2-07": ("clock", {"time": "12:10", "hourHand": False, "sweep": 10}, "dolphin"),
    "L7-3-03": ("quad", {"slots": ["icon:flower", "sun", "icon:leaf", "icon:snow"], "glow": [1], "arrowBack": True}, None),
    "L7-3-05": ("days", {"slots": ["sun+moon", "sun+moon", "sun+moon", "icon:house"]}, None),
    "L7-3-06": ("calendar", {"blink": [17]}, None),
    "L7-3-07": ("calendar", {"star": [17]}, None),
    "L7-4-01": ("clock", {"time": "8:58"}, "go"),
    "L7-4-02": ("clock", {"time": "8:58", "bold": "minute"}, None),
}


def icons_used(spec) -> set:
    """一张卡用到的全部现成小图（角上的 + 格子里的）"""
    _, params, icon = spec
    words = {icon} if icon else set()
    for slot in params.get("slots", []):
        words |= {t[5:] for t in slot.split("+") if t.startswith("icon:")}
    return words


def line_fields(line_id: str) -> dict:
    """写进 phrases.json 的字段：code / codeIcon / codeParams"""
    kind, params, icon = CODE_SPECS[line_id]
    return {"code": kind, **({"codeIcon": icon} if icon else {}), **({"codeParams": params} if params else {})}
