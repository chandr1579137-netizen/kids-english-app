import SwiftUI

/// "我的" Tab：用户卡 → 学习报告 → 设置组
struct ProfileView: View {
    @Environment(DataStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    userCard
                    reportCard
                    settingsGroup
                }
                .padding(.horizontal)
                .padding(.top, 4)
                .padding(.bottom, 12)
            }
            .creamBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - 用户卡（紫色渐变，白字 ≥ 4.7:1）

    private var userCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Palette.surface)
                    .frame(width: 88, height: 88)
                Text("🧒").font(.system(size: 52))
            }
            .overlay(Circle().strokeBorder(.white.opacity(0.85), lineWidth: 3))

            VStack(alignment: .leading, spacing: 7) {
                Text("小宝贝")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(.white)

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 15, weight: .semibold))
                    Text("已学习 \(store.studyDayCount) 天")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white.opacity(0.96))

                HStack(spacing: 6) {
                    Text("🔥").font(.system(size: 15))
                    Text("连续打卡 \(store.streakDays) 天")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white.opacity(0.96))
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.profileGradient, in: RoundedRectangle(cornerRadius: Radius.sheet))
        .elevationRaised()
    }

    // MARK: - 学习报告（3 个指标，数字用白底达标的深色）

    private var reportCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Func.accentDeep)
                Text("学习报告")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(Palette.ink)
            }

            HStack(spacing: 0) {
                metric(icon: "book.fill", color: Func.infoDeep,
                       value: "\(store.learnedWords.count)", label: "已学单词")
                divider
                metric(icon: "book.closed.fill", color: Func.positiveDeep,
                       value: "\(store.completedLessons.count)", label: "已读短文")
                divider
                metric(icon: "target", color: Func.accentDeep,
                       value: "\(store.gameAccuracy)%", label: "游戏正确率")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .whiteCard()
    }

    private func metric(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 38, weight: .heavy))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Palette.inkMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(width: 1, height: 44)
    }

    // MARK: - 设置项：参考图是 4 张独立卡片，不是合并成一组

    private var settingsGroup: some View {
        VStack(spacing: 10) {
            NavigationLink {
                FavoritesView()
            } label: {
                // 「学习报告」里的收藏数原本是个死数字：收藏入口藏在课文点词弹窗里，
                // 却没有任何页面能看到到底收藏了什么
                settingRow(icon: "star.fill", title: "我的收藏",
                           value: "\(store.favoriteWords.count) 个")
            }

            NavigationLink {
                SongsView()
            } label: {
                settingRow(icon: "music.note", title: "英文儿歌")
            }

            NavigationLink {
                ParentGateView()
            } label: {
                settingRow(icon: "lock.fill", title: "家长中心", trailingIcon: "lock.fill")
            }

            NavigationLink {
                SettingsDetailView()
            } label: {
                settingRow(icon: "timer", title: "每日限时",
                           value: store.timeLimitMinutes == 0 ? "不限" : "\(store.timeLimitMinutes) 分钟")
            }

            NavigationLink {
                SettingsDetailView()
            } label: {
                settingRow(icon: "gearshape.fill", title: "设置")
            }
        }
    }

    private func settingRow(icon: String, title: String,
                            value: String? = nil,
                            trailingIcon: String? = nil) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(Palette.ink)

            Spacer(minLength: 8)

            if let value {
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Palette.inkMuted)
            }

            if let trailingIcon {
                Image(systemName: trailingIcon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.inkSubtle)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Palette.inkSubtle)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 58)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .elevationGround()
        .contentShape(Rectangle())
    }
}

// MARK: - 设置详情（每日限时 / 每天新学词数）

struct SettingsDetailView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SubPageHeader(onBack: { dismiss() })

                VStack(alignment: .leading, spacing: 4) {
                    Text("设置")
                        .subPageTitleStyle()
                    Text("每日限时与每天新学词数")
                        .subPageSubtitleStyle()
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 14) {
                    Text("每日限时")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                    HStack(spacing: 8) {
                        ForEach([0, 10, 20, 30], id: \.self) { minutes in
                            let isSelected = store.timeLimitMinutes == minutes
                            Button {
                                store.timeLimitMinutes = minutes
                                store.saveProgress()
                            } label: {
                                Text(minutes == 0 ? "不限" : "\(minutes) 分")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(isSelected ? onFill(Func.accent) : Palette.inkMuted)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(
                                        isSelected ? Func.accent : Palette.hairline,
                                        in: RoundedRectangle(cornerRadius: Radius.chip)
                                    )
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .whiteCard()
                .padding(.horizontal)

                HStack {
                    Text("每天新学词数")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Stepper("\(store.dailyNewWords) 个", value: Binding(
                        get: { store.dailyNewWords },
                        set: { store.dailyNewWords = $0; store.saveProgress() }
                    ), in: 5...30, step: 5)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.inkMuted)
                }
                .padding(16)
                .whiteCard()
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("关于")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                    Text("英语小伙伴 KidsEnglish · \(appVersion)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    Text("课文与音频来自开源项目 magic-english-buddy（CC BY-NC-SA 4.0），仅限家庭内部学习使用。")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Palette.inkMuted)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .whiteCard()
                .padding(.horizontal)
            }
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .creamBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(short) (\(build))"
    }
}

// MARK: - 我的收藏（收藏的单词 + 通关收集的卡片）

struct FavoritesView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var player = AudioPlayer()

    private var words: [WordEntry] {
        store.favoriteWords
            .compactMap { store.wordDict[$0] }
            .sorted { $0.word.lowercased() < $1.word.lowercased() }
    }

    private var cards: [String] { store.collectedCards.sorted() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SubPageHeader(onBack: { dismiss() })

                VStack(alignment: .leading, spacing: 4) {
                    Text("我的收藏")
                        .subPageTitleStyle()
                    Text("单词 \(words.count) 个 · 卡片 \(cards.count) 张")
                        .subPageSubtitleStyle()
                }
                .padding(.horizontal)

                if words.isEmpty && cards.isEmpty {
                    Text("还没有收藏。在课文里点一个单词，再点「收藏」，它就会出现在这里。")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Palette.inkMuted)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .whiteCard()
                        .padding(.horizontal)
                }

                if !words.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("收藏的单词")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(Palette.ink)
                            .padding(.horizontal)
                        LazyVStack(spacing: 10) {
                            ForEach(words) { entry in
                                wordRow(entry)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                if !cards.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("收集到的卡片")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(Palette.ink)
                            .padding(.horizontal)
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 96), spacing: 10)],
                            spacing: 10
                        ) {
                            ForEach(cards, id: \.self) { card in
                                Text(card)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(Palette.ink)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Palette.surface,
                                                in: RoundedRectangle(cornerRadius: Radius.thumb,
                                                                     style: .continuous))
                                    .elevationGround()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .creamBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    private func wordRow(_ entry: WordEntry) -> some View {
        HStack(spacing: 12) {
            WordIconView(word: entry.word, size: 56)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.word)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Palette.ink)
                Text(entry.meaningCn ?? "")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Palette.inkMuted)
            }

            Spacer(minLength: 6)

            Button {
                if let url = store.bestAudioURL(forWord: entry.word) {
                    player.play(url: url)
                }
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Palette.inkOnColor)
                    .frame(width: 44, height: 44)
                    .background(Func.accent, in: Circle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("播放 \(entry.word)")
        }
        .padding(10)
        .whiteCard()
    }
}
