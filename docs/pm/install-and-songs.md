# 儿歌真唱：调研与方案

写于 2026-10-22（北京时间）。这份文件只做调研和写需求，我没有生成任何音频、图片或代码。
（换真机这件事已经按要求取消，不在本文里。）

---

## 0. 结论

1. **App 里现在的 10 首都是本项目的原创歌词，而且根本没有旋律。**
   - 每首都只是 Aria 念 4 句，长 8.3–10.7 秒。
   - 所以要先给它们配一段曲子，才谈得上「真唱」。
   - 公版的老录音唱的是别的歌，不能直接拿来唱我们这 10 首。
2. **推荐：免费，而且能按指定旋律唱。**
   - 原创歌词 + 公版老曲调（例如《小星星》的曲调，1761 年发表）+ 开源唱歌软件 OpenUtau + 免费英文女声音库「Hoshino Hanami」（作者明确允许商用，不用申请）。
   - 由 Qoder工程师制作。
   - **费用 0 元。** 唯一的风险是音质和咬字，所以先出 1 首样品。
3. **备选：花 15 美元买 Runway Standard 一个月，用 Lyria 3 Pro 生成。**
   - 625 点额度，8 点一首，大约能生成 78 次。
   - 曲子由 AI 自己编；我们的歌本来就没有曲子，所以这不是问题。
   - **要先经用户批准付费。**
4. **样品先做 song_007「Clap Your Hands」（拍拍手）**，原因见第 4 节。

---

## 1. App 现在的 10 首儿歌（核对过仓库 main `990fb86`）

- 歌词在 `KidsEnglish/KidsEnglish/Resources/songs.json`。
- 音频在 `KidsEnglish/KidsEnglish/Resources/song-audio/song_00X.mp3`；CI 编译时会拷到 `Resources/audio/songs/`（`.github/workflows/build.yml:130`）。
- 来源：README 第 105 行写着"儿歌词曲为本项目原创"，配音是 edge-tts `en-US-AriaNeural` 朗读（commit `b204c8b`，10-20）。
- `songs.json` 里没有任何时间轴；儿歌页的高亮是按句子平均分时间的。

| id | 歌名 | 级别 | 现在的音频长度 | 适合 4 岁吗 |
|---|---|---|---|---|
| song_001 | The Little Red Apple 小红苹果 | 1 | 9.3 秒 | 适合。"so neat" 稍难 |
| song_002 | Hop Little Bunny 小兔子跳跳 | 1 | 8.3 秒 | 适合。"twitch your ear" 稍难 |
| song_003 | Rainbow Colors 彩虹的颜色 | 1 | 9.3 秒 | 适合，正好复习颜色 |
| song_004 | One Two Three Four Five 一二三四五 | 1 | 10.7 秒 | 适合。由传统童谣 "Once I caught a fish alive" 改编，原版里"鱼咬我手指"那段已经去掉；"Little fish are all alive" 意思有点怪 |
| song_005 | My Happy Family 我快乐的一家 | 1 | 9.2 秒 | 适合 |
| song_006 | Twinkle Rain 闪亮的雨 | 2 | 9.1 秒 | 适合。"Washing clean the sleepy town"、"don't be late" 偏难 |
| song_007 | Clap Your Hands 拍拍手 | 1 | 9.1 秒 | **很适合**，是边唱边做动作的歌 |
| song_008 | Good Morning Sun 早安太阳 | 1 | 9.1 秒 | 适合 |
| song_009 | The Sleepy Moon 困倦的月亮 | 2 | 9.2 秒 | 适合，是摇篮曲 |
| song_010 | Wash Wash Wash 洗洗洗 | 1 | 9.9 秒 | 适合。"the soap expands" 很难，建议改成 "bubbles in my hands"（**改词要用户点头**） |

**版权**：歌词是我们自己写的，不存在公版不公版的问题。下面方案里借用的曲调都选 1900 年以前发表的传统曲调，在中国和美国都已进入公有领域。

**如果以后要加经典英文童谣，这些要避开或改词**：
- Rock-a-bye Baby：摇篮从树上掉下来。
- Ring a Ring o' Roses："all fall down"，常被解读为瘟疫。
- Oranges and Lemons：结尾"chop off your head"。
- Three Blind Mice：用切肉刀砍尾巴。
- Humpty Dumpty、Jack and Jill：摔碎、摔破头。
- Goosey Goosey Gander：把老人扔下楼梯。
- There Was an Old Woman Who Lived in a Shoe：打孩子。
- Peter Peter Pumpkin Eater：把妻子关进南瓜壳。

