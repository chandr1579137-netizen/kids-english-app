import SwiftUI

/// 家长区入口：数学题解锁。
///
/// 这几个页面此前全是系统组件（`List` / `navigationTitle` / 系统按钮），
/// 与主流程的自绘顶栏、白卡、糖果按钮不是一套语言，这里统一。
struct ParentGateView: View {
    var body: some View {
        ParentDashboardView()
            .creamBackground()
            .toolbar(.hidden, for: .navigationBar)
    }
}

/// 家长解锁：答对数学题。
/// 既被「我的 → 家长模式」推入，也被到点锁定弹层以 sheet 形式复用，
/// 所以顶栏用 dismiss（sheet 里即关闭）。
struct ParentUnlockView: View {
    let onUnlock: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var a = Int.random(in: 11...49)
    @State private var b = Int.random(in: 11...49)
    @State private var answer = ""
    @State private var wrong = false

    var body: some View {
        KidScrollView {
            VStack(spacing: 16) {
                SubPageHeader(onBack: { dismiss() })

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Func.accent.opacity(0.16))
                            .frame(width: 96, height: 96)
                        Text("🔒").kidFont(44)
                    }

                    Text("家长验证")
                        .kidFont(28, .heavy)
                        .foregroundStyle(Palette.ink)

                    Text("请回答下面的数学题进入家长区\n（防止小朋友误入）")
                        .kidFont(15, .medium)
                        .foregroundStyle(Palette.inkMuted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)

                    Text("\(a) + \(b) = ?")
                        .kidFont(44, .heavy)
                        .foregroundStyle(Palette.ink)
                        .padding(.top, 2)

                    TextField("答案", text: $answer)
                        .keyboardType(.numberPad)
                        .kidFont(28, .bold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Palette.ink)
                        .frame(width: 170, height: 56)
                        .background(Palette.canvasCool,
                                    in: RoundedRectangle(cornerRadius: Radius.thumb, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: Radius.thumb, style: .continuous)
                                .strokeBorder(Palette.hairline, lineWidth: 1.5)
                        }

                    if wrong {
                        Text("不对哦，再算算")
                            .kidFont(15, .semibold)
                            .foregroundStyle(Func.negativeDeep)
                    }

                    AppButton(title: "进入", tier: .primary) {
                        if Int(answer) == a + b {
                            onUnlock()
                        } else {
                            wrong = true
                            answer = ""
                        }
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .whiteCard()
                .padding(.horizontal)
            }
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
    }
}

