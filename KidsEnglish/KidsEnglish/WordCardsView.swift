import SwiftUI

// MARK: - 单词卡：按主题找单词
struct WordCardsView: View {
    var embedded: Bool = false
    @Environment(DataStore.self) private var store
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        Group {
            if embedded {
                cardsContent
                    .navigationTitle("单词卡")
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                NavigationStack {
                    cardsContent
                        .toolbar(.hidden, for: .navigationBar)
                }
            }
        }
    }

    private var cardsContent: some View {
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

// MARK: - 4 岁图画

struct Age4PicturesView: View {
    @Environment(DataStore.self) private var store
    @State private var lockedMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("图画")
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundStyle(AppTheme.navy)
                        .padding(.horizontal)
                    Text("先听这 8 组")
                        .font(.title3.bold())
                        .foregroundStyle(.gray)
                        .padding(.horizontal)
                    ForEach(store.age4UnlockedPacks()) { pack in
                        NavigationLink {
                            Age4PackStudyView(pack: pack)
                        } label: {
                            packRow(pack, locked: false)
                        }
                        .buttonStyle(PressableStyle())
                    }
                    Text("下一轮")
                        .font(.title3.bold())
                        .foregroundStyle(.gray)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    ForEach(store.age4LockedPacks()) { pack in
                        Button {
                            lockedMessage = "先学完前面的图画"
                        } label: {
                            packRow(pack, locked: true)
                        }
                        .buttonStyle(PressableStyle())
                    }
                    if !lockedMessage.isEmpty {
                        Text(lockedMessage)
                            .font(.headline.bold())
                            .foregroundStyle(.orange)
                            .padding(.horizontal)
                    }
                    Text("图画故事")
                        .font(.title3.bold())
                        .foregroundStyle(.gray)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    ForEach(store.childLessons()) { lesson in
                        NavigationLink {
                            PictureBookReaderView(lesson: lesson)
                        } label: {
                            HStack(spacing: 12) {
                                CoverImage(url: store.coverURL(forLesson: lesson.id), emoji: store.coverEmoji(for: lesson.id))
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(lesson.titleCn)
                                        .font(.headline.bold())
                                        .foregroundStyle(AppTheme.navy)
                                    Text("\(lesson.content.count) 页")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.gray)
                            }
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(PressableStyle())
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
            }
            .creamBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func packRow(_ pack: Age4Pack, locked: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(pack.nameCn)
                    .font(.title3.bold())
                    .foregroundStyle(locked ? Color.gray : AppTheme.navy)
                Text(pack.pattern)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                Text("\(pack.words.count) 个")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }
            Spacer()
            if locked {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.gray)
            } else {
                HStack(spacing: 4) {
                    ForEach(Array(pack.words.prefix(3)), id: \.self) { word in
                        WordIconView(word: word, size: 36)
                    }
                }
                Image(systemName: "chevron.right")
                    .foregroundStyle(.gray)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal)
    }
}

struct Age4PackStudyView: View {
    @Environment(DataStore.self) private var store
    private let player = AudioPlayer.shared
    let pack: Age4Pack

    @State private var index = 0
    @State private var known = 0

    private var entries: [WordEntry] { store.age4PackWords(pack) }

    var body: some View {
        VStack(spacing: 16) {
            if entries.isEmpty {
                Text("这一组还没有图画")
                    .font(.title2.bold())
            } else {
                let entry = entries[min(index, entries.count - 1)]
                Text("\(pack.nameCn) · \(index + 1)/\(entries.count)")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.brightBlue)
                WordIconView(word: entry.word, size: 180)
                Text(entry.word)
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundStyle(AppTheme.navy)
                Text(store.age4Sentence(for: entry))
                    .font(.title2.bold())
                    .foregroundStyle(.orange)
                if let cn = entry.meaningCn, !cn.isEmpty {
                    Text(cn)
                        .font(.title3)
                        .foregroundStyle(.gray)
                }
                HStack(spacing: 12) {
                    Button("不认识") {
                        store.markWrong(entry.word)
                        advance()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    Button("认识") {
                        store.markLearned(entry.word)
                        known += 1
                        advance()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .font(.title3.bold())
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .creamBackground()
        .navigationTitle(pack.nameCn)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { speakCurrent() }
        .onDisappear { player.stop() }
    }

    private func advance() {
        if index + 1 < entries.count {
            index += 1
            speakCurrent()
        }
    }

    private func speakCurrent() {
        guard entries.indices.contains(index) else { return }
        let entry = entries[index]
        player.play(url: store.bestAudioURL(forWord: entry.word), spokenFallback: entry.word)
    }
}
