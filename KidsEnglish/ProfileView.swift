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
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Palette.surface)
                    .frame(width: 68, height: 68)
                Text("🧒").font(.system(size: 38))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("小宝贝")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(.white)

                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13, weight: .semibold))
                    Text("已学习 \(store.studyDayCount) 天")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white.opacity(0.95))

                HStack(spacing: 5) {
                    Text("🔥").font(.system(size: 13))
                    Text("连续打卡 \(store.streakDays) 天")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white.opacity(0.95))
            }

            Spacer(minLength: 0)
        }
        .padding(18)
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
                    .font(.system(size: 18, weight: .heavy))
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
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.inkMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(width: 1, height: 44)
    }

    // MARK: - 设置组（4 行合并为一组，靠分隔线而非 4 张卡）

    private var settingsGroup: some View {
        VStack(spacing: 0) {
            NavigationLink {
                SongsView()
            } label: {
                settingRow(icon: "music.note", title: "英文儿歌")
            }

            rowDivider

            NavigationLink {
                ParentGateView()
            } label: {
                settingRow(icon: "lock.fill", title: "家长模式", trailingIcon: "lock.fill")
            }

            rowDivider

            NavigationLink {
                SettingsDetailView()
            } label: {
                settingRow(icon: "timer", title: "每日限时",
                           value: store.timeLimitMinutes == 0 ? "不限" : "\(store.timeLimitMinutes) 分钟")
            }

            rowDivider

            NavigationLink {
                SettingsDetailView()
            } label: {
                settingRow(icon: "gearshape.fill", title: "设置")
            }
        }
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
        .elevationGround()
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(height: 1)
            .padding(.leading, 52)
    }

    private func settingRow(icon: String, title: String,
                            value: String? = nil,
                            trailingIcon: String? = nil) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Func.accentDeep)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.ink)

            Spacer(minLength: 8)

            if let value {
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Palette.inkMuted)
            }

            if let trailingIcon {
                Image(systemName: trailingIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.inkSubtle)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Palette.inkSubtle)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .contentShape(Rectangle())
    }
}

// MARK: - 设置详情（每日限时 / 每天新学词数）

struct SettingsDetailView: View {
    @Environment(DataStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
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
            }
            .padding(.horizontal)
            .padding(.top, 4)
        }
        .creamBackground()
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}
