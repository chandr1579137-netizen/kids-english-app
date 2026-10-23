# 「说一说」音频识别核对（L1）

模型：small.en + medium.en（faster-whisper，int8，temperature 0，beam 5，无提示词）。
比对前统一大小写、去标点，连字符当空格，数字转英文；OK/okay、Goodnight/Good night 算一致。

共 38 句，两个模型都逐词一致 38 句，不一致 0 句。

| 句子 | 原句 | small.en | medium.en |
|---|---|---|---|
| L1-1-01 | Hello! | ✓ Hello | ✓ Hello |
| L1-1-02 | Hi! | ✓ Hi! | ✓ Hi. |
| L1-1-03 | How are you? | ✓ How are you? | ✓ How are you? |
| L1-1-04 | Fine, thanks. And you? | ✓ Fine, thanks. And you? | ✓ Fine, thanks. And you? |
| L1-1-05 | I'm fine, too. | ✓ I'm fine, too. | ✓ I'm fine, too. |
| L1-2-01 | Good morning! | ✓ Good morning. | ✓ Good morning. |
| L1-2-02 | Good morning, Mom! | ✓ Good morning, Mom. | ✓ Good morning, Mom. |
| L1-2-03 | Time to get up! | ✓ Time to get up. | ✓ Time to get up! |
| L1-2-04 | I wash my face. | ✓ I wash my face. | ✓ I wash my face. |
| L1-2-05 | I brush my teeth. | ✓ I brush my teeth | ✓ I brush my teeth. |
| L1-2-06 | I'm ready! | ✓ I'm ready! | ✓ I'm ready. |
| L1-3-01 | Juice, please! | ✓ Juice, please. | ✓ Juice, please. |
| L1-3-02 | Here you are. | ✓ Here you are. | ✓ Here you are. |
| L1-3-03 | Thank you! | ✓ Thank you. | ✓ Thank you. |
| L1-3-04 | You're welcome. | ✓ You're welcome. | ✓ You're welcome. |
| L1-3-05 | Sorry! | ✓ Sorry | ✓ Sorry |
| L1-3-06 | It's OK. | ✓ It's okay. | ✓ It's okay. |
| L1-4-01 | Wash your hands. | ✓ Wash your hands. | ✓ Wash your hands. |
| L1-4-02 | I'm hungry! | ✓ I'm hungry. | ✓ I'm hungry. |
| L1-4-03 | Let's eat! | ✓ Let's eat! | ✓ Let's eat! |
| L1-4-04 | Yummy! | ✓ Yummy! | ✓ Yummy! |
| L1-4-05 | More rice, please. | ✓ More rice, please. | ✓ More rice, please. |
| L1-4-06 | I'm thirsty. | ✓ I'm thirsty. | ✓ I'm thirsty. |
| L1-4-07 | I'm full. | ✓ I'm full. | ✓ I'm full. |
| L1-5-01 | Good afternoon! | ✓ Good afternoon. | ✓ Good afternoon. |
| L1-5-02 | Let's go home. | ✓ Let's go home. | ✓ Let's go home. |
| L1-5-03 | I have to go. | ✓ I have to go. | ✓ I have to go. |
| L1-5-04 | Goodbye, Amy! | ✓ Goodbye Amy | ✓ Goodbye, Amy. |
| L1-5-05 | Bye-bye! | ✓ Bye-bye. | ✓ Bye-bye! |
| L1-5-06 | See you tomorrow! | ✓ See you tomorrow! | ✓ See you tomorrow! |
| L1-5-07 | See you later! | ✓ See you later! | ✓ See you later. |
| L1-6-01 | Good evening, Dad! | ✓ Good evening, Dad. | ✓ Good evening, Dad. |
| L1-6-02 | It's bedtime. | ✓ It's bedtime. | ✓ It's bedtime. |
| L1-6-03 | I'm sleepy. | ✓ I'm sleepy. | ✓ I'm sleepy. |
| L1-6-04 | A story, please! | ✓ A story, please. | ✓ A story, please! |
| L1-6-05 | Good night, Mom. | ✓ Goodnight, Mom. | ✓ Good night, Mom. |
| L1-6-06 | I love you. | ✓ I love you | ✓ I love you. |
| L1-6-07 | I love you, too. | ✓ I love you, too! | ✓ I love you, too. |

## 重新生成的句子

- L1-4-07 "I'm full."：第一轮 medium.en 听成 "I'm four."。保持 Tom 降调 8%，放慢 16%，用 "I'm full!" 的语气重新生成（屏幕原句不变，参数见 scripts/gen_phrases.py 的 TTS_OVERRIDES）。上表是重新生成之后的结果。