可以放心用的：Twinkle Twinkle、Mary Had a Little Lamb、Row Row Row Your Boat、Baa Baa Black Sheep、Hot Cross Buns、The Mulberry Bush、Old MacDonald（1917 年版在美国已是公版）。
The Wheels on the Bus 是 1939 年 Verna Hills 写的，版权状态不清楚，不建议用。

---

## 2. 几种做法逐一评估

### (1) Qoder工程师
- 它自己说了：**不能免费唱歌。** 它唯一的办法是用户已连接的 Runway。
- Runway 能生成带人声和伴奏的歌（用文字描述加歌词），**但不能按指定的旋律或乐谱唱。**
- 用户的 Runway 是免费版，额度是 0，没有可用的音乐模型。
- Runway 的配音声音（Pip / Rachel / Rina）只会说、不会唱，而且也要扣点数。
- 不过 Qoder 在用户的 Windows 电脑上，**可以安装本地软件**，所以免费方案也由它来做。要问它的问题见第 6 节。

### (2) Muse / muse.ai
- 我们团队的 Muse 是 muse2api，只有 `muse-spark`（对话）、`muse-image`、`muse-video` 三个模型，**没有音频或音乐功能**（`/workspace/muse2api/app.py:216-221`）。
- 网上叫 muse.ai 的是视频托管平台，2026 年 3 月已改名 Skiv，**只做视频托管、转写字幕和声音分类，不能生成音乐**（https://skiv.com/blog/muse-ai-is-now-skiv ，https://muse.ai/api ）。
- 结论：**Muse 做不了这件事。**

### (3) 公版或 CC0 的现成录音（链接都打开核对过）

| 候选 | 许可 | 内容 | 能不能用 |
|---|---|---|---|
| LibriVox《The Baby's Songbook》，Carol Stripling 演唱，14 首。页面 https://librivox.org/the-babys-songbook-by-walter-crane/ ；音频示例 https://archive.org/download/babys_songbook_1102_librivox/babyssongbook_02_crane_64kb.mp3 （The Mulberry Bush，打开返回 200） | **CC0**（archive.org 的元数据 licenseurl = publicdomain/zero/1.0） | 成年女声清唱，64 kbps | 适合的有 Mulberry Bush、Dickory Dock（第 6 首）、Baa Baa Black Sheep、Polly Put the Kettle On、Hot Cross Buns。**Oranges and Lemons 要剔除。** 词比较老，比如 pedlar、steeple。音质一般 |
| LibriVox《Our Old Nursery Rhymes》，17 位音乐系学生演唱，30 首。页面 https://librivox.org/our-old-nursery-rhymes-by-alfred-moffat/ ；音频 https://archive.org/details/nursery_rhymes_librivox | 公有领域（publicdomain） | 30 首合在一个 25 分钟的文件里 | 要切开，还要逐首筛选内容（里面可能有上面列出的问题童谣） |
| Wikimedia Commons「Twinkle Twinkle Little Star - sung with full lyrics.ogg」 https://commons.wikimedia.org/wiki/File:Twinkle_Twinkle_Little_Star_-_sung_with_full_lyrics.ogg | **CC0** | 2 分 6 秒清唱 | 上传者自己说"不是专业歌手，有一些错误"，**不推荐** |
| Commons「Twinkle twinkle little star (vocal).ogg」 https://commons.wikimedia.org/wiki/File:Twinkle_twinkle_little_star_(vocal).ogg | CC BY-SA 3.0，要署名 | 25 秒人声 | 能用，但要署名，而且相同方式共享 |
| Commons「Itsy Bitsy Spiter - English.webm」（Anaheim 图书馆讲故事的人演唱） https://commons.wikimedia.org/wiki/File:Itsy_Bitsy_Spiter_-_English.webm | CC BY 3.0，要署名 | 21 秒视频 | 能用，要署名 |
| Musopen https://musopen.org/ | 大多是公版或 CC 授权 | **主要是古典器乐**，没有儿歌人声 | 不适合（网站拒绝了我的抓取，这条按已知资料写） |
| Free Music Archive https://freemusicarchive.org/ | 每首授权不同，很多是 NC（禁止商用）或 ND（禁止改编） | 儿歌人声很少 | 没找到合适的具体文件 |

