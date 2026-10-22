# 版式 B「一句一卡」出图方案（v2：一句一图）

生成：2026-10-22（北京时间）｜数据：`images-plan.json`｜复用核对图：`reuse_sheet.jpg`｜自检：`selfcheck.py`（共 249 句；每条复用路径都存在；每张图只用在一句上；8 张背景都用上了；已通过）

**规则：** 每张卡片图只给一句用，现成的词图和 8 张场景背景都各用一次；9 个头像只当说话人的小标，不做卡片图；能用代码画清楚的就让 Qoder 用代码画。

## 1. 总数

| 做法 | 句数 | 说明 |
|---|---|---|
| 复用现成图 | 98 | 词图 90 句（每张只用一次，包括刚重画的那批）+ 场景背景 **8/8 张全部用上** |
| 代码画 | 62 | Qoder 用 SwiftUI 画：钟面、日历、一周 7 格、12 个月的圆圈、四季盘、天气表、日出日落、数蜡烛、蜡笔盒、对勾/叉；可以叠一张现成小图；不占 Muse 额度 |
| 新画 | 89 | 需要 Muse 新画 **89 张**，一张对应一句 |
| **合计** | **249** | |

**和上一版比：** 上一版允许几句共用一张新图（例如点头图给 5 句 Yes 用），只要 62 张。改成一句一图以后，把能复用的现成图和背景都用上，又加了 22 句代码卡，新图还是从 62 张增加到 89 张。

## 2. 分级

| 级 | 句数 | 复用 | 代码画 | 新画 | 额度（累计） |
|---|---|---|---|---|---|
| L1 | 38 | 15 | 5 | 18 | 约 7.0%（7.0%） |
| L2 | 44 | 23 | 5 | 16 | 约 6.2%（13.3%） |
| L3 | 31 | 16 | 0 | 15 | 约 5.9%（19.1%） |
| L4 | 35 | 9 | 4 | 22 | 约 8.6%（27.7%） |
| L5 | 37 | 20 | 9 | 8 | 约 3.1%（30.8%） |
| L6 | 33 | 5 | 25 | 3 | 约 1.2%（32.0%） |
| L7 | 31 | 10 | 14 | 7 | 约 2.7%（34.7%） |

## 3. 额度

- 现在用到 94%，95% 就停，所以 **10/28 之前一张都不画**。
- 每张按 0.3% 算，再加 30% 的返工，约 0.39% 一张。
- 89 张一共约 **35%**（不返工的话约 27%），10/28 重置后够画完。
- 62 句代码卡不占额度。

## 4. 10/28 之后的出图顺序

先画 L1（18 张，约 7%），再画 L2（16 张），依次往后，每画完一级先验收再画下一级。L1–L2 一共 34 张（约 13%）。

