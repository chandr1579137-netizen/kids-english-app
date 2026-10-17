import SwiftUI

/// 封面图：异步加载本地文件，避免主线程解码卡顿
struct CoverImage: View {
    let url: URL?
    let fallbackText: String

    var body: some View {
        // 用 Color.clear 当尺寸权威：父级给多大就是多大。
        // 之前直接放 AsyncImage + aspectRatio(.fill)，图片的固有宽度会反过来撑宽
        // 网格单元，导致 3 列封面溢出到屏幕边缘、并吃掉 16pt 页边距。
        Color.clear
            .overlay { content }
            .clipped()
    }

    @ViewBuilder
    private var content: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: .fill)
                default:
                    fallback
                }
            }
        } else {
            fallback
        }
    }

    private var fallback: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(LinearGradient(
                colors: [.orange.opacity(0.7), .pink.opacity(0.7)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(Text(fallbackText).font(.largeTitle))
    }
}

/// 学习地图：7 个等级，每个等级的课程节点
struct MapView: View {
    @Environment(DataStore.self) private var store
    @State private var selectedLesson: Lesson?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(LevelInfo.all, id: \.level) { level in
                        LevelSection(level: level, selectedLesson: $selectedLesson)
                    }
                }
                .padding()
            }
            .navigationTitle("🗺️ 学习地图")
            .navigationDestination(item: $selectedLesson) { lesson in
                LessonView(lesson: lesson)
            }
        }
    }
}

struct LevelSection: View {
    @Environment(DataStore.self) private var store
    let level: LevelInfo
    @Binding var selectedLesson: Lesson?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(level.icon) L\(level.level) \(level.name)")
                    .font(.title2.bold())
                Spacer()
                let done = store.lessons(for: level.level).filter { store.completedLessons.contains($0.id) }.count
                let total = store.lessons(for: level.level).count
                Text("\(done)/\(total)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                ForEach(store.lessons(for: level.level)) { lesson in
                    LessonCard(lesson: lesson) {
                        if store.isUnlocked(lesson) { selectedLesson = lesson }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
}

struct LessonCard: View {
    @Environment(DataStore.self) private var store
    let lesson: Lesson
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    CoverImage(url: store.coverURL(forLesson: lesson.id),
                               fallbackText: String(lesson.titleCn.prefix(1)))
                    if !store.isUnlocked(lesson) {
                        Color.black.opacity(0.45)
                        Image(systemName: "lock.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    } else if store.completedLessons.contains(lesson.id) {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                    .background(Color.white.clipShape(Circle()))
                            }
                            Spacer()
                        }
                        .padding(6)
                    }
                }
                .frame(height: 80)
                .cornerRadius(12)
                .clipped()

                Text(lesson.titleCn)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.primary)
            }
        }
        .disabled(!store.isUnlocked(lesson))
    }
}