**结论**：现成录音**唱的不是我们这 10 首**，最多只能作为额外的「经典儿歌」栏目。而且音质参差、词也老。不推荐当主方案。

### (4) AI 音乐生成器（Suno、Udio）
- **Suno**（https://help.suno.com/en/articles/2416769 ，https://help.suno.com/en/articles/13876865 ）
  - 免费版生成的歌归 Suno 所有，只能"个人、非商业"使用。这个 App 只给自己孩子用，不上架，符合这个条件。
  - 但从 2026-09-03 起，**免费账号下载受限**：9 月 3 日前注册的账号一共只有 7 次试用下载；新注册的账号只是"偶尔"给试用下载，其他要另外买。
  - 付费 Pro 每月 20 次下载，有商用权。第三方资料说价格是 10 美元/月（https://undetectr.com/blog/udio-review-2026 ）。
  - Suno 也是自己编曲子，不能按指定旋律唱。
- **Udio**：从 2025-10-29 起，**所有档位都不能下载**，只能在网站上听（https://undetectr.com/blog/udio-review-2026 ，https://help.udio.com/en/articles/10739134 ）。**不能用。**

### (5) Runway（用户已连接）
- 价格（https://runway.com/pricing ）：
  - Standard 每月 15 美元（按年付是 12 美元/月），每月 625 点。
  - **Lyria 3 Pro 8 点一首**；Lyria 3 Clip 4 点一首；Seed Audio 1.0 每分钟 15 点。
  - 免费版只有一次性 125 点，用户现在是 0 点。
- 条款（Qoder 给出的 https://runwayml.com/terms-of-use 第 4.4 条）：Runway 不主张生成内容的所有权，不限制商用；但可能拿生成内容训练模型，也不保证不侵权。
- 优点：音质最好，有伴奏，Qoder 能直接通过 Runway 连接器操作。
- 缺点：要花钱；**不能按指定旋律唱**；AI 可能改词或漏词，要逐句核对；10 首歌的曲风可能不统一。
- 大致预算：10 首 × 每首最多 5 次 × 8 点 = 400 点，Standard 一个月的额度够用。**只买 1 个月就退订，大约 15 美元。**

### (6) 免费、能按旋律唱的开源方案（推荐）
- **OpenUtau**：免费开源，支持 Windows，用的是"音符 + 歌词"的钢琴卷帘界面，支持 DiffSinger 这种 AI 唱歌引擎（https://www.openutau.com/ ，https://www.openutau.com/DiffSinger-support/ ）。
- **DiffSinger**（OpenVPI 维护版）是 Apache-2.0 协议（https://github.com/openvpi/DiffSinger/ ）。
- **英文女声音库 Hoshino Hanami ~AI❤dol~ v1.0**（https://github.com/lottev1991/LotteV-Voicebank-Update-Repo/releases/tag/v1.0-hanami-ds ）：
  - 英文训练数据约 2 小时。
  - 有 3 种唱法，其中 "Nectar" 是柔和唱法。
  - 能自动生成音高。
  - 作者 Lotte V 在 2025-06-06 声明，她的所有音库**商用都不需要申请**（https://lottev.moe/2025/06/permission-for-commercial-use-is-no-longer-necessary/ ）。
- **一个限制**：OpenUtau 的命令行导出功能（PR #2162）**还没合并**（https://github.com/openutau/OpenUtau/pull/2162 ）。所以正式版只能在界面上点「导出 WAV」。两种办法：
  - Qoder 用 .NET 自己编译这个 PR 的分支，就能在命令行里导出；
  - 或者 Qoder 生成好工程文件，请用户在 OpenUtau 里点一次导出（约 2 分钟）。
- 其他对比：
  - **Synthesizer V Studio 2 Basic** 加免费的 Lite 英文声音（Eleanor Forte Lite）：Lite 声音**禁止商用，发布时必须注明**，音质也有限制（https://manual.synthv.info/faq/ ）。自家用可以，但不如 Hanami 宽松。
  - 另一个英文音库 Peiton 商用要买授权（https://utaurepository.miraheze.org/wiki/Peiton ）。
