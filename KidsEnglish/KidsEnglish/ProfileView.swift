import SwiftUI

/// "我的" Tab：学习报告、儿歌入口、家长模式入口、设置
struct ProfileView: View {
    @Environment(DataStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    reportCard
                    entriesCard
                    settingsCard
                }
                .padding()
            }
            .navigationTitle("我的")
        }
    }

    // MARK: - 学习报告

    private var reportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习报告")
                .font(.headline)

            // 已学单词
            HStack {
                Text("已学单词")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(store.learnedWords.count) / 1074")
                    .font(.title2.bold())
            }

            // 今日学习时长
            HStack {
                Text("今日学习")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(store.studyMinutesToday()) 分钟")
                    .font(.title2.bold())
            }

            Divider()

            // 各主题进度（前 6 个）
            Text("主题进度")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ForEach(store.wordThemes.prefix(6)) { theme in
                let progress = store.themeProgress(themeId: theme.id)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(theme.nameCn)
                            .font(.subheadline)
                        Spacer()
                        Text("\(progress.done)/\(progress.total)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: progress.total > 0 ? Double(progress.done) / Double(progress.total) : 0)
                        .tint(.orange)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - 功能入口

    private var entriesCard: some View {
        VStack(spacing: 0) {
            NavigationLink {
                SongsView()
            } label: {
                entryRow(icon: "music.note", title: "儿歌")
            }
            Divider()
            NavigationLink {
                ParentGateView()
            } label: {
                entryRow(icon: "lock.fill", title: "家长模式")
            }
        }
        .padding(.horizontal)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func entryRow(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.orange)
                .frame(width: 28)
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 14)
    }

    // MARK: - 设置

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("设置")
                .font(.headline)

            // 每日限时
            HStack {
                Text("每日限时")
                Spacer()
                Picker("每日限时", selection: Binding(
                    get: { store.timeLimitMinutes },
                    set: { store.timeLimitMinutes = $0; store.saveProgress() }
                )) {
                    Text("不限").tag(0)
                    Text("10 分钟").tag(10)
                    Text("20 分钟").tag(20)
                    Text("30 分钟").tag(30)
                }
                .pickerStyle(.menu)
            }

            // 每天新学词数
            HStack {
                Text("每天新学词数")
                Spacer()
                Stepper("\(store.dailyNewWords) 个", value: Binding(
                    get: { store.dailyNewWords },
                    set: { store.dailyNewWords = $0; store.saveProgress() }
                ), in: 5...30, step: 5)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}
