# App 儿歌真唱版

`songs.json` 里的 10 首儿歌，目标是把朗读版换成演唱版，**歌词一字不改**。验收标准很严：三个语音识别模型逐句、整首都要和歌词逐词一致才算过。

- 现在 **4 首过了**，已换成演唱版：song_003、song_004、song_007、song_009。
- **6 首还没过**：song_001、002、005、006、008、010。App 里仍用原来的朗读版；每首最好的一版放在 `docs/sung-songs/candidates/`（不打包进 App），下面列出没听对的词。

脚本和做法见 [`scripts/songs/README.md`](../scripts/songs/README.md)。「经典儿歌」栏目不在 `songs.json` 里，这次没有涉及。

## 做法

1. `make_song.py`：旋律谱（`song_specs.py`）+ 吐字表（`diction.json`）→ OpenUtau 工程 `.ustx`、伴奏 MIDI、每句时间轴。歌词和 `songs.json` 不一致就报错。
2. `render_song.py`：OpenUtau 命令行（PR #2162 编译）用 Hoshino Hanami 的 Nectar 唱法唱人声 → FluidSynth（FluidR3_GM，钢琴 + 钢片琴）弹伴奏 → ffmpeg 混音，平均音量 -27.5 dB，44.1 kHz 160 kbps mp3。
3. `asr_check.py`：faster-whisper small.en、medium.en、large-v3（int8，temperature 0，beam 5，不给提示词），一个模型跑完再跑下一个。逐句（在纯人声的换气处切开）和整首都要和歌词逐词一致。比对前统一大小写、标点、连字符、撇号，数字转英文，goodnight = good night，colours = colors。
4. 可调的渲染参数（都不改歌词）：音符时值和休止、显式音素和辅音提前量、每首的换气长度、速度、`velc` 咬字速度曲线、`voice` 唱法、`accomp_below_db` 伴奏比人声低多少 dB。

## 一览

| id | 歌名 | 状态 | 速度 BPM | 时长 | 验收（逐句通过数，整首 ✓/✗） |
|---|---|---|---|---|---|
| song_001 | The Little Red Apple（小红苹果） | 仍是朗读版（演唱候选没过验收） | 112 | 38.5 s | small.en 8/8 ✗；medium.en 7/8 ✗；large-v3 8/8 ✓ |
| song_002 | Hop Little Bunny（小兔子跳跳） | 仍是朗读版（演唱候选没过验收） | 116 | 37.2 s | small.en 7/8 ✗；medium.en 6/8 ✗；large-v3 4/8 ✗ |
| song_003 | Rainbow Colors（彩虹的颜色） | 演唱版（三个模型全过） | 112 | 38.5 s | small.en 8/8 ✓；medium.en 8/8 ✓；large-v3 8/8 ✓ |
| song_004 | One Two Three Four Five（一二三四五） | 演唱版（三个模型全过） | 112 | 38.5 s | small.en 8/8 ✓；medium.en 8/8 ✓；large-v3 8/8 ✓ |
| song_005 | My Happy Family（我快乐的一家） | 仍是朗读版（演唱候选没过验收） | 112 | 38.5 s | small.en 8/8 ✓；medium.en 6/8 ✓；large-v3 8/8 ✓ |
| song_006 | Twinkle Rain（闪亮的雨） | 仍是朗读版（演唱候选没过验收） | 108 | 39.8 s | small.en 6/8 ✗；medium.en 6/8 ✓；large-v3 8/8 ✗ |
| song_007 | Clap Your Hands（拍拍手） | 演唱版（三个模型全过） | 113 | 31.8 s | small.en 6/6 ✓；medium.en 6/6 ✓；large-v3 6/6 ✓ |
| song_008 | Good Morning Sun（早安太阳） | 仍是朗读版（演唱候选没过验收） | 112 | 38.5 s | small.en 7/8 ✓；medium.en 8/8 ✓；large-v3 8/8 ✓ |
| song_009 | The Sleepy Moon（困倦的月亮） | 演唱版（三个模型全过） | 96 | 44.5 s | small.en 8/8 ✓；medium.en 8/8 ✓；large-v3 8/8 ✓ |
| song_010 | Wash Wash Wash（洗洗洗） | 仍是朗读版（演唱候选没过验收） | 112 | 38.5 s | small.en 6/8 ✗；medium.en 8/8 ✗；large-v3 4/8 ✗ |

## 没过的歌：试了什么

每首都试了 10 版以上：挪休止、改音素（如 tx 送气 t、ch r 的 tree、hh o p 的 hop）、辅音提前、慢速（96 BPM）、Root 唱法、咬字速度 velc 40–160、伴奏压低到 15 dB。识别结果会在这些词上来回跳，改好一处常常别处又错，没有一版三个模型全过。常错的词：

