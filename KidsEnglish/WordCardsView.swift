import SwiftUI

// MARK: - 单词卡 Tab：主题彩色网格 → 点进主题看单词列表
struct WordCardsView: View {
    @Environment(DataStore.self) private var store

    private let columns = [GridItem(.flexible(), spacing: 12),
                           GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            KidScrollView {
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
            .coolBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func themeCard(_ theme: WordTheme) -> some View {
        let progress = store.themeProgress(themeId: theme.id)
        let isComplete = progress.total > 0 && progress.done >= progress.total

        // 参考图是横向长条：图标在左、名称居中偏左、进度靠右，底色为柔和渐变
        return HStack(spacing: 8) {
            uiIcon(themeIconName(for: theme.id))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 38, height: 38)

            Text(shortThemeName(theme.nameCn))
                .kidFont(17, .bold, maxScale: 1.1)
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .layoutPriority(1)

            Spacer(minLength: 2)

            // 勾只在「真的学完」时出现 —— 原来 6/6 和 12/67 都打勾，语义失效
            HStack(spacing: 3) {
                Text("\(progress.done)/\(progress.total)")
                    .kidFont(15, .bold, maxScale: 1.1)
                    .foregroundStyle(isComplete ? Func.positiveDeep : Func.accentVivid)
                if isComplete {
                    Image(systemName: "checkmark")
                        .kidFont(13, .black)
                        .foregroundStyle(Func.positiveDeep)
                }
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 62)
        // 渐变底，文字压在最浅处仍保持 9:1 以上
        .background(AppTheme.gradientForTheme(theme.id),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .elevationGround()
    }
}

// MARK: - 主题内单词列表

struct ThemeWordsView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var player = AudioPlayer()
    let theme: WordTheme

    private var words: [WordEntry] { store.words(forTheme: theme.id) }

    var body: some View {
        KidScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SubPageHeader(onBack: { dismiss() })

                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.nameCn)
                        .subPageTitleStyle()
                    Text("\(words.count) 个单词 · 点右侧喇叭听发音")
                        .subPageSubtitleStyle()
                }
                .padding(.horizontal)

                LazyVStack(spacing: 12) {
                    ForEach(words) { entry in
                        wordRow(entry)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 2)
            }
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .coolBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    private func wordRow(_ entry: WordEntry) -> some View {
        HStack(spacing: 14) {
            WordIconView(word: entry.word, size: 64)
                .background(Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.thumb))
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.word)
                    .kidFont(22, .bold)
                    .foregroundStyle(Func.infoDeep)
                Text(entry.meaningCn ?? "")
                    .kidFont(16, .semibold)
                    .foregroundStyle(Func.accentDeep)   // 16pt 属小字，需 ≥4.5:1
            }
            Spacer()
            Button {
                if let url = store.bestAudioURL(forWord: entry.word) {
                    player.play(url: url)
                }
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .kidFont(24, .semibold)
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
