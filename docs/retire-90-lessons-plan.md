# 旧「90 篇课文」下线方案（换成日常口语 L1–L7）

> 依据：main `cb5faa8`（只读核对）；新内容 `docs/daily-phrases/phrases-levels.json`（7 级 / 38 场景 / 249 句）+ `plan-levels.md`；原型 PR #11 `proto/daily-phrases`（版式 B，`bd37322`）。
> 行号都指内层 `KidsEnglish/KidsEnglish/`（Xcode 编译的这份）。外层 `KidsEnglish/*.swift` 和 `KidsEnglish/Resources/*.json` 是镜像，CI 会逐个文件 diff，**每处改动都要两份一起改**。
> 本文件只是方案，没有改动任何代码或数据。

## 0. 核心决定（一句话版）

1. **分两步下线：** 先「藏起来」，等用户决定 Q2 并且至少发一版后，再「删掉」。第一步只把「读短文」入口换成「日常口语」，旧代码和数据原样保留、不可达。
2. **孩子的东西一样不丢：**
   - `completedLessons`、`quizBest`、`collectedCards`、`favoriteWords` 这几个 UserDefaults key 和备份字段**永不改名、永不删除**。
   - 已得到的卡片继续显示在「我的收藏」里。
   - 家长中心保留一行「旧版短文（已归档）N 篇」。
3. **新进度单独存：** 用新 key `completedPhraseScenes`，旧进度不折算成新场景，因为两边内容不对应。想跳级的家长用「全部解锁」开关。
4. **Tab 位置不变：** `AppTab.read` 的 rawValue 还是 2，只改标题和图标。这样 CI 的 `-uiTab 2` 参数全部照用。

## 1. 引用清单与处理方式

### 1.1 数据与模型
| 位置 | 内容 | 处理 | 理由 |
|---|---|---|---|
| `Resources/lessons-l1…l7.json`（20/11/15/13/13/10/8 = 90 篇）、`custom-lessons.json`（空），外层镜像同名 | 课文数据 | **先藏，后删** | 第一步留着：现有测试和 21 词断言都依赖它；还要等 Q2「是否留约 8 篇 L1 小故事」的决定 |
| `Models.swift:46-67` `LessonRewards` / `LessonMeta` / `Lesson`（还有 `Paragraph` / `QuizItem`） | 课文模型 | 先藏，后删 | 数据删掉后一起删。`magicPower` 字段现在就没有用到 |
| `DataStore.swift:7,63-69` `lessons` 加载、`:308` `lessons(for:)`、`:302-306` `isUnlocked` | 加载课文、解锁 | 先藏，后删 | 新场景的解锁写成独立的纯逻辑 `PhraseUnlock`，放在 ProgressKit 里，方便单测 |
| `DataStore.swift:115` `audioURL(forLesson:)`、`audio-map.json`（305 段，13.5 MB，和单词音频不共用文件） | 课文朗读 | 先藏，后删 | 删除时包体能减约 13.5 MB |
| `DataStore.swift:144-151,180` `coverURL` / `coverIndex`、资源包 `covers/`、`lesson-illustrations/` | 课文封面 | 先藏，后删 | 只给课文用 |
| `DataStore.swift:267` `coverEmoji` | 课文兜底 emoji | 后删 | 只给课文用 |
| `DataStore.swift:16,75,186-194` `lessonDict` / `lookupWord`、`WordStemmer.swift` | 点词查词（完整多义） | **改造（migrate）** | 日常口语的句子也要点词查词，改名为 `lookupDict` 继续用 |
| `MapView.swift` `CoverImage` | 通用异步图片 | 保留 | 新场景卡片可以直接复用 |

