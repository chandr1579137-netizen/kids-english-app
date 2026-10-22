# 日常口语 L1–L7 进阶规划（用完用户给的 150 句）

> 产品经理 · 2026-10-22（北京时间）· 只读规划，没有改代码、出图或推送。
> 文件：`source150.json`（原句）· `mapping150.json`（每句的处理决定）· `phrases-levels.json`（最终 L1–L7 数据）· `build_levels.py` / `selfcheck_levels.py`（生成和自查脚本）

## 1. 总览

- **7 级、38 个场景、249 句。** 其中 149 句来自用户的 150 句，100 句是补充的儿童常用句（大部分来自上一版 phrases.json 的 81 句骨干，保留了 67 句）。
- **150 句全部有处理决定：** 原样保留 69、改成儿童版 75、合并 6、删除 **0**。
- **每句最多几个词：** L1 4 · L2 6 · L3 6 · L4 7 · L5 7 · L6 7 · L7 8（脚本里有断言检查）。
- **改编原则：** 句型不变，只换内容，把成人的人、物、事换成孩子的。例如：电脑换成蜡笔，经理换成医生，开会换成野餐，年份换成生日或季节，外国全名换成 Tom 和 Amy。

## 2. 分级表

| 级 | 主题 | 场景（句数） | 句数 | 平均/最多词数 | 新句型 | 例句 |
|---|---|---|---|---|---|---|
| L1 | 问候与礼貌 | 打招呼(5)；早上好(6)；请和谢谢(6)；吃饭啦(7)；说再见(7)；晚上好·晚安(7) | 38 | 2.5 / 4（上限 4） | Hello / Hi · How are you? – Fine, thanks. · Good morning / afternoon / evening / night · … , please. / Thank you. · Sorry. – It's OK. · I'm + 感受（hungry/sleepy） · See you … / Goodbye | Hello! / I'm fine, too. / Goodbye, Amy! |
| L2 | 我是谁·这是什么 | 认识新朋友(8)；猜猜我是谁(7)；这是什么(8)；是你的吗(8)；我的心情(6)；一起玩(7) | 44 | 3.1 / 6（上限 6） | What's your name? – I'm … / My name is … · Who are you? / Are you …? – Yes, I am. / No, I'm not. · What's this? – It's a … / Is that a …? · What color is …? · Is this your …? / Whose … is this? – It's Amy's. · Is this yours? – Yes, it's mine. | What's your name? / Are you Tom? / What's this in English? |
| L3 | 找东西·在幼儿园 | 找东西(8)；哪个是你的(7)；上学啦(8)；画画课(8) | 31 | 3.8 / 6（上限 6） | Where is/are my …? – On the … / Over there. · Do you know where …? · Which is your …? – The big one. · Mine is … · Are these … yours? – Some of them are mine. · 课堂句：May I …? / Could you say it again? / Any questions? | Where are my shoes? / Are these books all yours? / Where's the toilet, please? |
| L4 | 他是谁·做什么 | 那是谁(7)；大人做什么(7)；介绍朋友(7)；你姓什么(6)；借文具(8) | 35 | 4.4 / 7（上限 7） | Who is …? – He's my … / She's … · Is that girl a …? – No, she isn't. · What do you do? / What does he do? – He's a doctor. · I don't know. / I have no idea. / I think so. · This is … He's my classmate. · What's your family name? / How do you spell it? · Do you have …? – Yes, I do. / I have some left. | Who is the boy over there? / Is she a teacher? / Could you introduce me to her? |
| L5 | 家人·星期·月份 | 你家有谁(6)；去奶奶家(7)；今天星期几(6)；几月份(6)；天气怎么样(6)；买鞋子(6) | 37 | 4.4 / 7（上限 7） | How is your …? – She is very well. · Do you have any brothers or sisters? · … , doesn't he? – No, he doesn't. · What a … you have! · What day is it today? – It's Monday. · What month is it? – It's December. · What season is it? | How is your mom? / How big is your house, Grandma? / What day is it today? |
| L6 | 几点了·特别的日子 | 几点了(6)；我的小手表(5)；生日派对(8)；儿童节(4)；我的一天(5)；过新年(5) | 33 | 4.5 / 7（上限 7） | What time is it? – It's … o'clock / half past … / a quarter past … · It's almost … o'clock. · My watch says … · What's the date today? – It's June the first. · When is your birthday? – My birthday is in May. · Come to my party! – What time? – At three o'clock. | What time is it now? / What time is it on your watch? / At three o'clock. |
| L7 | 计划·过去·更长的句子 | 周末计划(7)；去动物园(7)；爷爷来了(7)；别迟到(5)；下雨天(5) | 31 | 5.0 / 8（上限 8） | What will you do this weekend? – I'll … · What did you do last …? – I went … · Does … open at …? – It opens at … · How long …? – Only … · We must be on time. / There are only … left. · It's been a long time! / I'll be back in … days. · … is put off. | What will you do this weekend? / Any tickets left? / What did you do last summer? |

