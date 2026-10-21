# 提案 v2：首页显示全部单词本 + 4 岁孩子的新玩法

写于 2026-10-22（北京时间）。**这是提案，还没改任何代码，要用户批准后才动手。**
所有代码结论都对照过 `/workspace/kea-pm/repo`（GitHub main，HEAD `990fb86`，2026-10-21 21:38，北京时间）。

> 新规矩：产品经理不自己出图。之前自己画的示意图已经全部作废，移到了 `/workspace/kea-pm/_unused-mockups/`，`visuals-v2/` 现在是空的。
> 下面第 4 节是给 Muse 的出图说明，第 5 节是给 Qoder 的开发说明，都按优先级排好了。

---

## 1. 真机截图核查（`/workspace/fleet-share/home-wordbooks.png`）

**手机上装的是旧版本，不是最新的 main。**
- 截图上显示「已学 123 / 491」。这里的 491 是 `store.words.count`（`LearnWordsView.swift:145`），也就是"主题词和词典的交集"。
- 我把历史版本逐个算了一遍：
  - `88ce0dc`（2026-10-19 16:11）和 `0db48d8`：主题词 **491 个**，15 个主题，交集也是 491。
  - `91e00e6`（2026-10-20 21:24）把数字扩到 1–100、加了服装主题，变成 **573 个**，16 个主题。
  - **所以手机上的包，是 10-19 16:11 到 10-20 21:24 之间编出来的。**
- 版本号：`2c4c49a`（10-19 16:47）升到 2.1(3)，`b204c8b`（10-20 00:18）升到 2.3(4)。在手机上打开「我的」页（版本号读自 `ProfileView.swift:337`）就能看是哪一版。
- Day 13 也对得上：现在的算法是 123 ÷ 每天 10 个 + 1 = 13（`LearnWordsView.swift` 里的 `dayNumber`）。
- **截图上的 4 个书本图标里，苹果和小汽车长了脸。** 它们用的是 `Resources/ui-icons/theme-apple.png`、`theme-car.png`（旧的 3D 图标），违反"东西不能有脸"的规则。

## 2. 代码分析：为什么只显示 4 本

| 问题 | 结论 | 位置 |
|---|---|---|
| 首页单词本列表从哪来 | **写死的 4 张卡**：`allWordsCard` + 水果 / 动物 / 交通三张 `bookCard(...)`，放在一个不能滚动的 `HStack` 里。注释原话是"参考图：4 张卡一行排开，无横向滚动" | `LearnWordsView.swift:65-83`（卡片在 71–82 行） |
| 4 张卡的颜色 | `AppTheme.bookBlue / bookPink / bookGreen / bookPurple` | `Theme.swift:190-193` |
| 卡片的样子 | 82×148，圆角 18，图标 54，白字 | `LearnWordsView.swift:200-226` 的 `bookCardBody` |
| 点了之后 | 把 `store.selectedThemeId` 设成这个主题，然后 `saveProgress()`；`wordsForCurrentBook()` 按这本书出词 | `LearnWordsView.swift:184-194`，`DataStore.swift:197-202` |
| 「单词卡」页签显示哪些主题 | `ForEach(store.wordThemes)`，**word-themes.json 里的 16 个全部显示**，两列网格 | `WordCardsView.swift:23` |
| 16 个主题（id / 名称 / 词数） | fruits 水果 21 · animals 动物 59 · colors 颜色 13 · numbers 数字 100 · body 身体部位 21 · foods 食物 24 · family 家人 22 · home 家居用品 29 · clothing 服装 3 · vehicles 交通工具 22 · nature 自然 34 · stationery 文具 18 · toys 玩具 18 · places 地方 25 · actions 动作 83 · adjectives 形容词 81 | `Resources/word-themes.json` |
| 单词卡页的短名称 | 身体部位→身体，家居用品→家居，交通工具→交通 | `WordCardsView.swift:42-49` 的 `shortThemeName` |
| 单词卡页的图标 | `themeIconName(for:)` 返回 ui-icons 里的旧 3D 图标 | `Theme.swift:494-514` |
| 全部单词的学习顺序 | `picturableThemeOrder` 只列了 15 个主题，**漏了 clothing**，所以服装的 3 个词会排到最后才学 | `DataStore.swift:206-209` |
| 两份源码 | `KidsEnglish/KidsEnglish/*.swift` 才是真正被编译的；外层 `KidsEnglish/*.swift` 是镜像，改完要运行 `python scripts/sync_duplicated_sources.py`，CI 会检查两份是否一致 | `scripts/sync_duplicated_sources.py` |
| 两个 Xcode 工程 | 根目录 `KidsEnglish.xcodeproj` 和 `KidsEnglish/KidsEnglish.xcodeproj` 都存在。**新增 .swift 文件就要同时改两个 pbxproj**，所以建议把新代码放进已有文件 | `ls` 核对 |

