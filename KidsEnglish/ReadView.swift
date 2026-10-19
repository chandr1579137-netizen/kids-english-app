import SwiftUI

// MARK: - 读短文 Tab：L1–L7 分级筛选 + 课次列表
struct ReadView: View {
    @Environment(DataStore.self) private var store

    /// 数据里 L1–L7 全部存在（共 90 课），不跳过任何一级
    private let levels = [1, 2, 3, 4, 5, 6, 7]
    @State private var selectedLevel = 1
    /// `-uiLesson` 截图用：直接把课文页当根视图渲染。
    /// 不走 push：path 式推入实测会落到 SwiftUI 的「无 destination」占位页
    /// （空白 + 黄色警告三角），而这里要的只是「把课文页拍进截图」。
    /// 用户真实点击仍走 NavigationLink 的 destination 闭包，行为不变。

    private var currentLessons: [Lesson] {
        store.lessons(for: selectedLevel)
    }

    /// 已读的课 + 该级第一篇未读的课可进入，其余保持锁定
    private func isUnlocked(_ lesson: Lesson) -> Bool {
        if store.completedLessons.contains(lesson.id) { return true }
        let firstUnread = currentLessons.first { !store.completedLessons.contains($0.id) }
        return firstUnread?.id == lesson.id
    }

    var body: some View {
        NavigationStack {
            Group {
                if LaunchOptions.forceLesson, let first = store.lessons(for: 1).first {
                    LessonView(lesson: first)
                } else {
                    lessonList
                }
            }
            .creamBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var lessonList: some View {
        KidScrollView {
            // 标题与「单词卡」「绘本」同一套：左对齐 + pageTitleStyle 深蓝。
            // 之前这里是 60pt 居中 + 专属蓝，同一层级出现了两种标题写法。
            VStack(alignment: .leading, spacing: 2) {
                Text("读短文")
                    .pageTitleStyle()
                Text("\(store.lessons.count) 篇分级小故事")
                    .pageSubtitleStyle()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom, 14)

            levelPicker
                .padding(.bottom, 14)

            LazyVStack(spacing: 10) {
                ForEach(currentLessons) { lesson in
                    let unlocked = isUnlocked(lesson)
                    NavigationLink {
                        LessonView(lesson: lesson)
                    } label: {
                        lessonRow(lesson)
                    }
                    .buttonStyle(PressableStyle())
                    // 锁不能只是画上去的：未解锁的课点开就等于没锁
                    .disabled(!unlocked)
                    .opacity(unlocked ? 1 : 0.65)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
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
                            .kidFont(19, .heavy)
                            // 选中 = 橙底白字；未选中 = 浅灰底深灰字（与参考图一致）
                            .foregroundStyle(isSelected ? .white
                                             : (hasLessons ? Palette.inkMuted : Palette.inkSubtle))
                            .frame(width: 52, height: 42)
                            .background(
                                isSelected ? Func.accentPill : Color(red: 0.90, green: 0.90, blue: 0.91),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
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
        // 该级里第一篇未读的课 = 可以点开的那篇；它之后的显示锁
        let isNext = !isRead && currentLessons.first(where: {
            !store.completedLessons.contains($0.id)
        })?.id == lesson.id
        return HStack(spacing: 12) {
            CoverImage(url: store.coverURL(forLesson: lesson.id), fallbackText: lesson.titleCn)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .clipped()

            // 英文标题是主信息（用户读的是英文），中文做副信息
            VStack(alignment: .leading, spacing: 2) {
                Text(lesson.title)
                    .kidFont(20, .bold)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(lesson.titleCn)
                    .kidFont(15, .medium)
                    .foregroundStyle(Palette.inkMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            // 三种状态：已读=绿色勾 / 下一课=灰色播放 / 之后=灰色锁
            ZStack {
                Circle()
                    .fill(isRead ? Func.positiveDeep : Color(red: 0.86, green: 0.86, blue: 0.87))
                    .frame(width: 32, height: 32)
                Image(systemName: isRead ? "checkmark" : (isNext ? "play.fill" : "lock.fill"))
                    .kidFont(isNext || isRead ? 15 : 13, .black)
                    .foregroundStyle(isRead ? .white : .white.opacity(0.95))
            }
            .accessibilityLabel(isRead ? "已读" : (isNext ? "可读" : "未解锁"))
        }
        .padding(10)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
        .elevationGround()
    }
}
