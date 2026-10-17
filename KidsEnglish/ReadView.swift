import SwiftUI

// MARK: - 读短文 Tab：L1–L7 分级筛选 + 课次列表
struct ReadView: View {
    @Environment(DataStore.self) private var store

    /// 数据里 L1–L7 全部存在（共 90 课），不跳过任何一级
    private let levels = [1, 2, 3, 4, 5, 6, 7]
    @State private var selectedLevel = 1

    private var currentLessons: [Lesson] {
        store.lessons(for: selectedLevel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    Text("读短文").pageTitleStyle()
                        .padding(.horizontal)
                        .padding(.top, 4)
                    Text("\(store.lessons.count) 篇分级小故事")
                        .pageSubtitleStyle()
                        .padding(.horizontal)
                        .padding(.bottom, 14)

                    levelPicker
                        .padding(.bottom, 14)

                    LazyVStack(spacing: 10) {
                        ForEach(currentLessons) { lesson in
                            NavigationLink {
                                LessonView(lesson: lesson)
                            } label: {
                                lessonRow(lesson)
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 12)
            }
            .creamBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - 分级筛选

    private var levelPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(levels, id: \.self) { level in
                    let isSelected = selectedLevel == level
                    let hasLessons = !store.lessons(for: level).isEmpty
                    Button {
                        guard hasLessons else { return }
                        selectedLevel = level
                    } label: {
                        Text("L\(level)")
                            .font(.system(size: 17, weight: .heavy))
                            // 选中 = 强调色底 + 自动对比文字；未选中 = 浅底 + 弱化文字
                            .foregroundStyle(isSelected ? onFill(Func.accent)
                                             : (hasLessons ? Palette.inkMuted : Palette.inkSubtle))
                            .frame(width: 52, height: 44)
                            .background(
                                isSelected ? Func.accent : Palette.hairline,
                                in: RoundedRectangle(cornerRadius: Radius.chip)
                            )
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("第 \(level) 级")
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 3)
        }
    }

    // MARK: - 课次行

    private func lessonRow(_ lesson: Lesson) -> some View {
        let isRead = store.completedLessons.contains(lesson.id)
        return HStack(spacing: 14) {
            CoverImage(url: store.coverURL(forLesson: lesson.id), fallbackText: lesson.titleCn)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: Radius.thumb))

            // 英文标题是主信息（用户读的是英文），中文做副信息
            VStack(alignment: .leading, spacing: 3) {
                Text(lesson.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                Text(lesson.titleCn)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Palette.inkMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // 状态用形状区分（勾 / 播放），不只靠颜色
            Image(systemName: isRead ? "checkmark.circle.fill" : "play.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(isRead ? Func.positiveDeep : Palette.inkSubtle)
                .accessibilityLabel(isRead ? "已读" : "未读")
        }
        .padding(10)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
        .elevationGround()
    }
}
