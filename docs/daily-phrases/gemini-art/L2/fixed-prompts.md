# 固定描述（最终版，L3 起使用）

2026-10-23 定稿。在 L2 所用版本的基础上，按产品经理验收意见改了三处：
1. STYLE 加了 "chibi proportions: big round head, short body"，防止人物比例偏写实（L2 的 N21）。
2. STYLE 加了 "Full-bleed illustration, no border, no frame, no inset card."，防止出现边框（L2 的 N21、N24、N25）。
3. AMY 的辫子从 "two low pigtails" 改成 "two short low pigtails (not braids)"，防止画成麻花辫。

## 用法
- 每张图开一个新的 Gemini 对话。开头写 "Generate an image."，然后接 STYLE、需要的人物段、最后那句“只出现点名的人物”，再写这一张的 SCENE。
- 只贴这一张会出场的人物段。比如只有 Tom 和妈妈，就贴 TOM 和 MOM。
- SCENE 最后写清人物名单，比如 "Only Tom and Mom. No other children."
- 在 Gemini 输入框里按换行会直接发送，所以粘贴时要把各段连成一行，文字不改。

## STYLE
```
STYLE: Flat 2D children's picture-book illustration, clean dark-brown outlines, flat colors with no gradients or 3D shading, warm off-white paper background with subtle texture. Full-bleed illustration, no border, no frame, no inset card. Square 1:1. Main subject fills about 65% of the frame. Characters have chibi proportions: big round head, short body. No text, no letters, no numbers anywhere (signs and name badges are blank). Objects and animals have no faces unless they are real animals.
```

## TOM
```
TOM: a 4-year-old Chinese boy, round face, short black hair with one small upright tuft on top, big dark-brown eyes with white sparkle highlights, pink cheeks, red crew-neck T-shirt, red shorts, white socks, red-and-white sneakers.
```

## AMY
```
AMY: a 4-year-old Chinese girl, round face, black hair with straight bangs and two short low pigtails (not braids) tied with yellow bows, big dark-brown eyes with sparkle highlights, pink cheeks, yellow T-shirt, yellow skirt, white socks, yellow Mary Jane shoes.
```

## MOM（照 L1 总览图里的妈妈）
```
MOM: Tom's mother, a young Chinese woman, oval face, long straight black hair falling past her shoulders with a side part, small earrings, dark-brown eyes with sparkle highlights, pink cheeks, a long open pink cardigan over a plain white top, dark-blue trousers.
```

## TEACHER（照 refs\avatar_teacher.jpg）
```
TEACHER: a young Chinese female kindergarten teacher, round friendly face, chin-length black bob haircut with side-swept bangs, dark-brown eyes with sparkle highlights, pink cheeks, a light-green collared short-sleeve shirt with a yellow bib apron over it, dark trousers.
```

## 收尾句（放在人物段之后、SCENE 之前）
```
Only the characters named in the scene appear. Nobody else.
```

## 示例（N30）
```
Generate an image. STYLE: … TOM: … MOM: … Only the characters named in the scene appear. Nobody else. SCENE (What's this in English?): in a simple bright kitchen with plain cabinets. Tom holds up a shiny red apple in one hand and turns back to look up at Mom with a questioning, asking-for-help face. Mom bends down toward him with a warm smile. Only Tom and Mom. No other children.
```

## 自查（每张画完都要看）
1. 画面里的人数和名单一致；
2. 没有任何文字或数字；
3. 和上一张的构图明显不同；
4. 没有边框，是满幅图。

有一项不合格就算一次失败。每张最多重画一次。
