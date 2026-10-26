# 「说一说」音频识别核对（L4）

模型：small.en + medium.en（faster-whisper，int8，temperature 0，beam 5，无提示词）。
比对前统一大小写、去标点，连字符当空格，数字转英文；OK/okay、Goodnight/Good night、colour/color 算一致。

共 35 句，两个模型都逐词一致 35 句，不一致 0 句。

| 句子 | 原句 | small.en | medium.en |
|---|---|---|---|
| L4-1-01 | Who is the boy over there? | ✓ Who is the boy over there? | ✓ Who is the boy over there? |
| L4-1-02 | He's my brother. | ✓ He's my brother. | ✓ He's my brother. |
| L4-1-03 | Is that girl a student? | ✓ Is that girl a student? | ✓ Is that girl a student? |
| L4-1-04 | No, she isn't. | ✓ No, she isn't. | ✓ No, she isn't. |
| L4-1-05 | Who is she? | ✓ Who is she? | ✓ Who is she? |
| L4-1-06 | I really don't know. | ✓ I really don't know. | ✓ I really don't know. |
| L4-1-07 | I have no idea. | ✓ I have no idea. | ✓ I have no idea. |
| L4-2-01 | What do you do? | ✓ What do you do? | ✓ What do you do? |
| L4-2-02 | I'm a farmer. | ✓ I'm a farmer. | ✓ I'm a farmer. |
| L4-2-03 | What does he do? | ✓ What does he do? | ✓ What does he do? |
| L4-2-04 | He's a doctor. | ✓ He's a doctor. | ✓ He's a doctor. |
| L4-2-05 | Is she a teacher? | ✓ Is she a teacher? | ✓ Is she a teacher? |
| L4-2-06 | Is she a bus driver? | ✓ Is she a bus driver? | ✓ Is she a bus driver? |
| L4-2-07 | Yes, I think so. | ✓ Yes, I think so. | ✓ Yes, I think so. |
| L4-3-01 | Mom, let me introduce my friend. | ✓ Mom, let me introduce my friend. | ✓ Mom, let me introduce my friend. |
| L4-3-02 | This is Amy. She's my classmate. | ✓ This is Amy. She's my classmate. | ✓ This is Amy. She's my classmate. |
| L4-3-03 | Hello, Amy! | ✓ Hello, Amy | ✓ Hello, Amy |
| L4-3-04 | How do you do? | ✓ How do you do? | ✓ How do you do? |
| L4-3-05 | Let me introduce myself. | ✓ Let me introduce myself. | ✓ Let me introduce myself. |
| L4-3-06 | My name is Amelia. | ✓ My name is Amelia. | ✓ My name is Amelia. |
| L4-3-07 | Just call me Amy. | ✓ Just call me Amy. | ✓ Just call me Amy. |
| L4-4-01 | Who is the girl in pink? | ✓ Who is the girl in pink? | ✓ Who is the girl in pink? |
| L4-4-02 | Could you introduce me to her? | ✓ Could you introduce me to her? | ✓ Could you introduce me to her? |
| L4-4-03 | What's your family name? | ✓ What's your family name? | ✓ What's your family name? |
| L4-4-04 | My family name is Wang. | ✓ My family name is Wong. | ✓ My family name is Wong. |
| L4-4-05 | How do you spell it? | ✓ How do you spell it? | ✓ How do you spell it? |
| L4-4-06 | W-A-N-G. | ✓ W A N G | ✓ W-A-N-G |
| L4-5-01 | Do you have a crayon? | ✓ Do you have a crayon? | ✓ Do you have a crayon? |
| L4-5-02 | Yes, I do. | ✓ Yes, I do. | ✓ Yes, I do. |
| L4-5-03 | Does your crayon box have pink? | ✓ Does your crayon box have pink? | ✓ Does your crayon box have pink? |
| L4-5-04 | Do you have glue? I need some. | ✓ Do you have glue? I need some. | ✓ Do you have glue? I need some. |
| L4-5-05 | I have some left. | ✓ I have some left. | ✓ I have some left. |
| L4-5-06 | Can I have some more? | ✓ Can I have some more? | ✓ Can I have some more? |
| L4-5-07 | Do you have my pencil? | ✓ Do you have my pencil? | ✓ Do you have my pencil? |
| L4-5-08 | Yes, I have your eraser, too. | ✓ Yes, I have your eraser, too. | ✓ Yes, I have your eraser, too. |