**结论**：不是数据问题，是首页把 4 本书写死了。改成直接读 `store.wordThemes`，就能和单词卡页完全对齐。

### 每本书用哪个图标、什么颜色（图标都是仓库里现成的平涂词图，没有文字，东西没有脸）

| 顺序 | 主题 | 卡片名 | 图标词（文件） | 颜色 | 白字对比度 |
|---|---|---|---|---|---|
| 1 | 全部 | 全部单词 | book（`assets/word-icons-overrides/book.jpg`） | #1F7AF0（沿用 bookBlue） | 4.1 |
| 2 | fruits | 水果 | apple.jpg | #E85C7D（沿用 bookPink） | 3.4 |
| 3 | animals | 动物 | cat.jpg | #3D9E42（沿用 bookGreen） | 3.4 |
| 4 | colors | 颜色 | rainbow.jpg | #DA7200 | 3.3 |
| 5 | numbers | 数字 | marbles.jpg（几颗弹珠代表"数一数"，因为数字图本身都是数字卡） | #0E8C9B | 4.0 |
| 6 | body | 身体 | hand.jpg | #DE563A | 3.8 |
| 7 | family | 家人 | family.jpg | #5560D6 | 5.2 |
| 8 | foods | 食物 | hamburger.jpg | #B0601A | 4.6 |
| 9 | vehicles | 交通 | car.jpg（注意：交通图现在是半写实风格，不是平涂） | #8F6BD9（沿用 bookPurple） | 4.0 |
| 10 | home | 家居 | house.jpg | #8A5A3C | 5.8 |
| 11 | clothing | 服装 | clothes.jpg | #C94FA8 | 4.1 |
| 12 | nature | 自然 | tree.jpg | #5C8A1A | 4.1 |
| 13 | toys | 玩具 | blocks.jpg（不用泰迪熊，免得有"玩具长脸"的争议） | #D63A40 | 4.6 |
| 14 | stationery | 文具 | pencil.jpg | #2880C4 | 4.2 |
| 15 | places | 地方 | school（现在仓库里是旧 3D 图；Muse 的平涂版 `/workspace/flashcards/out/places/school.jpg` 入库后会自动替换） | #008074 | 4.8 |
| 16 | actions | 动作 | run.jpg | #C48000 | 3.3 |
| 17 | adjectives | 形容词 | happy.jpg | #5D7285 | 5.0 |

对比度是按 WCAG 公式算的。白字粗体 15pt 以上要求 ≥3:1，这 17 个都达标。顺序就是现有的 `picturableThemeOrder`，再把 clothing 插在 home 后面。

**布局有两种，请用户选（Muse 会各出一张效果图）：**
- **A（推荐）：两排横向滑动。** 卡片 76×112，一屏能看到 9–10 本，最右边露出半张，提示"还能滑"。今日计划卡从 235 高降到 160，保证「开始学习」按钮在第一屏里。
- **B：一排横向滑动。** 卡片大小不变（82×148），改动最小，但一屏只看到 4 本。