| 顺序 | 新图 | 级 | 句子 |
|---|---|---|---|
| 1 | N01_hello | L1 | L1-1-01 Hello! |
| 2 | N02_hi | L1 | L1-1-02 Hi! |
| 3 | N03_howareyou | L1 | L1-1-03 How are you? |
| 4 | N04_fine_amy | L1 | L1-1-04 Fine, thanks. And you? |
| 5 | N05_fine_tom | L1 | L1-1-05 I'm fine, too. |
| 6 | N06_goodmorning_tom | L1 | L1-2-02 Good morning, Mom! |
| 7 | N07_washface | L1 | L1-2-04 I wash my face. |
| 8 | N08_brushteeth | L1 | L1-2-05 I brush my teeth. |
| 9 | N09_thankyou | L1 | L1-3-03 Thank you! |
| 10 | N10_welcome | L1 | L1-3-04 You're welcome. |
| 11 | N11_sorry | L1 | L1-3-05 Sorry! |
| 12 | N12_itsok | L1 | L1-3-06 It's OK. |
| 13 | N13_full | L1 | L1-4-07 I'm full. |
| 14 | N14_goodbye | L1 | L1-5-04 Goodbye, Amy! |
| 15 | N15_byebye | L1 | L1-5-05 Bye-bye! |
| 16 | N16_seeyoulater | L1 | L1-5-07 See you later! |
| 17 | N17_story | L1 | L1-6-04 A story, please! |
| 18 | N18_loveyoutoo | L1 | L1-6-07 I love you, too. |
| 19 | N19_whatsname | L2 | L2-1-01 What's your name? |
| 20 | N20_imtom | L2 | L2-1-02 I'm Tom. |
| 21 | N21_mayihavename | L2 | L2-1-03 May I have your name? |
| 22 | N22_amyname | L2 | L2-1-04 My name is Amy. |
| 23 | N23_nicetomeet | L2 | L2-1-05 Nice to meet you. |
| 24 | N24_nicetomeettoo | L2 | L2-1-06 Nice to meet you, too. |
| 25 | N25_howold | L2 | L2-1-07 How old are you? |
| 26 | N26_lionmask | L2 | L2-2-01 Who are you? |
| 27 | N27_areyoutom | L2 | L2-2-03 Are you Tom? |
| 28 | N28_areyoucat | L2 | L2-2-05 Are you a cat? |
| 29 | N29_whatsthis | L2 | L2-3-01 What's this? |
| 30 | N30_whatsthisenglish | L2 | L2-3-05 What's this in English? |
| 31 | N31_whosehat | L2 | L2-4-05 Whose hat is this? |
| 32 | N32_amys | L2 | L2-4-06 It's Amy's. |
| 33 | N33_myturn | L2 | L2-6-03 My turn. |
| 34 | N34_yourturn | L2 | L2-6-04 Your turn. |
| 35 | N35_whereteddy | L3 | L3-1-01 Where is my teddy? |
| 36 | N36_knowwhere | L3 | L3-1-04 Do you know where they are? |
| 37 | N37_wherebook | L3 | L3-1-06 Where is my book? |
| 38 | N38_foundpen | L3 | L3-2-01 I found your pen! |
| 39 | N39_whichbag | L3 | L3-2-03 Which is your bag? |
| 40 | N40_hook | L3 | L3-2-05 The one on the hook? |
| 41 | N41_booksyours | L3 | L3-2-06 Are these books all yours? |
| 42 | N42_comein | L3 | L3-3-02 Come in, please. |
| 43 | N43_rollcall | L3 | L3-3-05 Who is here today? |
| 44 | N44_here | L3 | L3-3-06 Here! |
| 45 | N45_toilet | L3 | L3-3-08 Where's the toilet, please? |
| 46 | N46_areyouready | L3 | L3-4-02 Are you ready? |
| 47 | N47_understand | L3 | L3-4-03 Do you understand? |
| 48 | N48_questions | L3 | L3-4-06 Any questions? |
| 49 | N49_allfortoday | L3 | L3-4-07 That's all for today. |
| 50 | N50_student | L4 | L4-1-03 Is that girl a student? |
| 51 | N51_dontknow | L4 | L4-1-06 I really don't know. |
| 52 | N52_noidea | L4 | L4-1-07 I have no idea. |
| 53 | N53_whatdoyoudo | L4 | L4-2-01 What do you do? |
| 54 | N54_farmer | L4 | L4-2-02 I'm a farmer. |
| 55 | N55_whatdoeshedo | L4 | L4-2-03 What does he do? |
| 56 | N56_doctor | L4 | L4-2-04 He's a doctor. |
| 57 | N57_teacher | L4 | L4-2-05 Is she a teacher? |
| 58 | N58_busdriver | L4 | L4-2-06 Is she a bus driver? |
| 59 | N59_thisisamy | L4 | L4-3-02 This is Amy. She's my classmate. |
| 60 | N60_helloamy | L4 | L4-3-03 Hello, Amy! |
| 61 | N61_howdoyoudo | L4 | L4-3-04 How do you do? |
| 62 | N62_introself | L4 | L4-3-05 Let me introduce myself. |
| 63 | N63_amelia | L4 | L4-3-06 My name is Amelia. |
| 64 | N64_callmeamy | L4 | L4-3-07 Just call me Amy. |
| 65 | N65_pinkgirl | L4 | L4-4-01 Who is the girl in pink? |
| 66 | N66_introduceher | L4 | L4-4-02 Could you introduce me to her? |
| 67 | N67_familyname | L4 | L4-4-03 What's your family name? |
| 68 | N68_wang | L4 | L4-4-04 My family name is Wang. |
| 69 | N69_spell | L4 | L4-4-06 W-A-N-G. |
| 70 | N70_someleft | L4 | L4-5-05 I have some left. |
| 71 | N71_somemore | L4 | L4-5-06 Can I have some more? |
| 72 | N72_bigbrother | L5 | L5-1-04 Yes, I have a big brother. |
| 73 | N73_anybrothers | L5 | L5-1-05 Do you have any brothers? |
| 74 | N74_shampoo | L5 | L5-2-07 Do you have shampoo here? |
| 75 | N75_snowman | L5 | L5-4-06 Let's make a snowman! |
| 76 | N76_umbrella | L5 | L5-5-06 Take your umbrella. |
| 77 | N77_sure | L5 | L5-6-02 Sure. Here you are. |
| 78 | N78_biggerone | L5 | L5-6-04 Do you have a bigger one? |
| 79 | N79_justright | L5 | L5-6-05 This one is just right! |
| 80 | N80_childrensday | L6 | L6-4-03 It's Children's Day! |
| 81 | N81_newyear | L6 | L6-6-01 Happy New Year! |
| 82 | N82_redenvelope | L6 | L6-6-05 Can I have a red envelope? |
| 83 | N83_tickets | L7 | L7-2-03 Any tickets left? |
| 84 | N84_heretickets | L7 | L7-2-04 Yes, here you are. |
| 85 | N85_grandpahug | L7 | L7-3-02 It's been a long time, Grandpa! |
| 86 | N86_yesready | L7 | L7-4-04 Yes! I'm ready! |
| 87 | N87_picnicoff | L7 | L7-5-02 The picnic is put off. |
| 88 | N88_homepicnic | L7 | L7-5-04 Let's have a picnic at home! |
| 89 | N89_greatidea | L7 | L7-5-05 What a great idea! |

