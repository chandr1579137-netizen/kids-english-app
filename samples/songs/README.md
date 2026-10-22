# 儿歌真唱样品：song_007「Clap Your Hands」

**这是样品，不合并。** App 里的 `song-audio/song_007.mp3` 没有替换。按 `docs/pm/install-and-songs.md` §5 Q-S1 制作。

## 文件

| 文件 | 说明 |
|---|---|
| `song_007_sung.mp3` | 试听用：44.1 kHz，160 kbps，42.0 秒。平均音量 -27.5 dB，与 App 现有音频一致（commit 88ce0dc） |
| `song_007_sung.wav` | 母带：44.1 kHz / 16 bit / 立体声 |
| `song_007.ustx` | OpenUtau 工程（由脚本生成）。可以直接用 OpenUtau 打开修改 |
| `song_007.mid` | 乐谱：4 轨，分别是指挥轨、人声旋律（每个音带歌词 meta）、钢琴和弦、钢片琴旋律 |
| `song_007_timing.json` | 6 句的开始和结束秒数，从乐谱算出 |
| `make_song007.py` | 乐谱 → ustx / mid / 时间轴 |
| `render_song007.py` | 一键渲染：OpenUtau 命令行 → FluidSynth 伴奏 → ffmpeg 混音和转码 |
| `song_007_sung_A_101bpm.mp3` / `.wav` | **加速版 A**：101 BPM（比 84 快约 20%），35.3 秒 |
| `song_007_sung_B_113bpm.mp3` / `.wav` | **加速版 B**：113 BPM（比 84 快约 35%），31.7 秒 |
| `song_007_A_101bpm.*`、`song_007_B_113bpm.*` | A/B 两版的 ustx、mid 和时间轴 |
| `song_007_sung_C_113bpm_clear.mp3` / `.wav` | **C 版（推荐）**：113 BPM，改善吐字，31.7 秒。做法见下文「C 版」一节 |
| `song_007_C_113bpm_clear.*`、`diction_clear.json` | C 版的 ustx、mid、时间轴，以及吐字表 |
| `asr_check_lines.py`、`asr_check_full.py` | 语音识别核对脚本：逐句识别一次，整首识别一次 |
| `licenses/` | 音库条款截图和全文，以及各工具的许可 |

## C 版：113 BPM，吐字更清楚（2026-10-22）

用户反馈 B 版的速度可以，但发音要准、要清楚，适合 4 岁孩子跟唱。原来的问题是 "stomp" 被听成 stump，"clap" 被听成 clip，"blink" 被听成 blank。

**改法**全部写在 `diction_clear.json` 里。`make_song007.py --diction diction_clear.json` 会把它写进 ustx，渲染流程不变，仍然是 OpenUtau 命令行、FluidSynth、ffmpeg，全自动：
```
python render_song007.py --tools <qs1-tools> --out . --bpm 113 --tag _C_113bpm_clear --diction diction_clear.json
```

| 改动 | 内容 | 原因 |
|---|---|---|
| clap | 显式音素 `k l a p`（原来是 `k l ae p`）；k 提前 30 tick | 音库的 ae 偏闭，像 clip；用音库里训练得最多的开口 a，再让 k 的爆破更清楚 |
| stomp | `s t o m p`（原来是 `aa`） | aa 和 ao 都会被听成 stump；圆唇的 o 才稳定地听成 stomp |
| blink | 固定为 `b l ih ng k` | 试过 iy：blink 是清楚了，但下一个词 eyes 会被听成 "ass"，所以保持标准读音 |
| 句末换气 | 从十六分音符改成八分音符 | 下一句开头的 s、k 有地方放，不再粘在上一句的 "three"、"me" 后面。旋律音高和小节数都没变，只是每句最后一个长音短了半拍 |
| 每个音素都设成 Nectar | 原来只设了前 4 个音素 | stomp 有 5 个音素，最后的 p 原来会回落到 Root 音色 |

- **试过但没有用的方法**：
  - 把辅音大幅提前（60–120 tick）：s 会被拉得太长，反而听成 "dump"。
  - DiffSinger 速度曲线 velc 设成 70 或 80：没有改善。
  - 用声门塞音 q 或 cl 把 "and"、"up" 隔开：小模型反而把 blink 听成 blank。
  - 这些试验的工程没有放进仓库。