/// 家长仪表盘：学习报告 + 限时 + 显示 + 关于。
struct ParentDashboardView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirm = false
    @State private var showImport = false
    @State private var importText = ""
    @State private var importMessage: String?
    /// 新格式备份：解析好了、等家长确认（确认前不写任何数据）
    @State private var pendingFamily: FamilyBackup?

    var body: some View {
        KidScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SubPageHeader(onBack: { dismiss() })

                VStack(alignment: .leading, spacing: 4) {
                    Text("家长中心")
                        .subPageTitleStyle()
                    Text("学习数据与使用限制")
                        .subPageSubtitleStyle()
                }
                .padding(.horizontal)

                // 最上面：切换看哪个孩子（下面的报告和设置都是这个孩子的）+ 管理孩子
                ParentChildrenCard()
                    .padding(16)
                    .whiteCard()
                    .padding(.horizontal)

                // 启蒙模式下展示当前孩子的「今天」卡片：今日 4 词（中英+配图）、点听孩子录音、今日句子、生活里这样用
                if LaunchOptions.isBaby(store) {
                    ParentTodayCard()
                        .padding(16)
                        .whiteCard()
                        .padding(.horizontal)
                }

                // 宝宝模式一栏放最前：开着宝宝模式时，家长进来最常改的就是它
                card("启蒙模式") {
                    Toggle(isOn: Binding(
                        get: { store.babyMode },
                        set: { store.babyMode = $0; store.saveProgress() }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("打开启蒙模式")
                                .kidFont(17, .semibold)
                                .foregroundStyle(Palette.ink)
                            Text("孩子只看到 今天 / 图画 / 说一说 / 儿歌 四个页签，其余内容在家长页后面")
                                .kidFont(13, .medium)
                                .foregroundStyle(Palette.inkMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(Func.accent)

                    HStack {
                        Text("每天新学")
                            .kidFont(17, .semibold)
                            .foregroundStyle(Palette.ink)
                        Spacer()
                        Stepper(value: Binding(
                            get: { store.babyNewPerDay },
                            set: { store.babyNewPerDay = min(max($0, 3), 8); store.saveProgress() }
                        ), in: 3...8) {
                            Text("\(store.babyNewPerDay) 个词")
                                .kidFont(17, .bold)
                                .foregroundStyle(Func.infoDeep)
                        }
                        .fixedSize()
                    }

                    Toggle(isOn: Binding(
                        get: { store.babyUnlockAll },
                        set: { store.babyUnlockAll = $0; store.saveProgress() }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("解锁全部词包")
                                .kidFont(17, .semibold)
                                .foregroundStyle(Palette.ink)
                            Text("默认前 7 包先开，学完再按顺序开后面的")
                                .kidFont(13, .medium)
                                .foregroundStyle(Palette.inkMuted)
                        }
                    }
                    .tint(Func.accent)

                    statRow("启蒙模式已学", "\(store.babyWords.count) / \(store.babyData?.allWords.count ?? 0) 个词")
                    statRow("贴纸", "\(store.babyStickers.count) 张")
                }

                card("学习报告") {
                    statRow("说一说", "\(store.completedPhraseScenes.count) / \(store.phraseCatalog?.allScenes.count ?? 0) 节课")
                    statRow("今日学习", "\(store.studyMinutesToday()) 分钟")
                    statRow("收藏单词", "\(store.favoriteWords.count) 个")
                    statRow("收集卡片", "\(store.collectedCards.count) 张")
                }

                card("已学单词") {
                    HStack {
                        Text("\(store.learnedWords.count) 个")
                            .kidFont(17, .semibold)
                            .foregroundStyle(Palette.ink)
                        Spacer()
                        NavigationLink {
                            LearnedWordsView()
                        } label: {
                            HStack(spacing: 4) {
                                Text("查看列表")
                                    .kidFont(15, .semibold)
                                Image(systemName: "chevron.right")
                                    .kidFont(12, .bold)
                            }
                            .foregroundStyle(Func.infoDeep)
                        }
                    }
                }

                card("每日限时") {
                    HStack {
                        Text("每天最多学")
                            .kidFont(17, .semibold)
                            .foregroundStyle(Palette.ink)
                        Spacer()
                        Picker("每天最多学", selection: Binding(
                            get: { store.timeLimitMinutes },
                            set: { store.timeLimitMinutes = $0; store.saveProgress() }
                        )) {
                            // 取值与「设置 → 每日限时」保持一致：0 / 10 / 20 / 30。
                            // 之前这里还有 15/45/60，设置页只有 0/10/20/30，
                            // 家长选了 45 之后设置页一个都不高亮。
                            Text("不限").tag(0)
                            Text("10 分钟").tag(10)
                            Text("20 分钟").tag(20)
                            Text("30 分钟").tag(30)
                        }
                        .pickerStyle(.menu)
                        .tint(Func.infoDeep)
                    }

                    if store.timeUp {
                        Button {
                            store.resetTimeUp()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "lock.open.fill")
                                    .kidFont(15, .bold)
                                Text("解除今日锁定")
                                    .kidFont(16, .bold)
                            }
                            .foregroundStyle(Func.infoDeep)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Func.info.opacity(0.14),
                                        in: RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
                        }
                        .buttonStyle(PressableStyle())
                    }
                }

                card("说一说（口语课）") {
                    Toggle(isOn: Binding(
                        get: { store.phraseShowChinese },
                        set: { store.phraseShowChinese = $0; store.saveProgress() }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("卡片下显示中文")
                                .kidFont(17, .semibold)
                                .foregroundStyle(Palette.ink)
                            Text("方便陪学；孩子看图听声就能懂，默认不显示")
                                .kidFont(13, .medium)
                                .foregroundStyle(Palette.inkMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(Func.accent)

                    Toggle(isOn: Binding(
                        get: { store.phraseUnlockAll },
                        set: { store.phraseUnlockAll = $0; store.saveProgress() }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("全部解锁")
                                .kidFont(17, .semibold)
                                .foregroundStyle(Palette.ink)
                            Text("默认按顺序一课一课开")
                                .kidFont(13, .medium)
                                .foregroundStyle(Palette.inkMuted)
                        }
                    }
                    .tint(Func.accent)
                }

                card("数据") {
                    ShareLink(item: store.exportSnapshotJSON()) {
                        dataRowLabel(icon: "square.and.arrow.up",
                                     title: "导出学习进度",
                                     tint: Func.infoDeep,
                                     background: Func.info.opacity(0.12))
                    }
                    .buttonStyle(PressableStyle())

                    Button {
                        importText = ""
                        importMessage = nil
                        showImport = true
                    } label: {
                        dataRowLabel(icon: "square.and.arrow.down",
                                     title: "从文本恢复进度",
                                     tint: Func.positiveDeep,
                                     background: Func.positive.opacity(0.12))
                    }
                    .buttonStyle(PressableStyle())

                    Button {
                        showResetConfirm = true
                    } label: {
                        dataRowLabel(icon: "trash",
                                     title: "清除全部学习进度",
                                     tint: Func.negativeDeep,
                                     background: Func.negative.opacity(0.12))
                    }
                    .buttonStyle(PressableStyle())

                    Text("换机或重装前先导出这段文本；恢复会覆盖当前进度。")
                        .kidFont(13, .medium)
                        .foregroundStyle(Palette.inkMuted)
                        .lineSpacing(2)
                }

                card("关于") {
                    Text("内容来源：magic-english-buddy（GitHub 开源，CC BY-NC-SA 4.0）\n仅限家庭内部学习使用")
                        .kidFont(13, .medium)
                        .foregroundStyle(Palette.inkMuted)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .overlay {
            if let family = pendingFamily {
                ConfirmCard(emoji: "📦",
                            title: "用备份替换全部孩子？",
                            message: BackupCodec.confirmMessage(family),
                            confirmTitle: "替换",
                            destructive: true,
                            onConfirm: {
                                importMessage = store.applyFamilyBackup(family)
                                pendingFamily = nil
                            },
                            onCancel: { pendingFamily = nil })
            }
            if showResetConfirm {
                ConfirmCard(emoji: "🗑️",
                            title: "确定清除全部学习进度？",
                            message: "已学单词、说一说和启蒙模式进度、收藏和游戏成绩都会清空，且不能撤销。",
                            confirmTitle: "清除",
                            destructive: true,
                            onConfirm: {
                                showResetConfirm = false
                                store.resetAllProgress()
                            },
                            onCancel: { showResetConfirm = false })
            }
        }
        .onAppear {
            // 截图用：直接展示确认卡片
            if LaunchOptions.alertDemo == "clear" { showResetConfirm = true }
            if LaunchOptions.importConfirmDemo { pendingFamily = LaunchOptions.demoFamilyBackup(store) }
        }
        .sheet(isPresented: $showImport) {
            importSheet
        }
    }

    private var importSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("把之前「导出学习进度」得到的文本粘贴到这里")
                    .kidFont(14, .medium)
                    .foregroundStyle(Palette.inkMuted)
                TextEditor(text: $importText)
                    .kidFont(12, design: .monospaced)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(maxHeight: .infinity)
                    .background(Palette.surface,
                                in: RoundedRectangle(cornerRadius: Radius.thumb, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.thumb, style: .continuous)
                            .strokeBorder(Palette.hairline, lineWidth: 1)
                    }
                if let importMessage {
                    Text(importMessage)
                        .kidFont(14, .semibold)
                        .foregroundStyle(importMessage.hasPrefix("已恢复")
                                         ? Func.positiveDeep : Func.negativeDeep)
                }
            }
            .padding()
            .creamBackground()
            .navigationTitle("恢复学习进度")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showImport = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("恢复") {
                        switch store.parseBackup(importText) {
                        case .family(let family):
                            // 新格式会替换所有孩子：先关掉粘贴页，弹确认框
                            showImport = false
                            pendingFamily = family
                        case .single, .invalid:
                            let result = store.importSnapshotJSON(importText)
                            importMessage = result
                            if result.hasPrefix("已恢复") {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    showImport = false
                                }
                            }
                        }
                    }
                    .disabled(importText.isEmpty)
                }
            }
        }
    }

    private func dataRowLabel(icon: String, title: String,
                              tint: Color, background: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .kidFont(15, .bold)
            Text(title)
                .kidFont(16, .bold)
        }
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(background, in: RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
    }

    // MARK: - 组件

    private func card<Content: View>(_ title: String,
                                     @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .kidFont(18, .heavy)                .foregroundStyle(Palette.ink)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .whiteCard()
        .padding(.horizontal)
    }

    private func statRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .kidFont(16, .medium)
                .foregroundStyle(Palette.ink)
            Spacer()
            Text(value)
                .kidFont(16, .bold)
                .foregroundStyle(Func.infoDeep)
        }
    }
}

