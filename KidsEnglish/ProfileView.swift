import SwiftUI

/// "我的" Tab：用户卡 → 学习报告 → 设置组
struct ProfileView: View {
    @Environment(DataStore.self) private var store
    @State private var showProfileEdit = false

    var body: some View {
        NavigationStack {
            KidScrollView {
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
        .sheet(isPresented: $showProfileEdit) {
            ProfileEditSheet()
        }
        .onAppear {
            // 截图用：直接展示编辑弹窗
            if LaunchOptions.profilePage == "edit" { showProfileEdit = true }
        }
    }

    // MARK: - 用户卡（紫色渐变，白字 ≥ 4.7:1）

    private var userCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Palette.surface)
                    .frame(width: 88, height: 88)
                Text(store.avatarEmoji).kidFont(52)
            }
            .overlay(Circle().strokeBorder(.white.opacity(0.85), lineWidth: 3))

            VStack(alignment: .leading, spacing: 7) {
                Text(store.childName)
                    .kidFont(30, .heavy)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .kidFont(15, .semibold)
                    Text("已学习 \(store.studyDayCount) 天")
                        .kidFont(16, .semibold)
                }
                .foregroundStyle(.white.opacity(0.96))

                HStack(spacing: 6) {
                    Text("🔥").kidFont(15)
                    Text("连续打卡 \(store.streakDays) 天")
                        .kidFont(16, .semibold)
                }
                .foregroundStyle(.white.opacity(0.96))
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.profileGradient, in: RoundedRectangle(cornerRadius: Radius.sheet))
        .overlay(alignment: .topTrailing) {
            Button {
                showProfileEdit = true
            } label: {
                Image(systemName: "pencil")
                    .kidFont(16, .bold)
                    .foregroundStyle(Palette.ink)
                    .frame(width: 36, height: 36)
                    .background(Palette.surface, in: Circle())
            }
            .buttonStyle(PressableStyle())
            .padding(12)
            .accessibilityLabel("编辑名字和头像")
        }
        .elevationRaised()
    }

    // MARK: - 学习报告（3 个指标，数字用白底达标的深色）

    private var reportCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .kidFont(16, .bold)
                    .foregroundStyle(Func.accentDeep)
                Text("学习报告")
                    .kidFont(22, .heavy)
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
                .kidFont(23, .bold)
                .foregroundStyle(color)
            Text(value)
                .kidFont(38, .heavy)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .kidFont(14, .medium)
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
                .kidFont(19, .semibold)
                .foregroundStyle(Palette.ink)
                .frame(width: 24)

            Text(title)
                .kidFont(19, .bold)
                .foregroundStyle(Palette.ink)

            Spacer(minLength: 8)

            if let value {
                Text(value)
                    .kidFont(16, .medium)
                    .foregroundStyle(Palette.inkMuted)
            }

            if let trailingIcon {
                Image(systemName: trailingIcon)
                    .kidFont(17, .semibold)
                    .foregroundStyle(Palette.inkSubtle)
            } else {
                Image(systemName: "chevron.right")
                    .kidFont(16, .bold)
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
        KidScrollView {
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
                        .kidFont(18, .heavy)
                        .foregroundStyle(Palette.ink)
                    HStack(spacing: 8) {
                        ForEach([0, 10, 20, 30], id: \.self) { minutes in
                            let isSelected = store.timeLimitMinutes == minutes
                            Button {
                                store.timeLimitMinutes = minutes
                                store.saveProgress()
                            } label: {
                                Text(minutes == 0 ? "不限" : "\(minutes) 分")
                                    .kidFont(15, .bold)
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
                        .kidFont(17, .semibold)
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Stepper("\(store.dailyNewWords) 个", value: Binding(
                        get: { store.dailyNewWords },
                        set: { store.dailyNewWords = $0; store.saveProgress() }
                    ), in: 5...30, step: 5)
                    .kidFont(16, .semibold)
                    .foregroundStyle(Palette.inkMuted)
                }
                .padding(16)
                .whiteCard()
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    Text("巩固练习难度")
                        .kidFont(18, .heavy)
                        .foregroundStyle(Palette.ink)
                    Text("简单档只出初学词（level 1–2）；标准档用当天学过的全部词。")
                        .kidFont(13, .medium)
                        .foregroundStyle(Palette.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        ForEach([true, false], id: \.self) { simple in
                            let isSelected = store.gameIsSimple == simple
                            Button {
                                store.gameIsSimple = simple
                                store.saveProgress()
                            } label: {
                                Text(simple ? "简单" : "标准")
                                    .kidFont(15, .bold)
                                    .foregroundStyle(isSelected ? onFill(Func.accent) : Palette.inkMuted)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(isSelected ? Func.accent : Palette.hairline,
                                                in: RoundedRectangle(cornerRadius: Radius.chip))
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .whiteCard()
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("关于")
                        .kidFont(18, .heavy)
                        .foregroundStyle(Palette.ink)
                    Text("英语小伙伴 KidsEnglish · \(appVersion)")
                        .kidFont(14, .semibold)
                        .foregroundStyle(Palette.ink)
                    Text("课文与音频来自开源项目 magic-english-buddy（CC BY-NC-SA 4.0），仅限家庭内部学习使用。")
                        .kidFont(13, .medium)
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
        KidScrollView {
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
                        .kidFont(15, .medium)
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
                            .kidFont(18, .heavy)
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
                            .kidFont(18, .heavy)
                            .foregroundStyle(Palette.ink)
                            .padding(.horizontal)
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 96), spacing: 10)],
                            spacing: 10
                        ) {
                            ForEach(cards, id: \.self) { card in
                                Text(card)
                                    .kidFont(15, .bold)
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
                    .kidFont(20, .bold)
                    .foregroundStyle(Palette.ink)
                Text(entry.meaningCn ?? "")
                    .kidFont(15, .medium)
                    .foregroundStyle(Palette.inkMuted)
            }

            Spacer(minLength: 6)

            Button {
                if let url = store.bestAudioURL(forWord: entry.word) {
                    player.play(url: url)
                }
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .kidFont(18, .semibold)
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


// MARK: - 编辑名字与头像

struct ProfileEditSheet: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = "🧒"

    private let avatars = ["🧒", "👦", "👧", "🐣", "🐼", "🦁", "🐯", "🐰", "🐻", "🐨",
                           "🦊", "🐸", "🐧", "🦄", "🚀", "⭐️", "🌈", "🍎", "⚽️", "🎨", "🎵", "🐳"]
    private let columns = [GridItem(.adaptive(minimum: 54), spacing: 10)]

    var body: some View {
        NavigationStack {
            KidScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("名字")
                        .kidFont(18, .heavy)
                        .foregroundStyle(Palette.ink)
                    TextField("小朋友的名字", text: $name)
                        .kidFont(22, .bold)
                        .padding(14)
                        .background(Palette.surface,
                                    in: RoundedRectangle(cornerRadius: Radius.card))
                        .onChange(of: name) { _, newValue in
                            if newValue.count > 10 { name = String(newValue.prefix(10)) }
                        }

                    Text("头像")
                        .kidFont(18, .heavy)
                        .foregroundStyle(Palette.ink)
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(avatars, id: \.self) { item in
                            Button {
                                emoji = item
                            } label: {
                                Text(item)
                                    .kidFont(30)
                                    .frame(width: 54, height: 54)
                                    .background(emoji == item ? Func.accent.opacity(0.22) : Palette.surface,
                                                in: Circle())
                                    .overlay {
                                        Circle().strokeBorder(
                                            emoji == item ? Func.accent : Palette.hairline,
                                            lineWidth: emoji == item ? 2.5 : 1
                                        )
                                    }
                            }
                            .buttonStyle(PressableStyle())
                            .accessibilityLabel("头像 \(item)")
                        }
                    }

                    AppButton(title: "保存", icon: "checkmark", tier: .primary) {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        store.childName = trimmed.isEmpty ? "小宝贝" : trimmed
                        store.avatarEmoji = emoji
                        store.saveProgress()
                        dismiss()
                    }
                    .padding(.top, 6)
                }
                .padding(16)
            }
            .creamBackground()
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                name = store.childName
                emoji = store.avatarEmoji
            }
        }
    }
}

// MARK: - 家长中心：已学单词列表

struct LearnedWordsView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var player = AudioPlayer()

    private var words: [WordEntry] {
        store.learnedWords
            .compactMap { store.wordDict[$0] }
            .sorted { $0.word.lowercased() < $1.word.lowercased() }
    }

    var body: some View {
        KidScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SubPageHeader(onBack: { dismiss() })

                VStack(alignment: .leading, spacing: 4) {
                    Text("已学单词")
                        .subPageTitleStyle()
                    Text("共 \(words.count) 个 · 点右侧可以再听一遍")
                        .subPageSubtitleStyle()
                }
                .padding(.horizontal)

                if words.isEmpty {
                    Text("还没有标记「认识」的单词。学习时点「认识」就会记录在这里。")
                        .kidFont(15, .medium)
                        .foregroundStyle(Palette.inkMuted)
                        .lineSpacing(3)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .whiteCard()
                        .padding(.horizontal)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(words) { entry in
                            HStack(spacing: 10) {
                                Text(entry.word)
                                    .kidFont(19, .bold)
                                    .foregroundStyle(Palette.ink)
                                if let cn = entry.meaningCn {
                                    Text(cn)
                                        .kidFont(15, .medium)
                                        .foregroundStyle(Palette.inkMuted)
                                }
                                Spacer()
                                Button {
                                    if let url = store.bestAudioURL(forWord: entry.word) {
                                        player.play(url: url)
                                    }
                                } label: {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .kidFont(15, .bold)
                                        .foregroundStyle(Func.infoDeep)
                                        .frame(width: 36, height: 36)
                                        .background(Func.info.opacity(0.14), in: Circle())
                                }
                                .buttonStyle(PressableStyle())
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 54)
                            .background(Palette.surface,
                                        in: RoundedRectangle(cornerRadius: Radius.card))
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .creamBackground()
        .toolbar(.hidden, for: .navigationBar)
    }
}