### 1.2 进度持久化（UserDefaults）
| 位置 | key | 处理 | 理由 |
|---|---|---|---|
| `DataStore.swift:21,324,348` | `completedLessons` | **保留（只读归档）** | 不删，不再写入；家长中心显示归档数。删掉就等于丢了孩子的记录 |
| `DataStore.swift:22,313-317,325,349` | `quizBest` | 保留（只读归档） | 同上 |
| `DataStore.swift:24,327,351`；`QuizView.swift:22-26` 写入 | `collectedCards` | **保留，并接上新来源** | 已得卡片一张不丢。新卡来自场景小练习，id 加前缀 `phrase:L1-1`，避免和旧的单词卡（如 `apple`）撞名 |
| `DataStore.swift:23,326,350`；唯一的写入口是 `WordsView.swift:55-58`（从 `LessonView.swift:89` 点词弹窗进入） | `favoriteWords` | 保留，并迁移入口 | ⚠️ 课文一下线，收藏就**没有入口**了。新场景卡片的点词也要弹出 `WordDetailView` |
| 新增 | `completedPhraseScenes`、`phrasesUnlockAll` | 新增 | 新进度；家长的「全部解锁」开关 |
| `DataStore.swift:460-475` `resetAllProgress` | — | 改造 | 也要清空 `completedPhraseScenes`。旧归档 key 照旧一起清，家长主动清除时行为不变 |
| `ProgressKit.swift:9-27` `ProgressSnapshot` | 备份 JSON | 改造 | 加 `var completedPhraseScenes: [String]? = nil`，写法和 `childName` 一样，旧备份照样能导入。`completedLessons` 和 `collectedCards` 字段**不许改名**；`version` 保持 1 |
| `DataStore.swift:487-525` 导出 / 导入 | — | 改造 | 导出和导入都带上新字段；导入老备份时新字段为 nil，不要覆盖成空 |
| `ProgressKit.swift:50` `summary` | "已恢复：N 篇课文、M 个单词" | 改造 | 改成「已恢复：N 个场景、M 个单词（旧短文 K 篇）」 |
| `AudioPlayer.swift:163-168` 跟读录音 | 存在 tmp 目录，key 形如 `lessonId#paraId` | 照旧沿用 | 本来就是临时文件，没有迁移问题；新 key 用 `L1-1#3` |

### 1.3 界面、入口与文案
| 位置 | 现在 | 处理 | 理由 |
|---|---|---|---|
| `KidsEnglishApp.swift:32,40,50,60` `AppTab.read`「读短文」/ `doc.text` | Tab 3 | **改造** | rawValue 保持 2；标题改「日常口语」，图标改 `bubble.left.and.bubble.right` |
| `KidsEnglishApp.swift:189-190` `ReadView()` | Tab 内容 | 改造 | 换成 `PhrasesView()`（级别按钮和锁复用 ReadView 的写法，卡片用 PR #11 的版式 B） |
| `ReadView.swift`（全文）、`LessonView.swift`、`QuizView.swift` | 课文列表、正文、练习 | **先藏，后删** | 第一步不可达但仍参与编译；最后一步删文件和 pbxproj 引用（`project.pbxproj:65,66,90,94-100`） |
| `KidsEnglishApp.swift:101-102` `-uiLesson`、`:115` `-uiAlert` | 截图参数 | 迁移 | `-uiLesson` 换成 `-uiPhraseScene <id>`；`-uiAlert unknown/mic` 改到新场景页上（新页也有点词和录音） |
| `ParentView.swift:126` `已完成课程 N / lessons.count`（显示 x/90） | 家长中心 | **改造** | 改成「日常口语 x / 38 个场景」，按数据算，不写死。下面加一行「旧版短文（已归档）N 篇」，只有 N>0 才显示 |
| `ParentView.swift:129` 收集卡片 N 张 | — | 保留 | 计数包含新卡和旧卡 |
| `ParentView.swift:199` 开关「课文默认显示中文翻译」 | key `showTranslation` | 改文案 | 改成「句子默认显示中文」，key 不变 |
| `ParentView.swift:258` 清除确认「已读课文…」 | — | 改文案 | 改成「已学场景…」 |
| 家长中心新增 | — | 新增 | 「全部解锁」开关 |
| `ProfileView.swift:107` 指标「已读短文」= `completedLessons.count` | 我的 | 改造 | 改成「已学场景」= 新进度数 |
| `ProfileView.swift:372` 空收藏提示「在课文里点一个单词…」 | — | 改文案 | 改成「在日常口语里点一个单词…」 |
| `ProfileView.swift:318` 版权说明「课文与音频来自 magic-english-buddy（CC BY-NC-SA 4.0）」 | — | 先保留，后改 | 只要还带着课文数据或音频，这条就必须留；最后一步删数据时再改 |
| `ProfileView.swift:356-420` 收集到的卡片 | 显示文本 | 改造 | `phrase:` 前缀的卡显示场景英文标题；旧卡原样显示 |
| `Theme.swift:31,206,457,640,764` | 只是注释 | 保留 | 不影响功能 |