// MARK: - 家长中心「今天」卡片（docs/pm/daily-lesson-v2.md §7）

/// 每个孩子名下的「今天」卡片：
/// 1. 今天学的 4 个词（配图 + 英文 + 中文）与今日句子
/// 2. 点一下播放孩子在第 3 步录下的声音（`<profileId>-baby-<word>`），没录过则放标准发音
/// 3. 词包写死的「生活里这样用」亲子互动提示，全离线
struct ParentTodayCard: View {
    @Environment(DataStore.self) private var store
    @State private var recorder = PhraseVoiceRecorder()
    @State private var wordPlayer = AudioPlayer()
    @State private var phraseAudio = PhraseAudio()
    @State private var playingWord: String?

    private var todayWords: [String] {
        guard let data = store.babyData else { return [] }
        if store.babyTodayDate == store.todayKeyString, !store.babyTodayWords.isEmpty {
            return store.babyTodayWords
        }
        let known: Set<String>
        if let demoStates = BabyDemo.states(data) {
            known = Set(demoStates.keys)
        } else {
            known = store.babyKnown
        }
        return BabyPlan.newWords(data, known: known, unlockAll: store.babyUnlockAll, count: store.babyNewPerDay)
    }

    private var primaryPack: BabyPack? {
        guard let data = store.babyData, let first = todayWords.first else { return nil }
        return data.pack(containing: first)
    }

