import SwiftUI

// MARK: - 读短文 Tab：按 L1–L7 分组，每课一行，点进 LessonView 阅读
struct ReadView: View {
    @Environment(DataStore.self) private var store

    private let levels = [1, 2, 3, 4, 5, 6, 7]

    var body: some View {
        NavigationStack {
            List {
                ForEach(levels, id: \.self) { level in
                    let lessons = store.lessons(for: level)
                    if !lessons.isEmpty {
                        Section("L\(level)") {
                            ForEach(lessons) { lesson in
                                NavigationLink {
                                    LessonView(lesson: lesson)
                                } label: {
                                    lessonRow(lesson)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .headerProminence(.increased)
                    }
                }
            }
            .navigationTitle("读短文")
        }
    }

    private func lessonRow(_ lesson: Lesson) -> some View {
        HStack(spacing: 14) {
            CoverImage(url: store.coverURL(forLesson: lesson.id), fallbackText: lesson.titleCn)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.titleCn)
                    .font(.title3).bold()
                Text(lesson.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