**年龄对应：** L1–L2 适合 4 岁（问候、礼貌、名字、这是什么），L3–L4 适合 4–5 岁（找东西、幼儿园、职业、介绍），L5 适合 5 岁（家人、星期、月份、天气），L6 适合 6 岁（整点、半点、一刻、日期），L7 适合 6–7 岁（周末计划、过去时、较长的句子）。

## 3. 解锁规则（推荐）

- **沿用现在「读短文」的逻辑：** 一级里按顺序解锁，已完成的场景加上第一个没完成的场景可以点，后面的显示锁。
- **级与级之间：** L1 一开始就开放；一级的所有场景都完成后，才解锁下一级（现在 L1–L7 一开始全部开放，4 岁孩子容易点进 L7 被吓到）。
- **「完成一个场景」：** 把整段对话听完一遍就算，自动播放也算。可以加一个可选的小练习「听一听，点出是谁说的」，做完给 1 张收集卡片，这样「收集卡片」有新来源，不会断。
- **家长中心：** 加一个「全部解锁」开关，给想跳级的家长用。

## 4. 需要特殊画法的句子（图里不能有数字和字母）

共 26 句。建议**钟面和日历都由 Qoder 用 SwiftUI 画，不占 Muse 额度**：
- **钟面：** 只画 12 个小圆点刻度，不写数字，指针按句子里的时间摆好。
- **日历：** 只画空白方格，用星星贴纸标出那一天。
- **天数：** 用几个小图标表示（例如 5 个小书包），不写数字。
- **「I'm four.」：** 画四根手指。

| 级 | 场景 | 句子 | 画法 |
|---|---|---|---|
| L2 | 认识新朋友 | I'm four. | 用手指个数表示，不画数字 |
| L6 | 几点了 | What time is it now? | 无数字钟面：圆形钟只画 12 个小圆点刻度，不写数字，指针指向对应位置 |
| L6 | 几点了 | It's two o'clock. | 无数字钟面：圆形钟只画 12 个小圆点刻度，不写数字，指针指向对应位置 |
| L6 | 几点了 | It's not four o'clock. | 无数字钟面：圆形钟只画 12 个小圆点刻度，不写数字，指针指向对应位置 |
| L6 | 几点了 | It's half past nine. | 无数字钟面：圆形钟只画 12 个小圆点刻度，不写数字，指针指向对应位置 |
| L6 | 几点了 | It's twelve o'clock. Lunch time! | 无数字钟面：圆形钟只画 12 个小圆点刻度，不写数字，指针指向对应位置 |
| L6 | 几点了 | It's a quarter past five. | 无数字钟面：圆形钟只画 12 个小圆点刻度，不写数字，指针指向对应位置 |
| L6 | 我的小手表 | What time is it on your watch? | 无数字钟面：圆形钟只画 12 个小圆点刻度，不写数字，指针指向对应位置 |
| L6 | 我的小手表 | My watch says two o'clock. | 无数字钟面：圆形钟只画 12 个小圆点刻度，不写数字，指针指向对应位置 |
| L6 | 我的小手表 | My watch is two minutes fast. | 无数字钟面：圆形钟只画 12 个小圆点刻度，不写数字，指针指向对应位置 |
| L6 | 我的小手表 | It's almost four o'clock. | 无数字钟面：圆形钟只画 12 个小圆点刻度，不写数字，指针指向对应位置 |
| L6 | 生日派对 | At three o'clock. | 无数字钟面：圆形钟只画 12 个小圆点刻度，不写数字，指针指向对应位置 |
| L6 | 儿童节 | Today is June the first. | 日历页只画空白方格，用贴纸/小星星标出那一天，不写数字和字母 |
| L6 | 我的一天 | I get up at seven o'clock. | 无数字钟面：圆形钟只画 12 个小圆点刻度，不写数字，指针指向对应位置 |
| L6 | 我的一天 | I go to school at eight. | 无数字钟面：圆形钟只画 12 个小圆点刻度，不写数字，指针指向对应位置 |
| L6 | 我的一天 | I have lunch at twelve. | 无数字钟面：圆形钟只画 12 个小圆点刻度，不写数字，指针指向对应位置 |
| L6 | 我的一天 | I play in the park at four. | 无数字钟面：圆形钟只画 12 个小圆点刻度，不写数字，指针指向对应位置 |
| L6 | 我的一天 | Bedtime is half past eight. | 无数字钟面：圆形钟只画 12 个小圆点刻度，不写数字，指针指向对应位置 |
| L6 | 过新年 | Is it January the first? | 日历页只画空白方格，用贴纸/小星星标出那一天，不写数字和字母 |
| L7 | 周末计划 | I'll go to school for five days. | 用 5 个小图标表示天数，不写数字 |
| L7 | 去动物园 | Does the zoo open at nine? | 无数字钟面：圆形钟只画 12 个小圆点刻度，不写数字，指针指向对应位置 |
| L7 | 去动物园 | It opens at eight on weekends. | 无数字钟面：圆形钟只画 12 个小圆点刻度，不写数字，指针指向对应位置 |
| L7 | 去动物园 | Only ten minutes. | 无数字钟面：圆形钟只画 12 个小圆点刻度，不写数字，指针指向对应位置 |
| L7 | 爷爷来了 | I'll be back in three days. | 用 3 个太阳/月亮小图标表示三天，不写数字 |
| L7 | 爷爷来了 | Let's check the calendar. | 日历页只画空白方格，用贴纸/小星星标出那一天，不写数字和字母 |
| L7 | 别迟到 | There are only two minutes left. | 无数字钟面：圆形钟只画 12 个小圆点刻度，不写数字，指针指向对应位置 |

