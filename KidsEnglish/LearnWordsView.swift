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
    /// 是否跳转巩固练习（截图用 -uiConsolidate 自动进入）
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
                if LaunchOptions.forceConsolidate, !goConsolidate {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        goConsolidate = true
                    }
                }
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
            // 参考图首页没有大标题 —— 计划卡直接贴顶部，整屏留给出词书和主 CTA
            VStack(alignment: .leading, spacing: 26) {
                planCard
                    .padding(.horizontal)

                // 选词书
                VStack(alignment: .leading, spacing: 14) {
                    Text("选单词本")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal)
                    // 参考图：4 张卡一行排开，无横向滚动
                    HStack(spacing: 10) {
                        allWordsCard
                        bookCard(fill: AppTheme.bookPink, themeId: "fruits", title: "水果篇",
                                 subtitle: "\(store.words(forTheme: "fruits").count) 词",
                                 iconName: "theme-apple")
                        bookCard(fill: AppTheme.bookGreen, themeId: "animals", title: "动物篇",
                                 subtitle: "\(store.words(forTheme: "animals").count) 词",
                                 iconName: "theme-cat")
                        bookCard(fill: AppTheme.bookPurple, themeId: "vehicles", title: "交通篇",
                                 subtitle: "\(store.words(forTheme: "vehicles").count) 词",
                                 iconName: "theme-car")
                    }
                    .padding(.horizontal)
                }

                // 主 CTA —— 参考图：开始学习高 80pt / 巩固练习高 72pt
                VStack(spacing: 12) {
                    Button {
                        startStudy()
                    } label: {
                        HStack(spacing: 10) {
                            Text("开始学习")
                                .font(.system(size: 36, weight: .heavy))
                            Image(systemName: "play.fill")
                                .font(.system(size: 28, weight: .black))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(Func.ctaGreen, in: Capsule())
                    }
                    .buttonStyle(PressableStyle())

                    Button {
                        goConsolidate = true
                    } label: {
                        HStack(spacing: 8) {
                            Text("巩固练习 · 9 种玩法")
                                .font(.system(size: 26, weight: .heavy))
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 23, weight: .bold))
                        }
                        .foregroundStyle(Func.infoDeep)
                        .frame(maxWidth: .infinity)
                        .frame(height: 72)
                        .background(Func.info.opacity(0.42), in: Capsule())
                    }
                    .buttonStyle(PressableStyle())
                }
                .padding(.horizontal)
                .padding(.top, 2)

                // 参考图首页到「巩固练习」为止；每天新学 / 学习安排已移入「我的 → 设置」
            }
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
    }

    // MARK: - 今日计划卡

    private var planCard: some View {
        // 参考图：满饱和橙渐变 + 白字 + 右侧火箭插图（无底板）
        HStack(alignment: .center, spacing: 2) {
            VStack(alignment: .leading, spacing: 4) {
                Text("今日计划")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.96))
                Text("Day \(dayNumber)")
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundStyle(.white)
                Text("新学 \(todayWords.count) 个词")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                Text("已学 \(store.learnedWords.count) / \(store.words.count)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Spacer(minLength: 0)
            uiIcon("rocket")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 142, height: 142)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, minHeight: 235)
        .background(AppTheme.planGradient, in: RoundedRectangle(cornerRadius: Radius.sheet))
        .elevationRaised()
    }

    private var dayNumber: Int {
        let perDay = max(1, store.dailyNewWords)
        return store.learnedWords.count / perDay + 1
    }

    // MARK: - 选词书卡片

    /// 四张等宽竖条卡：图标在上、名称、词数，满饱和底 + 白字（与参考图一致）
    private var allWordsCard: some View {
        let isSelected = store.selectedThemeId == nil
        return Button {
            store.selectedThemeId = nil
            store.saveProgress()
        } label: {
            bookCardBody(fill: AppTheme.bookBlue, title: "全部单词",
                         subtitle: "\(store.words.count) 词", iconName: "book",
                         isSelected: isSelected)
        }
        .buttonStyle(PressableStyle())
    }

    private func bookCard(fill: Color, themeId: String, title: String,
                          subtitle: String, iconName: String) -> some View {
        let isSelected = store.selectedThemeId == themeId
        return Button {
            store.selectedThemeId = themeId
            store.saveProgress()
        } label: {
            bookCardBody(fill: fill, title: title, subtitle: subtitle,
                         iconName: iconName, isSelected: isSelected)
        }
        .buttonStyle(PressableStyle())
    }

    private func bookCardBody(fill: Color, title: String, subtitle: String,
                              iconName: String, isSelected: Bool) -> some View {
        VStack(spacing: 6) {
            Spacer(minLength: 0)
            uiIcon(iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 54, height: 54)
            Spacer(minLength: 0)
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(subtitle)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
        }
        .padding(.vertical, 12)
        .frame(width: 82, height: 148)
        .background(fill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .elevationGround()
        // 选中态用白描边，在满饱和底上比换色更清楚
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white, lineWidth: isSelected ? 3 : 0)
        }
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

    /// 头部：参考图是「背单词 · 第 3 个」+ 右侧喇叭，序号直接进标题
    private var studyHeader: some View {
        HStack(spacing: 6) {
            Button {
                showStudy = false
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Palette.inkMuted)
                    .frame(width: 28, height: 44)
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("返回")

            Text("背单词 · 第 \(cardIndex + 1) 个")
                .font(.system(size: 27, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            Button {
                playBest()
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Func.infoDeep)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("再听一遍")
        }
        .padding(.horizontal, 16)
    }

    /// 进度：几何与终态一致，不闪跳
    private var studyProgress: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(red: 0.85, green: 0.85, blue: 0.86))
                    Capsule()
                        .fill(Func.accent)
                        .frame(width: geo.size.width * progressFraction)
                }
            }
            .frame(height: 9)

            Text("学习进度 \(cardIndex + 1)/\(todayWords.count)")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Func.accentVivid)
        }
        .padding(.horizontal, 20)
    }

    private var progressFraction: Double {
        guard !todayWords.isEmpty else { return 0 }
        return Double(cardIndex + 1) / Double(todayWords.count)
    }

    private func wordCard(_ entry: WordEntry) -> some View {
        VStack(spacing: 8) {
            // 参考图：插图后面有一团柔和的暖黄光晕
            ZStack {
                RadialGradient(
                    colors: [Color(red: 1.0, green: 0.93, blue: 0.72), .clear],
                    center: .center, startRadius: 10, endRadius: 130
                )
                .frame(width: 250, height: 200)
                // 词图是带灰底的实拍图，用径向遮罩把边缘化开，
                // 避免出现一块灰色方片（参考图是透明 3D 插图）
                WordIconView(word: entry.word, size: 158)
                    .mask(
                        RadialGradient(
                            colors: [.black, .black, .clear],
                            center: .center,
                            startRadius: 53, endRadius: 80
                        )
                    )
            }

            Text(entry.word)
                .font(.system(size: 54, weight: .heavy))
                .foregroundStyle(Func.infoDeep)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(entry.phonetic ?? "")
                .font(.system(size: 21, weight: .medium))
                .foregroundStyle(Palette.inkMuted)
            Text(entry.meaningCn ?? "")
                .font(.system(size: 42, weight: .heavy))
                .foregroundStyle(Func.accentBright)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            // 发音：参考图是蓝底白字 / 绿底白字两枚胶囊
            HStack(spacing: 12) {
                pillButton(title: "正常", icon: "speaker.wave.2.fill",
                           fill: Func.infoDeep, fg: .white) {
                    playBest(for: entry)
                }
                pillButton(title: "慢速", icon: "tortoise.fill",
                           fill: Func.positiveDeep, fg: .white) {
                    playSlow(for: entry)
                }
            }
            .padding(.top, 6)

            // 判定与导航同排四键（参考图布局）：中间判定饱和色配白字。
            // 两侧导航不做成同一种灰：灰＝不可用，会让「下一个」看起来点不动，
            // 所以「上一个」在第一张卡真正置灰禁用，「下一个」用次级蓝表示可点。
            HStack(spacing: 8) {
                judgeKey(title: "上一个", icon: "arrow.left", leadingIcon: true,
                         fill: Color(red: 0.78, green: 0.78, blue: 0.79),
                         fg: Palette.ink,
                         enabled: cardIndex > 0) {
                    if cardIndex > 0 {
                        cardIndex -= 1
                        playBest()
                    }
                }
                judgeKey(title: "认识", icon: "checkmark",
                         fill: Func.positiveDeep, fg: .white) {
                    markKnown(entry)
                }
                judgeKey(title: "不认识", icon: "xmark",
                         fill: Func.negativeDeep, fg: .white) {
                    nextCard()
                }
                judgeKey(title: "下一个", icon: "arrow.right",
                         fill: Func.info.opacity(0.42),
                         fg: Func.infoDeep) {
                    nextCard()
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 20)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.sheet))
        .elevationGround()
        .padding(.horizontal, 16)
    }

    private func pillButton(title: String, icon: String,
                            fill: Color, fg: Color,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .bold))
                Text(title)
                    .font(.system(size: 20, weight: .heavy))
            }
            .foregroundStyle(fg)
            .padding(.horizontal, 22)
            .frame(height: 47)
            .background(fill, in: Capsule())
        }
        .buttonStyle(PressableStyle())
    }

    private func judgeKey(title: String, icon: String,
                          leadingIcon: Bool = false,
                          fill: Color, fg: Color,
                          enabled: Bool = true,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                HStack(spacing: 3) {
                    // 参考图：「← 上一个」箭头在前，「下一个 →」箭头在后
                    if leadingIcon {
                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .bold))
                    }
                    Text(title)
                        .font(.system(size: 17, weight: .heavy))
                    if !leadingIcon {
                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .bold))
                    }
                }
                .foregroundStyle(enabled ? fg : fg.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(enabled ? fill : Palette.hairline,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressableStyle())
        .disabled(!enabled)
        .accessibilityLabel(title)
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
