import SwiftUI

// MARK: - 单词卡 Tab：18 主题网格 → 点进主题看单词列表
struct WordCardsView: View {
    @Environment(DataStore.self) private var store

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(store.wordThemes) { theme in
                        NavigationLink {
                            ThemeWordsView(theme: theme)
                        } label: {
                            themeCard(theme)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("单词卡")
        }
    }

    private func themeCard(_ theme: WordTheme) -> some View {
        let words = store.words(forTheme: theme.id)
        let progress = store.themeProgress(themeId: theme.id)
        let firstWord = words.first?.word ?? theme.words.first ?? ""
        return VStack(spacing: 8) {
            WordIconView(word: firstWord, size: 80)
                .frame(height: 90)
            Text(theme.nameCn)
                .font(.title2).bold()
            Text(theme.nameEn)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(progress.done)/\(progress.total)")
                .font(.headline)
                .foregroundStyle(.orange)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color(.systemYellow).opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - 主题内单词列表
struct ThemeWordsView: View {
    @Environment(DataStore.self) private var store
    @State private var player = AudioPlayer()
    let theme: WordTheme

    var body: some View {
        List(store.words(forTheme: theme.id)) { entry in
            wordRow(entry)
                .padding(.vertical, 8)
        }
        .navigationTitle(theme.nameCn)
    }

    private func wordRow(_ entry: WordEntry) -> some View {
        HStack(spacing: 14) {
            WordIconView(word: entry.word, size: 60)
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.word)
                    .font(.title2).bold()
                Text(entry.meaningCn ?? "")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                if let url = store.bestAudioURL(forWord: entry.word) {
                    player.play(url: url)
                }
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(Color.orange)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
}
