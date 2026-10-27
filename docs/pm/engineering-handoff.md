# 工程交接说明（工程师 → Antigravity）

仓库：https://github.com/chandr1579137-netizen/kids-english-app
SwiftUI，iOS 17，`@Observable DataStore`，家庭自用，不上架（D7）。只按 iPhone 设计和验收（D5）。

## 0. 当前状态（2026-10-25）

| 项 | 状态 |
|---|---|
| main 最新 | e9943f6（合并了 PR #24：「说一说」L2 + 每 3 课一次复习课） |
| PR #23 多孩子档案 | 已合并，63e1100 |
| PR #24 L2 + 复习课 | 已合并，e9943f6 |
| **PR #25（Draft）** L3–L7 的 52 张代码卡 | **未完成**：分支 `feat/phrase-code-cards`，554e88f。CI 还没有一次通过：前两轮是编译错误，已修；第 3 轮 run 40155822783 交接时还在跑，结果没看。截图一张都没看过。详情见 PR 正文 |
| PR #17 docs/pm-decisions | 产品经理的决定文档历史版本。**最新内容已复制到 main 的 docs/pm/**，以 main 为准 |
| 下一项（产品经理排的） | PR #25 做完 → v2「每天一课」（docs/pm/daily-lesson-v2.md）。届时把例句改掉：fly →「Birds can fly.」，teeth →「Show me your teeth.」 |

## 1. 本地怎么跑

### Windows 路径太长
仓库放在 Claude 会话目录下，路径超过 260 个字符，Python 和 git 都会出错。用 subst 映射成短盘符：

```
subst K: "<会话目录>"        # 仓库在 K:\kids-english-app
```

- 脚本里**不要用 `Path.resolve()`**，它会还原成长路径。`gen_phrases.py` 用的是 `absolute()`。
- 在 worktree 里 `git push` / `git status` 会报 `'$GIT_DIR' too big`。要从主仓库目录推送；在 worktree 里只做 commit、merge。

### 本机没有 Xcode
编译、单测、截图**全在 GitHub Actions 上跑**（macos-15）。
- workflow 只在 push main 或手动触发时运行。分支上要手动触发：`gh workflow run build.yml --ref <分支>`。
- 截图在 artifact `KidsEnglish-screenshots/shots/` 里，下载命令：`gh run download <run id>`。

### 两份 Swift 源码必须一致
- `KidsEnglish/KidsEnglish/*.swift` 是 Xcode 实际编译的，**只改这一份**，然后运行 `python scripts/sync_duplicated_sources.py`，把它同步到外层镜像 `KidsEnglish/*.swift`。CI 第一步会检查两份是否一致。
- 资源 JSON 也有两份：`KidsEnglish/KidsEnglish/Resources/...` 和 `KidsEnglish/Resources/...`。CI 会检查是否一致；phrases 的两份由生成脚本同时写出。
- 有两个 Xcode 工程：`KidsEnglish/KidsEnglish.xcodeproj`（CI 用这个）和根目录的 `KidsEnglish.xcodeproj`。**新加 .swift 文件，两个 pbxproj 都要手工加 4 处**：PBXBuildFile、PBXFileReference、Sources build phase、group children。ID 用 `E1A5E00000000000000000xx` 系列，目前用到 36。

### 单测
`swift test --package-path .`（只能在 CI 的 Mac 上跑）。
- `Package.swift` 的 `KidsEnglishCore` 只编译纯 Foundation 的文件：Models、WordStemmer、ProgressKit、StudyPlan、Phrases、BabyPath、Profiles。**新的逻辑放进这些文件**才能测；视图文件不进测试包。
- 测试在 `Tests/KidsEnglishCoreTests/`。很多测试直接读仓库里的资源 JSON，所以改了数据，测试会跟着检查。
- **坑**：Swift 编译器对长表达式会类型推断超时（第 2 轮 CI 就是这样失败的）。几个可选数组用 `+` 连在一起、复杂的 SwiftUI 链，都要拆开写。

## 2. CI 截图参数

带 `-ui` 开头的参数就算截图模式（`LaunchOptions.isUIScreenshotRun`）：动画停在最后一帧，不放声音，不写进度。截图命令格式是 `shoot <文件名> <参数…>`，见 `.github/workflows/build.yml`。