---

## 3. 调研：怎么让 4 岁孩子觉得好玩（每条都有来源）

### 这几家都在做什么
- **叽里呱啦**：内容形式有儿歌、绘本、动画、情景游戏、实拍、真人对话等十多种。孩子在屏幕上"点选、拖拽、描画、录音"参与互动；完成后发"魔石"，可以换实物奖励；有日、周、阶段三种学习闭环。评测者也指出语音识别不够准。
  来源：http://jiaoyu.cjsjw.cn/zixun/60873.html ，http://www.mngood.com/xiamen/szjy/21029.html
- **斑马英语**：每节 15 分钟，分 video → words → story → speaking → quiz → report → zebra call（模拟 AI 视频电话）。评测认为互动形式偏少、游戏场景不多。
  来源：https://tech.ifeng.com/c/82SWeGAQftu ，https://www.dashizg.com/jijin/2021030914257.html
- **小猴启蒙**：每节 15 分钟，流程是磨耳朵（歌谣）→ 互学 → 开口练 → 玩游戏（点选、拖拽）→ 读报告。评测认为它的口语游戏最丰富。
  来源：https://www.dashizg.com/jijin/2021030914257.html
- **Khan Academy Kids**：有吉祥物 Kodi 带着走学习路径；300 多本书有「Read to Me」，读到哪个词就高亮哪个词；书里的图可以点着探索。随机对照研究：4–5 岁孩子平均每天用 13 分钟，10 周后读写启蒙能力明显提升。
  来源：https://khankids.zendesk.com/hc/en-us/articles/4409036780955 ，https://khankids.zendesk.com/hc/en-us/articles/360042832631
- **Lingokids**：活动有游戏、儿歌、视频、有声书、播客五种形式；词汇练习里有「Hidden Objects」（在场景里找东西）、「Bug Catcher」等小游戏；还有 PlayTogether 亲子活动。
  来源：https://help.lingokids.com/hc/en-us/articles/9566835203601 ，https://help.lingokids.com/hc/en-us/articles/23532720590610
- **Duolingo ABC**：每课 5 分钟以内；课程排成一条线，做完一课解锁下一课；中间穿插庆祝动画；给孩子一个"帮角色收集书本"的任务，满足孩子爱收集的心理。
  来源：https://abc.duolingo.com/how-we-teach ，https://duolingo-papers.s3.amazonaws.com/reports/Duolingo_whitepaper_duolingo_method_2023.pdf
- **Endless Alphabet**：小怪兽把单词的意思"演"出来，配一句口语解释，没有压力。但字母发音有不准的地方，不建议照抄它教字母音。
  来源：https://originatorkids.com/endless-alphabet/ ，https://www.phonics.org/endless-alphabet-app-review/
- **Gus on the Go**：完全不需要识字，只靠图和母语者的发音，点一点、配一配，大约 90 个基础词。
  来源：https://screenwiseapp.com/guides/gus-on-the-go-app
- **Toca Boca**：做的是"数字玩具"，没有分数、没有时间限制、几乎没有文字，让孩子自由玩。
  来源：https://kidscreen.com/2014/02/20/toca-talks-why-freedom-is-best-for-kids-and-apps/ ，https://www.newyorker.com/culture/culture-desk/how-to-make-a-great-kids-app

### 研究结论
- **4 岁孩子能熟练用 7 种常见手势**，包括点、拖拽放下、捏合；2 岁的孩子拖拽有困难。所以"点"和"拖"都可以用。
  来源：https://doi.org/10.14569/ijacsa.2014.050415
- 另一项研究发现，4–6 岁孩子点中**正在移动的目标**只有 37% 能做到。所以游戏里的东西要静止或者慢慢动。
  来源：https://pmc.ncbi.nlm.nih.gov/articles/PMC7303424/