### 1.4 测试
| 位置 | 内容 | 处理 |
|---|---|---|
| `ModelDecodingTests.swift:64-83` `testLessonsDecode`（`:74` `lessons.count == 90`） | 写死 90 | 第一步不动（数据还在）；最后一步删除 |
| `ModelDecodingTests.swift:86-121` `testQuizItemsDecodeByType`、`:126-133` `testAudioMapKeys` | 课文题、课文音频 | 最后一步删除 |
| `StarterBookRemovalTests.swift:37-44,64-79` `testStillInDictionaryAndLessons`（15 个词「仍在课文里」） | 依赖课文原文 | 第一步不动；删数据时只保留「词典里还有这 21 个词」那一半，课文那一半删掉（这需要用户点头，因为它会让「这 21 个词保留在课文里」的承诺落空） |
| `ProgressKitTests.swift:27,49,111-117` | 快照和 summary 文案 | 改：summary 期望值换成新文案 |
| `ProgressKitTests.swift:194,205` | ResetPlan 的 key 列表 | 加上 `completedPhraseScenes`，断言它不会被按天前缀误删 |
| `ProfileFieldTests.swift:11,34` | 旧版备份 JSON | **原样保留**，作为「老备份能导入」的回归样本 |
| 新增 `PhrasesLevelsTests` | — | 7 级、38 场景、249 句；每句不超过本级词数上限；不含数字；句子不重复；场景 id 唯一；每个说话人都有配音；两份 Resources 一致 |
| 新增 `PhraseUnlockTests` | — | 级内按顺序解锁；整级完成才开下一级；`unlockAll` 开关 |
| 新增 `LegacyProgressMigrationTests` | — | 老备份（无新字段）导入后 `completedLessons` 和 `collectedCards` 原样保留；新旧来回导出导入不丢；新卡和旧卡不撞名；reset 会清掉新 key |

### 1.5 CI、脚本与文档
| 位置 | 内容 | 处理 |
|---|---|---|
| `build.yml:269` `03-read -uiTab 2` | 列表截图 | 保留名称，画面变成 L1 场景列表 |
| `build.yml:278` `08-lesson`、`:320` `26-large-lesson`、`:339-340` `40/41-large-alert-*`、`:432` `ipad-08-lesson` | 课文页截图 | 换成 `-uiPhraseScene`（文件名改为 `08-phrase-card` 等） |
| `build.yml:73-80` 资源包 v3 里打印 illustrations / covers 的数量 | — | 最后一步删除这两行打印 |
| `build.yml:170-190` Prune 读取 `audio-map.json` | 留住课文音频 | ⚠️ 删掉 audio-map 后这个脚本会报错；要先改成读 `phrase-audio-map.json`（同时加上 `audio-slow`） |
| `scripts/validate_resources.py:32-50,73,93` `check_lessons(expected_min=1)` | — | 先加上 `check_phrases`；最后一步去掉 lessons 检查，否则文件删掉 CI 就失败 |
| `scripts/audit_lessons.py`、`flag_overage_lessons.py`、`docs/lesson-audit.md` | 历史工具 | 最后一步移到 `docs/archive/`，或者直接删 |
| `README.md:13,18,73,75,87,97,105` | 「90 篇课文 / 305 段朗读」 | 第二步（PR-C）改 |
| 小游戏、单词卡、儿歌 | 不读课文数据 | 不受影响 |

## 2. 数据迁移（孩子的东西不丢）

| 旧数据 | 升级后 | 显示在哪里 |
|---|---|---|
| `completedLessons`（如 12 篇） | 原 key 原样保留，只读，不再写入 | 家长中心「旧版短文（已归档）12 篇」；导出备份里照样带着 |
| `quizBest` | 原样保留 | 不显示，只在备份里 |
| `collectedCards`（旧课文奖励，90 课共 200 种单词卡） | 原样保留，新卡继续往里加 | 「我的收藏 → 收集到的卡片」、家长中心计数 |
| `favoriteWords` | 原样保留 | 「我的收藏」；新的点词入口能继续加 |
| 老版本导出的备份 | 能导入（新字段为 nil） | — |
| 新版本导出的备份导入到旧版 App | 旧版会忽略不认识的字段，不报错 | — |

- 旧进度**不折算**成新场景。
- 首次升级**不做**任何写操作或清理，所以没有迁移代码可能出错。

