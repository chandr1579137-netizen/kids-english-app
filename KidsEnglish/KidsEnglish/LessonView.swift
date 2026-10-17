import SwiftUI
import UIKit

/// 课文阅读页：逐段朗读 + 逐词高亮 + 点词查词典 + 跟读录音
struct LessonView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let lesson: Lesson

    @State private var player = AudioPlayer()
    @State private var recorder = Recorder()
    @State private var playingParagraph: String?
    @State private var highlightIndex: [String: Int] = [:]  // paragraphId -> word index
    @State private var showTranslation: Bool = true
    @State private var tappedWord: WordEntry?
    @State private var tappedRawWord: String = ""
    @State private var showUnknownWordAlert = false
    @State private var showQuiz = false
    @State private var recordingParagraph: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 封面：与其他页统一内边距 + Radius.sheet
                CoverImage(url: store.coverURL(forLesson: lesson.id),
                           fallbackText: String(lesson.titleCn.prefix(1)))
                    .imageFrame(height: 200, corner: Radius.sheet)
                    .padding(.horizontal)
                    .padding(.top, 4)

                // 英文是主信息（孩子读的是英文），中文做副信息
                VStack(spacing: 4) {
                    Text(lesson.title)
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                    Text(lesson.titleCn)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Palette.inkMuted)
                }
                .padding(.horizontal)

                // 段落
                ForEach(lesson.content, id: \.paragraphId) { para in
                    ParagraphCard(
                        lesson: lesson,
                        para: para,
                        player: player,
                        recorder: recorder,
                        isPlaying: playingParagraph == para.paragraphId,
                        highlightIndex: highlightIndex[para.paragraphId] ?? -1,
                        showTranslation: showTranslation,
                        isRecording: recordingParagraph == para.paragraphId,
                        onPlay: { togglePlay(para) },
                        onWordTap: { word in
                            if let entry = store.lookupWord(word) {
                                tappedWord = entry
                            } else {
                                tappedRawWord = word
                                showUnknownWordAlert = true
                            }
                        },
                        onRecord: { toggleRecord(para) }
                    )
                    .padding(.horizontal)
                }

                // 开始练习
                if !lesson.quiz.isEmpty {
                    AppButton(title: "开始练习 · \(lesson.quiz.count) 道题",
                              icon: "pencil.and.list.clipboard",
                              tier: .primary) {
                        showQuiz = true
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .padding(.vertical, 12)
        }
        .creamBackground()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) { lessonHeader }
        .sheet(item: $tappedWord) { entry in
            WordDetailView(entry: entry)
                .presentationDetents([.medium])
        }
        .alert("查不到这个词", isPresented: $showUnknownWordAlert) {
            Button("知道了") { }
        } message: {
            Text("「\(tappedRawWord)」暂时没有收录")
        }
        .navigationDestination(isPresented: $showQuiz) {
            QuizView(lesson: lesson)
        }
        .onDisappear {
            player.stop()
        }
    }

    /// 自定义顶栏：系统返回键在英文环境下会显示 “Back”，中文 App 里很突兀
    private var lessonHeader: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                    Text("返回")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(Func.infoDeep)
                .frame(height: 44)
            }
            .buttonStyle(PressableStyle())

            Spacer()

            Text(lesson.titleCn)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)

            Spacer()

            // 译文开关：一个开关只表达一件事
            Button {
                showTranslation.toggle()
            } label: {
                Text(showTranslation ? "译文开" : "译文关")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(showTranslation ? onFill(Func.accent) : Palette.inkMuted)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(
                        showTranslation ? Func.accent : Palette.hairline,
                        in: Capsule()
                    )
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("中文译文")
            .accessibilityValue(showTranslation ? "已开启" : "已关闭")
        }
        .padding(.horizontal)
        .background(Palette.canvas)
    }

    private func togglePlay(_ para: Paragraph) {
        if playingParagraph == para.paragraphId {
            player.pause()
            playingParagraph = nil
            return
        }
        guard let url = store.audioURL(forLesson: lesson.id, paragraphId: para.paragraphId) else { return }
        playingParagraph = para.paragraphId
        player.onTimeUpdate = { t in
            if t > 900000 {  // 播放结束
                playingParagraph = nil
                highlightIndex[para.paragraphId] = -1
                return
            }
            let ms = t * 1000
            if let idx = para.words.firstIndex(where: { ms >= $0.start && ms < $0.end }) {
                highlightIndex[para.paragraphId] = idx
            }
        }
        player.play(url: url)
    }

    private func toggleRecord(_ para: Paragraph) {
        if recordingParagraph == para.paragraphId {
            recorder.toggleRecord()
            recordingParagraph = nil
        } else {
            player.stop()
            playingParagraph = nil
            recorder.toggleRecord()
            recordingParagraph = para.paragraphId
        }
    }
}