- **儿歌和边唱边做动作（TPR）**能提升学前儿童"听得懂"的词汇；两者结合效果最好。北京幼儿园的研究也发现唱歌组明显比对照组学得多。但 2024 年的系统综述提醒，这类研究大多设计较弱，不能保证效果。
  来源：https://files.eric.ed.gov/fulltext/EJ1304648.pdf ，https://doi.org/10.1515/cjal-2016-0004 ，https://doi.org/10.1016/j.system.2024.103350
- **带动画、可点热点的电子绘本**比静态绘本更能帮幼儿园孩子学词。但 meta 分析指出，热点和小游戏太多会分心，而动画、音乐、音效有帮助。
  来源：https://doi.org/10.1017/s0142716413000556 ，https://pmc.ncbi.nlm.nih.gov/articles/PMC4647204/
- **奖励要有上限**：ABCmouse 同一个活动最多奖励 5 次，引导孩子去学新内容。
  来源：https://support.abcmouse.com/hc/en-us/articles/360048194473

### 6 种新玩法（全部不需要识字），按推荐顺序排

| 排名 | 玩法 | 怎么玩 | 为什么适合 4 岁 | 需要什么素材 | 开发量 |
|---|---|---|---|---|---|
| **①** | **听音找一找** | 一张大场景图（农场 / 厨房 / 公园 / 卧室）里放 6–7 个物品。App 说"Where is the duck?"，孩子点对了，鸭子跳一下并读出单词；点错了，那个东西轻轻晃一下，再读一遍问题。每轮 5 题，得 5 颗星 | 只用"点"，最容易上手；Lingokids 有同类的 Hidden Objects；比现在的"听音选图"多了场景和故事感 | Muse：4 张场景背景（只画环境，不画可点的物品）。物品用现有词图抠掉背景。Qoder：每个词一句"Where is the X?"，再加 3 句表扬 | M |
| **②** | **喂小动物** | 一只动物说"I want a banana!"，孩子从下面 3 种食物里拖一个给它。喂对了，动物吃掉、跳一下、说"Yummy banana!"；喂错了，动物摇头说"No, thank you!"，食物弹回原位 | 4 岁孩子拖拽没问题；有"照顾小动物"的情感动机；叽里呱啦、小猴都有拖拽互动 | **不需要新图**，动物和食物都用现有词图抠图。Qoder：每种食物生成"I want a/an X""Yummy X"，再加"No, thank you" | M |
| ③ | 贴纸本 | 每学会一个词就得到这个词的贴纸，孩子把它拖到场景页上贴好；贴满一页有小动画，然后开新一页；同一个词最多奖励 5 次 | 解决"没意思"：给孩子收集的目标（Duolingo 的收集任务、叽里呱啦的魔石、ABCmouse 的上限都是这个思路） | Muse：3–4 张贴纸页背景。贴纸用现有词图 | M |
| ④ | 我来说（小鸟学舌） | 先听单词，然后按住红色麦克风说一遍，小鸟用孩子自己的声音学一遍。**不打分** | 鼓励开口；国内几家都有跟读，但 AI 评分不准，所以只做"录下来放给自己听" | 不需要新图（小鸟用 `bird.jpg`）。代码里已有 `Recorder`（`AudioPlayer.swift:153`），麦克风权限说明已写在 Info.plist | S |
| ⑤ | 儿歌跟唱 | 唱到哪句就显示这句的关键词大图，当前唱到的词高亮，配合拍手、跺脚之类的动作提示；可以慢速唱、可以重唱 | 儿歌加动作对学前儿童有效 | 不需要新图。Qoder 要用 edge-tts 重新生成 10 首儿歌，并拿到逐词时间。**问题：现在的儿歌是 Aria 朗读的，不是真的唱，孩子可能还是觉得没意思（见第 6 节）** | M |
| ⑥ | 小故事 | 每个故事 5 页，自动朗读，读到哪个词高亮哪个词；每页有 1 个可以点的地方（例如"球在盒子里吗？"） | Khan Kids 的 Read to Me、电子绘本研究都支持；但可点的地方要少，否则会分心 | Muse：每个故事 5 张图，第一批 2 个故事就要 10 张。Qoder：朗读 + 逐词时间 | L |

