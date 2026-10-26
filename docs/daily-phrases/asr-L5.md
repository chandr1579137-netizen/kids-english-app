# 「说一说」音频识别核对（L5）

模型：small.en + medium.en（faster-whisper，int8，temperature 0，beam 5，无提示词）。
比对前统一大小写、去标点，连字符当空格，数字转英文；OK/okay、Goodnight/Good night、colour/color 算一致。

共 37 句，两个模型都逐词一致 37 句，不一致 0 句。

| 句子 | 原句 | small.en | medium.en |
|---|---|---|---|
| L5-1-01 | How is your mom? | ✓ How is your mom? | ✓ How is your mom? |
| L5-1-02 | She is very well, thank you. | ✓ She is very well. Thank you. | ✓ She is very well. Thank you. |
| L5-1-03 | Do you have any brothers or sisters? | ✓ Do you have any brothers or sisters? | ✓ Do you have any brothers or sisters? |
| L5-1-04 | Yes, I have a big brother. | ✓ Yes, I have a big brother. | ✓ Yes, I have a big brother. |
| L5-1-05 | Do you have any brothers? | ✓ Do you have any brothers? | ✓ Do you have any brothers? |
| L5-1-06 | No, I'm the only child. | ✓ No, I'm the only child. | ✓ No, I'm the only child. |
| L5-2-01 | What a beautiful garden you have! | ✓ What a beautiful garden you have! | ✓ What a beautiful garden you have! |
| L5-2-02 | How big is your house, Grandma? | ✓ How big is your house, Grandma? | ✓ How big is your house, Grandma? |
| L5-2-03 | Come and see! | ✓ Come and see! | ✓ Come and see! |
| L5-2-04 | Grandpa has a dog, doesn't he? | ✓ Grandpa has a dog, doesn't he? | ✓ Grandpa has a dog, doesn't he? |
| L5-2-05 | No, he doesn't. He has a cat. | ✓ No, he doesn't. He has a cat. | ✓ No, he doesn't. He has a cat. |
| L5-2-06 | What's the name of the cat? | ✓ What's the name of the cat? | ✓ What's the name of the cat? |
| L5-2-07 | Do you have shampoo here? | ✓ Do you have shampoo here? | ✓ Do you have shampoo here? |
| L5-3-01 | What day is it today? | ✓ What day is it today? | ✓ What day is it today? |
| L5-3-02 | It's Monday today. | ✓ It's Monday today. | ✓ It's Monday today. |
| L5-3-03 | Time for school! | ✓ Time for school. | ✓ Time for school. |
| L5-3-04 | What day is tomorrow? | ✓ What day is tomorrow? | ✓ What day is tomorrow? |
| L5-3-05 | Tomorrow is Tuesday. | ✓ Tomorrow is Tuesday. | ✓ Tomorrow is Tuesday |
| L5-3-06 | I can't wait for Saturday! | ✓ I can't wait for Saturday! | ✓ I can't wait for Saturday. |
| L5-4-01 | What month is it? | ✓ What month is it? | ✓ What month is it? |
| L5-4-02 | It's December. | ✓ It's December. | ✓ It's December. |
| L5-4-03 | What season is it? | ✓ What season is it? | ✓ What season is it? |
| L5-4-04 | It's winter. | ✓ It's winter. | ✓ It's winter. |
| L5-4-05 | It's so cold! | ✓ It's so cold. | ✓ It's so cold. |
| L5-4-06 | Let's make a snowman! | ✓ Let's make a snowman! | ✓ Let's make a snowman. |
| L5-5-01 | What's the weather like? | ✓ What's the weather like? | ✓ What's the weather like? |
| L5-5-02 | It's sunny today. | ✓ It's sunny today. | ✓ It's sunny today. |
| L5-5-03 | Is it windy? | ✓ Is it windy? | ✓ Is it windy? |
| L5-5-04 | Yes! Let's fly a kite. | ✓ Yes, let's fly a kite | ✓ Yes. Let's fly a kite. |
| L5-5-05 | Oh, it's cloudy now. | ✓ Oh, it's cloudy now. | ✓ Oh, it's cloudy now. |
| L5-5-06 | Take your umbrella. | ✓ Take your umbrella. | ✓ Take your umbrella. |
| L5-6-01 | Can I try them on? | ✓ Can I try them on? | ✓ Can I try them on? |
| L5-6-02 | Sure. Here you are. | ✓ Sure. Here you are. | ✓ Sure, here you are. |
| L5-6-03 | They're too small. | ✓ They're too small. | ✓ They're too small. |
| L5-6-04 | Do you have a bigger one? | ✓ Do you have a bigger one? | ✓ Do you have a bigger one? |
| L5-6-05 | This one is just right! | ✓ This one is just right. | ✓ This one is just right. |
| L5-6-06 | You look great! | ✓ You look great! | ✓ You look great! |