- **额外好处**：旋律是我们自己写的，所以**每句的开始时间可以从乐谱直接算出来**。这样功能 ⑤ 儿歌跟唱需要的"唱到哪句就高亮哪句"就有了准确的时间轴，不用再按句子平均分。

---

## 3. 推荐路线

| 顺序 | 做法 | 费用 | 谁来做 | 需要谁批准 |
|---|---|---|---|---|
| **1（推荐）** | 原创词 + 公版曲调 + OpenUtau + Hanami 音库，配简单钢琴伴奏，**先做 1 首样品** | 0 元。Qoder 在 10/24 23:59 之后按 0.1 倍扣积分 | Qoder工程师 | 样品不用改 App 代码；入库要用户先试听同意 |
| 2（样品不行时） | Runway Standard 一个月 + Lyria 3 Pro，同样先做 1 首 | 约 15 美元（买 1 个月后退订） | Qoder工程师（通过 Runway 连接器） | **付费要用户批准** |
| 3（可选的额外内容） | LibriVox CC0 清唱，做一个「经典儿歌」栏目 | 0 元 | Qoder 剪辑 | 内容要用户看过 |

**排期**：用户之前定的优先级是 首页 A → 听音找一找 → 喂小动物 → 真唱样品。所以真唱样品**在两个玩法之后**再发给 Qoder，不占 10/24 前的免费时间。如果 Qoder 有空档，可以提前做。

---

## 4. 为什么样品选 song_007「Clap Your Hands」
- **歌词正好合《小星星》的格律**：每句 7 个音节（第一句 6 个），两句一押韵（three/me、eyes/skies）。可以直接套 1761 年发表的公版曲调 "Ah! vous dirai-je, maman"，孩子一听就熟。
- **边唱边做动作**（拍手、跺脚、点头、眨眼、伸手）：proposal-v2.md 第 3 节引用的研究里，儿歌加动作对学前儿童学词效果最好。
- **歌里的词大多在 App 的词表里**：hand、foot、head、eye、clap、blink、sky、one、two、three 都在（已核对 word-themes.json）。
- 这首是 1 级，内容没有任何问题。效果图 M7「儿歌跟唱」用的也是这首。

---

## 5. 可以直接发的说明

### Q-S1（发给 Qoder工程师，免费方案，推荐）
> **任务：** 儿歌真唱样品 1 首，song_007「Clap Your Hands」。只做样品，**不改 App 代码，不合并 main**。
>
> **工具：**
> - OpenUtau 正式版（Windows）：https://www.openutau.com/
> - 英文女声音库 Hoshino Hanami ~AI❤dol~ for DiffSinger v1.0：https://github.com/lottev1991/LotteV-Voicebank-Update-Repo/releases/tag/v1.0-hanami-ds （按 release 页面上的 MediaFire 链接下载）。用 "Nectar" 柔和唱法。如果 OpenUtau 提示缺声码器，按 https://www.openutau.com/DiffSinger-support/ 的说明装。
> - 安装后看一下音库自带的 readme / 使用条款，确认可以用于"家用儿童学习 App"，把条款截一段放进交付里。
> - 伴奏：FluidSynth + 一个免费的 General MIDI 音色库（例如 FluidR3_GM），只用钢琴或钢片琴，或者两个一起。
> - 混音和转码用 ffmpeg。
>
> **歌词**（一字不改，不加词，不改顺序）：
> ```
> Clap your hands, one two three,
> Stomp your feet along with me.
> Nod your head and blink your eyes,
> Now we reach up to the skies!
> ```
>
> **曲调：** 公版《小星星》曲调（"Ah! vous dirai-je, maman"，1761 年），C 大调，4/4 拍，**每分钟 84 拍**（比常见版本慢，方便 4 岁孩子听清、跟唱），音域 C4–A4。
>
> | 段 | 歌词 | 音符（每个四分音符一个音节，句末是二分音符） |
> |---|---|---|
> | A1 | Clap your hands, one two three | C C G G A A G（"hands" 跨两个音 G–G 连唱） |
> | A2 | Stomp your feet along with me | F F E E D D C |
> | B1 | Nod your head and blink your eyes | G G F F E E D |
> | B2 | Now we reach up to the skies | G G F F E E D |
> | A1' | Clap your hands, one two three | C C G G A A G |
> | A2' | Stomp your feet along with me | F F E E D D C |
>
> **结构：** 前奏 1 小节（钢琴弹 C 和弦，提示要开始了）→ 上面 6 句 → 最后一个音延长 1 小节收尾。**总长 35–45 秒。** 两句之间不要加花腔、颤音和装饰音。
>
> **声音要求：** 温暖的成年女声，像幼儿园老师那样。慢一点，每个词都清楚，辅音要清晰（尤其 clap、stomp、blink 的结尾）。不要流行唱腔，不要混响太大；人声比伴奏响 6 dB 以上。
>
> **交付**（放到新分支 `sample/sing-song007`，开 PR 标「样品，不合并」，**不要替换** `song-audio/song_007.mp3`）：
> 1. `samples/songs/song_007_sung.mp3`：44.1 kHz，128 kbps 以上，音量和现有音频一致（参考 commit `88ce0dc` 的统一音量）。
> 2. `samples/songs/song_007_sung.wav`：母带。
> 3. `samples/songs/song_007.ustx` 和 `song_007.mid`：工程和乐谱源文件，方便以后改。
> 4. `samples/songs/song_007_timing.json`：每句的开始和结束秒数，例如 `[{"line":0,"start":2.86,"end":8.57}, …]`，从乐谱算出来，6 句全写。
> 5. 一段说明：用了哪些工具和版本，音库的条款截图，花了多长时间，**一首要多久、能不能全自动导出**（如果能编译 OpenUtau PR #2162 的命令行版本，就说明怎么做的）。
>
> **验收（产品经理先听）：**
> - 26 个词全部听得清，没有多词或少词，咬字不怪。
> - 节拍稳定在 84 左右，旋律听得出是《小星星》。
> - 没有爆音或电流声。
> - 时间轴误差小于 0.2 秒。
>
> 通过后再给用户试听，用户满意了才批量做剩下 9 首（每首也要先定一个公版曲调）。

