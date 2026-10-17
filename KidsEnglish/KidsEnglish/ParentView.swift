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
        ScrollView {
            VStack(spacing: 16) {
                SubPageHeader(onBack: { dismiss() })

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Func.accent.opacity(0.16))
                            .frame(width: 96, height: 96)
                        Text("🔒").font(.system(size: 44))
                    }

                    Text("家长验证")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(Palette.ink)

                    Text("请回答下面的数学题进入家长区\n（防止小朋友误入）")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Palette.inkMuted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)

                    Text("\(a) + \(b) = ?")
                        .font(.system(size: 44, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                        .padding(.top, 2)

                    TextField("答案", text: $answer)
                        .keyboardType(.numberPad)
                        .font(.system(size: 28, weight: .bold))
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
                            .font(.system(size: 15, weight: .semibold))
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

    var body: some View {
        ScrollView {
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
                    statRow("已完成课程", "\(store.completedCount) / \(store.lessons.count)")
                    statRow("今日学习", "\(store.studyMinutesToday()) 分钟")
                    statRow("收藏单词", "\(store.favoriteWords.count) 个")
                    statRow("收集卡片", "\(store.collectedCards.count) 张")
                }

                card("每日限时") {
                    HStack {
                        Text("每天最多学")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                        Spacer()
                        Picker("每天最多学", selection: Binding(
                            get: { store.timeLimitMinutes },
                            set: { store.timeLimitMinutes = $0; store.saveProgress() }
                        )) {
                            Text("不限").tag(0)
                            Text("15 分钟").tag(15)
                            Text("20 分钟").tag(20)
                            Text("30 分钟").tag(30)
                            Text("45 分钟").tag(45)
                            Text("60 分钟").tag(60)
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
                                    .font(.system(size: 15, weight: .bold))
                                Text("解除今日锁定")
                                    .font(.system(size: 16, weight: .bold))
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
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                    }
                    .tint(Func.accent)
                }

                card("关于") {
                    Text("内容来源：magic-english-buddy（GitHub 开源，CC BY-NC-SA 4.0）\n仅限家庭内部学习使用")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Palette.inkMuted)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
    }

    // MARK: - 组件

    private func card<Content: View>(_ title: String,
                                     @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(Palette.ink)
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
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Palette.ink)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Func.infoDeep)
        }
    }
}