**建议先做 ① 听音找一找 + ② 喂小动物。**
- Muse 只需要 4 张场景背景，加上 8 张效果图，在 150–200 张的额度里很宽裕。
- 词、图、音频全部复用现有资源，代码量是中等，有机会在 Qoder 免费期（10/24 23:59，北京时间）结束前做完。
- 一个练"点"、一个练"拖"，加上去以后，App 就不再只是"翻卡片"。
- 下一步做 ③ 贴纸本，作为长期的奖励目标。

---

## 4. 给 Muse 的出图说明（按优先级）

**共同要求（每张都要遵守）：**
- 尺寸 1179×2556，竖屏，PNG（iPhone 15 Pro 截图尺寸）。
- 效果图是"App 界面截图"的样子：米白底 #FFF7F0，标题深蓝 #1A2478，主按钮绿 #1A9E2E，今日计划卡是橙色渐变（#E06A00 → #F59B14），底部 5 个页签：背单词 / 单词卡 / 读短文 / 儿歌 / 我的。
- 界面里的插画（动物、东西、场景）必须是平涂 2D 风格：深棕描边、米白纸纹底。**插画里不能有文字、字母、数字；东西和身体部位不能画脸。** 要尽量照着我列出的参考图画。
- 右下角加一个小标签「示意图」。
- 界面上的中文按我写的照抄。如果中文生成出来是乱码，就把文字位置留成浅灰色条，交回时告诉我，我改走 Qoder 截图的方式。

### M1（最优先）`home-after-A.png`：首页，两排横滑
- 从上往下：
  1. 状态栏。
  2. 今日计划卡（高约 160pt）：左边写「今日计划」「Day 13」「新学 10 个词 · 已学 123 / 573」，右边是火箭（参考 `repo/KidsEnglish/KidsEnglish/Resources/ui-icons/rocket.png`）。
  3. 标题「选单词本」，右边一行小灰字「左右滑 ›」。
  4. **两排单词本卡片**，竖着排（第 1 列上面是全部单词、下面是水果；第 2 列上面动物、下面颜色……）。一屏显示 5 列，第 5 列只露出一半。每张卡 76×112pt，圆角 18，是彩色底；里面有一个白色圆角小方块放图标，下面是白字卡名和词数。卡片的颜色和图标严格按第 2 节的表；图标文件在 `/workspace/kea-pm/repo/assets/word-icons-overrides/<词>.jpg`，「地方」用 `/workspace/flashcards/out/places/school.jpg`。第一张「全部单词」加 3pt 白色描边，表示当前选中。
  5. 绿色大按钮「开始学习 ▶」。
  6. 浅蓝按钮「巩固练习 · 9 种玩法」。
  7. 底部页签，「背单词」是选中状态。
- 参考现在的样子：`/workspace/fleet-share/home-wordbooks.png`。

### M2 `home-after-B.png`：首页，一排横滑（备选）
- 和现在一样高的计划卡（235pt）；单词本一排，卡片 82×148，一屏显示 4 张半，颜色和图标同上。其他同 M1。

### M3 `home-before-after.png`：改前改后对比
- 左边直接贴真机截图 `/workspace/fleet-share/home-wordbooks.png`，右边贴 M1。下面配字：「改造前：只有 4 本」「改造后：17 本，和单词卡一致」。

### M4 `play1-find-in-scene.png`：① 听音找一找
- 顶部：左边返回按钮，右边 5 颗星，点亮 2 颗。
- 中间大部分是一张平涂农场场景：天空、两座小山、木栅栏、草地；云不能有脸，不画太阳。
- 场景里放 7 只动物，参考：`cow.jpg`、`pig.jpg`、`hen.jpg`、`horse.jpg`、`sheep.jpg`、`duck.jpg`、`dog.jpg`（都在 `word-icons-overrides/`）。鸭子外面一圈金色光环，周围有小星星，表示答对了。
- 底部是白色圆角提示条：左边橙色喇叭按钮，右边写「“Where is the duck?”」，下面一行小灰字「只播声音，孩子不用看字」。

