# 英语启蒙 App（KidsEnglish）项目现状核查 + 竞品调研 + 优先级计划

写于 2026-10-22 02:45 前后（北京时间）。结论里每一项代码事实都对照过仓库文件；核对方法写在括号里。
配图都在 `/workspace/kea-pm/visuals/`。

---

## 0. 一句话结论

- **以 GitHub `main` 为准**：https://github.com/chandr1579137-netizen/kids-english-app ，HEAD `990fb86`，提交于 2026-10-21 21:38（北京时间）。最近 8 次 Actions 构建全部成功，包括 990fb86 这次（run 39609833630）。
- **最大的问题**：`main` 现在是"能识字的 5–6 岁孩子背单词"的形态（背单词、选词书、读短文、听写、看词选义），**没有 4 岁孩子用的"不识字也能玩"的入口**，也**没有字母音（phonics）**。PR #3 做过"4 岁路线"（今天听 3 个词 + 只玩听音选图 + 家长门），但这个分支停在 10 月 15 日，没合进 main。
- **图片**：main 正在把词图统一成"平涂 2D、深棕描边、米白纸纹底"。还有 **203 张没换**：Muse 已出的 187 张（地方/动作/形容词，正在重画其中不清楚的）+ 自然主题 16 张。另外**有 12 张图给东西画了脸**，违反规则。
- **声音**：有 4 个主题词**点了没声音**（shoes、clothes、hat、fire），main 也没有系统朗读兜底。

---

## 1. 代码在哪、哪份最新（附证据）

| 位置 | 状态 | 证据 |
|---|---|---|
| **GitHub main（以此为准）** | 最新。HEAD `990fb86`，2026-10-21 21:38（北京时间） | `list_commits` 和 `git fetch` 结果一致；我克隆到了 `/workspace/kea-pm/repo` |
| PR #3 分支 `cursor/home-books-review-f047` | 过时。从 `a8bb752`（10-14）分出去，只有 7 个提交，最后一个是 `7532f2a`（10-15 10:15）。main 从同一个分叉点往后已经走了 **85 个提交** | `git rev-list --count a8bb752..main` = 85，`a8bb752..pr3` = 7；检出在 `/workspace/kea-pm/pr3` |
| `/workspace/kea-audit` | 旧克隆，停在 `a8bb752`（10-14 19:43） | `git log` |
| `/workspace/kea-bundle` | 没有 git 的导出副本，更旧 | 没有 .git |
| 用户 Mac 上的 `~/kids-english-app-build` | 没碰（按要求）。总控说那里编译过 PR #3，但我无法核实它现在在哪个提交 | — |

**两次交接说法不一致，以 GitHub 为准**：第一次说"PR #3 最新、在 Mac 上编译"，第二次说"main 最新、用 Actions 编译"。GitHub 上的数据支持第二次的说法。但要注意：**PR #3 里有 main 没有的东西**，就是 4 岁路线（`age4-path.json`、今天/图画/儿歌/家长四个页签、每天 3 个新词、家长门把其他内容锁起来），代码在提交 `42b70b1`。后面计划里会把这套思路搬到 main 上，而不是直接合并 PR #3，因为两边的图和音频改动冲突太多。

### 怎么编译
- `.github/workflows/build.yml`（存在，已核对）：推到 main 后自动执行 → 检查两份源码是否一致 → 检查资源 JSON → 跑 SwiftPM 单元测试（`Tests/KidsEnglishCoreTests` 下有 6 个测试文件）→ 下载资源包 `assets-v3/assets-bundle-v3.zip`（85.7 MB，从 GitHub Release 下载）→ 用 `assets/word-icons-overrides/` 里的平涂图覆盖 → 合并数字发音 → 删掉没用到的音频 → 编译未签名 IPA → 在 iPhone/iPad 模拟器上截图。
- 平台：iOS 17+，iPhone + iPad（`TARGETED_DEVICE_FAMILY = "1,2"`），只支持竖屏，版本 2.3 (4)。
- 装到手机：从 Actions 下载 IPA，再用 Sideloadly 装（README 里有步骤）。
- 备用：用户的 MacBook Air 装的是 Xcode 15.4，而 CI 用的是 `macos-15` 镜像。**main 能不能在 Xcode 15.4 上编译，没验证过**。`/workspace/xcode154-fixes.patch` 是针对旧代码树写的，打到 PR #3 上已经打不上了。
- 改代码的规矩：两份 Swift 源码（`KidsEnglish/*.swift` 和 `KidsEnglish/KidsEnglish/*.swift`）必须一致，改完运行 `python scripts/sync_duplicated_sources.py`。

