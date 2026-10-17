import SwiftUI

// MARK: - 单词卡 Tab：主题彩色网格 → 点进主题看单词列表
struct WordCardsView: View {
    @Environment(DataStore.self) private var store

    private let columns = [GridItem(.flexible(), spacing: 12),
                           GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    Text("单词卡").pageTitleStyle()
                        .padding(.horizontal)
                        .padding(.top, 4)
                    Text("按主题找单词")
                        .pageSubtitleStyle()
                        .padding(.horizontal)
                        .padding(.bottom, 14)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(store.wordThemes) { theme in
                            NavigationLink {
                                ThemeWordsView(theme: theme)
                            } label: {
                                themeCard(theme)
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 12)
            }
            .creamBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func themeCard(_ theme: WordTheme) -> some View {
        let progress = store.themeProgress(themeId: theme.id)
        let fill = AppTheme.colorForTheme(theme.id)
        let isComplete = progress.total > 0 && progress.done >= progress.total

        // 三段式：图标左上 / 进度右上 / 名称底部 —— 名称独占整行，不再被进度挤断
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 6) {
                IconPlate(name: themeIconName(for: theme.id),
                          iconSize: 30, plateSize: 42, corner: 12)
                Spacer(minLength: 0)
                // 勾只在「真的学完」时出现 —— 原来 6/6 和 12/67 都打勾，语义失效
                HStack(spacing: 3) {
                    Text("\(progress.done)/\(progress.total)")
                        .font(.system(size: 13, weight: .bold))
                    if isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                    }
                }
                .foregroundStyle(isComplete ? Func.positiveDeep : Palette.inkMuted)
                .padding(.top, 2)
            }

            Text(theme.nameCn)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Palette.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        // 分类色只作底，永不作文字色 —— 浅底保证深字 9–14:1
        .background(fill.opacity(0.35), in: RoundedRectangle(cornerRadius: Radius.card))
        .elevationGround()
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
                .background(Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.thumb))
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.word)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Func.infoDeep)
                Text(entry.meaningCn ?? "")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Func.accentDeep)   // 16pt 属小字，需 ≥4.5:1
            }
            Spacer()
            Button {
                if let url = store.bestAudioURL(forWord: entry.word) {
                    player.play(url: url)
                }
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Palette.inkOnColor)
                    .frame(width: 54, height: 54)
                    .background(Func.accent, in: Circle())
                    .candyEdge(27)
            }
            .buttonStyle(PressableStyle())
        }
        .padding(12)
        .whiteCard()
    }
}