- song_001：tree 听成 trees（“tree so” 连读）、apple 听成 a bow / purple、neat 和 so 连成 Sony
- song_002：Hop 听成 Hup / Help、twitch 听成 switch、ear 听成 hair / ears
- song_005：Daddy 听成 Steady / Teddy（medium.en）、days 听成 day
- song_006：Pitter-patter 听成 Peter Peter / Bitter / Play the pattern、town 听成 tongue
- song_008：tree 听成 trees、sun 听成同音的 son。最好的一版只差 small.en 第 5 句把 sun 写成同音的 son，medium.en 和 large-v3 全过；同音词没法靠唱法区分，要不要放行请产品经理定
- song_010：Rub-a-dub 听成 Rub it up / Rubber the / Rubbered up

## 每首歌

### song_001 The Little Red Apple（小红苹果）

- 文件：`docs/sung-songs/candidates/song_001_best.mp3`
- 速度 112 BPM，时长 38.5 秒（整段唱两遍）
- 最好的一版：`song_001@z11`，相对提交的谱：“tree so” 之间的休止从 tree 前挪到 tree 后；apple 显式音素 ae p ah l；伴奏比人声低 15 dB
- 谱和吐字表：`docs/sung-songs/candidates/song_001/`
- small.en：逐句 8/8，整首 没过
  - 整首：replace: apple -> a bow
- medium.en：逐句 7/8，整首 没过
  - L2 “Hanging on the tree so neat.” → “Hanging on the trees so neat”
  - 整首：replace: yummy apple just for me -> y y
- large-v3：逐句 8/8，整首 通过

### song_002 Hop Little Bunny（小兔子跳跳）

- 文件：`docs/sung-songs/candidates/song_002_best.mp3`
- 速度 116 BPM，时长 37.2 秒（整段唱两遍）
- 最好的一版：`song_002@z23`，相对提交的谱：twitch 前休止加长到半拍、twitch 用送气 tx；伴奏低 15 dB
- 谱和吐字表：`docs/sung-songs/candidates/song_002/`
- small.en：逐句 7/8，整首 没过
  - L1 “Hop, hop, little bunny,” → “Hup, hup, little bunny.”
  - 整首：replace: hop hop -> help help
  - 整首：insert:  -> spring
  - 整首：replace: twitch -> switch
- medium.en：逐句 6/8，整首 没过
  - L1 “Hop, hop, little bunny,” → “Help, help, little bunny”
  - L7 “Wiggle your nose, twitch your ear,” → “Wiggle your nose, switch your hair”
  - 整首：replace: ear -> hair
- large-v3：逐句 4/8，整首 没过
  - L1 “Hop, hop, little bunny,” → “Hup, hup, little bunny.”
  - L3 “Wiggle your nose, twitch your ear,” → “Wiggle your nose, switch your ear”
  - L5 “Hop, hop, little bunny,” → “Hup, hup, little bunny.”
  - L7 “Wiggle your nose, twitch your ear,” → “Wiggle your nose, switch your ear”
  - 整首：replace: twitch -> switch

### song_003 Rainbow Colors（彩虹的颜色）

- 文件：`KidsEnglish/KidsEnglish/Resources/song-audio/song_003.mp3`
- 速度 112 BPM，时长 38.5 秒（整段唱两遍）
- small.en：逐句 8/8，整首 通过
- medium.en：逐句 8/8，整首 通过
- large-v3：逐句 8/8，整首 通过

### song_004 One Two Three Four Five（一二三四五）

- 文件：`KidsEnglish/KidsEnglish/Resources/song-audio/song_004.mp3`
- 速度 112 BPM，时长 38.5 秒（整段唱两遍）
- small.en：逐句 8/8，整首 通过
- medium.en：逐句 8/8，整首 通过
- large-v3：逐句 8/8，整首 通过

### song_005 My Happy Family（我快乐的一家）

- 文件：`docs/sung-songs/candidates/song_005_best.mp3`
- 速度 112 BPM，时长 38.5 秒（整段唱两遍）
- 最好的一版：`song_005@v5`，相对提交的谱：伴奏低 15 dB（其余同提交的谱）
- 谱和吐字表：`docs/sung-songs/candidates/song_005/`
- small.en：逐句 8/8，整首 通过
- medium.en：逐句 6/8，整首 通过
  - L1 “This is Daddy, big and strong,” → “This is Steady, Big and Strong”
  - L5 “This is Daddy, big and strong,” → “This is Steady, Big and Strong”
- large-v3：逐句 8/8，整首 通过

### song_006 Twinkle Rain（闪亮的雨）

