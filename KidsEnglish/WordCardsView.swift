import SwiftUI

// MARK: - 单词卡：按主题找单词
struct WordCardsView: View {
    @Environment(DataStore.self) private var store
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    Text("单词卡")
                        .font(.system(size: 48, weight: .heavy))
                        .foregroundStyle(AppTheme.navy)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    Text("按主题找单词")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.gray)
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    LazyVGrid(columns: columns, spacing: 14) {
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
                    .padding(.bottom, 12)
                }
            }
            .creamBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func themeCard(_ theme: WordTheme) -> some View {
        let progress = store.themeProgress(themeId: theme.id)
        let doneAll = progress.total > 0 && progress.done == progress.total
        return ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                uiIcon(themeIconName(for: theme.id))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                Text(theme.nameCn)
                    .font(.headline.bold())
                    .foregroundStyle(Color.black.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            Text(doneAll ? "\(progress.done)/\(progress.total) ✓" : "\(progress.done)/\(progress.total)")
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.colorForTheme(theme.id))
        }
        .padding(14)
        .frame(height: 132)
        .background { themeBackground(theme.id) }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }

    @ViewBuilder
    private func themeBackground(_ id: String) -> some View {
        if id == "colors" {
            LinearGradient(
                colors: [.pink, .orange, .yellow, .green, .cyan, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.55)
        } else {
            AppTheme.colorForTheme(id).opacity(0.38)
        }
    }
}

// MARK: - 主题闪卡
struct ThemeWordsView: View {
    @Environment(DataStore.self) private var store
    private let player = AudioPlayer.shared
    let theme: WordTheme

    @State private var index = 0
    @State private var forwards = true
    @State private var showSuccess = false
    @State private var successTick = 0

    private var entries: [WordEntry] { store.words(forTheme: theme.id) }

    var body: some View {
        VStack(spacing: 16) {
            if entries.isEmpty {
                Text("这个主题还没有单词")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.navy)
            } else {
                let entry = entries[min(index, entries.count - 1)]
                let done = entries.filter { store.learnedWords.contains($0.id) }.count
                Text("\(done)/\(entries.count)")
                    .font(.headline.bold())
                    .foregroundStyle(.orange)
                FlashCardFace(entry: entry)
                    .padding(.horizontal, 18)
                    .id(entry.id)
                    .transition(.asymmetric(
                        insertion: .move(edge: forwards ? .trailing : .leading).combined(with: .opacity),
                        removal: .move(edge: forwards ? .leading : .trailing).combined(with: .opacity)
                    ))
                    .overlay {
                        if showSuccess {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 100))
                                .foregroundStyle(.green)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                WordAudioButtons(player: player, entry: entry)
                HStack(spacing: 10) {
                    themeButton("← 上一个", color: AppTheme.grayBtn) { step(-1) }
                    themeButton(store.learnedWords.contains(entry.id) ? "已认识 ✓" : "认识 ✓", color: AppTheme.green) {
                        know(entry)
                    }
                    themeButton("下一个 →", color: AppTheme.brightBlue) { step(1) }
                }
                .padding(.horizontal, 16)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .creamBackground()
        .navigationTitle(theme.nameCn)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .animation(Motion.spring, value: index)
        .animation(Motion.spring, value: showSuccess)
        .sensoryFeedback(.success, trigger: successTick)
        .onDisappear { player.stop() }
    }

    private func themeButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressableStyle())
    }

    private func step(_ delta: Int) {
        guard !entries.isEmpty else { return }
        forwards = delta > 0
        withAnimation(Motion.spring) {
            index = (index + delta + entries.count) % entries.count
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let entry = entries[index]
            player.play(url: store.bestAudioURL(forWord: entry.word), spokenFallback: entry.word)
        }
    }

    private func know(_ entry: WordEntry) {
        store.markLearned(entry.word)
        store.saveProgress()
        successTick += 1
        withAnimation(Motion.spring) { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(Motion.spring) { showSuccess = false }
            if entries.count > 1 { step(1) }
        }
    }
}
