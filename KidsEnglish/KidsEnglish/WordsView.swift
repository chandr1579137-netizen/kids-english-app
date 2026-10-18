import SwiftUI

/// 单词详情弹窗
struct WordDetailView: View {
    @Environment(DataStore.self) private var store
    let entry: WordEntry
    @State private var player = AudioPlayer()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // 有词图就用词图；没有（her/his/its 这类功能词）退回 emoji，
                // 首字母灰块对孩子没有任何信息量。
                if store.iconURL(forWord: entry.word) == nil,
                   let emoji = entry.emoji, !emoji.isEmpty {
                    Text(emoji).kidFont(96)
                } else {
                    WordIconView(word: entry.word, size: 120)
                }
                Text(entry.word).kidFont(44, .bold)
                if let p = entry.phonetic {
                    Text(p).kidFont(20).foregroundColor(.secondary)
                }
                HStack {
                    if let pos = entry.partOfSpeech {
                        Text(pos).padding(6).background(Color.blue.opacity(0.15)).cornerRadius(8)
                    }
                    if let cn = entry.meaningCn {
                        Text(cn).kidFont(20, .bold)
                    }
                }
                if let exs = entry.examples, !exs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("例句").kidFont(17, .semibold)
                        ForEach(Array(exs.enumerated()), id: \.offset) { _, ex in
                            Text("• \(ex)").kidFont(17).foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                HStack(spacing: 20) {
                    Button {
                        if let url = store.audioURL(forWord: entry.word) { player.play(url: url) }
                    } label: {
                        Label("🔊 发音", systemImage: "speaker.wave.2.fill")
                    }
                    .buttonStyle(.borderedProminent).tint(.blue)

                    Button {
                        let k = entry.word.lowercased()
                        if store.favoriteWords.contains(k) {
                            store.favoriteWords.remove(k)
                        } else {
                            store.favoriteWords.insert(k)
                        }
                        store.saveProgress()
                    } label: {
                        Label(
                            store.favoriteWords.contains(entry.word.lowercased()) ? "已收藏" : "收藏",
                            systemImage: store.favoriteWords.contains(entry.word.lowercased()) ? "star.fill" : "star"
                        )
                    }
                    .buttonStyle(.borderedProminent).tint(.orange)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("单词卡")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}
