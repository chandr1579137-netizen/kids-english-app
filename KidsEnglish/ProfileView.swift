import SwiftUI

/// 我的：学习报告、儿歌、家长模式、每日限时
struct ProfileView: View {
    @Environment(DataStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    hero
                    report
                    NavigationLink {
                        SongsView()
                    } label: {
                        menuRow(icon: "music.note", tint: .purple, title: "英文儿歌", trailing: .chevron)
                    }
                    .buttonStyle(PressableStyle())
                    NavigationLink {
                        ParentGateView()
                    } label: {
                        menuRow(icon: "lock.fill", tint: .orange, title: "家长模式", trailing: .lock)
                    }
                    .buttonStyle(PressableStyle())
                    limitRow
                    NavigationLink {
                        ProfileSettingsView()
                    } label: {
                        menuRow(icon: "gearshape.fill", tint: .gray, title: "设置", trailing: .chevron)
                    }
                    .buttonStyle(PressableStyle())
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            .creamBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var hero: some View {
        HStack(spacing: 16) {
            KidAvatar()
                .frame(width: 86, height: 86)
            VStack(alignment: .leading, spacing: 8) {
                Text("小宝贝")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white)
                Label("已学习 \(store.studyDayCount) 天", systemImage: "calendar")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))
                Label("连续打卡 \(store.streakDays) 天", systemImage: "flame.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.48, green: 0.38, blue: 1.0),
                    Color(red: 0.70, green: 0.36, blue: 0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.purple.opacity(0.28), radius: 12, y: 6)
    }

    private var report: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("学习报告", systemImage: "chart.bar.fill")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.navy)
            HStack(spacing: 0) {
                stat(icon: "book.closed.fill", color: AppTheme.brightBlue, value: "\(store.learnedWords.count)", label: "已学单词")
                divider
                stat(icon: "text.book.closed.fill", color: .green, value: "\(store.completedCount)", label: "已读短文")
                divider
                stat(icon: "target", color: .orange, value: store.gameAnswered == 0 ? "—" : "\(store.gameAccuracy)%", label: "游戏正确率")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 1, height: 64)
    }

    private func stat(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var limitRow: some View {
        Menu {
            Button("不限") { setLimit(0) }
            Button("10 分钟") { setLimit(10) }
            Button("20 分钟") { setLimit(20) }
            Button("30 分钟") { setLimit(30) }
        } label: {
            menuRow(
                icon: "clock.fill",
                tint: .orange,
                title: store.timeLimitMinutes == 0 ? "每日限时 不限" : "每日限时 \(store.timeLimitMinutes) 分钟",
                trailing: .lock
            )
        }
    }

    private func setLimit(_ minutes: Int) {
        store.timeLimitMinutes = minutes
        store.saveProgress()
    }

    private enum Trailing { case chevron, lock }

    private func menuRow(icon: String, tint: Color, title: String, trailing: Trailing) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3.bold())
                .foregroundStyle(tint)
                .frame(width: 32)
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.navy)
            Spacer()
            Image(systemName: trailing == .chevron ? "chevron.right" : "lock.fill")
                .font(trailing == .chevron ? .body.weight(.semibold) : .body)
                .foregroundStyle(Color.gray.opacity(0.45))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}

struct ProfileSettingsView: View {
    @Environment(DataStore.self) private var store

    var body: some View {
        List {
            Section("每天新学") {
                Stepper("\(store.dailyNewWords) 个", value: Binding(
                    get: { store.dailyNewWords },
                    set: { store.dailyNewWords = $0; store.saveProgress() }
                ), in: 5...20, step: 5)
            }
            Section("课文") {
                Toggle("默认显示中文翻译", isOn: Binding(
                    get: { store.showTranslationDefault },
                    set: { store.showTranslationDefault = $0; store.saveProgress() }
                ))
            }
            Section("关于") {
                Text("内容来源：magic-english-buddy（CC BY-NC-SA 4.0）\n仅限家庭内部学习使用")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 参考图里的圆形小孩头像，用形状画出来，不依赖额外图片。
struct KidAvatar: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.white)
            Circle()
                .fill(Color(red: 1.0, green: 0.86, blue: 0.72))
                .padding(8)
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color(red: 0.45, green: 0.28, blue: 0.16))
                    .frame(width: 46, height: 22)
                    .offset(y: 6)
                Circle()
                    .fill(Color(red: 1.0, green: 0.84, blue: 0.70))
                    .frame(width: 40, height: 40)
                    .overlay(
                        HStack(spacing: 10) {
                            Circle().fill(Color.black).frame(width: 4, height: 4)
                            Circle().fill(Color.black).frame(width: 4, height: 4)
                        }
                        .offset(y: -4)
                    )
                    .overlay(
                        Capsule()
                            .fill(Color(red: 0.9, green: 0.45, blue: 0.45))
                            .frame(width: 10, height: 4)
                            .offset(y: 8)
                    )
            }
            .offset(y: 4)
            Image(systemName: "sparkle")
                .font(.caption.bold())
                .foregroundStyle(.yellow)
                .offset(x: 22, y: -24)
        }
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 3))
    }
}