- 文件：`docs/sung-songs/candidates/song_006_best.mp3`
- 速度 108 BPM，时长 39.8 秒（整段唱两遍）
- 最好的一版：`song_006@w70`，相对提交的谱：咬字速度 velc 70（更慢）；伴奏低 15 dB
- 谱和吐字表：`docs/sung-songs/candidates/song_006/`
- small.en：逐句 6/8，整首 没过
  - L5 “Pitter-patter, rain comes down,” → “Play the pattern, rain comes down”
  - L6 “Washing clean the sleepy town.” → “Washing clean the sleepy tongue”
  - 整首：delete: hold -> 
- medium.en：逐句 6/8，整首 通过
  - L3 “Hold your umbrella, don't be late,” → “uh”
  - L4 “Rainbow's waiting at the gate!” → “Rainbows waitin' at the gate”
- large-v3：逐句 8/8，整首 没过
  - 整首：replace: pitter patter -> peter peter
  - 整首：replace: pitter patter -> peter peter

### song_007 Clap Your Hands（拍拍手）

- 文件：`KidsEnglish/KidsEnglish/Resources/song-audio/song_007.mp3`
- 速度 113 BPM，时长 31.8 秒（整段唱两遍）
- small.en：逐句 6/6，整首 通过
- medium.en：逐句 6/6，整首 通过
- large-v3：逐句 6/6，整首 通过

### song_008 Good Morning Sun（早安太阳）

- 文件：`docs/sung-songs/candidates/song_008_best.mp3`
- 速度 112 BPM，时长 38.5 秒（整段唱两遍）
- 最好的一版：`song_008@q81`，相对提交的谱：are 用 ah r、tree 用 ch r i、句末换气 480 tick；伴奏低 15 dB
- 谱和吐字表：`docs/sung-songs/candidates/song_008/`
- small.en：逐句 7/8，整首 通过
  - L5 “Good morning, sun, so warm and bright,” → “Good morning, son, so warm and bright.”
- medium.en：逐句 8/8，整首 通过
- large-v3：逐句 8/8，整首 通过

### song_009 The Sleepy Moon（困倦的月亮）

- 文件：`KidsEnglish/KidsEnglish/Resources/song-audio/song_009.mp3`
- 速度 96 BPM，时长 44.5 秒（整段唱两遍）
- small.en：逐句 8/8，整首 通过
- medium.en：逐句 8/8，整首 通过
- large-v3：逐句 8/8，整首 通过

### song_010 Wash Wash Wash（洗洗洗）

- 文件：`docs/sung-songs/candidates/song_010_best.mp3`
- 速度 112 BPM，时长 38.5 秒（整段唱两遍）
- 最好的一版：`song_010@z102`，相对提交的谱：Rub-a 和 dub 之间、dub 之后各留 1/16 休止，dub 用 dd；伴奏低 15 dB
- 谱和吐字表：`docs/sung-songs/candidates/song_010/`
- small.en：逐句 6/8，整首 没过
  - L2 “Rub-a-dub, bubbles in my hands.” → “Rub up the bubbles in my hands.”
  - L6 “Rub-a-dub, bubbles in my hands.” → “Rub a cup of bubbles in my hands”
  - 整首：replace: a dub -> up the
  - 整首：replace: a dub -> up the
- medium.en：逐句 8/8，整首 没过
  - 整首：replace: rub a dub -> rubbered up
  - 整首：replace: rub a dub -> rubbered up
- large-v3：逐句 4/8，整首 没过
  - L2 “Rub-a-dub, bubbles in my hands.” → “Rubber duck bubbles in my hands”
  - L3 “Rinse them clean from left to right,” → “Thank drugs.好吧 [♪  ~~ ~~ ~~INAUDIBLE”
  - L4 “Hands so clean and feeling light!” → “So clean and feeling light”
  - L6 “Rub-a-dub, bubbles in my hands.” → “Rubber the bubbles in my hands”
  - 整首：replace: rub a dub -> rubber the
  - 整首：replace: rub a dub -> rubber the
  - 整首：replace: so -> all

## 许可（发布前必看）

- 人声：Hoshino Hanami ~AI❤dol~ for DiffSinger v1.0，作者 **Lotte V**（Team L❤VE），可商用，须署名 Lotte V。
- ⚠ **声码器**：音库自带的声码器（AI❤olGAN）是 **CC BY-NC-SA 4.0**，只能非商业使用。现在的演唱只能家用；**上架任何应用商店前，必须换成允许商用的声码器（例如 OpenVPI 的 NSF-HiFiGAN），然后全部重新渲染**。原文见 `scripts/songs/licenses/hanami/LICENSE_vocoder.txt`。
- 其余：OpenUtau（MIT）、音库词典（MIT）、FluidSynth（LGPL-2.1，只在制作时调用，不随 App 分发）、FluidR3_GM（MIT）。原文在 `scripts/songs/licenses/`。
- 曲调：公有领域（1900 年以前，song_007 是 1761 年的 “Ah! vous dirai-je, maman”，song_008 是贝多芬《欢乐颂》主题 1824 年）或本项目原创。