其他规避：「How do you spell it? / W-A-N-G.」这两句，字母只出现在屏幕的字幕文字里，图里只画孩子用手指在空中画；邀请卡、票、名牌、黑板都只画图案。

## 5. 图和音频预算（按版式 A 对话气泡计算）

| 方案 | 新画多少张 | Muse 额度（每张约 0.3%，返工系数 1.3） |
|---|---|---|
| ① 每个场景一张专属情景图 + 9 个角色头像 | 38 + 9 = **47** | 约 14%，算上返工约 **18%** |
| ② 按地点共用背景（客厅、教室、幼儿园门口、卧室、厨房、公园、农场、奶奶家花园、雪地院子、鞋店、阳台烟花、动物园、机场，共 13 个地点；公园、厨房、卧室、农场 4 个复用「找一找」现有的背景图）+ 9 个角色头像 | 9 + 9 = **18** | 约 5.4%，算上返工约 **7%** |
| 推荐 ③ 分批：L1–L2 的 12 个场景每个一张专属图 + 9 个头像；L3–L7 用 ② 的共用背景 | 12 + 9 + 约 7 = **约 28** | 约 8.4%，算上返工约 **11%** |

- 气泡里的小图可以复用现有词图（21 句）。钟面和日历由代码画，**0 张**。
- 推荐方案 ③ 排在 10/28 额度重置之后画。先画 L1–L2 共 21 张（约 6–8%），L1–L2 先上线，后面的级边做边补。
- **音频：** 249 句，正常速度和慢速（0.8 倍）各一份，共 **498 个 mp3**，另附逐词时间戳。
- **配音人选：**
  - Mom 用 Aria（和全 App 一致）
  - Dad 用 Guy
  - Teacher 用 Jenny
  - Tom 用 AnaNeural 降调
  - Amy 用 AnaNeural
  - 爷爷用 Christopher（慢速）
  - 奶奶用 Michelle（慢速）
  - 农民叔叔用 Eric
  - 动物园工作人员用 Emma
- edge-tts 没有老人和男童的声音，需要 Qoder 先出试听版，让用户选。

## 6. 和旧的 90 篇课文相比，实现上要改什么

- **数据：** 新增 `phrases-levels.json`，两份 Resources 都要放，配新的模型 `PhraseLevel / PhraseScene / PhraseLine`。旧的 `lessons-l*.json` 怎么处理，见第 7 节的待决定问题。
- **页面：** `ReadView` 的分级按钮和锁可以直接复用，列表项改成场景。场景页按版式 A 新写。朗读、录音和中文开关复用 `LessonView` 和 `Recorder` 的做法。
- **测试：**
  - `ModelDecodingTests` 里写死的 `lessons.count == 90` 要改成按数据计算。
  - 新增测试：一共 38 个场景、249 句；每句不超过本级的词数上限；不含数字；没有重复的句子；每个说话人都有对应的声音。
  - `validate_resources.py` 加上对 phrases 的检查。
- **进度：**
  - 新增 `completedPhraseScenes`，进度导出的 JSON 要兼容旧版本（ProgressKit）。
  - 家长中心的「已完成课程 N/90」改成按实际篇数计算。
  - 「收集卡片」现在只能从课文练习里得到，改成场景小练习也能得到。
- **21 个移除词：** 新内容里只出现了 nice（Nice to meet you）、make（Let's make a snowman!）和 right（just right），都是整句里的固定用法，不进启蒙书。如果旧课文下线，「这 21 个词保留在课文里」这一条就落空了，词图表意分支里相关的测试断言要一起改。
- **CI 截图：** `03-read`、`08-lesson`、`26-large-lesson`、`40/41-large-alert-*` 要换成新页面，另外加每一级的列表截图和一张钟面截图。
- **README：** 「90 篇课文 · 305 段朗读」要更新。
- **小游戏：** 不读课文数据，不受影响。

## 7. 需要用户决定的问题

1. **解锁方式：** 一级的场景全部完成后才开下一级（推荐，家长可以一键全部解锁），还是像现在一样 L1–L7 一开始全部开放？
2. **旧的 90 篇课文：** 全部下线，还是 L1 里约 8 篇适合 4 岁的短故事留作「小故事」栏（推荐）？
3. **名字：** 主角叫 Tom，好朋友叫 Amy。L4 里「My family name is Wang.」用的姓「王」、L6 里「My birthday is in May.」用的五月，要不要换成孩子家真实的姓和孩子真实的生日月份？
4. **出图方案：** 选推荐的分批方案 ③（约 28 张，约 11% 额度），还是每个场景都画专属图的方案 ①（47 张，约 18%）？两种都排在 10/28 之后。
5. **L6–L7 的难度：** 一刻钟（a quarter past）、反意疑问句（doesn't he?）、过去时这些内容大约是 6–7 岁的水平，可以吗？如果觉得太难，可以先只上线 L1–L5。

