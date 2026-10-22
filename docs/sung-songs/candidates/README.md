# 没过验收的演唱候选

这 4 首（001、002、006、010）的演唱版没通过三个模型的语音识别验收，App 里仍用朗读版，不再继续试。这里放每首最好的一版，供试听和以后接着改：

- `<id>_best.mp3`：成品混音（不打包进 App）
- `<id>/song_specs.py`、`<id>/diction.json`：这一版的谱和吐字表（重做：`render_song.py <id> --specs ... --diction ...`）
- `<id>/<id>.ustx`：OpenUtau 工程
- `<id>/asr.json`：三个模型的识别结果

没听对的词见 [`../../sung-songs.md`](../../sung-songs.md)。