/// 段落卡片
struct ParagraphCard: View {
    @Environment(DataStore.self) private var store
    let lesson: Lesson
    let para: Paragraph
    let player: AudioPlayer
    let recorder: Recorder
    let isPlaying: Bool
    let highlightIndex: Int
    let showTranslation: Bool
    let isRecording: Bool
    let onPlay: () -> Void
    let onWordTap: (String) -> Void
    let onRecord: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            WordTextView(
                words: para.words.map { $0.word },
                highlightIndex: highlightIndex,
                onWordTap: onWordTap
            )
            .frame(minHeight: 60)

            if showTranslation {
                Text(para.translation)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Palette.inkMuted)
            }

            HStack(spacing: 10) {
                compactButton(
                    title: isPlaying ? "暂停" : "朗读",
                    icon: isPlaying ? "pause.fill" : "play.fill",
                    fill: Func.positiveDeep,
                    fg: .white,
                    action: onPlay
                )
                compactButton(
                    title: isRecording ? "停止" : "跟读",
                    icon: isRecording ? "stop.fill" : "mic.fill",
                    fill: isRecording ? Func.negativeDeep : Func.info.opacity(0.28),
                    fg: isRecording ? .white : Palette.ink,
                    action: onRecord
                )
                if recorder.hasRecording && !isRecording {
                    compactButton(
                        title: "回放",
                        icon: "speaker.wave.2.fill",
                        fill: Palette.hairline,
                        fg: Palette.ink,
                        action: { recorder.playBack() }
                    )
                }
                Spacer()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
        .elevationGround()
    }

    /// 段落内的小操作：比全局按钮矮一档，避免和主 CTA 抢
    private func compactButton(title: String, icon: String,
                               fill: Color, fg: Color,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(fg)
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(fill, in: Capsule())
        }
        .buttonStyle(PressableStyle())
    }
}

/// 可点词 + 高亮的文本（UITextView 封装）
struct WordTextView: UIViewRepresentable {
    let words: [String]
    let highlightIndex: Int
    let onWordTap: (String) -> Void

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap(_:)))
        tv.addGestureRecognizer(tap)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        let coord = context.coordinator
        coord.words = words
        coord.onWordTap = onWordTap
        // 单词或高亮变化时才重建，避免每帧刷新
        if coord.lastWords != words || coord.lastHighlight != highlightIndex {
            coord.lastWords = words
            coord.lastHighlight = highlightIndex
            let attr = NSMutableAttributedString()
            let font = UIFont.systemFont(ofSize: 22, weight: .medium)
            // 与全站文字色一致：深蓝而非系统黑，且高亮仍保持深字浅底
            let ink = UIColor(Palette.ink)
            let highlightBg = UIColor(Func.accent).withAlphaComponent(0.38)
            for (i, w) in words.enumerated() {
                var attrs: [NSAttributedString.Key: Any] = [.font: font]
                if i == highlightIndex {
                    attrs[.backgroundColor] = highlightBg
                    attrs[.foregroundColor] = ink
                } else {
                    attrs[.foregroundColor] = ink
                }
                attr.append(NSAttributedString(string: w, attributes: attrs))
                if i < words.count - 1 {
                    attr.append(NSAttributedString(string: " ", attributes: [.font: font]))
                }
            }
            tv.attributedText = attr
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject {
        var words: [String] = []
        var onWordTap: (String) -> Void = { _ in }
        var lastWords: [String] = []
        var lastHighlight: Int = -2

        @objc func handleTap(_ g: UITapGestureRecognizer) {
            guard let tv = g.view as? UITextView else { return }
            let loc = g.location(in: tv)
            let layout = tv.layoutManager
            let idx = layout.characterIndex(
                for: loc, in: tv.textContainer,
                fractionOfDistanceBetweenInsertionPoints: nil)
            // 根据字符位置找到对应单词
            var count = 0
            for w in words {
                let end = count + w.count
                if idx >= count && idx < end {
                    let clean = w.trimmingCharacters(in: .punctuationCharacters)
                    if !clean.isEmpty { onWordTap(clean) }
                    return
                }
                count = end + 1  // +空格
            }
        }
    }
}
