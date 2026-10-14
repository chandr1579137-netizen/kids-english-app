import SwiftUI

// MARK: - 单词卡 Tab：18 主题彩色网格 → 点进主题看单词列表
struct WordCardsView: View {
    @Environment(DataStore.self) private var store

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    Text("单词卡")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundColor(AppTheme.navy)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    Text("按主题找单词")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.bottom, 12)
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
                    .padding(.horizontal)
                }
            }
            .creamBackground()
        }
    }

    private func themeCard(_ theme: WordTheme) -> some View {
        let progress = store.themeProgress(themeId: theme.id)
        let color = AppTheme.colorForTheme(theme.id)
        return HStack {
            VStack(alignment: .leading, spacing: 6) {
                uiIcon(themeIconName(for: theme.id))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 52, height: 52)
                Text(theme.nameCn)
                    .font(.headline.bold())
                    .foregroundColor(.black.opacity(0.8))
            }
            Spacer()
            Text("\(progress.done)/\(progress.total) ✓")
                .font(.subheadline.bold())
                .foregroundColor(color)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.35))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }
}

// MARK: - 主题内单词列表
struct ThemeWordsView: View {
    @Environment(DataStore.self) private var store
    @State private var player = AudioPlayer()
    let theme: WordTheme

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.words(forTheme: theme.id)) { entry in
                    wordRow(entry)
                }
            }
            .padding()
        }
        .creamBackground()
        .navigationTitle(theme.nameCn)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func wordRow(_ entry: WordEntry) -> some View {
        HStack(spacing: 14) {
            WordIconView(word: entry.word, size: 64)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.word)
                    .font(.title2.bold())
                    .foregroundColor(AppTheme.brightBlue)
                Text(entry.meaningCn ?? "")
                    .font(.headline)
                    .foregroundColor(AppTheme.wordOrange)
            }
            Spacer()
            Button {
                if let url = store.bestAudioURL(forWord: entry.word) {
                    player.play(url: url)
                }
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.orange)
                    .clipShape(Circle())
                    .shadow(color: .orange.opacity(0.3), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .whiteCard()
    }
}
