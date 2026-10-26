# 「说一说」音频识别核对（L6）

模型：small.en + medium.en（faster-whisper，int8，temperature 0，beam 5，无提示词）。
比对前统一大小写、去标点，连字符当空格，数字转英文；OK/okay、Goodnight/Good night、colour/color 算一致。

共 33 句，两个模型都逐词一致 33 句，不一致 0 句。

| 句子 | 原句 | small.en | medium.en |
|---|---|---|---|
| L6-1-01 | What time is it now? | ✓ What time is it now? | ✓ What time is it now? |
| L6-1-02 | It's two o'clock. | ✓ It's two o'clock. | ✓ It's two o'clock. |
| L6-1-03 | It's not four o'clock. | ✓ It's not four o'clock. | ✓ It's not four o'clock. |
| L6-1-04 | It's half past nine. | ✓ It's half past nine. | ✓ It's half past nine. |
| L6-1-05 | It's twelve o'clock. Lunch time! | ✓ It's 12 o'clock. Lunchtime. | ✓ It's 12 o'clock. Lunchtime. |
| L6-1-06 | It's a quarter past five. | ✓ It's a quarter past five. | ✓ It's a quarter past five. |
| L6-2-01 | What time is it on your watch? | ✓ What time is it on your watch? | ✓ What time is it on your watch? |
| L6-2-02 | My watch says two o'clock. | ✓ My watch says two o'clock. | ✓ My watch says 2 o'clock. |
| L6-2-03 | My watch is two minutes fast. | ✓ My watch is 2 minutes fast. | ✓ My watch is two minutes fast. |
| L6-2-04 | It's almost four o'clock. | ✓ It's almost four o'clock. | ✓ It's almost four o'clock. |
| L6-2-05 | Time for the cartoon! | ✓ Time for the cartoon. | ✓ Time for the cartoon. |
| L6-3-01 | Tomorrow is my birthday! | ✓ Tomorrow is my birthday. | ✓ Tomorrow is my birthday. |
| L6-3-02 | Happy birthday! | ✓ Happy birthday! | ✓ Happy birthday! |
| L6-3-03 | Come to my party! | ✓ Come to my party! | ✓ Come to my party! |
| L6-3-04 | What time? | ✓ What time? | ✓ What time? |
| L6-3-05 | At three o'clock. | ✓ at 3 o'clock. | ✓ At three o'clock. |
| L6-3-06 | I'll see you tomorrow. | ✓ I'll see you tomorrow. | ✓ I'll see you tomorrow. |
| L6-3-07 | When is your birthday? | ✓ When is your birthday? | ✓ When is your birthday? |
| L6-3-08 | My birthday is in May. | ✓ My birthday is in May. | ✓ My birthday is in May. |
| L6-4-01 | What's the date today? | ✓ What's the date today? | ✓ What's the date today? |
| L6-4-02 | Today is June the first. | ✓ Today is June the first | ✓ Today is June the 1st |
| L6-4-03 | It's Children's Day! | ✓ It's Children's Day. | ✓ It's Children's Day. |
| L6-4-04 | Hooray! Let's go to the park! | ✓ Hooray! Let's go to the park. | ✓ Hooray! Let's go to the park! |
| L6-5-01 | I get up at seven o'clock. | ✓ I get up at seven o'clock. | ✓ I get up at 7 o'clock. |
| L6-5-02 | I go to school at eight. | ✓ I go to school at eight. | ✓ I go to school at 8. |
| L6-5-03 | I have lunch at twelve. | ✓ I have lunch at twelve. | ✓ I have lunch at 12. |
| L6-5-04 | I play in the park at four. | ✓ I play in the park at 4. | ✓ I play in the park at four. |
| L6-5-05 | Bedtime is half past eight. | ✓ Bedtime is half past 8. | ✓ Bedtime is half past eight. |
| L6-6-01 | Happy New Year! | ✓ Happy New Year! | ✓ Happy New Year |
| L6-6-02 | Is it January the first? | ✓ Is it January the 1st? | ✓ Is it January the 1st? |
| L6-6-03 | Yes, it is! | ✓ Yes, it is. | ✓ Yes, it is. |
| L6-6-04 | Let's watch the fireworks! | ✓ Let's watch the fireworks. | ✓ Let's watch the fireworks. |
| L6-6-05 | Can I have a red envelope? | ✓ Can I have a red envelope? | ✓ Can I have a red envelope? |