    private var todaySentencesText: String {
        guard let data = store.babyData else { return "" }
        let sents = todayWords.prefix(2).compactMap { data.sentence(for: $0) }
        return sents.joined(separator: "  ")
    }

    var body: some View {
        let words = todayWords
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今天学的")
                    .kidFont(18, .heavy)
                    .foregroundStyle(Palette.ink)
                if let pack = primaryPack {
                    Text(pack.nameZh)
                        .kidFont(13, .bold)
                        .foregroundStyle(Func.accentDeep)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Func.accent.opacity(0.16), in: Capsule())
                }
                Spacer()
                Text("点小喇叭听录音")
                    .kidFont(12, .semibold)
                    .foregroundStyle(Palette.inkMuted)
            }

            // 今日 4 个词（2×2 网格：配图 + 英文 + 中文 + 录音回放按钮）
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(words, id: \.self) { w in
                    wordCell(w)
                }
            }

            // 今日句子
            if !todaySentencesText.isEmpty {
                Button {
                    if let first = words.first {
                        phraseAudio.play(store.phraseFileURL("audio", "baby_sent_\(first).mp3"))
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "text.bubble.fill")
                            .kidFont(15, .bold)
                            .foregroundStyle(Func.infoDeep)
                        Text("今日句子：\(todaySentencesText)")
                            .kidFont(13, .bold)
                            .foregroundStyle(Palette.ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Image(systemName: "speaker.wave.2.fill")
                            .kidFont(13, .bold)
                            .foregroundStyle(Func.infoDeep)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Palette.canvasCool, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(PressableStyle())
            }

            // 生活里这样用（写死在词包里，全离线）
            if let tip = primaryPack?.tipZh, !tip.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .kidFont(15, .bold)
                        .foregroundStyle(PhraseColors.gold)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("生活里这样用")
                            .kidFont(13, .heavy)
                            .foregroundStyle(Func.accentDeep)
                        Text(tip)
                            .kidFont(13, .medium)
                            .foregroundStyle(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PhraseColors.gold.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .onDisappear {
            wordPlayer.stop()
            phraseAudio.stop()
        }
    }

    private func wordCell(_ w: String) -> some View {
        let key = "\(store.currentProfileId)-baby-\(w)"
        let hasRec = recorder.hasRecording(key) || LaunchOptions.isUIScreenshotRun
        let cn = store.wordDict[w]?.meaningCn ?? ""
        let pic = store.babyData?.picture(for: w) ?? w
        return Button {
            playChildOrModel(word: w, key: key)
        } label: {
            HStack(spacing: 6) {
                BabyPicture(word: pic, size: 36)
                VStack(alignment: .leading, spacing: 1) {
                    Text(w)
                        .kidFont(15, .heavy)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(cn.isEmpty ? "点听发音" : cn)
                        .kidFont(12, .medium)
                        .foregroundStyle(Palette.inkMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Spacer(minLength: 0)
                ZStack {
                    Circle()
                        .fill(hasRec ? Func.positive.opacity(0.18) : Palette.canvasCool)
                        .frame(width: 28, height: 28)
                    Image(systemName: hasRec ? "waveform" : "speaker.wave.2.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(hasRec ? Func.positiveDeep : Func.infoDeep)
                }
            }
            .padding(7)
            .background(Palette.canvasCool.opacity(0.65), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(playingWord == w ? Func.positiveDeep : Palette.hairline, lineWidth: 1.2)
            }
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("\(w)，\(cn)")
    }

    private func playChildOrModel(word: String, key: String) {
        playingWord = word
        if recorder.hasRecording(key) {
            recorder.playBack(key) {
                playingWord = nil
            }
        } else {
            wordPlayer.playWord(word, url: store.audioURL(forWord: word))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if playingWord == word { playingWord = nil }
            }
        }
    }
}