每张图的中文画图说明在 `images-plan.json` → `new_images[].brief`。统一画风写在 `style` 里：平涂 2D、深棕描边、暖米白纸底，没有文字、字母和数字，物体不画脸。

## 5. 8 张场景背景用在哪

| 背景 | 句子 |
|---|---|
| living_room | L1-5-02 Let's go home. |
| kindergarten_classroom | L3-3-04 It's time for class. |
| grandma_garden | L5-2-01 What a beautiful garden you have! |
| kindergarten_gate | L5-3-03 Time for school! |
| snowy_yard | L5-4-04 It's winter. |
| shoe_shop | L5-6-01 Can I try them on? |
| balcony_fireworks | L6-6-04 Let's watch the fireworks! |
| zoo_entrance | L7-1-02 I'll go to the zoo! |

## 6. 要你看一眼的地方

- **勉强能用的复用**：图里只画出了句子的关键词，其余意思靠声音。觉得哪句不够清楚，可以改成新画，每张约 0.4%：
  - L1-3-01 Juice, please! ← juice：只画了果汁，please 靠声音
  - L1-4-05 More rice, please. ← rice：只画了米饭，more/please 靠声音
  - L1-5-02 Let's go home. ← bg_living_room：家里客厅表示「回家」
  - L2-4-04 No, it isn't. ← stop：举手掌表示「不是」
  - L2-4-07 Is this yours? ← teddy：只画了泰迪熊，「是你的吗」靠声音
  - L3-1-03 Where are my shoes? ← shoes：只画了鞋，where 靠声音
  - L3-2-02 No. Mine is blue. ← blue：蓝色气球表示「我的是蓝色」
  - L3-3-04 It's time for class. ← bg_kindergarten_classroom：空教室表示「上课时间」
  - L3-4-08 Give me your picture, please. ← picture：一幅画表示「把画给我」
  - L4-1-05 Who is she? ← girl：女孩表示「她是谁」
  - L4-4-05 How do you spell it? ← write：孩子在写字，表示「怎么拼」
  - L4-5-08 Yes, I have your eraser, too. ← eraser：只画了橡皮，「也在我这」靠声音
  - L5-1-02 She is very well, thank you. ← smile：微笑表示「她很好」
  - L5-1-06 No, I'm the only child. ← child：大人牵一个孩子（高亮），表示独生
  - L5-2-06 What's the name of the cat? ← kitten：小猫+猫妈妈，表示「猫叫什么名字」
  - L5-6-01 Can I try them on? ← bg_shoe_shop：鞋店，「试穿」靠声音
  - L5-6-06 You look great! ← pretty：女孩照镜子般臭美，表示「你看起来真棒」
  - L6-3-03 Come to my party! ← balloon：气球表示派对
  - L7-3-01 Grandpa's plane is late. ← airport：机场+飞机，「晚点」靠声音
  - L7-4-05 Let's go! ← run：奔跑表示「走吧」
- **对勾 / 叉：** 有 7 句 Yes / No 用代码画的绿色对勾、红色叉，叠在对应物体的小图上（例如猫的小图加叉＝No, I'm not）。对勾和叉是形状，不是字母，但算不算符合「图里不出现文字」，要你定一下。不接受的话，这 7 句改成新画，约 2.7%。
- **代码卡里的小图：** 代码卡里会叠一些现成小图，比如 7 点钟面旁边放 wake 图。这些图在别的卡片上也是整张大图，这里只是缩小后放进图表里。
- **几张图还没进仓库：** give、hungry、thirsty、brave、clap、point、find、big、small、know、brother、smile、child、kitten、beach 这 15 张是刚重画的，还在 `/workspace/kea-pm/meaning-redo/out/`，要等单词图那次改动合并后才进仓库。
- **背景要裁切：** 背景是 3:2 横图，主体偏小，放进卡片时要居中缩放。
- **没用的旧图：** 现成的 sun、moon 图有脸，不用，太阳和月亮都由代码画成没有脸的。旧的 grandma、grandpa 是 3D 黏土风格，也不用，改用平涂的 grandmother。

## 7. 代码卡（交给 Qoder）

daysky 4 句、days 5 句、count 2 句、yesno 7 句、mood 1 句、crayonbox 1 句、week 7 句、calendar 6 句、monthring 3 句、season 2 句、weather 1 句、clock 23 句。每句怎么画写在 `lines[].code_spec`，要叠的现成小图写在 `code_icons` 里。同一类卡片里每句的画法都不一样，比如问句的指针会转、答句的指针不动、手表和挂钟样式不同，不会出现两张一模一样的卡。