| 参数 | 作用 |
|---|---|
| `-uiTab N` | 打开第 N 个页签。正常模式：0 背单词、1 单词卡、2 说一说、3 儿歌、4 我的 |
| `-uiBaby` | 进启蒙模式（宝宝模式），**截图默认是正常模式** |
| `-uiBabyTab N` / `-uiBabyStep N` / `-uiBabyDemo x` | 启蒙模式的页签 / 今天第几步 / 演示状态（recording、praised、correct、wrong…） |
| `-uiBabyKnown N` / `-uiBabyPack id` / `-uiBabyStickers N` | 假装已学 N 个词 / 打开某个词包 / 假装有 N 张贴纸 |
| `-uiPhraseScene id` `-uiPhraseStep N` | 「说一说」打开某一课（如 L1-1、L1-R1 复习课、L2-3）的第 N 步 |
| `-uiPhraseDemo x` | 卡片状态：recording、praised、answer |
| `-uiPhraseCompleted a,b` | 假装这些课已完成（列表页看解锁和高亮） |
| `-uiPhraseChinese` | 卡片下显示中文 |
| `-uiCodePreview N` | L3–L7 代码卡预览第 N 页（0–8，每页 6 张），在 PR #25 里 |
| `-uiProfiles N` / `-uiWho` / `-uiChildEdit add` | 假装有 N 个孩子 / 直接显示「谁来学？」/ 打开添加孩子页 |
| `-uiImportConfirm` / `-uiDeleteConfirm` | 家长中心直接弹出导入确认框 / 删除确认框 |
| `-uiProfile x` | 「我的」页的子页 |
| `-uiLargeText` | 大字号 |
| `-uiGuide` | 第一次打开时的引导 |
| `-uiAlert x` / `-uiTheme id` | 演示弹窗 / 主题 |
| `-uiStudy` `-uiStudyWord w` `-uiBook id` `-uiBooksScrolled` `-uiConsolidate` `-uiGame N` | 背单词流程、巩固游戏 |
| `-uiScene` `-uiSceneFound` `-uiSceneDone` | 「听音找一找」游戏 |
| `-uiFeedDrag` `-uiFeedYummy` `-uiFeedNo` `-uiFeedDone` | 「喂动物」游戏 |
| `-uiPhonics` | 进入自然拼读探索岛 |
| `-uiPhonicsLetter <letter>` | 直接打开特定字母详情页（如 `-uiPhonicsLetter s`） |
| `-uiPhonicsQuiz` | 直接打开听音辨字母（3 选 1）测验 |
| `-uiPhonicsGroup2` | 探索岛默认切换至第 2 组（Group 2: c, e, h, r, m, d） |
| `-uiPhonicsTrain` | 直接打开滑音小火车（Sound Blending Train） |
| `-uiPhonicsCargo` | 直接打开小火车装车厢拼词测验 |

截图编号：60–63 是说一说 L1，64 是复习课，65 是 L2，66 是代码卡预览，70–78 是启蒙模式，79a–79f 是自然拼读（79a 探索岛、79b 字母卡详情、79c 听音挑战、79d 滑音小火车、79e 装车厢挑战、79f Group 2 字母音），80 是多孩子档案。iPad 也有截图步骤，但 D5 定了不用看；要去掉 iPad 那一步，先问产品经理。
**没有 `-uiLesson`**：旧课文已经在 PR E 里全部下线了，用户原话是「旧课文：全部下线」。

## 3. 资源在哪

| 资源 | 位置 |
|---|---|
| 词图（大包） | GitHub Release `assets-v3` 的 `assets-bundle-v3.zip`，**不在 git 里**，CI 下载后解压到 `Resources/word-icons/` |
| 覆盖词图 | `assets/word-icons-overrides/*.jpg`（交通 22 张半写实图、数字卡、平涂新图），CI 解压大包后覆盖进去。D10：交通保持半写实风格 |
| 数字读音 | `assets/number-audio/`，CI 合并进 word-audio-map |
| 单词数据 | `Resources/words-a..d.json`、`word-themes.json`、`word-audio-map.json`、`audio/` |
| 启蒙模式词包 | `Resources/baby-path.json`：31 包、243 词，带句型和例句，反义词成对 |
| 说一说 | `Resources/phrases/`（文件夹引用，新文件自动打包）：`phrases.json`、`img/`、`avatars/`、`audio/`（每句一条 + `prompt_*` 旁白）、`code-preview.json`（PR #25） |
| 说一说原稿 | `docs/daily-phrases/phrases-levels.json`：7 级 249 句，产品经理定稿；`images-plan.json`：每句配图怎么来，new / reuse / code |
| 说一说配图原图 | `assets/daily-phrases` 分支：`docs/daily-phrases/art/`（头像、背景）、`qoder-art/L1/`、`gemini-art/L2/`（7518cb5，N21/N24/N25 已裁掉边框） |
| 以后的新图 | D11：用户自己用 Gemini 出，产品经理验收后交来入库。出图提示词在 `docs/pm/image-prompts/`（79 张：反义词 24 张，说一说 L3–L7 55 张） |
| 儿歌 | `Resources/songs.json`、`song-audio/`。6 首是演唱版，4 首是朗读版，见 `scripts/songs/README.md` |
| 场景、喂动物小游戏 | `Resources/scenes/`、`feed-pairs.json`，物品抠图由 CI 生成 |

## 4. 脚本

