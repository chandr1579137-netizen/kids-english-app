# 「说一说」音频识别核对（L2）

模型：small.en + medium.en（faster-whisper，int8，temperature 0，beam 5，无提示词）。
比对前统一大小写、去标点，连字符当空格，数字转英文；OK/okay、Goodnight/Good night、colour/color 算一致。

共 44 句，两个模型都逐词一致 44 句，不一致 0 句。

| 句子 | 原句 | small.en | medium.en |
|---|---|---|---|
| L2-1-01 | What's your name? | ✓ What's your name? | ✓ What's your name? |
| L2-1-02 | I'm Tom. | ✓ I'm Tom. | ✓ I'm Tom. |
| L2-1-03 | May I have your name? | ✓ May I have your name? | ✓ May I have your name? |
| L2-1-04 | My name is Amy. | ✓ My name is Amy. | ✓ My name is Amy. |
| L2-1-05 | Nice to meet you. | ✓ Nice to meet you. | ✓ Nice to meet you. |
| L2-1-06 | Nice to meet you, too. | ✓ Nice to meet you, too. | ✓ Nice to meet you, too. |
| L2-1-07 | How old are you? | ✓ How old are you? | ✓ How old are you? |
| L2-1-08 | I'm five. | ✓ I'm five. | ✓ I'm five. |
| L2-2-01 | Who are you? | ✓ Who are you? | ✓ Who are you? |
| L2-2-02 | I'm a lion! | ✓ I'm a lion. | ✓ I'm a lion. |
| L2-2-03 | Are you Tom? | ✓ Are you Tom? | ✓ Are you Tom? |
| L2-2-04 | Yes, I am! | ✓ Yes, I am. | ✓ Yes, I am. |
| L2-2-05 | Are you a cat? | ✓ Are you a cat? | ✓ Are you a cat? |
| L2-2-06 | No, I'm not. | ✓ No, I'm not. | ✓ No, I'm not. |
| L2-2-07 | I'm a rabbit! | ✓ I'm a rabbit. | ✓ I'm a rabbit. |
| L2-3-01 | What's this? | ✓ What's this? | ✓ What's this? |
| L2-3-02 | It's a pen. | ✓ It's a pen. | ✓ It's a pen. |
| L2-3-03 | Is that a car? | ✓ Is that a car? | ✓ Is that a car? |
| L2-3-04 | No, it isn't. It's a bus. | ✓ No, it isn't. It's a bus. | ✓ No, it isn't. It's a bus. |
| L2-3-05 | What's this in English? | ✓ What's this in English? | ✓ What's this in English? |
| L2-3-06 | It's an apple. | ✓ It's an apple. | ✓ It's an apple. |
| L2-3-07 | What color is your new book? | ✓ What colour is your new book? | ✓ What color is your new book? |
| L2-3-08 | It's red. | ✓ It's red. | ✓ It's red. |
| L2-4-01 | Is this your ball? | ✓ Is this your ball? | ✓ Is this your ball? |
| L2-4-02 | Yes, it is. | ✓ Yes, it is. | ✓ Yes, it is. |
| L2-4-03 | Is this your hat? | ✓ Is this your hat? | ✓ Is this your hat? |
| L2-4-04 | No, it isn't. | ✓ No, it isn't. | ✓ No, it isn't. |
| L2-4-05 | Whose hat is this? | ✓ Whose hat is this? | ✓ Whose hat is this? |
| L2-4-06 | It's Amy's. | ✓ It's Amy's. | ✓ It's Amy's. |
| L2-4-07 | Is this yours? | ✓ Is this yours? | ✓ Is this yours? |
| L2-4-08 | Yes, it's mine. | ✓ Yes, it's mine. | ✓ Yes, it's mine. |
| L2-5-01 | How do you feel? | ✓ How do you feel? | ✓ How do you feel? |
| L2-5-02 | I'm happy! | ✓ I'm happy | ✓ I'm happy. |
| L2-5-03 | Are you OK? | ✓ Are you okay? | ✓ Are you okay? |
| L2-5-04 | I'm sad. | ✓ I'm sad. | ✓ I'm sad. |
| L2-5-05 | Big hug! | ✓ Big hug! | ✓ Big hug! |
| L2-5-06 | I'm OK now. | ✓ I'm okay now. | ✓ I'm okay now. |
| L2-6-01 | Let's play! | ✓ Let's play. | ✓ Let's play! |
| L2-6-02 | OK! | ✓ Okay. | ✓ Okay. |
| L2-6-03 | My turn. | ✓ My turn. | ✓ My turn. |
| L2-6-04 | Your turn. | ✓ Your turn. | ✓ Your turn. |
| L2-6-05 | Help me, please. | ✓ Help me, please. | ✓ Help me, please. |
| L2-6-06 | Let's share! | ✓ Let's share. | ✓ Let's share. |
| L2-6-07 | Good job! | ✓ Good job! | ✓ Good job! |
## 修正记录

- L2-1-08「I'm five.」：第一轮 small.en 听成「and five」。保持 Tom 降调 8% 不变，放慢 16%，用「I'm five!」的语气重新生成（屏幕上的原句不变）。
- L2-3-07「What color is your new book?」：第一轮 small.en 把 book 听成 bot。放慢 12% 后仍然听错，放慢 20% 后两个模型都听对了。small.en 写成英式拼法 colour，比对时算一致。
- 参数见 scripts/gen_phrases.py 的 TTS_OVERRIDES。上表是重新生成之后的结果。