- **音库**：仍然用 Hoshino Hanami（Nectar），条款不变，见 `licenses/`。英文元音和辅音的训练量足够，没有必要换音库。

**语音识别核对**（faster-whisper，int8，temperature 0，beam 5，不给提示词，听的是成品混音）：
- **逐句**：用纯人声找到每句之间的换气点并在那里切开，句尾的 z 和下一句开头的 s、k 各归各句，然后每句单独识别。
- **整首**：一次识别整首歌，只听到人声结束后 0.25 秒（29.98 秒）为止。
  - 这样剪是因为 whisper 按 30 秒一段处理。剩下的零点几秒纯伴奏尾巴会让 medium.en 幻听出 "thank you"，这不是听错了歌词。
- **结果**：small.en、medium.en、large-v3 三个模型，逐句和整首都与歌词一字不差，6 句全部正确。B 版（只改速度）用同样的方法核对时，small.en 和 medium.en 都有听错的词（stump、clip 等）。
- 多语种模型 medium（非 .en）整首也全对；逐句有 2 处听错（stomp 听成 put，up 听成 out）。small 多语种模型在唱歌上不稳定（会循环幻听），不作为依据。

| 版本 | 时长 | 平均 / 峰值音量 | 响度 | 结尾 "me"（C4 = 261.63 Hz） | "hands"（G4 = 392.00 Hz） |
|---|---|---|---|---|---|
| B（113 BPM） | 31.76 s | -27.9 / -13.1 dB | -24.8 LUFS | 261.96 Hz | 392.04 Hz |
| C（113 BPM clear） | 31.76 s | -28.0 / -11.6 dB | -24.8 LUFS | 262.13 Hz | 391.96 Hz |

## 加速版 A / B（2026-10-22）

用户觉得 84 BPM 太慢，所以加做了两个速度。84 BPM 的原版文件都保留着，没有改动。

- **只改了速度。** 乐谱里只改了 BPM，然后从头重新合成：OpenUtau 唱人声，FluidSynth 弹伴奏，ffmpeg 混音。没有把旧音频拉伸压缩，所以音高不变，仍然是 C 大调。
- **做法**：`render_song007.py` 新增 `--bpm` 和 `--tag` 两个参数：
  ```
  python render_song007.py --tools <qs1-tools> --out . --bpm 101 --tag _A_101bpm
  python render_song007.py --tools <qs1-tools> --out . --bpm 113 --tag _B_113bpm
  ```
  - 总时长按速度算：人声结束时间加 2 秒，最后 1.5 秒淡出。
  - 不带参数时输出和原样品逐字节相同（已核对 ustx、mid、时间轴）。

| 版本 | BPM | 时长 | 平均 / 峰值音量 | 结尾 "me"（C4 = 261.63 Hz） | 第 1 句 "hands"（G4 = 392.00 Hz） |
|---|---|---|---|---|---|
| 原版 | 84 | 42.03 s | -28.0 / -13.1 dB | 261.91 Hz | 391.82 Hz |
| A | 101 | 35.32 s | -27.9 / -13.9 dB | 261.89 Hz | 391.91 Hz |
| B | 113 | 31.76 s | -27.9 / -13.1 dB | 261.96 Hz | 392.01 Hz |

- **时长**：等于人声部分（84 BPM 时为 40.0 秒）乘以 84/BPM，再加结尾 2 秒。算出来 A 约 35.3 秒，B 约 31.7 秒，和实测一致；mp3 编码会多出约 0.04 秒。
- **音高**：用自相关法测长音的基频，三个版本差距在 ±0.1 Hz 以内（不到 1 音分），跟原版一样。
- **语音识别**（faster-whisper small.en，三个版本用同样设置）：每句都识别出来了，23 个不同的词识别出 21–23 个。
  - 常被听错的词三个版本一样："stomp" 常被听成 "stump"，"blink" 有时被听成 "blank"。
  - 加速后没有变差，这两个词仍然请用耳朵确认。