### M5 `play2-feed-the-animal.png`：② 喂小动物
- 上半部分是米色舞台，中间一只大猴子（参考 `monkey.jpg`），右上角有一个圆形气泡，里面是橙色喇叭；舞台左上角写「“I want a banana!”」。
- 下面是一个白色托盘，有 3 个格子：第 1 格空着（只有虚线框），第 2 格苹果（`apple.jpg`），第 3 格鱼（`fish.jpg`）。
- 香蕉（`banana.jpg`）正被一根手指从第 1 格拖向猴子，画一条橙色轨迹线，旁边小字「↑ 拖给小猴」。
- 最底部一行小字：「喂对了：小猴吃掉、开心跳一下，并说 “Yummy banana!”」。

### M6 `play3-sticker-book.png`：③ 贴纸本
- 标题「我的贴纸本」，副标题「农场 · 已贴 5 / 8」。
- 一页农场场景，已经贴好 5 张：`cow`、`pig`、`hen`、`duck`、`sheep`；还有 3 个灰色虚线圆圈，里面一个「?」，表示还没贴。
- 下面写「今天得到的贴纸（拖到上面贴好）」，下面 3 张贴纸卡：`horse`、`dog`、`rabbit`，每张右上角有一颗小星星。

### M7 `play4-sing-along.png`：⑤ 儿歌跟唱
- 标题「Clap Your Hands」，副标题「拍拍手 · 第 1 / 4 句」。
- 白色大卡片里是两只张开的手（参考 `hand.jpg`），中间画拍手的动作线。卡片下方是歌词「Clap your hands, one two three」，当前唱到的「your」是橙色，上面有一个红色小球；已唱过的是深蓝色，还没唱到的是灰色。
- 再下面是动作提示条：一个开心的小男孩（`happy.jpg`），写「跟着一起做！唱到 clap 就拍手，唱到 feet 就跺脚」。
- 最下面 3 个圆形按钮：「0.7x」慢速唱、大的橙色播放键、「再唱一遍」。底部页签「儿歌」是选中状态。

### M8 `play5-say-it.png`：④ 我来说
- 顶部 5 颗星，点亮 3 颗。
- 中间白色大卡片里是苹果（`apple.jpg`）。
- 下面左边一只小鸟（`bird.jpg`），右边气泡写「“apple!” 轮到你说～」，下面一行小字「说完小鸟学你说一遍」。
- 最下面 3 个按钮，之间留出间隔：橙色「先听」（喇叭）、最大的红色「按住说话」（麦克风）、绿色「听我自己」（播放）。

### M9 `play6-mini-story.png`：⑥ 小故事
- 标题「Where Is My Ball?」，副标题「小故事 · 第 2 / 5 页」。
- 一页卧室场景：床（`bed.jpg`）、小狗（`dog.jpg`）、纸箱（`box.jpg`），球（`ball.jpg`）从纸箱里露出半个，纸箱外面一圈金色光环（这是可以点的地方）。
- 下面是朗读条：橙色喇叭，后面写「Is it in the box?」，其中「box?」是橙色高亮。
- 最下面是左右翻页按钮。底部页签「读短文」是选中状态。

### S1（等用户选定玩法 ① 后再出）：找一找的 4 张场景背景
- `scene_farm.jpg`、`scene_kitchen.jpg`、`scene_park.jpg`、`scene_bedroom.jpg`。
- 1:1，2048×2048，JPG。**只画环境**（地面、墙、天空、远处的树），留出 6–8 块空地放物品。**不要画任何可点的物品，不要画动物和人**，不要文字，不要有脸的太阳和云。风格整段照抄：
  "STYLE: flat 2D children's educational flashcard illustration, cute cartoon, clean even dark-brown outlines, flat bright soft colors, almost no gradients, tiny white highlight accents, very light warm off-white paper texture background … No text, no letters, no numbers, no logo, no border, no watermark, no cast shadow."

