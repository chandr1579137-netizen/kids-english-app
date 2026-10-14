import SwiftUI

/// 读短文：L1–L7 横滑，完成 / 当前 / 锁定
struct ReadView: View {
    @Environment(DataStore.self) private var store
    @State private var level = 1

    private let levels = [1, 2, 3, 4, 5, 6, 7]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("读短文")
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundStyle(AppTheme.brightBlue)
                    .padding(.horizontal)
                    .padding(.top, 4)
                Text("\(store.lessons.count) 篇分级小故事")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.gray)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(levels, id: \.self) { lv in
                            Button {
                                withAnimation(Motion.spring) { level = lv }
                            } label: {
                                Text("L\(lv)")
                                    .font(.system(size: 22, weight: .heavy))
                                    .foregroundStyle(level == lv ? Color.white : Color.gray)
                                    .frame(width: 64, height: 64)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(level == lv ? Color.orange : Color.gray.opacity(0.18))
                                    )
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(store.lessons(for: level)) { lesson in
                            lessonRow(lesson)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .creamBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func lessonRow(_ lesson: Lesson) -> some View {
        let unlocked = store.isUnlocked(lesson)
        let done = store.completedLessons.contains(lesson.id)
        return NavigationLink {
            LessonView(lesson: lesson)
        } label: {
            HStack(spacing: 12) {
                CoverImage(url: store.coverURL(forLesson: lesson.id), fallbackText: String(lesson.titleCn.prefix(1)))
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.title)
                        .font(.headline.bold())
                        .foregroundStyle(AppTheme.navy)
                        .lineLimit(1)
                    Text(lesson.titleCn)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                statusBadge(done: done, unlocked: unlocked)
            }
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        }
        .buttonStyle(PressableStyle())
        .disabled(!unlocked)
    }

    private func statusBadge(done: Bool, unlocked: Bool) -> some View {
        Group {
            if done {
                Image(systemName: "checkmark")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.green))
            } else if unlocked {
                Image(systemName: "play.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.gray.opacity(0.45)))
            } else {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundStyle(.gray)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.gray.opacity(0.18)))
            }
        }
    }
}
