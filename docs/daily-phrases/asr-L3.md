# 「说一说」音频识别核对（L3）

模型：small.en + medium.en（faster-whisper，int8，temperature 0，beam 5，无提示词）。
比对前统一大小写、去标点，连字符当空格，数字转英文；OK/okay、Goodnight/Good night、colour/color 算一致。

共 31 句，两个模型都逐词一致 31 句，不一致 0 句。

| 句子 | 原句 | small.en | medium.en |
|---|---|---|---|
| L3-1-01 | Where is my teddy? | ✓ Where is my teddy? | ✓ Where is my teddy? |
| L3-1-02 | It's on the bed. | ✓ It's on the bed. | ✓ It's on the bed. |
| L3-1-03 | Where are my shoes? | ✓ Where are my shoes? | ✓ Where are my shoes? |
| L3-1-04 | Do you know where they are? | ✓ Do you know where they are? | ✓ Do you know where they are? |
| L3-1-05 | Over there. | ✓ Over there | ✓ Over there. |
| L3-1-06 | Where is my book? | ✓ Where is my book? | ✓ Where is my book? |
| L3-1-07 | On the desk. | ✓ On the desk | ✓ On the desk. |
| L3-1-08 | Here it is! | ✓ Here it is. | ✓ Here it is! |
| L3-2-01 | I found your pen! | ✓ I found your pen. | ✓ I found your pen. |
| L3-2-02 | No. Mine is blue. | ✓ No, mine is blue. | ✓ No. Mine is blue. |
| L3-2-03 | Which is your bag? | ✓ Which is your bag? | ✓ Which is your bag? |
| L3-2-04 | The bigger one. | ✓ the bigger one. | ✓ The bigger one. |
| L3-2-05 | The one on the hook? | ✓ The one on the hook? | ✓ The one on the hook? |
| L3-2-06 | Are these books all yours? | ✓ Are these books all yours? | ✓ Are these books all yours? |
| L3-2-07 | Some of them are mine. | ✓ Some of them are mine. | ✓ Some of them are mine. |
| L3-3-01 | May I come in? | ✓ May I come in? | ✓ May I come in? |
| L3-3-02 | Come in, please. | ✓ Come in, please. | ✓ Come in, please. |
| L3-3-03 | Sit down, please. | ✓ Sit down, please. | ✓ Sit down, please. |
| L3-3-04 | It's time for class. | ✓ It's time for class. | ✓ It's time for class. |
| L3-3-05 | Who is here today? | ✓ Who is here today? | ✓ Who is here today? |
| L3-3-06 | Here! | ✓ Here. | ✓ Here. |
| L3-3-07 | Open your books, please. | ✓ Open your books, please. | ✓ Open your books, please. |
| L3-3-08 | Where's the toilet, please? | ✓ Where's the toilet, please? | ✓ Where's the toilet, please? |
| L3-4-01 | Does everyone have paper? | ✓ Does everyone have paper? | ✓ Does everyone have paper? |
| L3-4-02 | Are you ready? | ✓ Are you ready? | ✓ Are you ready? |
| L3-4-03 | Do you understand? | ✓ Do you understand? | ✓ Do you understand? |
| L3-4-04 | Could you say it again? | ✓ Could you say it again? | ✓ Could you say it again? |
| L3-4-05 | Who has a different idea? | ✓ Who has a different idea? | ✓ Who has a different idea? |
| L3-4-06 | Any questions? | ✓ Any questions? | ✓ Any questions? |
| L3-4-07 | That's all for today. | ✓ That's all for today. | ✓ That's all for today. |
| L3-4-08 | Give me your picture, please. | ✓ Give me your picture, please. | ✓ Give me your picture, please. |