---

## 2. 功能和内容盘点（main，已逐项核对）

**页签**：背单词 / 单词卡 / 读短文 / 儿歌 / 我的（`KidsEnglishApp.swift` 里的 `AppTab`）。

| 项 | 实际数量 | 怎么核对的 |
|---|---|---|
| 可学的主题词 | 16 个主题，**573 个词**（数字 100 个、动作 83 个、形容词 81 个、动物 59 个……服装只有 3 个） | 统计 `word-themes.json` |
| 词典 | 1347 条（`words-a..d.json`），只有主题里的词能学（`ThemeWhitelist`） | `DataStore.swift:83` |
| `kid-whitelist.json`（180 词） | **代码里没用到**，是死文件 | 在 Swift 里搜不到引用 |
| 课文 | 90 篇（L1–L7 分别是 20/11/15/13/13/10/8），需要识字，超出 4 岁水平 | `lessons-l*.json` |
| 儿歌 | 10 首，都有 mp3 | `songs.json`、`song-audio/` |
| 巩固游戏 | 9 种，其中看词选图、看词选音、看图选词、看词选义、听写这 5 种**需要识字** | `ConsolidationGames2.swift:435` |
| 复习算法 | 有间隔复习：间隔 1 天 → 3 天 → 乘以熟练系数，最长 60 天 | `DataStore.swift:477-486` |
| 每天新学几个词 | 默认 **10 个**（对 4 岁太多） | `DataStore.swift:22` |
| 家长 | 数学题门，每天限时默认 20 分钟，可导出进度 | `ParentView`、`DataStore.swift:35` |
| 单词发音 | 仓库里的映射有 1610 条，CI 再补 78 条数字发音；音色统一用 en-US-AriaNeural | `word-audio-map.json` 加上 `assets/number-audio/` |
| **点了没声音** | `shoes`、`clothes`、`hat`、`fire`：两份映射里都没有，main 的 `AudioPlayer` 也没有系统朗读兜底（PR #3 有） | 脚本核对 + `AudioPlayer.swift` |
| 词图 | 按 CI 的方式拼出最终图集，573 个词全部有图 | `/workspace/kea-pm/effective/`（1339 张） |

### 词图风格现状（见 `visuals/main-sheet-*.jpg`）
- 已经是平涂的（370 张在 overrides 里）：水果、动物、颜色、身体、食物、家人、家居、服装、文具、玩具、自然里的 18 个。
- **交通 22 张是"半写实矢量"**（提交 `b379a44`），和平涂风格不统一。
- **还是旧 3D 的**：自然 16 张（forest、island、beach、air、cave、hill、plant、shell、valley、water、wave、sand、mud、ice、thunder、puddle）+ 地方 25 + 动作 82 + 形容词 80。
- **数字 1–100 是纯数字卡**（白底黑字的"3"），和平涂风格不一样，而且和 STYLE 里"图里不出现数字"冲突（见 `visuals/decision3-numbers.jpg`）。
- **东西长了脸（违反规则）**：平涂版的 sun、moon、sky；旧 3D 版的 air、water、wave、sand、mud、ice、thunder、puddle、shell。其中 3D 这 9 张换成平涂后就解决了，因为 `remaining-prompts.json` 里的提示词已经写了"No face"。平涂那 3 张需要重画。

