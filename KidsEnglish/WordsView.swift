import SwiftUI

/// 单词页：分级浏览 + 闪卡 + 收藏
struct WordsView: View {
    @Environment(DataStore.self) private var store
    @State private var level = 1
    @State private var selectedWord: WordEntry?
    @State private var showFavoritesOnly = false
    @State private var player = AudioPlayer()

    var filtered: [WordEntry] {
        var list = store.words.filter { ($0.level ?? 1) == level }
        if showFavoritesOnly {
            list = list.filter { store.favoriteWords.contains($0.word.lowercased()) }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            VStack {
                // 等级选择
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(1...7, id: \.self) { lv in
                            Button("L\(lv)") { level = lv }
                                .buttonStyle(.borderedProminent)
                                .tint(level == lv ? .orange : .gray)
                        }
                        Button(showFavoritesOnly ? "⭐ 收藏中" : "☆ 收藏") {
                            showFavoritesOnly.toggle()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                }

                List(filtered) { w in
                    HStack {
                        Button {
                            selectedWord = w
                        } label: {
                            HStack {
                                Text(w.emoji ?? "📝").font(.title)
                                VStack(alignment: .leading) {
                                    Text(w.word).font(.headline)
                                    Text(w.meaningCn ?? "").font(.subheadline).foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)

                        Button {
                            playWord(w)
                        } label: {
                            Image(systemName: "speaker.wave.2.fill").foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("📚 单词乐园")
            .sheet(item: $selectedWord) { entry in
                WordDetailView(entry: entry)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func playWord(_ w: WordEntry) {
        if let url = store.audioURL(forWord: w.word) {
            player.play(url: url)
        }
    }
}

/// 单词详情弹窗
struct WordDetailView: View {
    @Environment(DataStore.self) private var store
    let entry: WordEntry
    @State private var player = AudioPlayer()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // 用真实词图代替 emoji：emoji 语料里有 356 条是 📘 占位，
                // 80pt 的蓝皮书顶在弹窗最上面比没有图更糟。
                WordIconView(word: entry.word, size: 120)
                Text(entry.word).font(.system(size: 44, weight: .bold))
                if let p = entry.phonetic {
                    Text(p).font(.title3).foregroundColor(.secondary)
                }
                HStack {
                    if let pos = entry.partOfSpeech {
                        Text(pos).padding(6).background(Color.blue.opacity(0.15)).cornerRadius(8)
                    }
                    if let cn = entry.meaningCn {
                        Text(cn).font(.title3.bold())
                    }
                }
                if let exs = entry.examples, !exs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("例句").font(.headline)
                        ForEach(Array(exs.enumerated()), id: \.offset) { _, ex in
                            Text("• \(ex)").font(.body).foregroundColor(.secondary)
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
