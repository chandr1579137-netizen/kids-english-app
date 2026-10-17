import SwiftUI
import UIKit

/// 课文阅读页：逐段朗读 + 逐词高亮 + 点词查词典 + 跟读录音
struct LessonView: View {
    @Environment(DataStore.self) private var store
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
                // 封面
                CoverImage(url: store.coverURL(forLesson: lesson.id),
                           fallbackText: String(lesson.titleCn.prefix(1)))
                    .frame(height: 200)
                    .cornerRadius(20)
                    .clipped()
                Text(lesson.title).font(.title.bold())
                Text(lesson.titleCn).font(.title3).foregroundColor(.secondary)

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
                }

                // 开始练习
                if !lesson.quiz.isEmpty {
                    Button {
                        showQuiz = true
                    } label: {
                        Text("✏️ 开始练习 (\(lesson.quiz.count) 道题)")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .navigationTitle(lesson.titleCn)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(showTranslation ? "中" : "EN") { showTranslation.toggle() }
            }
        }
        .sheet(item: $tappedWord) { entry in
            WordDetailView(entry: entry)
                .presentationDetents([.medium])
        }
        .alert("查不到这个词 😅", isPresented: $showUnknownWordAlert) {
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
        VStack(alignment: .leading, spacing: 10) {
            WordTextView(
                words: para.words.map { $0.word },
                highlightIndex: highlightIndex,
                onWordTap: onWordTap
            )
            .frame(minHeight: 60)

            if showTranslation {
                Text(para.translation)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                Button(action: onPlay) {
                    Label(isPlaying ? "暂停" : "🔊 朗读",
                          systemImage: isPlaying ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.bordered)

                Button(action: onRecord) {
                    Label(isRecording ? "停止录音" : "🎤 跟读",
                          systemImage: isRecording ? "stop.fill" : "mic.fill")
                }
                .buttonStyle(.bordered)
                .tint(isRecording ? .red : .blue)

                if recorder.hasRecording && !isRecording {
                    Button(action: { recorder.playBack() }) {
                        Label("回放", systemImage: "speaker.wave.2.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                }
                Spacer()
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
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
            for (i, w) in words.enumerated() {
                var attrs: [NSAttributedString.Key: Any] = [.font: font]
                if i == highlightIndex {
                    attrs[.backgroundColor] = UIColor.systemYellow
                    attrs[.foregroundColor] = UIColor.black
                } else {
                    attrs[.foregroundColor] = UIColor.label
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
