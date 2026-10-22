"""App 儿歌的旋律谱（除 song_007 外）。

每首：
  bpm      速度（四分音符/分钟）
  tune     曲调出处（公有领域写明作曲者、年份和来源；原创写 original）
  lines    4 句。每句是 (带音节分隔符的歌词, 音符)：
           - 歌词去掉 "|" 后必须和 songs.json 的 en 完全一样（make_song.py 会检查，保证一字不改）。
             "|" 只是把一个词切成几个音节；空格和 "-" 分开不同的词。
           - 音符写成 "音名八度:拍数"，例如 "E4:1"（四分音符）、"G4:2"（二分）、"A4:0.5"（八分）。
             以 "~" 开头的音不带新音节，是上一个音节的拖腔（ustx 里写 "+"）。
           - "R:0.25" 是休止：逗号处或两个词之间留一点空，让词尾辅音和下一个词分开
             （比如 nose, twitch 不会被听成 nose switch），句末不能是休止。
           - 每句正好 2 小节（8 拍）。
  breath   （可选）这首歌的句末换气长度，tick；不写就用 diction.json 的 breath
  end_hold （可选）最后一个音多拖几拍；默认 0
  repeat   整段唱几遍（默认 2：两遍之间只留句末换气，和 song_007 一样先熟悉、再跟唱）
全部 C 大调，音域 C4–A4（音库最舒服的音区，和 song_007 一致）。
"""