- **A/B 时间轴**：见 `song_007_A_101bpm_timing.json` 和 `song_007_B_113bpm_timing.json`。
  - A 版第一句开始于 2.38 秒，最后一句结束于 33.27 秒。
  - B 版第一句开始于 2.12 秒，最后一句结束于 29.73 秒。

## 曲调（公有领域）

- 曲调用的是 **"Ah! vous dirai-je, maman"**，也就是《小星星》"Twinkle, Twinkle, Little Star" 的曲调。
- **作曲者不详**，是法国传统曲调。
  - 据 Henri-Irénée Marrou 的说法，它源于约 1740 年的一首匿名牧歌。
  - **1761 年首次刊印**。
  - 1774 年，曲谱和歌词一起刊印在 Charles de Lusse 的 *Recueil de romances* 第 2 卷。
  - 资料来源：https://en.wikipedia.org/wiki/Ah!_vous_dirai-je,_maman ，其中引用了 George List（1978，*Yearbook of the International Folk Music Council* 第 10 卷，33–52 页）和 J. J. Fuld 的 *The Book of World-famous Music*。
- 这首曲调比 1900 年早一百多年，在中国和美国都已进入公有领域。
- 歌词是本项目原创，一字未改。
- 编曲（和弦和钢片琴旋律）由脚本按《小星星》常见的 I–IV–I–V 配法生成。

## 乐谱（按 Q-S1 规定）

- C 大调，4/4 拍，84 BPM，音域 C4–A4。
- 每个音节占一个四分音符，句末是二分音符。
  - 句末留一个十六分音符的换气，最后一句除外。
  - "hands" 唱两个音（G–G），"along" 拆成 a / long 两个音。
- 结构：前奏 1 小节（钢琴 C 和弦）→ A1 A2 B B A1 A2 → 最后一个音延长 1 小节 → 1.5 秒淡出。
- 时间轴就是乐谱上每句第一个音和最后一个音的时间：

  | 句 | 歌词 | 开始（秒） | 结束（秒） |
  |---|---|---|---|
  | 0 | Clap your hands, one two three | 2.86 | 8.39 |
  | 1 | Stomp your feet along with me | 8.57 | 14.11 |
  | 2 | Nod your head and blink your eyes | 14.29 | 19.82 |
  | 3 | Now we reach up to the skies | 20.00 | 25.54 |
  | 4 | Clap your hands, one two three | 25.71 | 31.25 |
  | 5 | Stomp your feet along with me | 31.43 | 40.00 |

  - 实测人声第一个声音出现在 2.70 秒。这是 "cl" 辅音，按惯例提前于拍点，比乐谱早 0.16 秒，在 0.2 秒的误差要求以内。

## 工具和版本（全部免费，全部自动化，不用点界面）

