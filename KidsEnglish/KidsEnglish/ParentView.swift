import SwiftUI

/// 家长区入口：数学题解锁
struct ParentGateView: View {
    @State private var unlocked = false

    var body: some View {
        NavigationStack {
            if unlocked {
                ParentDashboardView()
            } else {
                ParentUnlockView(onUnlock: { unlocked = true })
                    .navigationTitle("家长中心")
            }
        }
    }
}

/// 家长解锁：答对数学题
struct ParentUnlockView: View {
    let onUnlock: () -> Void
    @State private var a = Int.random(in: 11...49)
    @State private var b = Int.random(in: 11...49)
    @State private var answer = ""
    @State private var wrong = false

    var body: some View {
        VStack(spacing: 24) {
            Text("🔒").font(.system(size: 80))
            Text("家长验证").font(.title.bold())
            Text("请回答下面的数学题进入家长区\n（防止小朋友误入）")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Text("\(a) + \(b) = ?")
                .font(.system(size: 48, weight: .bold))
            TextField("答案", text: $answer)
                .keyboardType(.numberPad)
                .font(.title)
                .multilineTextAlignment(.center)
                .frame(width: 160)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            if wrong {
                Text("不对哦，再算算").foregroundColor(.red)
            }
            Button("进入") {
                if Int(answer) == a + b {
                    onUnlock()
                } else {
                    wrong = true
                    answer = ""
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .font(.title3)
        }
        .padding()
    }
}

/// 家长仪表盘：学习报告 + 设置
struct ParentDashboardView: View {
    @Environment(DataStore.self) private var store

    var body: some View {
        List {
            Section("📊 学习报告") {
                HStack {
                    Text("已完成课程")
                    Spacer()
                    Text("\(store.completedCount) / \(store.lessons.count)")
                        .bold()
                }
                HStack {
                    Text("今日学习")
                    Spacer()
                    Text("\(store.studyMinutesToday()) 分钟").bold()
                }
                HStack {
                    Text("收藏单词")
                    Spacer()
                    Text("\(store.favoriteWords.count) 个").bold()
                }
                HStack {
                    Text("收集卡片")
                    Spacer()
                    Text("\(store.collectedCards.count) 张").bold()
                }
            }

            Section("⏱️ 每日限时") {
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
                if store.timeUp {
                    Button("🔓 解除今日锁定") {
                        store.resetTimeUp()
                    }
                }
            }

            Section("📖 显示") {
                Toggle("课文默认显示中文翻译", isOn: Binding(
                    get: { store.showTranslationDefault },
                    set: { store.showTranslationDefault = $0; store.saveProgress() }
                ))
            }

            Section("ℹ️ 关于") {
                Text("内容来源：magic-english-buddy（GitHub 开源，CC BY-NC-SA 4.0）\n仅限家庭内部学习使用")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("家长中心")
    }
}
