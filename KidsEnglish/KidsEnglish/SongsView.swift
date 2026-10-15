import SwiftUI

/// 儿歌：有 mp3 就播文件并按进度点亮歌词；没有就逐句朗读。
struct SongsView: View {
    var childMode: Bool = false
    var focusSongId: String? = nil
    @Environment(DataStore.self) private var store
    private let player = AudioPlayer.shared
    @State private var playingSong: String?
    @State private var expandedSong: String?
    @State private var activeLine: Int?
    @State private var paused = false

    var body: some View {
        List {
            if childMode {
                Section {
                    ForEach(store.childSongs()) { song in
                        songBlock(song, locked: false)
                    }
                }
                Section {
                    ForEach(store.laterSongs()) { song in
                        songBlock(song, locked: true)
                    }
                }
            } else {
                ForEach(store.songs) { song in
                    songBlock(song, locked: false)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(childMode ? "儿歌" : "英文儿歌")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if expandedSong == nil, let focusSongId {
                expandedSong = focusSongId
            }
        }
        .onDisappear {
            player.stop()
            playingSong = nil
            activeLine = nil
            paused = false
        }
    }

    @ViewBuilder
    private func songBlock(_ song: Song, locked: Bool) -> some View {
        if locked {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.gray)
                VStack(alignment: .leading) {
                    Text(song.title).font(.headline).foregroundStyle(.gray)
                    Text(song.titleCn).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text("以后再唱")
                    .font(.caption.bold())
                    .foregroundStyle(.gray)
            }
            .padding(.vertical, 4)
        } else {
            songRow(song)
        }
    }

    private func songRow(_ song: Song) -> some View {
        VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🎵").font(.title)
                    VStack(alignment: .leading) {
                        Text(song.title).font(.headline)
                        Text(song.titleCn).font(.subheadline).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        togglePlay(song)
                    } label: {
                        Image(systemName: playingSong == song.id && !paused
                              ? "pause.circle.fill" : "play.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(PressableStyle())
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(Motion.spring) {
                        expandedSong = (expandedSong == song.id) ? nil : song.id
                    }
                }

                if expandedSong == song.id {
                    VStack(alignment: .leading, spacing: 6) {
                        if playingSong == song.id {
                            Text(paused ? "已暂停" : "正在播放")
                                .font(.caption.bold())
                                .foregroundStyle(.orange)
                        }
                        ForEach(Array(song.lines.enumerated()), id: \.offset) { index, line in
                            let hot = playingSong == song.id && activeLine == index
                            VStack(alignment: .leading, spacing: 2) {
                                Text(line.en).font(.body.bold())
                                Text(line.cn).font(.caption).foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(hot ? Color.orange.opacity(0.22) : Color.clear)
                            )
                        }
                    }
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func togglePlay(_ song: Song) {
        if playingSong == song.id {
            if paused {
                player.resume()
                paused = false
            } else {
                player.pause()
                paused = true
            }
            return
        }
        playingSong = song.id
        paused = false
        expandedSong = song.id
        activeLine = 0
        let lines = song.lines.map(\.en)
        if let url = store.songAudioURL(song.id) {
            let count = max(lines.count, 1)
            player.onFinish = {
                playingSong = nil
                activeLine = nil
                paused = false
            }
            player.onTimeUpdate = { t in
                let dur = max(player.duration, 0.01)
                let idx = min(count - 1, max(0, Int((t / dur) * Double(count))))
                activeLine = idx
            }
            player.play(url: url, spokenFallback: lines.joined(separator: ". "))
        } else {
            player.playLines(lines, onLine: { index in
                activeLine = index
            }, onFinish: {
                playingSong = nil
                activeLine = nil
                paused = false
            })
        }
    }