## 3. PR 顺序（每一步都立即 commit 和 push；PR 都不自动合并，交给产品经理验收）

| # | 分支 | 内容 | 用户可见 |
|---|---|---|---|
| 0 | `docs/retire-90-lessons` | 本方案（只存档，不开 PR） | 无 |
| A | `feat/phrases-data` | 两份 `phrases-levels.json`、`PhraseLevel/Scene/Line` 模型、`PhrasesLevelsTests`、`validate_resources` 加 phrases 检查 | 无 |
| B | `feat/phrases-progress` | `completedPhraseScenes`、`phrasesUnlockAll`、`PhraseUnlock`、快照新字段、reset、summary、迁移测试；家长中心和「我的」的计数改造（含归档行）；截图参数 `-uiSeedLegacy`（注入 12 篇旧课、30 张卡、5 个收藏） | 家长中心和「我的」的文案 |
| C | `feat/daily-phrases` | `PhrasesView`（版式 B）接到 Tab 2；点词查词和收藏；录音；场景小练习发卡；SwiftUI 画的钟面和日历；读短文入口下线（代码保留、不可达）；CI 截图替换；README | **切换点** |
| D | 同 C 或后续 | 498 个 mp3（正常速度和 0.8 倍）加 Whisper 核对；L1 的 21 张图；其余用占位图，等 10/28 之后 Muse 补 | 内容 |
| E | `chore/remove-lessons` | 等 Q2 定下来、并且 C 已经发过一版以后：删课文 JSON、模型、ReadView/LessonView/QuizView、audio-map 和 305 个 mp3、封面；改 prune、validate、测试、版权文案。**备份字段和 UserDefaults key 仍然保留** | 包体减约 13.5 MB |

## 4. 用哪些截图证明（CI 模拟器）

| 截图 | 证明什么 |
|---|---|
| `03-read`（-uiTab 2） | Tab 叫「日常口语」，显示 L1 场景列表，后面的场景带锁 |
| `03b-phrases-L2-locked` / `03c-unlock-all` | 级与级之间上锁；家长打开「全部解锁」后都能点 |
| `08-phrase-card`、`08b-phrase-clock` | 版式 B 卡片；钟面没有数字 |
| `26-large-phrase-card`、`40/41-large-alert-*` | 大字号；点词和麦克风提示照常 |
| `23-parent-dash -uiSeedLegacy` | 显示「日常口语 x / 38」+「旧版短文（已归档）12 篇」+「收集卡片 30 张」 |
| `19-favorites -uiSeedLegacy` | 旧卡片和收藏都还在 |
| `05-profile -uiSeedLegacy` | 「已学场景」计数 |
| `ipad-08-phrase-card` | iPad 布局 |

## 5. 风险

| 风险 | 对策 |
|---|---|
| 两份源码和资源漂移 | 每处都改两份；CI 已有 diff 守卫 |
| `try?` 解码失败会静默变成空数组 | validate 脚本和 `PhrasesLevelsTests` 硬断言数量 |
| 快照字段改名导致老备份导入失败 | 新字段一律写成可选；`ProfileFieldTests` 的旧 JSON 当回归样本 |
| 删掉 audio-map 后 prune 脚本报错 | E 之前先改脚本 |
| 收藏和卡片失去来源 | C 必须同时带上点词收藏和场景小练习 |
| Tab 序号变化导致截图错位 | rawValue 不动 |
| 21 词「仍在课文里」的承诺在 E 落空 | E 之前请用户确认 |
| 家长以为进度丢了 | 显示归档行；升级时不写也不清任何数据 |
| 图片只有 L1 的 21 张，其余是占位图 | 先只开放 L1（或 L1–L2），其余等 Muse |
| 手改 pbxproj 出错 | C 和 E 都要让 CI 跑通 Release 构建 |

## 6. 待产品经理（或用户）决定

1. **Q2：** 旧 90 篇全部下线，还是留约 8 篇 L1 小故事做「小故事」栏？这决定 E 删多少。
2. 家长中心要不要显示「旧版短文（已归档）N 篇」？还是只放进导出备份、不显示？
3. 新卡片 id 用 `phrase:<场景id>`、显示场景英文标题，可以吗？还是新卡也用单词卡的形式？
4. C 上线时只开放 L1（图齐），还是 L1–L7 都开放、没图的先用占位图？
5. E（物理删除）是在 C 发版之后的第几版做？还是 C 验收之后马上做？
