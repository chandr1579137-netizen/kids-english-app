import SwiftUI

// MARK: - 绘本 Tab：90 课封面网格 → 点进 PictureBookReaderView 简单阅读
struct PictureBookView: View {
    @Environment(DataStore.self) private var store

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    Text("绘本").pageTitleStyle()
                        .padding(.horizontal)
                        .padding(.top, 4)
                    Text("\(store.lessons.count) 本可翻的图画书")
                        .pageSubtitleStyle()
                        .padding(.horizontal)
                        .padding(.bottom, 14)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(store.lessons) { lesson in
                            NavigationLink {
                                PictureBookReaderView(lesson: lesson)
                            } label: {
                                VStack(spacing: 6) {
                                    CoverImage(url: store.coverURL(forLesson: lesson.id),
                                               fallbackText: lesson.titleCn)
                                        .imageFrame(height: 110, corner: Radius.thumb)
                                    Text(lesson.titleCn)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Palette.ink)
                                        .lineLimit(1)
                                }
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
}

// MARK: - 绘本阅读器：大封面 + 标题 + 段落大字（英文+中文）+ 每段播放按钮
struct PictureBookReaderView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var player = AudioPlayer()
    let lesson: Lesson

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SubPageHeader(onBack: { dismiss() })

                CoverImage(url: store.coverURL(forLesson: lesson.id), fallbackText: lesson.titleCn)
                    .imageFrame(height: 220, corner: Radius.sheet)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.titleCn)
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                    Text(lesson.title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Palette.inkMuted)
                }
                .padding(.horizontal)

                ForEach(lesson.content, id: \.paragraphId) { paragraph in
                    paragraphCard(paragraph)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
        .creamBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    private func paragraphCard(_ paragraph: Paragraph) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(paragraph.text)
                .font(.title2)
                .lineSpacing(8)
            Text(paragraph.translation)
                .font(.title3)
                .foregroundStyle(.secondary)
                .lineSpacing(6)
            Button {
                if let url = store.audioURL(forLesson: lesson.id, paragraphId: paragraph.paragraphId) {
                    player.play(url: url)
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 34))
                    Text("听一听")
                        .font(.title2).bold()
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 64)
                .background(Func.infoDeep)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.sheet))
        .elevationGround()
        .padding(.horizontal)
    }
}
