import SwiftUI

/// 背单词 Tab：选词书 → 学习计划 → 今日新学（滑动卡片）→ 巩固练习入口
struct LearnWordsView: View {
    @Environment(DataStore.self) private var store
    @State private var player = AudioPlayer()

    /// 选词书 sheet
    @State private var showThemeSheet = false
    /// 今日学习的卡片队列
    @State private var todayWords: [WordEntry] = []
    /// 当前卡片下标
    @State private var cardIndex = 0
    /// 是否显示庆祝页
    @State private var finished = false
    /// 今天新学的词（用于巩固练习入口）
    @State private var learnedToday: [WordEntry] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. 选词书
                    Button {
                        showThemeSheet = true
                    } label: {
                        HStack {
                            Text("📚 \(currentThemeName)")
                                .font(.title2.bold())
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.title3)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // 2. 学习计划卡片
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📅 学习计划")
                            .font(.title2.bold())
                        HStack {
                            Text("每天新学")
                                .font(.title3)
                            Stepper("\(store.dailyNewWords) 个", value: .init(
                                get: { store.dailyNewWords },
                                set: { newValue in
                                    store.dailyNewWords = newValue
                                    store.saveProgress()
                                }
                            ), in: 5...20, step: 5)
                            .font(.title3)
                        }
                        Divider()
                        // 计划预览：前 3 天
                        let days = Array(store.planDays().prefix(3))
                        if days.isEmpty {
                            Text("全部学完啦，太棒了！🎉")
                                .font(.title3)
                        } else {
                            ForEach(days.indices, id: \.self) { i in
                                HStack {
                                    Text("Day\(i + 1)")
                                        .font(.title3.bold())
                                    Text("（\(days[i].count) 个）")
                                        .font(.title3)
                                    Spacer()
                                    Text(days[i].prefix(3).map { $0.word }.joined(separator: " · "))
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // 3. 今日新学
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🌟 今日新学")
                            .font(.title2.bold())
                            .padding(.horizontal)
                        if finished {
                            celebrationView
                        } else {
                            todayCardView
                        }
                    }

                    // 5. 巩固练习入口
                    NavigationLink {
                        ConsolidationView(words: learnedToday)
                    } label: {
                        Text("🎮 巩固练习")
                            .font(.title.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(learnedToday.isEmpty ? Color.gray : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                    .disabled(learnedToday.isEmpty)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("背单词")
            .sheet(isPresented: $showThemeSheet) {
                themeSheet
            }
            .onAppear {
                resetToday()
            }
            .onChange(of: store.selectedThemeId) { _, _ in
                resetToday()
            }
            .onChange(of: store.dailyNewWords) { _, _ in
                resetToday()
            }
        }
    }

    // MARK: - 今日学习卡片

    @ViewBuilder
    private var todayCardView: some View {
        if todayWords.isEmpty {
            Text("今天没有新单词啦，换一本词书或明天再来吧！😊")
                .font(.title3)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)
        } else {
            TabView(selection: $cardIndex) {
                ForEach(todayWords.indices, id: \.self) { i in
                    wordCard(todayWords[i])
                        .tag(i)
                }
            }
            .tabViewStyle(.page)
            .frame(height: 480)
            .onChange(of: cardIndex) { _, _ in
                // 滑动切换卡片时自动播慢速发音，帮助孩子跟读
                playBest()
            }
        }
    }

    private func wordCard(_ entry: WordEntry) -> some View {
        VStack(spacing: 14) {
            WordIconView(word: entry.word, size: 180)

            Text(entry.word)
                .font(.system(size: 52, weight: .bold))
            Text(entry.phonetic)
                .font(.title2)
                .foregroundColor(.secondary)
            Text(entry.meaningCn)
                .font(.title)
                .foregroundColor(.accentColor)

            HStack(spacing: 16) {
                Button {
                    playBest(for: entry)
                } label: {
                    Text("🔊 发音")
                        .font(.title2.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }

                if store.slowAudioURL(forWord: entry.word) != nil {
                    Button {
                        playSlow(for: entry)
                    } label: {
                        Text("🐢 慢速")
                            .font(.title2.bold())
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                }
            }

            Button {
                markKnown(entry)
            } label: {
                Text("认识了 →")
                    .font(.title2.bold())
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(20)
        .padding(.horizontal, 24)
    }

    // MARK: - 庆祝页

    private var celebrationView: some View {
        VStack(spacing: 20) {
            Text("🎉")
                .font(.system(size: 80))
            Text("今天学完啦！")
                .font(.largeTitle.bold())
            HStack(spacing: 16) {
                NavigationLink {
                    ConsolidationView(words: learnedToday)
                } label: {
                    Text("去巩固")
                        .font(.title2.bold())
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                Button {
                    resetToday()
                } label: {
                    Text("再看一遍")
                        .font(.title2.bold())
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(20)
        .padding(.horizontal)
    }

    // MARK: - 选词书 sheet

    private var themeSheet: some View {
        NavigationStack {
            List {
                Button {
                    store.selectedThemeId = nil
                    store.saveProgress()
                    showThemeSheet = false
                } label: {
                    HStack {
                        Text("📖 全部单词")
                            .font(.title2.bold())
                        Spacer()
                        if store.selectedThemeId == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                ForEach(store.wordThemes, id: \.id) { theme in
                    Button {
                        store.selectedThemeId = theme.id
                        store.saveProgress()
                        showThemeSheet = false
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(theme.nameCn)
                                    .font(.title2.bold())
                                Text(theme.nameEn)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            let (done, total) = store.themeProgress(themeId: theme.id)
                            Text("\(done)/\(total)")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            if store.selectedThemeId == theme.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            .navigationTitle("选词书")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - 逻辑

    private var currentThemeName: String {
        if let id = store.selectedThemeId,
           let theme = store.wordThemes.first(where: { $0.id == id }) {
            return theme.nameCn
        }
        return "全部单词"
    }

    private func resetToday() {
        todayWords = store.planDays().first ?? []
        learnedToday = []
        cardIndex = 0
        finished = false
        // 进入第一张卡时播发音
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            playBest()
        }
    }

    private func currentEntry() -> WordEntry? {
        guard todayWords.indices.contains(cardIndex) else { return nil }
        return todayWords[cardIndex]
    }

    private func markKnown(_ entry: WordEntry) {
        store.markLearned(entry.word)
        store.saveProgress()
        if !learnedToday.contains(where: { $0.word == entry.word }) {
            learnedToday.append(entry)
        }
        if cardIndex + 1 < todayWords.count {
            cardIndex += 1
        } else {
            finished = true
        }
    }

    private func playBest() {
        if let entry = currentEntry() {
            playBest(for: entry)
        }
    }

    private func playBest(for entry: WordEntry) {
        if let url = store.bestAudioURL(forWord: entry.word) {
            player.play(url: url)
        }
    }

    private func playSlow(for entry: WordEntry) {
        if let url = store.slowAudioURL(forWord: entry.word) {
            player.play(url: url)
        }
    }
}