### Muse 的 187 张（`/workspace/flashcards/out/`）
- 和 `docs/word-icon-prompts/muse-remaining-187.md` 里的文件名**一一对应**：187 对 187，没有多也没有少。风格描述也逐字一致。
- 输出是 1024×1024 JPG（约 158 KB）。仓库 overrides 的规格是 **512×512、每张约 40 KB**，入库前要缩小。
- 第 1 轮把 32 张不清楚的重画了（`redo_report.md`），第 2 轮又重画 7 张（`prompts_redo2.json`）。02:35 时日志还在写，说明还在跑。`sheets/` 里的拼图是重画之前的，入库前要重新拼一版给用户看。
- **还没提交到仓库。**

### 和 4 岁孩子的需求比，缺什么
1. 没有"不识字也能玩"的孩子首页。现在首页是"Day 1 / 新学 10 个词 / 选词书"（`visuals/decision1-kid-home.jpg`）。
2. 没有字母音 / phonics 模块（代码里搜不到 phonics/alphabet 相关内容）。
3. 4 岁最先学的口语词不在主题里：mom、dad、hello、hi、bye、yes、no、grandma、grandpa、sock、dress、shirt（主题里只有 mother/father/grandmother 这类写法）。PR #3 的 4 岁路线里有这些词。
4. 词量太大：数字到 100，动作和形容词有 160 多个，很多是抽象词（clever、interesting、peaceful……）。

---

## 3. 竞品调研：对 4 岁孩子验证过的做法

| 做法 | 证据 | 我们怎么用 |
|---|---|---|
| **每次 5 分钟左右，每天 10–20 分钟** | Duolingo ABC：每课 5 分钟以内 [1]。Khan Kids 的随机对照研究：4–5 岁孩子平均每天 13 分钟，用 10 周，读写启蒙能力从第 34 百分位升到第 47 [2][3]。叽里呱啦、斑马、小猴每节 10–15 分钟 [7][8] | 一节"今天"控制在 5–8 分钟，每天限时默认 15–20 分钟 |
| **总屏幕时间：3–4 岁每天不超过 1 小时** | WHO [4] | 保留每日限时；时间到了温和结束，家长可以加时 |
| **字母音按 s a t i p n 的顺序教，教音不教名，b 和 d 分开** | Jolly Phonics 的 7 组 42 个音 [5][6]。Duolingo ABC 也用合成拼读，从最常见、最规则的音开始 [1][9] | 字母音模块的第 1 组就用 s a t i p n，每个音配一个动作和一张图 |
| **不要求识字：靠声音和大图，点一下就能操作** | Gus on the Go 不需要阅读，只靠图和母语者发音，大约 90 个基础词 [10]。Duolingo ABC 大量用语音旁白 [11] | 孩子页面只用图、喇叭、星星，不放中文说明 |
| **线性路径 + 每做完一步就庆祝** | Duolingo ABC 把课排成一条路，做完解锁下一课，中间穿插庆祝动画 [9]。ABCmouse 发"票"，同一个活动最多奖励 5 次，鼓励孩子去学新的 [12] | "今天"做完给一张贴纸；同一个词复习满 5 次后不再发奖励 |
| **间隔复习对学龄前有效** | 学龄前儿童用逐渐拉长间隔的方式复习，回忆量大约翻倍 [13]。4–5 岁研究：逐渐拉长和等间隔最终效果差不多，关键是要有复习 [14] | 已有的 1/3/N 天复习保留；4 岁模式每天复习 3–6 个 |
| **家长门 + 限时 + 能看进度** | Lingokids：家长门、每个孩子单独限时、时间到了可以"再玩一会" [15][16] | 已经有了，只要做进 4 岁模式 |
| **听、跟唱、开口** | 小猴：磨耳朵 → 跟读 → 游戏；叽里呱啦：儿歌热身 → 学 → 复习 → 测；斑马：video → words → story → speaking → quiz [7][8] | "今天"的流程：听儿歌片段 → 认 3 个新词 → 听音选图 → 复习 |

