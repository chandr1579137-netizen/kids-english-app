import SwiftUI

/// 儿歌页：原创英文儿歌 + 配音 + 双语歌词。
///
/// 原来是系统 `List` + `.navigationTitle`，和主流程（自绘顶栏 + 白卡 + 糖果按钮）
/// 不是一套语言；这里改成与其他页一致的卡片列表。
struct SongsView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var player = AudioPlayer()
    @State private var playingSong: String?
    @State private var expandedSong: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SubPageHeader(onBack: { dismiss() })

                VStack(alignment: .leading, spacing: 4) {
                    Text("英文儿歌")
                        .subPageTitleStyle()
                    Text("\(store.songs.count) 首原创儿歌 · 点歌名看歌词")
                        .subPageSubtitleStyle()
                }
                .padding(.horizontal)

                LazyVStack(spacing: 12) {
                    ForEach(store.songs) { song in
                        songCard(song)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 2)
            }
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .creamBackground()
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear { player.stop() }
    }

    // MARK: - 单首歌

    private func songCard(_ song: Song) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Func.accent.opacity(0.18))
                        .frame(width: 48, height: 48)
                    Image(systemName: "music.note")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Func.accentDeep)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(song.titleCn)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Palette.inkMuted)
                }

                Spacer(minLength: 6)

                Button {
                    togglePlay(song)
                } label: {
                    Image(systemName: playingSong == song.id ? "pause.fill" : "play.fill")
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Func.accent, in: Circle())
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(playingSong == song.id ? "暂停" : "播放")
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.2)) {
                    expandedSong = (expandedSong == song.id) ? nil : song.id
                }
            }

            if expandedSong == song.id {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(song.lines.enumerated()), id: \.offset) { _, line in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(line.en)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Palette.ink)
                            Text(line.cn)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Palette.inkMuted)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Palette.canvasCool,
                            in: RoundedRectangle(cornerRadius: Radius.thumb, style: .continuous))
            }
        }
        .padding(14)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .elevationGround()
    }

    // MARK: - 播放

    private func togglePlay(_ song: Song) {
        if playingSong == song.id {
            player.pause()
            playingSong = nil
            return
        }
        guard let url = store.songAudioURL(song.id) else { return }
        playingSong = song.id
        expandedSong = song.id
        player.onTimeUpdate = { t in
            if t > 900000 {
                playingSong = nil
            }
        }
        player.play(url: url)
    }
}
