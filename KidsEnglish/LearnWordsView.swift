import SwiftUI

/// 背单词 Tab：首页（今日计划 / 选词书 / 开始学习）→ 学习页（tab 内切换，保留底栏）
struct LearnWordsView: View {
    @Environment(DataStore.self) private var store
    @State private var player = AudioPlayer()

    /// 今日学习的卡片队列
    @State private var todayWords: [WordEntry] = []
    /// 当前卡片下标
    @State private var cardIndex = 0
    /// 是否显示庆祝页
    @State private var finished = false
    /// 今天新学的词（用于巩固练习入口）
    @State private var learnedToday: [WordEntry] = []
    /// 是否处于学习页（tab 内切换，不是全屏覆盖，这样底栏保留）
    @State private var showStudy = LaunchOptions.forceStudy
    /// 是否跳转巩固练习
    @State private var goConsolidate = false

    var body: some View {
        NavigationStack {
            Group {
                if showStudy {
                    studyContent
                } else {
                    homeContent
                }
            }
            .creamBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                refreshToday()
            }
            .onChange(of: store.selectedThemeId) { _, _ in
                refreshToday()
            }
            .onChange(of: store.dailyNewWords) { _, _ in
                refreshToday()
            }
            .navigationDestination(isPresented: $goConsolidate) {
                ConsolidationView(words: learnedToday.isEmpty ? todayWords : learnedToday)
            }
        }
    }

    // MARK: - 首页

    private var homeContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 统一页面骨架：大标题 + 副标题（其余 4 个 tab 同构）
                VStack(alignment: .leading, spacing: 2) {
                    Text("背单词").pageTitleStyle()
                    Text("每天一点点，越学越顺")
                        .pageSubtitleStyle()
                }
                .padding(.horizontal)
                .padding(.top, 4)

                // 今日计划（橙色渐变，唯一允许渐变的分类外卡片之一）
                planCard
                    .padding(.horizontal)

                // 选词书
                VStack(alignment: .leading, spacing: 12) {
                    Text("选词书")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            // 「全部单词」是聚合项，不是分类 —— 用中性底区分层级
                            allWordsCard
                            // 词数一律读真实数据，不再写死（原来 6/49/7 与数据 9/80/36 不符）
                            bookCard(themeId: "fruits", title: "水果篇",
                                     subtitle: "\(store.words(forTheme: "fruits").count) 词",
                                     iconName: "strawberry")
                            bookCard(themeId: "animals", title: "动物篇",
                                     subtitle: "\(store.words(forTheme: "animals").count) 词",
                                     iconName: "panda")
                            bookCard(themeId: "vehicles", title: "交通工具",
                                     subtitle: "\(store.words(forTheme: "vehicles").count) 词",
                                     iconName: "bus")
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 3)
                    }
                }

                // 主 CTA —— 必须落在首屏。上面任何卡片都不许把它挤下去
                VStack(spacing: 12) {
                    AppButton(title: "开始学习", icon: "play.fill", tier: .primary) {
                        startStudy()
                    }
                    AppButton(title: "巩固练习", icon: "square.grid.2x2.fill", tier: .secondary) {
                        goConsolidate = true
                    }
                }
                .padding(.horizontal)
                .padding(.top, 2)

                // 每天新学 —— 放在主 CTA 之后：它是设置项，不该把主操作挤出首屏
                HStack {
                    Text("每天新学")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Stepper("\(store.dailyNewWords) 个", value: .init(
                        get: { store.dailyNewWords },
                        set: { newValue in
                            store.dailyNewWords = newValue
                            store.saveProgress()
                        }
                    ), in: 5...20, step: 5)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.inkMuted)
                }
                .padding()
                .whiteCard()
                .padding(.horizontal)

                // 学习安排预览
                planPreviewCard
                    .padding(.horizontal)
            }
            .padding(.vertical, 12)
        }
    }

    // MARK: - 今日计划卡

    private var planCard: some View {
        // 橙色是童趣的一部分，不动色值；只把文字色交给 onFill 自动判定
        let fg = onFill(AppTheme.planBase)   // 亮橙 → 深墨字，8.1:1
        return HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("今日计划")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(fg.opacity(0.82))
                Text("Day \(dayNumber)")
                    .font(.system(size: 38, weight: .heavy))
                    .foregroundStyle(fg)
                Text("新学 \(todayWords.count) 个词")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(fg)
                Text("已学 \(store.learnedWords.count) / \(store.words.count)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(fg.opacity(0.78))
            }
            Spacer()
            IconPlate(name: "rocket", iconSize: 66, plateSize: 86, corner: 24)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(AppTheme.planGradient, in: RoundedRectangle(cornerRadius: Radius.sheet))
        .elevationRaised()
    }

    private var dayNumber: Int {
        let perDay = max(1, store.dailyNewWords)
        return store.learnedWords.count / perDay + 1
    }

    // MARK: - 选词书卡片

    /// 聚合项：中性底，靠层级而非颜色区分
    private var allWordsCard: some View {
        let isSelected = store.selectedThemeId == nil
        return Button {
            store.selectedThemeId = nil
            store.saveProgress()
        } label: {
            VStack(spacing: 8) {
                IconPlate(name: "book", iconSize: 44, plateSize: 60, corner: 18)
                Text("全部单词")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Palette.ink)
                Text("\(store.words.count) 词")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Palette.inkMuted)
            }
            .frame(width: 130, height: 150)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .strokeBorder(Palette.hairline, lineWidth: 1.5)
            )
            .elevationGround()
            .selectionRing(isSelected, radius: Radius.card)
            .scaleEffect(isSelected ? 1.03 : 1.0)
        }
        .buttonStyle(PressableStyle())
    }

    /// 分类卡：满饱和底 + 自动对比文字（保住截图的颜色，修掉白字不可读）
    private func bookCard(themeId: String, title: String, subtitle: String, iconName: String) -> some View {
        let fill = AppTheme.colorForTheme(themeId)
        let fg = onFill(fill)
        let isSelected = store.selectedThemeId == themeId
        return Button {
            store.selectedThemeId = themeId
            store.saveProgress()
        } label: {
            VStack(spacing: 8) {
                IconPlate(name: iconName, iconSize: 44, plateSize: 60, corner: 18)
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(fg)
                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(fg.opacity(0.85))
            }
            .frame(width: 130, height: 150)
            .background(fill, in: RoundedRectangle(cornerRadius: Radius.card))
            .elevationGround()
            .selectionRing(isSelected, radius: Radius.card)
            .scaleEffect(isSelected ? 1.03 : 1.0)
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: - 学习安排预览

    private var planPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习安排")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(Palette.ink)
            let days = Array(store.planDays().prefix(3))
            if days.isEmpty {
                Text("全部学完啦，太棒了！🎉")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Palette.inkMuted)
            } else {
                ForEach(days.indices, id: \.self) { i in
                    HStack {
                        Text("Day\(i + 1)")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(i == 0 ? Func.accent : Palette.ink)
                            .frame(width: 70, alignment: .leading)
                        Text(days[i].prefix(3).map { $0.word }.joined(separator: " · "))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Palette.inkMuted)
                            .lineLimit(1)
                        Spacer()
                        Text("\(days[i].count)词")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(i == 0 ? Palette.inkOnColor : Palette.inkMuted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                (i == 0 ? Func.accent.opacity(0.55) : Palette.hairline),
                                in: Capsule()
                            )
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(20)
        .whiteCard()
    }

    // MARK: - 学习页（tab 内切换，保留底栏）

    private var studyContent: some View {
        ScrollView {
            VStack(spacing: 14) {
                if finished {
                    celebrationView
                } else if todayWords.isEmpty {
                    emptyStudyCard
                } else {
                    studyHeader
                    studyProgress
                    if todayWords.indices.contains(cardIndex) {
                        wordCard(todayWords[cardIndex])
                    }
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 24)   // 学习页底部有 tab bar，12 太贴
        }
    }

    private var emptyStudyCard: some View {
        Text("今天没有新单词啦，换一本词书或明天再来吧！😊")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(Palette.inkMuted)
            .multilineTextAlignment(.center)
            .padding()
            .whiteCard()
            .padding()
    }

    /// 头部：标题只说页面身份，「第几个」交给下面的进度条表达，不重复
    private var studyHeader: some View {
        HStack {
            Button {
                showStudy = false
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("返回")

            Text("背单词")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(Palette.ink)

            Spacer()

            Button {
                playBest()
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Func.infoDeep)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("再听一遍")
        }
        .padding(.horizontal, 12)
    }

    /// 进度：几何与终态一致，不闪跳
    private var studyProgress: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // 轨道要看得见：hairline 与页面底只差 1.1:1，等于没有
                    Capsule().fill(Color(red: 0.82, green: 0.78, blue: 0.71))
                    Capsule()
                        .fill(Func.accent)
                        .frame(width: geo.size.width * progressFraction)
                }
            }
            .frame(height: 10)

            Text("学习进度 \(cardIndex + 1)/\(todayWords.count)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Func.accentDeep)   // 小字必须 ≥4.5:1
        }
        .padding(.horizontal, 20)
    }

    private var progressFraction: Double {
        guard !todayWords.isEmpty else { return 0 }
        return Double(cardIndex + 1) / Double(todayWords.count)
    }

    private func wordCard(_ entry: WordEntry) -> some View {
        VStack(spacing: 14) {
            WordIconView(word: entry.word, size: 180)

            Text(entry.word)
                .font(.system(size: 56, weight: .heavy))
                .foregroundStyle(Func.infoDeep)
            Text(entry.phonetic ?? "")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Palette.inkMuted)
            Text(entry.meaningCn ?? "")
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(Func.accentVivid)   // 大字 ≥3:1，且不发褐

            // 发音：两个并列的次要操作，同层级
            // 「慢速」始终显示 —— 无预生成慢速文件时走同一音频 0.7 倍速
            HStack(spacing: 14) {
                AppButton(title: "正常", icon: "speaker.wave.2.fill", tier: .secondary) {
                    playBest(for: entry)
                }
                AppButton(title: "慢速", icon: "tortoise.fill", tier: .secondary) {
                    playSlow(for: entry)
                }
            }
            .padding(.top, 4)

            // 判定：与导航分开 —— 判错和翻页是两件完全不同的事
            HStack(spacing: 12) {
                AppButton(title: "认识", icon: "checkmark", tier: .judgePositive) {
                    markKnown(entry)
                }
                AppButton(title: "不认识", icon: "xmark", tier: .judgeNegative) {
                    nextCard()
                }
            }
            .padding(.top, 4)

            // 导航：降为幽灵按钮，不与判定争夺注意力
            HStack(spacing: 12) {
                AppButton(title: "上一个", icon: "chevron.left", tier: .ghost) {
                    if cardIndex > 0 {
                        cardIndex -= 1
                        playBest()
                    }
                }
                AppButton(title: "下一个", icon: "chevron.right", tier: .ghost) {
                    nextCard()
                }
            }
        }
        .padding(22)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.sheet))
        .elevationGround()
        .padding(.horizontal, 20)
    }

    // MARK: - 庆祝页

    private var celebrationView: some View {
        VStack(spacing: 22) {
            Text("🎉")
                .font(.system(size: 90))
            Text("今天学完啦！")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(Palette.ink)
            Text("你学会了 \(learnedToday.count) 个新单词")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Palette.inkMuted)
            VStack(spacing: 12) {
                AppButton(title: "去巩固", icon: "gamecontroller.fill", tier: .primary) {
                    showStudy = false
                    goConsolidate = true
                }
                AppButton(title: "再看一遍", icon: "arrow.counterclockwise", tier: .secondary) {
                    startStudy()
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(28)
        .padding(.horizontal, 20)
    }

    // MARK: - 逻辑

    private func refreshToday() {
        todayWords = store.planDays().first ?? []
    }

    private func startStudy() {
        todayWords = store.planDays().first ?? []
        learnedToday = []
        cardIndex = 0
        finished = false
        showStudy = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
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
        nextCard()
    }

    private func nextCard() {
        if cardIndex + 1 < todayWords.count {
            cardIndex += 1
            playBest()
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
        // 优先用预生成的慢速文件；没有就把同一条音频放慢到 0.7 倍
        if let url = store.slowAudioURL(forWord: entry.word) {
            player.play(url: url)
        } else if let url = store.bestAudioURL(forWord: entry.word) {
            player.play(url: url, rate: 0.7)
        }
    }
}

// MARK: - 选中环（一条规则，适用于任何底色）

extension View {
    /// 选中指示放在填充之外，因此在饱和色卡与中性卡上都成立
    func selectionRing(_ selected: Bool, radius: CGFloat) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: radius)
                .strokeBorder(Func.accent, lineWidth: selected ? 3 : 0)
                .padding(-3)
        )
    }
}