| 工具 | 版本 | 用途 | 许可 |
|---|---|---|---|
| OpenUtau | 从 PR [#2162](https://github.com/openutau/OpenUtau/pull/2162)（headless `render` 命令）的分支 `christian/cli` 编译，提交 06990cf5 | 唱歌合成 | MIT |
| .NET SDK | 8.0.426（装在用户目录 `%USERPROFILE%\.dotnet`） | 编译 OpenUtau | MIT |
| 音库 | Hoshino Hanami ~AI❤dol~ for DiffSinger v1.0，作者 Lotte V；唱法用 **Nectar（柔和）** | 人声 | 见下文 |
| FluidSynth | 2.6.1（win10-x64） | 伴奏合成 | LGPL-2.1 |
| 音色库 | FluidR3_GM.sf2，作者 Frank Wen，取自 Debian 软件包 fluid-soundfont-gm 3.1-5.3 | 钢琴（GM 0）和钢片琴（GM 8） | MIT |
| ffmpeg | 9.0.2 essentials | 混音、限幅、转码 | LGPL/GPL |

**编译和渲染步骤**（Windows）：
1. 用 `dotnet-install.ps1 -Channel 8.0` 安装 .NET SDK。
2. `git fetch origin pull/2162/head`，然后执行 `dotnet publish OpenUtau/OpenUtau.csproj -c Release -r win-x64 --self-contained false -o ou-build`。
3. 渲染命令：
   ```
   OpenUtau.exe render --input song_007.ustx --output vocal.wav --singers-path <Singers 目录>
   ```
   `render_song007.py` 把上面这些步骤和伴奏、混音串在一起。

**为了跑通改过的地方**（都没有动 OpenUtau 源码，也没有动音频文件）：
1. **补装系统运行库。** PR 分支带的 onnxruntime 1.23 需要更新的 VC++ 运行库：系统自带的 14.36 版会让 onnxruntime 初始化失败（0x8007045A）。用 winget 装了 Microsoft.VCRedist.2015+.x64，版本 14.51。
2. **在音库的英文词典 `dsdur/dsdict-en.yaml` 末尾加了 `replacements:`。**
   - 原因：OpenUtau 默认把 ARPAbet 音素写成 `en/<音素>`，而这个音库的音素没有 `en/` 前缀，不加的话每个英文词都报 "Unrecognized phoneme"。加的内容是 39 个音素映射回同名音素。
   - 原文件备份为 `.orig`。
   - 音库条款允许修改配置，也允许自由分发自定义词典。
3. **手动创建缓存目录。** headless 模式不会自己建 `Cache` 目录，渲染脚本会先建好。

**唱法说明：** 每个音都设置了 `clr = 2`，也就是 Nectar。日志提示时长和音高模型找不到 Nectar 的嵌入，这两个模型退回用 Root；声学模型（音色）用的是 Nectar。

**耗时：**
- 渲染一首：人声约 36 秒（GTX 1660 SUPER 机器，用默认的 CPU 推理），伴奏和混音约 5 秒。
- 一次性准备：编译约 2.5 分钟，下载音库约 1 分钟（524 MB）。
- 整个样品（含排错）大约 1 小时。
- 后面 9 首主要的工作是给每首定曲调、写乐谱数据，渲染本身是全自动的。

## 自检（产品经理验收前我自己做的）

- **逐词识别。** 用 faster-whisper small.en 识别成品，26 个词全部识别出来，没有多词或少词。
  - 识别结果把 "Stomp" 听成 "Stump"。第 2 句里 "blink" 在纯人声里识别成 blink，但混音后识别成 "blank"。这两处请产品经理用耳朵确认。
- **节拍和长度。** 节拍由乐谱固定在 84 BPM，总长 42.0 秒，在 35–45 秒的要求以内。
- **音量和爆音。** 峰值 -13 dBFS，没有削波，没有爆音。人声比伴奏响 9 dB 以上（要求 ≥ 6 dB）。

## 署名（Credits）

- Vocal: **Hoshino Hanami ~AI❤dol~** voicebank by **Lotte V** (https://lottev.moe/), Nectar mode
  - vocoder: AI❤dolGAN, finetuned from OpenVPI NSF-HiFiGAN
- Singing synthesis: OpenUtau (MIT), using DiffSinger
- Accompaniment: FluidSynth (LGPL-2.1) with the FluidR3_GM SoundFont by Frank Wen (MIT)
- Tune: "Ah! vous dirai-je, maman", traditional French, anonymous, first printed 1761 (public domain)
- Lyrics: KidsEnglish original

## 许可要点（详见 `licenses/`）

- **音库许可**（`licenses/hanami/LICENSE_voicebank.txt` 和 Terms of Use 截图 `terms_of_use_en_p3.png`）：
  - 允许任何创作用途，包括商用，不需要事先许可。
  - 必须署名 Lotte V。
  - 不得修改或再分发原始录音，不得转售音库文件。不得用于政治、仇恨或违法用途。
  - 家用儿童学习 App 符合这些条款。
  - 本仓库**没有**收录音库本身。
- **⚠ 声码器许可是 CC BY-NC-SA 4.0**（`licenses/hanami/LICENSE_vocoder.txt`）。音库自带的 AI❤dolGAN 声码器是**非商用**许可，它基于 OpenVPI 的 NSF-HiFiGAN。
  - 本 App 只给自家孩子用、不上架，符合非商用。
  - **如果以后要上架或收费**，需要换一个允许商用的声码器重新渲染，或者另外取得授权。
- `install-and-songs.md` 里引用的 Lotte V 2025-06-06 声明页面现在打不开（404）。音库包里的 Terms of Use 写的是同样的内容（"commercial and non-commercial … without prior permission"），所以以音库包内的条款为准。