**额度**：M1–M9 共 9 张，加上重画大约 15 张；S1 是 4 张。合计不超过 20 张，占本周剩余额度（150–200 张）的很小一部分。

---

## 5. 给 Qoder 的开发说明（按优先级；每一项都要等用户批准后才发）

通用要求：
- 仓库 https://github.com/chandr1579137-netizen/kids-english-app ，先 `git pull` main。
- **在新分支上开发，开 PR，不要直接推 main。** 用户看过 CI 的模拟器截图才合并。
- 只改 `KidsEnglish/KidsEnglish/*.swift`，改完运行 `python scripts/sync_duplicated_sources.py`。
- 尽量不要新建 .swift 文件。如果一定要新建，必须同时改 `KidsEnglish.xcodeproj/project.pbxproj` 和 `KidsEnglish/KidsEnglish.xcodeproj/project.pbxproj`。
- 发音统一用 edge-tts `en-US-AriaNeural`，放进 `Resources/audio/`，两份 `word-audio-map.json` 都要同步。

### Q1（最优先）首页显示全部单词本，分支 `feat/all-wordbooks`
1. `LearnWordsView.swift:71-82`：把写死的 `HStack` 换成
   `ScrollView(.horizontal, showsIndicators: false) { LazyHGrid(rows: [GridItem(.fixed(112)), GridItem(.fixed(112))], spacing: 10) { allWordsCard; ForEach(orderedThemes) { bookCard(...) } } }`。
   如果用户选了布局 B，就改成单行 `LazyHStack`，卡片保持 82×148。
2. 数据源用 `store.wordThemes`，和 `WordCardsView.swift:23` 一样。排序规则：先按 `DataStore.picturableThemeOrder`，排不到的放最后。**同时把 "clothing" 补进 `picturableThemeOrder`，放在 "home" 后面**（`DataStore.swift:206-209`）。排序逻辑写成纯函数，放进 `ProgressKit.swift`，例如 `enum BookOrder { static func sorted(_ ids: [String]) -> [String] }`，并在 `Tests/KidsEnglishCoreTests/ProgressKitTests.swift` 里加测试：17 本都在、没有重复、clothing 在 home 后面。
3. 卡片名称：把 `WordCardsView.swift:42` 的 `shortThemeName` 挪到 `Theme.swift`，两个页面共用。
4. 卡片颜色：在 `Theme.swift` 的 `AppTheme` 里新增 `bookColor(_ themeId: String) -> Color`，色值照第 2 节的表；原来的 4 个常量保留。
5. 卡片图标：在 `Theme.swift` 新增 `bookIconWord(for:) -> String`，按第 2 节的表返回单词（全部单词返回 "book"）。卡片里用 `WordIconView(word:size: 46)` 显示，外面套一个 52pt 的米白圆角底。**不要再用 ui-icons 里长脸的 theme-apple / theme-car。**
6. 如果用户选了 A：今日计划卡改成高 160，火箭 100pt。数字、日期、每天新词数的算法都不动。
7. 截图：让 CI 的截图步骤多截一张首页滑到最右边的图（加一个启动参数，比如 `-uiBooksScrolled`）。
- **验收标准**：
  - CI 全部通过。
  - 首页截图能看到 9 本以上，滑到底能看到全部 17 本。
  - 每本书的词数和单词卡页上显示的总数一样。
  - 选「服装」后点开始学习，出现的词在 clothes / shoes / hat 里面。
  - 杀掉 App 重新打开，选中的书还在。
  - 系统字号调到最大（App 里封顶 1.35 倍）时，卡片名字不被截断。