## 8. 150 句逐句处理表

| # | 原句 | 决定 | 最终句（级·场景） | 理由 |
|---|---|---|---|---|
| 1 | Hello! / Hi! | 保留 | Hello!（L1·L1-1）<br>Hi!（L1·L1-1） | 原句就适合孩子，只做了标点或大小写的规范 |
| 2 | Good morning / afternoon / evening! | 改编 | Good morning!（L1·L1-2）<br>Good afternoon!（L1·L1-5）<br>Good evening, Dad!（L1·L1-6） | 拆成 3 句，分别放在早上、下午、晚上的情景里：Good morning! / Good afternoon! / Good evening, Dad! |
| 3 | I'm Kathy King. | 改编 | I'm Tom.（L2·L2-1） | 把成人全名换成主角 Tom，句型 I'm … 不变 |
| 4 | Are you Peter Smith? | 改编 | Are you Tom?（L2·L2-2） | 把成人全名换成 Tom，改成化装游戏里猜人，句型 Are you …? 不变 |
| 5 | Yes, I am. / No, I'm not. | 改编 | Yes, I am!（L2·L2-2）<br>No, I'm not.（L2·L2-2） | 拆成两句，分别回答两个不同的问题 |
| 6 | How are you? | 保留 | How are you?（L1·L1-1） | 原句就适合孩子，只做了标点或大小写的规范 |
| 7 | Fine, thanks. And you? | 保留 | Fine, thanks. And you?（L1·L1-1） | 原句就适合孩子，只做了标点或大小写的规范 |
| 8 | I'm fine, too. | 保留 | I'm fine, too.（L1·L1-1） | 原句就适合孩子，只做了标点或大小写的规范 |
| 9 | How is Amy / your wife / your husband? | 改编 | How is your mom?（L5·L5-1） | 把 wife / husband 换成 mom，句型 How is your …? 不变 |
| 10 | She is very well, thank you. | 保留 | She is very well, thank you.（L5·L5-1） | 原句不变（她 = Amy 的妈妈） |
| 11 | Good night, Jane. | 改编 | Good night, Mom.（L1·L1-6） | 把 Jane 换成 Mom，用在睡前情景 |
| 12 | Good-bye, Mike. | 改编 | Goodbye, Amy!（L1·L1-5） | 把 Mike 换成 Amy，Good-bye 写成 Goodbye |
| 13 | See you tomorrow. | 保留 | See you tomorrow!（L1·L1-5） | 原句就适合孩子，只做了标点或大小写的规范 |
| 14 | See you later. | 保留 | See you later!（L1·L1-5） | 原句就适合孩子，只做了标点或大小写的规范 |
| 15 | I have to go now. | 改编 | I have to go.（L1·L1-5） | L1 每句不超过 4 词，所以去掉 now：I have to go. |
| 16 | May I come in? | 保留 | May I come in?（L3·L3-3） | 原句就适合孩子，只做了标点或大小写的规范 |
| 17 | Come in, please. | 保留 | Come in, please.（L3·L3-3） | 原句就适合孩子，只做了标点或大小写的规范 |
| 18 | Sit down, please. | 保留 | Sit down, please.（L3·L3-3） | 原句就适合孩子，只做了标点或大小写的规范 |
| 19 | It's time for class. | 保留 | It's time for class.（L3·L3-3） | 原句就适合孩子，只做了标点或大小写的规范 |
| 20 | Open your books and turn to page 20. | 改编 | Open your books, please.（L3·L3-3） | 去掉“翻到第 20 页”，避免页码数字，加上 please |
| 21 | I'll call the roll before class. | 改编 | Who is here today?（L3·L3-3） | “点名”对孩子太抽象，改成老师点名时常说的 Who is here today?，后面接 Here! |
| 22 | Here! | 保留 | Here!（L3·L3-3） | 原句就适合孩子，只做了标点或大小写的规范 |
| 23 | Has everybody got a sheet? | 改编 | Does everyone have paper?（L3·L3-4） | sheet / 材料改成画画课上的纸：Does everyone have paper? |
| 24 | Any different opinion? | 改编 | Who has a different idea?（L3·L3-4） | “不同意见”对 4 岁太抽象，改成 Who has a different idea?，保留 different |
| 25 | Are you with me? | 改编 | Are you ready?（L3·L3-4） | Are you with me? 是成人课堂的说法，改成孩子听得懂的 Are you ready? |
| 26 | Have I made myself clear? | 改编 | Do you understand?（L3·L3-4） | Have I made myself clear? 改成 Do you understand?，意思相同、更简单 |
| 27 | Could you say it again? | 保留 | Could you say it again?（L3·L3-4） | 原句就适合孩子，只做了标点或大小写的规范 |
| 28 | Any questions? | 保留 | Any questions?（L3·L3-4） | 原句就适合孩子，只做了标点或大小写的规范 |
| 29 | That's all for today. | 保留 | That's all for today.（L3·L3-4） | 原句就适合孩子，只做了标点或大小写的规范 |
| 30 | Please turn in your paper before leaving. | 改编 | Give me your picture, please.（L3·L3-4） | 交论文改成交画：Give me your picture, please. |
| 31 | What's this? | 保留 | What's this?（L2·L2-3） | 原句就适合孩子，只做了标点或大小写的规范 |
| 32 | It's a pen. | 保留 | It's a pen.（L2·L2-3） | 原句就适合孩子，只做了标点或大小写的规范 |
| 33 | Is this your handbag? | 改编 | Is this your ball?（L2·L2-4） | 手提包换成球，句型 Is this your …? 不变 |
| 34 | No, it isn't. / Yes, it is. | 改编 | Yes, it is.（L2·L2-4）<br>No, it isn't.（L2·L2-4） | 拆成 Yes, it is. 和 No, it isn't. 两句，分别回答球和帽子两个问题 |
| 35 | Whose pen is this? | 改编 | Whose hat is this?（L2·L2-4） | 笔换成帽子，好接上一句的情景；句型 Whose … is this? 不变 |
| 36 | It's Kate's. | 改编 | It's Amy's.（L2·L2-4） | Kate 换成 Amy，句型 It's …'s. 不变 |
| 37 | Is that a car? | 保留 | Is that a car?（L2·L2-3） | 原句就适合孩子，只做了标点或大小写的规范 |
| 38 | No, it isn't. It's a bus. | 保留 | No, it isn't. It's a bus.（L2·L2-3） | 原句就适合孩子，只做了标点或大小写的规范 |
| 39 | What do you call this in English? | 改编 | What's this in English?（L2·L2-3） | What do you call this in English? 简化成 What's this in English?，意思不变 |
| 40 | What is the color of your new book? | 改编 | What color is your new book?（L2·L2-3） | What is the color of … 改成孩子常用的 What color is …? |
| 41 | How big is your house? | 改编 | How big is your house, Grandma?（L5·L5-2） | 加上 Grandma，用在去奶奶家的情景；句型不变 |
| 42 | How long is the street? | 改编 | How long is the snake?（L7·L7-2） | 街道换成动物园里的蛇：How long is the snake? |
| 43 | What's the name of the cat? | 保留 | What's the name of the cat?（L5·L5-2） | 原句不变（奶奶家的猫） |
| 44 | Where's the company? | 改编 | Where's the toilet, please?（L3·L3-3） | 公司换成孩子最需要问的厕所：Where's the toilet, please? |
| 45 | Which is the right size? | 合并 | → 并入 #56/#57 | 和 56 / 57（Which is your bag? – The bigger one.）是同一个“哪一个”句型；尺码对 4 岁没有意义，所以并进 L3-2 |
| 46 | What's this? | 合并 | → 并入 #31 | 和 31 What's this? 完全重复 |
| 47 | It's an air-conditioner. | 合并 | → 并入 #32 | 和 32 It's a pen. 是同一个 It's a/an … 句型；空调不是启蒙词，L2-3 里用 It's an apple. 来练 an |
| 48 | Is this yours? | 保留 | Is this yours?（L2·L2-4） | 原句就适合孩子，只做了标点或大小写的规范 |
| 49 | Yes, it's mine. | 保留 | Yes, it's mine.（L2·L2-4） | 原句就适合孩子，只做了标点或大小写的规范 |
| 50 | Where are my glasses? | 改编 | Where are my shoes?（L3·L3-1） | 眼镜换成鞋子，句型 Where are my …? 不变 |
| 51 | Do you know where I've put my glasses? | 改编 | Do you know where they are?（L3·L3-1） | 简化成 Do you know where they are?，保留 Do you know where … 句型 |
| 52 | Over there. | 保留 | Over there.（L3·L3-1） | 原句就适合孩子，只做了标点或大小写的规范 |
| 53 | On the desk. | 保留 | On the desk.（L3·L3-1） | 原句就适合孩子，只做了标点或大小写的规范 |
| 54 | Is this your pen? I found it under the desk. | 改编 | I found your pen!（L3·L3-2） | 原句两句共 10 词太长，改成 I found your pen!，保留 found |
| 55 | No. Mine is blue. | 保留 | No. Mine is blue.（L3·L3-2） | 原句就适合孩子，只做了标点或大小写的规范 |
| 56 | Which is your bag? | 保留 | Which is your bag?（L3·L3-2） | 原句就适合孩子，只做了标点或大小写的规范 |
| 57 | The bigger one. | 保留 | The bigger one.（L3·L3-2） | 原句就适合孩子，只做了标点或大小写的规范 |
| 58 | The one on your right. | 改编 | The one on the hook?（L3·L3-2） | 孩子分不清左右，改成 The one on the hook?，保留 The one on … 句型 |
| 59 | Are these books all yours? | 保留 | Are these books all yours?（L3·L3-2） | 原句就适合孩子，只做了标点或大小写的规范 |
| 60 | Some of them are mine. | 保留 | Some of them are mine.（L3·L3-2） | 原句就适合孩子，只做了标点或大小写的规范 |
| 61 | Who are you? | 保留 | Who are you?（L2·L2-2） | 原句就适合孩子，只做了标点或大小写的规范 |
| 62 | I'm Jim. | 改编 | I'm a lion!（L2·L2-2） | Jim 换成化装游戏里的 I'm a lion! |
| 63 | Who is the guy over there? | 改编 | Who is the boy over there?（L4·L4-1） | guy 换成 boy |
| 64 | He's Bob. | 改编 | He's my brother.（L4·L4-1） | Bob 换成 He's my brother. |
| 65 | Is that girl a student? | 保留 | Is that girl a student?（L4·L4-1） | 原句就适合孩子，只做了标点或大小写的规范 |
| 66 | No, she isn't. | 保留 | No, she isn't.（L4·L4-1） | 原句就适合孩子，只做了标点或大小写的规范 |
| 67 | What do you do? | 保留 | What do you do?（L4·L4-2） | 原句就适合孩子，只做了标点或大小写的规范 |
| 68 | I'm a farmer. | 保留 | I'm a farmer.（L4·L4-2） | 原句就适合孩子，只做了标点或大小写的规范 |
| 69 | What does he do? | 保留 | What does he do?（L4·L4-2） | 原句就适合孩子，只做了标点或大小写的规范 |
| 70 | He's a manager. | 改编 | He's a doctor.（L4·L4-2） | 经理换成医生 |
| 71 | She must be a model, isn't she? | 改编 | Is she a teacher?（L4·L4-2） | 模特，加上原句的语法问题（must be … isn't she），改成 Is she a teacher? |
| 72 | I really don't know. | 保留 | I really don't know.（L4·L4-1） | 原句就适合孩子，只做了标点或大小写的规范 |
| 73 | I have no idea about it. | 改编 | I have no idea.（L4·L4-1） | 去掉 about it，更口语 |
| 74 | Can she be a driver? | 改编 | Is she a bus driver?（L4·L4-2） | Can she be a driver? 改成更自然的 Is she a bus driver? |
| 75 | Yes, I think so. | 保留 | Yes, I think so.（L4·L4-2） | 原句就适合孩子，只做了标点或大小写的规范 |
| 76 | What's your name? | 保留 | What's your name?（L2·L2-1） | 原句就适合孩子，只做了标点或大小写的规范 |
| 77 | May I have your name? | 保留 | May I have your name?（L2·L2-1） | 原句就适合孩子，只做了标点或大小写的规范 |
| 78 | My name is Thomas. | 改编 | My name is Amelia.（L4·L4-3） | Thomas 换成 Amelia，正好配合下一句“就叫我 Amy”，句型不变 |
| 79 | Just call me Tom. | 改编 | Just call me Amy.（L4·L4-3） | Tom 换成 Amy，配合上一句；句型不变 |
| 80 | What's your family name? | 保留 | What's your family name?（L4·L4-4） | 原句就适合孩子，只做了标点或大小写的规范 |
| 81 | My family name is Ayneswonth. | 改编 | My family name is Wang.（L4·L4-4） | 生僻的外国姓换成中国姓 Wang（可以改成孩子家真实的姓） |
| 82 | How do you spell it? | 保留 | How do you spell it?（L4·L4-4） | 原句就适合孩子，只做了标点或大小写的规范 |
| 83 | Who is the lady in white? | 改编 | Who is the girl in pink?（L4·L4-4） | lady in white 换成 the girl in pink |
| 84 | Could you introduce me to her? | 保留 | Could you introduce me to her?（L4·L4-4） | 原句就适合孩子，只做了标点或大小写的规范 |
| 85 | Rose, let me introduce my friend to you. | 改编 | Mom, let me introduce my friend.（L4·L4-3） | 把 Rose 换成 Mom，句子缩短到 6 词以内 |
| 86 | This is Tom. He's my classmate. | 改编 | This is Amy. She's my classmate.（L4·L4-3） | Tom 介绍 Amy，所以 He's 改成 She's |
| 87 | Nice to meet you. | 保留 | Nice to meet you.（L2·L2-1） | 原句就适合孩子，只做了标点或大小写的规范 |
| 88 | Nice to meet you, too. | 保留 | Nice to meet you, too.（L2·L2-1） | 原句就适合孩子，只做了标点或大小写的规范 |
| 89 | Let me introduce myself. | 保留 | Let me introduce myself.（L4·L4-3） | 原句就适合孩子，只做了标点或大小写的规范 |
| 90 | How do you do? | 保留 | How do you do?（L4·L4-3） | 原句就适合孩子，只做了标点或大小写的规范 |
| 91 | What day is it today? | 保留 | What day is it today?（L5·L5-3） | 原句就适合孩子，只做了标点或大小写的规范 |
| 92 | It's Monday today. | 保留 | It's Monday today.（L5·L5-3） | 原句就适合孩子，只做了标点或大小写的规范 |
| 93 | What's the date today? | 保留 | What's the date today?（L6·L6-4） | 原句就适合孩子，只做了标点或大小写的规范 |
| 94 | It's January the 15th, 1999. | 改编 | Tomorrow is my birthday!（L6·L6-3） | 1999 年的日期换成孩子会说的 Tomorrow is my birthday!（按用户建议） |
| 95 | What month is this? | 改编 | What month is it?（L5·L5-4） | this 改成更口语的 it |
| 96 | It's December. | 保留 | It's December.（L5·L5-4） | 原句不变 |
| 97 | What year is this? | 改编 | What season is it?（L5·L5-4） | “哪一年”对孩子没有意义，而且要出现年份数字，改成 What season is it?，保留 What … is it? 句型 |
| 98 | It's the year of 1999. | 改编 | It's winter.（L5·L5-4） | 年份 1999 改成 It's winter. |
| 99 | What will you do during this weekend? | 改编 | What will you do this weekend?（L7·L7-1） | during this weekend 改成 this weekend，更口语 |
| 100 | Does the shop open at 9 am on weekdays? | 改编 | Does the zoo open at nine?（L7·L7-2） | 商店 9 am 改成 Does the zoo open at nine?，用英文读数字 |
| 101 | It opens at 8 am on weekdays, but at 9 at weekends. | 改编 | It opens at eight on weekends.（L7·L7-2） | 原句太长（12 词），改成 It opens at eight on weekends. |
| 102 | What will you do the day after next? | 改编 | What will you do the day after tomorrow?（L7·L7-1） | day after next（用户原文是 after on next）改成孩子常说的 the day after tomorrow |
| 103 | What did you do the week before last? | 改编 | What did you do last weekend?（L7·L7-1） | the week before last 太难，改成 last weekend |
| 104 | I'll work for the next 5 days. | 改编 | I'll go to school for five days.（L7·L7-1） | “工作 5 天”改成 I'll go to school for five days. |
| 105 | It's been 5 years since I last saw you. | 改编 | It's been a long time, Grandpa!（L7·L7-3） | 5 years since … 改成 It's been a long time, Grandpa! |
| 106 | Do you have a computer? | 改编 | Do you have a crayon?（L4·L4-5） | 电脑换成蜡笔（按用户建议） |
| 107 | Yes, I do. | 保留 | Yes, I do.（L4·L4-5） | 原句就适合孩子，只做了标点或大小写的规范 |
| 108 | He has that book, doesn't he? | 改编 | Grandpa has a dog, doesn't he?（L5·L5-2） | 书换成爷爷的狗：Grandpa has a dog, doesn't he?，保留反意疑问句 |
| 109 | No, he doesn't. | 保留 | No, he doesn't. He has a cat.（L5·L5-2） | 原句不变，后面补一句 He has a cat. 让对话接得上 |
| 110 | Do you have any brothers or sisters? | 保留 | Do you have any brothers or sisters?（L5·L5-1） | 原句就适合孩子，只做了标点或大小写的规范 |
| 111 | No, I'm a single son. | 改编 | No, I'm the only child.（L5·L5-1） | single son 改成 I'm the only child.，由女孩 Amy 来说 |
| 112 | Does your computer have a modem? | 改编 | Does your crayon box have pink?（L4·L4-5） | 电脑和调制解调器改成 Does your crayon box have pink?，保留 Does your … have …? 句型 |
| 113 | Do you have shampoo here? | 保留 | Do you have shampoo here?（L5·L5-2） | 原句不变，场景换成奶奶家洗澡 |
| 114 | What a beautiful garden you have! | 保留 | What a beautiful garden you have!（L5·L5-2） | 原句就适合孩子，只做了标点或大小写的规范 |
| 115 | Any tickets left? | 保留 | Any tickets left?（L7·L7-2） | 原句就适合孩子，只做了标点或大小写的规范 |
| 116 | Do you have glue? I need some here. | 改编 | Do you have glue? I need some.（L4·L4-5） | 去掉 here：Do you have glue? I need some. |
| 117 | I have some left. | 保留 | I have some left.（L4·L4-5） | 原句就适合孩子，只做了标点或大小写的规范 |
| 118 | If you have more, please give me some. | 改编 | Can I have some more?（L4·L4-5） | If you have more… 是 8 词的条件句，改成 Can I have some more? |
| 119 | Do you have my pencil? | 保留 | Do you have my pencil?（L4·L4-5） | 原句就适合孩子，只做了标点或大小写的规范 |
| 120 | Yes, I have your eraser, too. | 保留 | Yes, I have your eraser, too.（L4·L4-5） | 原句就适合孩子，只做了标点或大小写的规范 |
| 121 | What time is it now? | 保留 | What time is it now?（L6·L6-1） | 原句就适合孩子，只做了标点或大小写的规范 |
| 122 | It's two o'clock. | 保留 | It's two o'clock.（L6·L6-1） | 原句就适合孩子，只做了标点或大小写的规范 |
| 123 | It's a quarter past five. | 保留 | It's a quarter past five.（L6·L6-1） | 原句就适合孩子，只做了标点或大小写的规范 |
| 124 | It's ten minutes to four. | 改编 | It's almost four o'clock.（L6·L6-2） | 差十分四点对 6 岁偏难，改成 It's almost four o'clock. |
| 125 | It's half past nine. | 保留 | It's half past nine.（L6·L6-1） | 原句就适合孩子，只做了标点或大小写的规范 |
| 126 | It's one o'clock sharp. | 改编 | It's twelve o'clock. Lunch time!（L6·L6-1） | one o'clock sharp 改成 It's twelve o'clock. Lunch time!，sharp 太难 |
| 127 | It's not four o'clock. | 保留 | It's not four o'clock.（L6·L6-1） | 原句就适合孩子，只做了标点或大小写的规范 |
| 128 | My watch says two o'clock. | 保留 | My watch says two o'clock.（L6·L6-2） | 原句不变（玩具手表） |
| 129 | My watch is two minutes fast. | 保留 | My watch is two minutes fast.（L6·L6-2） | 原句不变（L6） |
| 130 | What's the time by your watch? | 改编 | What time is it on your watch?（L6·L6-2） | What's the time by your watch? 改成更口语的 What time is it on your watch? |
| 131 | We must arrive there on time. | 改编 | We must be on time!（L7·L7-4） | arrive there on time 改成 We must be on time! |
| 132 | There are only two minutes left. | 保留 | There are only two minutes left.（L7·L7-4） | 原句不变 |
| 133 | Can you finish your work ahead of time? | 改编 | Can you finish your milk quickly?（L7·L7-4） | 提前完成工作改成 Can you finish your milk quickly? |
| 134 | The flight is delayed. | 改编 | Grandpa's plane is late.（L7·L7-3） | flight is delayed 改成 Grandpa's plane is late. |
| 135 | The meeting is put off. | 改编 | The picnic is put off.（L7·L7-5） | 会议延期改成野餐延期：The picnic is put off.，保留 put off |
| 136 | What day is today? | 合并 | → 并入 #91 | 和 91 What day is it today? 意思相同 |
| 137 | Today is Monday. | 合并 | → 并入 #92 | 和 92 It's Monday today. 意思相同 |
| 138 | What's the date today? | 合并 | → 并入 #93 | 和 93 What's the date today? 完全重复 |
| 139 | Today is May 21st. | 改编 | Today is June the first.（L6·L6-4） | 5 月 21 日改成六一儿童节：Today is June the first. |
| 140 | When were you born? | 改编 | When is your birthday?（L6·L6-3） | When were you born? 改成孩子常说的 When is your birthday? |
| 141 | I was born on September 1st, 1976. | 改编 | My birthday is in May.（L6·L6-3） | 去掉年份和具体日期：My birthday is in May.（可以改成孩子真实的生日月份） |
| 142 | What time? | 保留 | What time?（L6·L6-3） | 原句就适合孩子，只做了标点或大小写的规范 |
| 143 | You name the time. | 改编 | At three o'clock.（L6·L6-3） | “你定时间”是大人约时间的说法，改成直接回答 At three o'clock. |
| 144 | I'll meet you tomorrow. | 改编 | I'll see you tomorrow.（L6·L6-3） | meet 改成 see：I'll see you tomorrow. |
| 145 | Do you know the exact date? | 保留 | Do you know the exact date?（L7·L7-3） | 原句不变（问爷爷哪天回来） |
| 146 | Please check the date. | 改编 | Let's check the calendar.（L7·L7-3） | check the date 改成 Let's check the calendar. |
| 147 | What were you doing this time last year? | 改编 | What did you do last summer?（L7·L7-3） | this time last year 改成 What did you do last summer? |
| 148 | How long will the sale last? | 改编 | How long will the show last?（L7·L7-2） | 打折换成动物园的表演：How long will the show last? |
| 149 | Only three days. | 改编 | Only ten minutes.（L7·L7-2） | 三天改成 Only ten minutes.，配合表演 |
| 150 | I'll be back in 5 days. | 改编 | I'll be back in three days.（L7·L7-3） | 5 改成英文单词 three，回来的是爷爷 |

## 9. 自查（脚本 `selfcheck_levels.py`）

- 150 句全部有决定，脚本断言 id 从 1 到 150 齐全：保留 69 + 改编 75 + 合并 6 + 删除 0 = 150。
- 除了合并的句子，每一句都至少落到一个最终句子上；合并的句子不单独出现。
- 每级的词数上限都满足；所有最终句子里没有阿拉伯数字；没有 wife、manager、company、meeting、flight、computer、sale 这类成人或办公词；249 句没有重复；每个场景 4–8 句。
- 复用的词图都核对过存在，并且排除了不合规的图（four、sun、moon 等）。