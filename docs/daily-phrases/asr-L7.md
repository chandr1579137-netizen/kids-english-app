# 「说一说」音频识别核对（L7）

模型：small.en + medium.en（faster-whisper，int8，temperature 0，beam 5，无提示词）。
比对前统一大小写、去标点，连字符当空格，数字转英文；OK/okay、Goodnight/Good night、colour/color 算一致。

共 31 句，两个模型都逐词一致 31 句，不一致 0 句。

| 句子 | 原句 | small.en | medium.en |
|---|---|---|---|
| L7-1-01 | What will you do this weekend? | ✓ What will you do this weekend? | ✓ What will you do this weekend? |
| L7-1-02 | I'll go to the zoo! | ✓ I'll go to the zoo. | ✓ I'll go to the zoo. |
| L7-1-03 | What will you do the day after tomorrow? | ✓ What will you do the day after tomorrow? | ✓ What will you do the day after tomorrow? |
| L7-1-04 | I'll visit my grandma. | ✓ I'll visit my grandma. | ✓ I'll visit my grandma. |
| L7-1-05 | What did you do last weekend? | ✓ What did you do last weekend? | ✓ What did you do last weekend? |
| L7-1-06 | I went to the beach. | ✓ I went to the beach. | ✓ I went to the beach. |
| L7-1-07 | I'll go to school for five days. | ✓ I'll go to school for five days. | ✓ I'll go to school for five days. |
| L7-2-01 | Does the zoo open at nine? | ✓ Does the zoo open at 9? | ✓ Does the zoo open at 9? |
| L7-2-02 | It opens at eight on weekends. | ✓ It opens at 8 on weekends. | ✓ It opens at 8 on weekends. |
| L7-2-03 | Any tickets left? | ✓ Any tickets left? | ✓ Any tickets left? |
| L7-2-04 | Yes, here you are. | ✓ Yes, here you are. | ✓ Yes, here you are. |
| L7-2-05 | How long is the snake? | ✓ How long is the snake? | ✓ How long is the snake? |
| L7-2-06 | How long will the show last? | ✓ How long will the show last? | ✓ How long will the show last? |
| L7-2-07 | Only ten minutes. | ✓ Only 10 minutes | ✓ Only 10 minutes. |
| L7-3-01 | Grandpa's plane is late. | ✓ Grandpa's plane is late. | ✓ Grandpa's plane is late. |
| L7-3-02 | It's been a long time, Grandpa! | ✓ It's been a long time, Grandpa. | ✓ It's been a long time. Grandpa! |
| L7-3-03 | What did you do last summer? | ✓ What did you do last summer? | ✓ What did you do last summer? |
| L7-3-04 | I swam in the sea! | ✓ I swam in the sea. | ✓ I swam in the sea. |
| L7-3-05 | I'll be back in three days. | ✓ I'll be back in three days. | ✓ I'll be back in three days. |
| L7-3-06 | Do you know the exact date? | ✓ Do you know the exact date? | ✓ Do you know the exact date? |
| L7-3-07 | Let's check the calendar. | ✓ Let's check the calendar. | ✓ Let's check the calendar. |
| L7-4-01 | We must be on time! | ✓ We must be on time. | ✓ We must be on time. |
| L7-4-02 | There are only two minutes left. | ✓ There are only two minutes left. | ✓ There are only two minutes left. |
| L7-4-03 | Can you finish your milk quickly? | ✓ Can you finish your milk quickly? | ✓ Can you finish your milk quickly? |
| L7-4-04 | Yes! I'm ready! | ✓ Yes, I'm ready. | ✓ Yes. I'm ready. |
| L7-4-05 | Let's go! | ✓ Let's go! | ✓ Let's go! |
| L7-5-01 | Look! It's raining. | ✓ Look! It's raining! | ✓ Look! It's raining! |
| L7-5-02 | The picnic is put off. | ✓ The picnic is put off. | ✓ The picnic is put off. |
| L7-5-03 | Oh no! I'm sad. | ✓ Oh no. I'm sad. | ✓ Oh no. I'm sad. |
| L7-5-04 | Let's have a picnic at home! | ✓ Let's have a picnic at home. | ✓ Let's have a picnic at home. |
| L7-5-05 | What a great idea! | ✓ What a great idea! | ✓ What a great idea! |
