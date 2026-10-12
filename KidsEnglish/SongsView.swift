import SwiftUI

/// 儿歌页：原创英文儿歌 + 配音 + 双语歌词
struct SongsView: View {
    @Environment(DataStore.self) private var store
    @State private var player = AudioPlayer()
    @State private var playingSong: String?
    @State private var expandedSong: String?

    var body: some View {
        NavigationStack {
            List(store.songs) { song in
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
                            Image(systemName: playingSong == song.id ? "pause.circle.fill" : "play.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                        }
                        .buttonStyle(.plain)
                    }
                    .onTapGesture {
                        withAnimation {
                            expandedSong = (expandedSong == song.id) ? nil : song.id
                        }
                    }

                    if expandedSong == song.id {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(song.lines.enumerated()), id: \.offset) { _, line in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(line.en).font(.body.bold())
                                    Text(line.cn).font(.caption).foregroundColor(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding(.vertical, 4)
            }
            .listStyle(.plain)
            .navigationTitle("🎶 儿歌时间")
        }
        .onDisappear { player.stop() }
    }

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