| 脚本 | 作用 |
|---|---|
| `scripts/sync_duplicated_sources.py` | 把内层 Swift 源码同步到外层镜像。**每次改完 Swift 都要跑** |
| `scripts/validate_resources.py` | 按 Swift 模型的必填字段校验资源 JSON。DataStore 用 `try?` 解码，缺字段会悄悄变成空数组，这个脚本让它直接报错。CI 会跑 |
| `scripts/gen_phrases.py` | 「说一说」生成脚本，输出 phrases.json 两份、配图（768 方图）、头像、配音（edge-tts）、旁白。<br>用法：`--art <素材目录> --levels 1,2`。素材目录要把 assets 分支里的头像、背景、L1 图、L2 图平铺放在一起。<br>已有的 mp3 默认不重新生成，要重新生成加 `--redo-audio`。<br>`--code-preview` 只生成 L3–L7 代码卡预览。<br>读音不准的句子写进 `TTS_OVERRIDES`（屏幕上的原句不变）。<br>声音：Tom 用 AnaNeural 降调 -8%，旁白用 Aria |
| `scripts/phrase_code_specs.py` | L3–L7 的 52 张代码卡参数表（PR #25） |
| `scripts/asr_check_phrases.py` | 用 faster-whisper 的 small.en 和 medium.en 核对每句配音，两个模型都要逐词一致。<br>用法：`--levels 2 --out docs/daily-phrases/asr-L2.md`。<br>本机虚拟环境：`C:/Users/Administrator/AppData/Local/Temp/kea-whisper`（Python 3.11）。一级大约要 10 分钟 |
| `scripts/add_baby_packs_v2.py` | 一次性脚本：往 baby-path.json 加 v2 词包（已执行，留作记录） |
| `scripts/make_icons_transparent.py` | 把 ui-icons 的白色外圈改成透明（CI 跑） |
| `scripts/make_scene_items.py` | 给「听音找一找」生成透明底物品图（CI 跑） |
| `scripts/songs/` | 儿歌演唱版流水线：OpenUtau 唱人声、FluidSynth 弹伴奏、ffmpeg 混音，`asr_check.py` 验收。见该目录 README |

## 5. 关键设计（改之前先看）

- **多孩子档案**（docs/pm/profiles-v1.md）：
  - 按孩子分开的 key 都加前缀 `p.<id>.<key>`，DataStore 里统一用 `k("…")`。
  - 共用的 key：profiles、currentProfileId、hasSeenGuide、lastBackgroundAt。
  - 迁移旧数据时只复制、不删除旧 key。备份 v2 包含全家所有孩子。录音文件名也带孩子 id。
- **复习课**（Phrases.swift 的 `PhraseReview`）：
  - 不写在 JSON 里，App 读数据时自动插入：每级每 3 课插一节，从前 3 课各挑 2 句交错排开，只做「轮到你」。
  - 复习课排在学习路线上，做完才开下一课。只给星星，不发卡片。
  - 复习课之后的新课，热身跳过复习课，回想上一节新课。
- **出图规矩**（images-plan.json 的 rule）：每张卡片图只给一句用；图里没有字和数字；太阳、月亮、物体都不画脸。代码卡用形状表示意思，不写字。
- 启蒙模式 = 代码里的 baby mode。UI 上叫「启蒙模式」，代码名和 key 不改（D8）。默认每天 4 个新词。

## 6. 已知的坑和没修的问题

1. **PR #25 未完成**：`PhraseTimeCards.swift` 还没编译通过过，可能还有 SwiftUI 编译错误或类型推断超时；52 张卡的截图都没看过。
2. 旧资源包里还有毛绒风格和旧 3D 风格的图，没清理。启蒙模式用 `pictures` 映射避开了这些图（BabyPicture 内部也有兜底），但别的页面直接用词图时可能还会出现。待办：清理资源包里的旧图。
3. `Resources/kid-whitelist.json` 已经没有用了，待删，删之前确认没有地方还在引用它。
4. Xcode 15.4 能不能编译没验证过（CI 用的是 macos-15 自带的 Xcode）。
5. 字母音模块（D2，P1）还没做：先做 s a t i p n 的样音，加押韵和拍手铺垫。
6. 「说一说」的 N32 书架上有一只带脸的小熊玩偶，产品经理已经定了不改。
7. 配音读音：edge-tts 有时会读错短句，whisper 一核对就能发现。办法是放慢语速，或在 `TTS_OVERRIDES` 里加感叹号语气。这类修正记录在 `docs/daily-phrases/asr-L1.md` 和 `asr-L2.md`。
8. `Resources/phrases/` 是文件夹引用，**删掉的图和音频要手动删**，生成脚本只会新增和覆盖。
9. 截图模式下动画停在最后一帧、不放声音。所以有动画的卡片（逐根点亮、轮流亮、指针转动），截图只能看到最后一帧，动画本身要在真机上确认。用户的规矩是中途不做真机测试，等全部做完再一起试。

## 7. 工作方式（交接后）

- 2026-10-25 起，后续工作由 Antigravity 接手，产品经理和工程师两边的活都由它来做。工作规矩见根目录 HANDOFF.md 第 5 节。
- 原来的 inbox 流程（工程师把材料放进 inbox，等产品经理回复「通过」）不再使用。现在的做法是：在 PR 说明里附上 CI 链接、截图和逐条核对表，CI 通过、截图检查没问题后再合并。
