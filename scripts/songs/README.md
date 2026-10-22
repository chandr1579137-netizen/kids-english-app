# App 儿歌真唱（scripts/songs）

App 里的 10 首儿歌（`KidsEnglish/KidsEnglish/Resources/songs.json`）都改成真人风格的演唱版，替换原来的朗读版，文件是 `KidsEnglish/KidsEnglish/Resources/song-audio/<id>.mp3`。CI 打包时会把它们拷到 `audio/songs/`，播放器用 `DataStore.songAudioURL` 读取，路径和文件名都没变。

做法和 song_007 C 版（原样品 PR #9）一样：OpenUtau 命令行唱人声，FluidSynth 弹伴奏，ffmpeg 混音，全自动。**歌词一字不改**：`make_song.py` 会核对 `song_specs.py` 里的歌词和 `songs.json` 是否完全一致，不一致就报错。

每首歌的曲调、速度和验收结果见 [`docs/sung-songs.md`](../../docs/sung-songs.md)。

## 文件

| 文件 | 说明 |
|---|---|
| `song_specs.py` | 9 首歌的旋律谱：速度、曲调出处、每句音符（song_007 另见 `song_007/`） |
| `diction.json` | 吐字表：显式 ARPAbet 音素、辅音提前量、句末换气长度；分全局和单首两层 |
| `make_song.py` | 旋律谱 → OpenUtau 工程 `.ustx`、MIDI（人声带歌词 + 钢琴 + 钢片琴）、每句时间轴 |
| `render_song.py` | 一键渲染；加 `--install` 直接拷进 App 的 `song-audio/` |
| `asr_check.py` | 验收：faster-whisper small.en、medium.en、large-v3 三个模型，逐句和整首都要和歌词一字不差 |
| `song_007/` | song_007 C 版的生成脚本、吐字表、工程和时间轴（来自样品分支 509320b） |
| `licenses/` | 音库条款（文字和截图）以及各工具的许可 |

## 怎么重做一首

Windows，工具装在 `qs1-tools/` 下，不进仓库：

```
python scripts/songs/render_song.py song_001 --tools <qs1-tools> --out <输出目录> --keep-vocal --install
python scripts/songs/asr_check.py <输出目录>/song_001_timing.json <输出目录>/song_001_sung.mp3 --vocal=<输出目录>/song_001_sung_vocal.wav
```

- `<qs1-tools>` 下需要这些：
  - `ou-build/OpenUtau.exe`：从 OpenUtau PR #2162 编译的命令行渲染版。
  - `Singers/Hoshino Hanami ~AIdol~ for DiffSinger v1.0/`：音库。英文词典 `dsdur/dsdict-en.yaml` 末尾要加 39 个 ARPAbet 音素的同名 `replacements`。
  - `fluidsynth/`。
  - `soundfont/FluidR3_GM.sf2`。
- ffmpeg 要在 PATH 里。
- 渲染一首约 40 秒，语音识别验收约 3 分钟（CPU）。

## 统一的唱法

- 前奏 1 小节钢琴主和弦，整段唱两遍，最后一个音延长 1 小节，最后 1.5 秒淡出。
- 句末留八分音符换气，下一句开头的 s、k 等辅音不会粘在上一句上。
- 每个音素都用 Hanami 的 **Nectar**（柔和）唱法。
- 伴奏：钢琴每半小节一个和弦（按旋律自动配 C、F、G、Am、Dm），钢片琴轻轻跟一遍旋律，伴奏比人声低 9 dB。
- 成品是 44.1 kHz 立体声、160 kbps 的 mp3，平均音量 -27.5 dB，和 App 现有音频一致（commit 88ce0dc）。

## 许可和署名（发布前必须看）

- **人声音库**：Hoshino Hanami ~AI❤dol~ for DiffSinger v1.0，作者 **Lotte V**。
  - Team L❤VE 的条款：可以商用，不需要事先申请；**必须注明 Lotte V**；不能再分发或修改音库的原始录音。
  - 条款全文和截图在 `licenses/hanami/`。
- ⚠ **声码器**：音库自带的声码器（AI❤olGAN）是 **CC BY-NC-SA 4.0**，只能非商业使用。
  - 现在这些演唱只能用于家用、非商业。
  - **上架任何应用商店之前，必须换成允许商用的声码器（例如 OpenVPI 的 NSF-HiFiGAN），然后全部重新渲染。**
  - 许可原文见 `licenses/hanami/LICENSE_vocoder.txt`。
- **音库词典**：MIT。
- **工具**：
  - OpenUtau：MIT。
  - FluidSynth：LGPL-2.1，只在制作时调用，不随 App 分发。
  - FluidR3_GM 音色库：MIT。
  - 许可原文见 `licenses/tools/`。
- **曲调**：都是公有领域（1900 年以前创作，出处见 docs）或本项目原创。
  - song_007 用的是 "Ah! vous dirai-je, maman"（1761 年首次刊印）。
  - song_008 用的是贝多芬《欢乐颂》主题（1824 年）。