### Q2 玩法 ① 听音找一找，分支 `feat/find-in-scene`
- 数据：新建 `Resources/scenes.json`（两份 Resources 都要放）。结构：`[{ "id": "farm", "background": "scene_farm.jpg", "items": [{ "word": "cow", "x": 0.12, "y": 0.55, "size": 0.26 }, …] }]`，坐标是相对比例 0–1。
- 物品图：就用现有的词图。在 CI 的图标覆盖步骤之后，加一步用 `scripts/make_icons_transparent.py` 的四边泛洪方法给这些词生成透明底 PNG，输出到 `Resources/scene-items/`。
- 界面：放进 `ConsolidationGames2.swift`。`Mode` 枚举（第 435 行）在最前面加 `findInScene = "听音找一找"`，第 676 行附近的 switch 加一个分支，再加图标映射和颜色映射。画面用 `ZStack` + `GeometryReader`，按比例摆物品。
- 流程：每轮从当前场景随机出 5 题。点对了：物品放大到 1.15 倍再弹回，播放单词和表扬语，点亮一颗星；点错了：物品左右晃一下，再播一遍问题。没有倒计时。
- 音频：每个场景词生成一句"Where is the X?"，再生成"You found it!""Great job!""Well done!"三句表扬，映射写进 `custom-audio-map.json`（现在是空的，可以用这个机制）。
- 在 S1 的背景图到之前，先用纯色渐变当背景，方便提前验证代码。
- **验收标准**：CI 通过，截图里每个物品的可点区域 ≥ 64pt，5 题做完有庆祝画面；画面上不出现任何中文说明。

### Q3 玩法 ② 喂小动物，分支 `feat/feed-animal`
- 配对数据：新建 `Resources/feed-pairs.json`，例如 monkey→banana、rabbit→vegetable、cat→fish、dog→meat、mouse→cheese、bee→honey、bear→honey 等。**每个词都必须在 word-themes.json 里，而且有平涂图。**
- 界面：同样加进 `ConsolidationGames2.swift`，模式名 `feedAnimal = "喂小动物"`。食物用 `DragGesture` 拖动；松手时判断有没有落在动物的范围里（动物范围放大 30%）；放错了食物用弹簧动画回到原位。
- 音频：每种食物生成"I want a/an X!"和"Yummy X!"，再加一句"No, thank you!"。
- 每轮 5 题，3 个选项里 1 个是对的，干扰项从别的配对里抽。
- **验收标准**：CI 通过；在模拟器里录一段 10 秒的视频，或截一张拖拽过程中的图；拖错了能回到原位。

### Q4 之后再做：贴纸本、我来说、儿歌跟唱、小故事
等用户看过 M6–M9 效果图、排好顺序后，再写同样详细的开发说明。

**时间**：Qoder 免费期到 10/24 23:59（北京时间）。Q1 预计半天，Q2 和 Q3 各要 1 天左右，再加上 CI 每次 15–20 分钟。**如果用户今天就批准，Q1 + Q2 能在期限内做完，Q3 比较紧。**

---

## 6. 需要用户回答的问题
1. 首页布局选 A（两排横滑，推荐）还是 B（一排）？要等 Muse 的 M1 和 M2 出来再选。
2. 6 种玩法里先做哪两种？推荐 ① + ②。
3. 手机上装的是旧版本（491 词，10-19 到 10-20 之间编的）。要不要先装最新的 main（573 词）？装法：从 Actions 下载 IPA，用 Sideloadly 安装。
4. 数字本有 100 个词，其中大部分是 21–100，对 4 岁太多。首页要不要先只放 1–10？这要改词表，需要另外批准。
5. 儿歌现在是 TTS 朗读，不是真的唱。要不要另外找人真唱或者用别的方式生成？这超出了 Qoder 的 TTS 能力，需要用户决定。
6. Qoder 在分支上做原型、开 PR 给用户看截图（不合并进 main），算不算"改代码"？我建议允许，因为这是最准确的效果图。
7. 如果 Muse 生成的效果图里中文是乱码，能不能接受文字位置留空，或者改用 Qoder 的模拟器截图？