来源：
[1] https://abc.duolingo.com/how-we-teach
[2] https://khankids.zendesk.com/hc/en-us/articles/360042832631
[3] https://www.tandfonline.com/doi/full/10.1080/17482798.2020.1863239
[4] https://www.who.int/news/item/24-04-2019-to-grow-up-healthy-children-need-to-sit-less-and-play-more
[5] https://jollylearning.com/en-us/our-programs/jolly-phonics
[6] https://jolly2.s3.amazonaws.com/Catalogues%20and%20Guide/Parent%20Teacher%20Guide.pdf
[7] https://www.dashizg.com/jijin/2021030914257.html
[8] https://tech.ifeng.com/c/82SWeGAQftu
[9] https://duolingo-papers.s3.amazonaws.com/reports/Duolingo_whitepaper_duolingo_method_2023.pdf
[10] https://screenwiseapp.com/guides/gus-on-the-go-app
[11] https://blog.duolingo.com/a-good-read-building-duolingo-abc-for-android/
[12] https://support.abcmouse.com/hc/en-us/articles/360048194473
[13] https://doi.org/10.1080/17470210600823595
[14] https://pmc.ncbi.nlm.nih.gov/articles/PMC11087082/
[15] https://help.lingokids.com/hc/en-us/articles/360017671017
[16] https://lingokids.com/blog/posts/this-parental-control-makes-screen-time-even-safer

---

## 4. 优先级计划

### 第 0 步：先让用户确认（不确认，Qoder 不动代码）
给用户看 4 张图，每题选一个：
1. `visuals/decision1-kid-home.jpg`：孩子首页用 A（今天听 3 个、大图大按钮）还是 B（保持现在）。**推荐 A。**
2. `visuals/decision2-faces.jpg`：sun、moon、sky、air 这些长了脸的图要不要重画。**推荐重画。**
3. `visuals/decision3-numbers.jpg`：数字词的图用 A（数字卡）还是 B（数东西，比如 3 个苹果）。4 岁模式里数字只学 1–10。**推荐 B**，因为 STYLE 规定图里不能出现数字。
4. `visuals/decision4-phonics.jpg`：要不要加字母音模块（s a t i p n）。**推荐加，放在 P1。**

另外还要用户点头两件事：
- Muse 重画完以后，重新拼 187 张的总览图，用户看过再入库。
- Qoder 的免费额度到 10/24 23:59（北京时间），P0 要在这之前做完。

### P0（10/22–10/24 完成）

**P0-1 修好"点了没声音"的 4 个词 + 加系统朗读兜底**（Qoder）
- 为什么：孩子点了没反应，会以为 App 坏了。
- 做法：用 edge-tts 的 `en-US-AriaNeural` 生成 shoes、clothes、hat、fire 四个 mp3，放进 `KidsEnglish/KidsEnglish/Resources/audio/`，在 `word-audio-map.json` 里加上映射（两份 Resources 都要改）。`AudioPlayer.play` 在 URL 为空时改用 `AVSpeechSynthesizer` 读 en-US（PR #3 的 `AudioPlayer.swift` 可以参考）。`scripts/validate_resources.py` 加一条检查：每个主题词都必须有映射，而且对应的文件存在。
- 验收：CI 通过；校验脚本列出的"缺音频"为 0。

**P0-2 Muse 的 187 张 + 自然 16 张入库**（Muse 出图 → Qoder 入库）
- 做法：Muse 按 `docs/word-icon-prompts/remaining-prompts.json` 里 theme=nature 的 16 条出图，再重画 sun、moon、sky（共 19 张）。用户确认总览图后，Qoder 把图缩成 512×512、JPEG 质量 85，放进 `assets/word-icons-overrides/<word>.jpg`（词里有空格的用下划线），更新 `docs/word-icon-prompts/`。
- 验收：CI 通过；模拟器截图里地方、动作、形容词、自然四个主题都是平涂风格；不再有长脸的东西。

