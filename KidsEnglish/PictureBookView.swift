import SwiftUI

/// 绘本：封面网格，点进去一页一句，可以翻页。
struct PictureBookView: View {
    @Environment(DataStore.self) private var store
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("绘本")
                        .font(.system(size: 48, weight: .heavy))
                        .foregroundStyle(AppTheme.navy)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    Text("\(store.lessons.count) 本图画故事")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.gray)
                        .padding(.horizontal)
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(store.lessons) { lesson in
                            NavigationLink {
                                PictureBookReaderView(lesson: lesson)
                            } label: {
                                VStack(spacing: 8) {
                                    CoverImage(url: store.coverURL(forLesson: lesson.id), fallbackText: String(lesson.titleCn.prefix(1)))
                                        .frame(height: 140)
                                        .frame(maxWidth: .infinity)
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    Text(lesson.title)
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                        .lineLimit(1)
                                    Text(lesson.titleCn)
                                        .font(.headline.bold())
                                        .foregroundStyle(AppTheme.navy)
                                        .lineLimit(1)
                                        .padding(.bottom, 8)
                                }
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }
            .creamBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct PictureBookReaderView: View {
    @Environment(DataStore.self) private var store
    private let player = AudioPlayer.shared
    let lesson: Lesson

    @State private var page = 0
    @State private var forwards = true
    @State private var dragX: CGFloat = 0
    @State private var flip: Double = 0

    private var pageCount: Int { lesson.content.count + 1 }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                pageBody
                    .id(page)
                    .offset(x: dragX)
                    .rotation3DEffect(
                        .degrees(flip + Double(dragX) / 14),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: dragX >= 0 ? .leading : .trailing,
                        perspective: 0.55
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: forwards ? .trailing : .leading).combined(with: .opacity),
                        removal: .move(edge: forwards ? .leading : .trailing).combined(with: .opacity)
                    ))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 16)
            .gesture(turnGesture)
            .animation(Motion.spring, value: page)

            HStack(spacing: 18) {
                turnButton("上一页", system: "chevron.left") { changePage(-1) }
                    .opacity(page == 0 ? 0.35 : 1)
                    .disabled(page == 0)
                Text("\(page + 1) / \(pageCount)")
                    .font(.headline.bold())
                    .foregroundStyle(AppTheme.navy)
                turnButton("下一页", system: "chevron.right") { changePage(1) }
                    .opacity(page + 1 >= pageCount ? 0.35 : 1)
                    .disabled(page + 1 >= pageCount)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .creamBackground()
        .navigationTitle(lesson.titleCn)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .onDisappear { player.stop() }
    }

    @ViewBuilder
    private var pageBody: some View {
        if page == 0 {
            VStack(spacing: 16) {
                CoverImage(url: store.coverURL(forLesson: lesson.id), fallbackText: String(lesson.titleCn.prefix(1)))
                    .frame(height: 240)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                Text(lesson.title)
                    .font(.title2.bold())
                    .foregroundStyle(.secondary)
                Text(lesson.titleCn)
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(AppTheme.navy)
                    .multilineTextAlignment(.center)
                Text("向左滑，开始听故事")
                    .font(.headline)
                    .foregroundStyle(.gray)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        } else {
            let paragraph = lesson.content[page - 1]
            VStack(spacing: 18) {
                Text(paragraph.text)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(AppTheme.navy)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                Text(paragraph.translation)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button {
                    play(paragraph, autoAdvance: false)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.2.fill")
                        Text("听一听")
                    }
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.brightBlue)
                    .clipShape(Capsule())
                }
                .buttonStyle(PressableStyle())
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        }
    }

    private var turnGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragX = value.translation.width
            }
            .onEnded { value in
                let width = value.translation.width
                if width < -70 {
                    changePage(1)
                } else if width > 70 {
                    changePage(-1)
                } else {
                    withAnimation(Motion.spring) { dragX = 0 }
                }
            }
    }

    private func turnButton(_ title: String, system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: system)
                .font(.headline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppTheme.brightBlue)
                .clipShape(Capsule())
        }
        .buttonStyle(PressableStyle())
    }

    private func changePage(_ delta: Int) {
        let next = page + delta
        guard next >= 0, next < pageCount else {
            withAnimation(Motion.spring) { dragX = 0 }
            return
        }
        forwards = delta > 0
        flip = delta > 0 ? -46 : 46
        withAnimation(Motion.spring) {
            page = next
            dragX = 0
            flip = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            guard page == next, page > 0 else { return }
            play(lesson.content[page - 1], autoAdvance: true)
        }
    }

    private func play(_ paragraph: Paragraph, autoAdvance: Bool) {
        let url = store.audioURL(forLesson: lesson.id, paragraphId: paragraph.paragraphId)
        player.onFinish = {
            guard autoAdvance else { return }
            if page + 1 < pageCount, page > 0, lesson.content[page - 1].paragraphId == paragraph.paragraphId {
                changePage(1)
            }
        }
        player.play(url: url, spokenFallback: paragraph.text)
    }
}
