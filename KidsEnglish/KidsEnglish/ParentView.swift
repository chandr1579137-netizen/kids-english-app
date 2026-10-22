import SwiftUI

/// 家长区入口：数学题解锁。
///
/// 这几个页面此前全是系统组件（`List` / `navigationTitle` / 系统按钮），
/// 与主流程的自绘顶栏、白卡、糖果按钮不是一套语言，这里统一。
struct ParentGateView: View {
    @State private var unlocked = false

    var body: some View {
        Group {
            if unlocked {
                ParentDashboardView()
            } else {
                ParentUnlockView(onUnlock: { unlocked = true })
            }
        }
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

                card("学习报告") {
                    statRow("说一说", "\(store.completedPhraseScenes.count) / \(store.phraseCatalog?.allScenes.count ?? 0) 个场景")
                    // 旧「读短文」已下线（先藏后删），进度只读归档，不再增加
                    statRow("旧版短文（已归档）", "\(store.completedCount) 篇")
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

                card("显示") {
                    Toggle(isOn: Binding(
                        get: { store.showTranslationDefault },
                        set: { store.showTranslationDefault = $0; store.saveProgress() }
                    )) {
                        Text("课文默认显示中文翻译")
                            .kidFont(17, .semibold)
                            .foregroundStyle(Palette.ink)
                    }
                    .tint(Func.accent)
                }

                card("宝宝模式（4 岁）") {
                    Toggle(isOn: Binding(
                        get: { store.babyMode },
                        set: { store.babyMode = $0; store.saveProgress() }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("打开宝宝模式")
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

                    statRow("宝宝模式已学", "\(store.babyWords.count) / \(store.babyData?.allWords.count ?? 0) 个词")
                    statRow("贴纸", "\(store.babyStickers.count) 张")
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
            if showResetConfirm {
                ConfirmCard(emoji: "🗑️",
                            title: "确定清除全部学习进度？",
                            message: "已学单词、已读课文、收藏和游戏成绩都会清空，且不能撤销。",
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
                        let result = store.importSnapshotJSON(importText)
                        importMessage = result
                        if result.hasPrefix("已恢复") {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                showImport = false
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