**P0-3 4 岁"宝宝模式"首页**（Qoder；必须先等决策 1 通过）
- 做法：参照 PR #3 的提交 `42b70b1`（`age4-path.json`、`age4Today`、`age4Review`），在 main 上重新实现，不直接合并。孩子看到四个页签：今天 / 图画 / 儿歌 / 家长。每天 3 个新词（家长可以调到 3–8），只玩听音选图，复习沿用现有的间隔算法。词表用 PR #3 的 11 个词包（78 个词，其中 63 个默认解锁），缺的 12 个词补进主题和音频。
- 验收：模拟器截图里孩子页面没有长句中文说明，只有图和喇叭；一节做完 5–8 分钟；其他内容要过家长门才能看到。

### P1
- **字母音模块**：s a t i p n → c k e h r m d → g o u l f b。注意：TTS 很难读准单独的音，Qoder 先出一组样音给用户听，不行就请家长自己录。
- 4 岁口语词补图：hello、hi、bye、yes、no、sock、dress、shirt（8 张新图；mom/dad/grandma/grandpa 可以复用现有的图）。
- 数字 1–10 改成"数东西"的图（10 张，如果决策 3 选 B）。
- 贴纸奖励：做完"今天"给一张；同一个词最多奖励 5 次。

### P2
- ~~交通 22 张改成平涂。~~ 作废：用户定了交通工具保持半写实 3D 风格（decisions.md D10）。
- 删掉没用的 `kid-whitelist.json`。
- 在 Mac 的 Xcode 15.4 上验证 main 能否编译。
- 课文和听写这类需要识字的内容，留到 5–6 岁再开。

### Muse 额度
本周剩大约 150–200 张，10/28 重置。P0 需要 19 张，P1 需要 18 张，额度够。

---

## 5. 可以直接发出去的派活指令（等第 0 步确认后再发）

### 发给 Qoder工程师
> 仓库：https://github.com/chandr1579137-netizen/kids-english-app ，分支 main（HEAD 990fb86）。先 `git pull`。
> 任务 P0-1：
> 1. 用 edge-tts `en-US-AriaNeural` 生成 shoes、clothes、hat、fire 四个单词的 mp3，放进 `KidsEnglish/KidsEnglish/Resources/audio/` 和 `KidsEnglish/Resources/audio/`，在两份 `word-audio-map.json` 里加映射。
> 2. `KidsEnglish/KidsEnglish/AudioPlayer.swift`：单词没有音频时，用 `AVSpeechSynthesizer`（en-US）把单词读出来。可以参考 PR #3 分支 `cursor/home-books-review-f047` 里的 `AudioPlayer.swift`。
> 3. `scripts/validate_resources.py`：加检查，每个主题词都要有音频映射，而且文件存在。
> 4. 运行 `python scripts/sync_duplicated_sources.py`，推到 main，等 Actions 变绿，把截图链接发回来。
> 不要动图片、不要改其他功能。

### 发给 Muse
> 1. 自然主题 16 张：按 `docs/word-icon-prompts/remaining-prompts.json` 里 theme=nature 的提示词原样出图。
> 2. 重画 3 张：sun、moon、sky，**不要画脸**。风格整段照抄：
> "STYLE: flat 2D children's educational flashcard illustration, cute cartoon, clean even dark-brown outlines, flat bright soft colors, almost no gradients, tiny white highlight accents, very light warm off-white paper texture background, the scene centered at about 75% of the square frame with generous empty margins. No text, no letters, no numbers, no logo, no border, no watermark, no cast shadow."
> 3. 格式：每张写清 文件名 / 画什么 / 意思 / 尺寸（1:1，1024×1024 JPG），文件名小写、空格换成下划线。
> 4. 重画完 187 张里的那批后，重新拼一版总览图交回来，用户看过才入库。

---

## 6. 没查到 / 被卡住的

- **没读到其他 Bot 的聊天记录**：当前没有 ReadTranscript 工具，各 Bot 的存储目录我也打不开。历史全部根据 git 记录、文件和你转来的话判断。
- Mac 上那份代码在哪个提交、是否有没提交的改动：没碰 Mac，不知道。
- main 能不能用 Xcode 15.4 编译：没验证。
- 真机上的音频和录音：README 里自己写了"尚未真机验证"。
- Muse 的重画任务还在跑，没碰它。