### Q-S2（发给 Qoder工程师，付费备选，**用户批准买 Runway Standard 之后才发**）
> **任务：** 同样是 song_007 样品，改用 Runway 的 Lyria 3 Pro。
> - **花费上限：**这首样品最多 5 次生成，共 40 点。
>
> **文字描述（英文）：** "Gentle children's nursery song for 4-year-olds, warm friendly female voice like a kindergarten teacher, slow and very clear diction, about 84 BPM, simple soft piano and glockenspiel accompaniment, cheerful, no drums, no effects, no background vocals, about 40 seconds."
>
> **歌词：** 同 Q-S1，按这个顺序唱：前 2 句 → 后 2 句 → 再唱前 2 句。
>
> **交付：** 和 Q-S1 一样放到 `samples/songs/`，文件名 `song_007_sung_runway.mp3`；时间轴用人工听写记录。另外写明每次生成花了多少点。
>
> **验收：** 同 Q-S1。另外要逐词核对 AI 有没有改词——Lyria 可能会改词，改了就重新生成。

### 给 Muse 的说明
**不需要。** Muse 只能生成图片和视频，不能做音频。

---

## 6. 发给 Qoder 之前要它确认的问题
1. 你的 Windows 电脑能不能安装 OpenUtau 和 DiffSinger 音库？大约要多少磁盘空间？有没有显卡（没有显卡只用 CPU 也能渲染，但会慢）？
2. 你能不能编译 OpenUtau PR #2162 的命令行版本（需要 .NET SDK）？如果不能，最后一步「导出 WAV」是不是要请用户手动点？
3. 你能不能装 FluidSynth 和 ffmpeg？
4. 你能不能用代码直接生成 .ustx 文件（它是 YAML 格式），不用手动在钢琴卷帘上画音符？
5. 一首歌从头做到验收大约要多久？10/24 之后按 0.1 倍扣积分，大约要扣多少？

## 7. 需要用户决定的事
1. 同意先走免费方案（OpenUtau + Hanami + 公版曲调），样品先做「Clap Your Hands」吗？
2. 如果免费样品音质不满意，同意花大约 15 美元买 Runway Standard 一个月，改用 Lyria 生成吗？
3. song_010 那句 "the soap expands" 要不要改成 "bubbles in my hands"？要改的话，朗读版也要一起重新生成。
4. 要不要再加一个「经典儿歌」栏目（用 LibriVox 的公版清唱，剔除有问题的那些）？