SONGS = {
"song_001": dict(accomp_below_db=15, bpm=112, tune="original", lines=[
    ("Lit|tle red ap|ple, round and sweet,", "E4:0.5 E4:0.5 G4:1 A4:1 G4:1 E4:1 F4:1 G4:2"),
    ("Hang|ing on the tree so neat.",       "A4:1 A4:1 G4:1 E4:0.75 R:0.25 F4:1 E4:1 D4:2"),
    ("I will pick you, one two three,",     "C4:1 E4:1 G4:1 E4:0.75 R:0.25 A4:1 A4:1 G4:2"),
    ("Yum|my ap|ple, just for me!",         "F4:1 A4:1 G4:1 E4:1 D4:1 E4:1 C4:2"),
]),
"song_002": dict(accomp_below_db=15, bpm=116, breath=480, tune="original", lines=[
    ("Hop, hop, lit|tle bun|ny,",           "G4:0.75 R:0.25 G4:0.75 R:0.25 E4:1 G4:1 A4:1 G4:3"),
    ("Hop a|round so fun|ny.",              "F4:1 E4:1 F4:1 D4:0.75 R:0.25 E4:1 C4:3"),
    ("Wig|gle your nose, twitch your ear,", "E4:1 E4:1 G4:1 G4:0.75 R:0.25 A4:1 A4:0.75 R:0.25 G4:2"),
    ("Spring is fi|nal|ly here!",           "F4:1 E4:1 D4:1 E4:0.5 D4:0.5 C4:4"),
]),
"song_003": dict(bpm=112, tune="original", lines=[
    ("Red and yel|low, green and blue,",    "C4:1 E4:1 G4:1 G4:1 A4:1 G4:1 E4:2"),
    ("Pret|ty col|ors just for you.",       "F4:1 F4:1 A4:1 A4:1 G4:1 E4:1 D4:2"),
    ("Or|ange, pur|ple, pink so bright,",   "E4:1 G4:1 F4:1 A4:0.75 R:0.25 G4:1 E4:1 G4:2"),
    ("Rain|bow dan|cing in the light!",     "A4:1 G4:1 F4:1 E4:1 D4:1 E4:1 C4:2"),
]),
"song_004": dict(bpm=112, breath=480, tune="original", lines=[
    ("One, two, three, four, five,",        "C4:0.75 R:0.25 D4:0.75 R:0.25 E4:0.75 R:0.25 F4:0.75 R:0.25 G4:4"),
    ("Lit|tle fish are all a|live.",        "A4:0.5 A4:0.5 G4:1 E4:1 F4:1 E4:1 D4:3"),
    ("Six, sev|en, eight, nine, ten,",      "A4:1 G4:0.5 G4:0.5 F4:1 E4:1 D4:4"),
    ("Count them all and start a|gain!",    "E4:1 E4:1 F4:1 G4:1 E4:1 D4:1 C4:2"),
]),
"song_005": dict(accomp_below_db=15, bpm=112, tune="original", lines=[
    ("This is Dad|dy, big and strong,",     "G4:1 E4:1 G4:1.5 E4:0.5 F4:1 A4:1 G4:2"),
    ("Mom|my sings a hap|py song.",         "F4:1 D4:1 F4:1 A4:1 G4:1 F4:1 E4:2"),
    ("Sis|ter laughs and broth|er plays,",  "E4:1 C4:1 E4:1 G4:1 A4:1 A4:1 G4:2"),
    ("Love is here on sun|ny days!",        "F4:1 A4:1 G4:1 E4:1 D4:1 E4:1 C4:2"),
]),
"song_006": dict(accomp_below_db=15, bpm=108, tune="original", lines=[
    ("Pit|ter-pat|ter, rain comes down,",   "G4:1 E4:1 G4:1 E4:1 F4:1 E4:1 D4:2"),
    ("Wash|ing clean the sleep|y town.",    "E4:1 D4:1 E4:1 G4:1 F4:1 D4:1 C4:2"),
    ("Hold your um|brel|la, don't be late,", "A4:1 G4:0.5 F4:0.5 A4:1 G4:1 E4:1 F4:1 G4:2"),
    ("Rain|bow's wait|ing at the gate!",    "A4:1 G4:1 F4:1 E4:1 F4:1 D4:1 C4:2"),
]),
"song_008": dict(accomp_below_db=15, bpm=112,
    tune="Ludwig van Beethoven, \"Ode to Joy\" theme from Symphony No. 9 in D minor, Op. 125, 4th movement (1824); "
         "public domain. Source: https://en.wikipedia.org/wiki/Ode_to_Joy  (melody transposed to C, rhythm adapted to the syllables)",
    lines=[
    ("Good mor|ning, sun, so warm and bright,", "E4:1 E4:0.5 F4:0.5 G4:0.5 R:0.5 G4:1 F4:1 E4:1 D4:2"),
    ("Thank you for your gol|den light.",       "C4:1 C4:1 D4:1 E4:1 E4:1.5 D4:0.5 D4:2"),
    ("Birds are sing|ing in the tree,",         "E4:1 E4:1 F4:1 G4:1 G4:1 F4:1 E4:2"),
    ("A brand-new day for you and me!",         "C4:0.5 C4:0.5 D4:1 E4:1 E4:1 D4:1.5 C4:0.5 C4:2"),
]),
"song_009": dict(bpm=96, tune="original (lullaby)", lines=[
    ("Sleep|y moon is in the sky,",         "E4:1 G4:1 G4:1.5 E4:0.5 F4:1 E4:1 D4:2"),
    ("Stars are wink|ing way up high.",     "C4:1 E4:1 G4:1 A4:1 G4:1 F4:1 E4:2"),
    ("Close your eyes, my lit|tle dear,",   "F4:1 A4:1 A4:1 F4:1 G4:1 F4:1 E4:2"),
    ("Sweet dreams, good night is here!",   "G4:1 E4:0.75 R:0.25 F4:1 D4:1 D4:1 C4:3"),
]),
"song_010": dict(accomp_below_db=15, bpm=112, tune="original", lines=[
    ("Wash, wash, wash your lit|tle hands,",  "G4:1 G4:1 G4:1 E4:1 A4:1 A4:1 G4:2"),
    ("Rub-a-dub, bub|bles in my hands.",      "F4:0.5 F4:0.5 R:0.25 F4:0.5 R:0.25 A4:1 G4:1 E4:1 D4:1 C4:2"),
    ("Rinse them clean from left to right,",  "E4:1 E4:1 G4:1 E4:1 F4:1 E4:1 D4:2"),
    ("Hands so clean and feel|ing light!",    "E4:1 G4:1 F4:1 D4:1 E4:1 D4:0.75 R:0.25 C4:2"),
]),
}
