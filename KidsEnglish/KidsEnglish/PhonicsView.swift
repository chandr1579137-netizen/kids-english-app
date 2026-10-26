import SwiftUI

// MARK: - 自然拼读专区：字母音探索岛（Group 1: s, a, t, i, p, n）

public struct PhonicsIslandView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var store
    @State private var audioPlayer = AudioPlayer()
    @State private var selectedLetter: PhonicsLetter? = LaunchOptions.phonicsLetter.flatMap(PhonicsCatalog.letter)
    @State private var showQuiz: Bool = LaunchOptions.phonicsQuiz
    @State private var playingLetterId: String? = nil
    @State private var bounce = false

    public init() {}

    public var body: some View {
        NavigationStack {
            KidScrollView {
                VStack(spacing: 16) {
                    // 顶栏返回与标题
                    HStack {
                        SubPageHeader(onBack: {
                            audioPlayer.stop()
                            dismiss()
                        })
                        Spacer(minLength: 0)
                        Button {
                            audioPlayer.stop()
                            showQuiz = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .kidFont(16, .heavy)
                                Text("听音挑战")
                                    .kidFont(16, .heavy)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Func.accent, in: Capsule())
                            .elevationRaised()
                        }
                        .buttonStyle(PressableStyle())
                        .accessibilityLabel("听音挑战测验")
                        .padding(.trailing, 16)
                    }

                    // 探索岛主标题栏
                    HStack(spacing: 14) {
                        TomMoodView(mood: .happy, size: 76)
                            .offset(y: bounce ? -6 : 0)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("字母音探索岛")
                                .kidFont(26, .heavy)
                                .foregroundStyle(Palette.ink)
                            Text("听顺口溜 · 做体感动作 · 认字母发音")
                                .kidFont(15, .bold)
                                .foregroundStyle(Palette.inkMuted)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(16)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .elevationGround()
                    .padding(.horizontal, 16)

                    // 6 个字母卡片网格（2 列 × 3 行）
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                        ForEach(PhonicsCatalog.group1) { item in
                            letterTile(item)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .creamBackground()
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedLetter) { letter in
                PhonicsLetterDetailView(letter: letter, onNext: { nextLetter(after: letter) })
            }
            .sheet(isPresented: $showQuiz) {
                PhonicsQuizView()
            }
            .onAppear {
                guard !LaunchOptions.isUIScreenshotRun else { return }
                playWelcomeAudio()
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    bounce = true
                }
            }
            .onDisappear {
                audioPlayer.stop()
            }
        }
    }

    private func letterTile(_ item: PhonicsLetter) -> some View {
        let isPlaying = playingLetterId == item.id
        return Button {
            audioPlayer.stop()
            selectedLetter = item
        } label: {
            VStack(spacing: 8) {
                HStack {
                    Text(item.letter)
                        .kidFont(36, .heavy)
                        .foregroundStyle(item.cardTint)
                    Spacer()
                    Text(item.phoneme)
                        .kidFont(16, .heavy)
                        .foregroundStyle(item.cardTint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.cardTint.opacity(0.14), in: Capsule())
                }

                GeometryReader { geo in
                    BabyPicture(word: item.word, size: geo.size.width)
                }
                .aspectRatio(1, contentMode: .fit)

                HStack {
                    Text(item.word)
                        .kidFont(17, .heavy)
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Button {
                        playChant(item)
                    } label: {
                        Image(systemName: isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .kidFont(18, .bold)
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(item.cardTint, in: Circle())
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            .padding(12)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(isPlaying ? item.cardTint : Palette.hairline, lineWidth: isPlaying ? 3 : 1.5)
            }
            .elevationRaised()
            .scaleEffect(isPlaying ? 1.03 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPlaying)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("\(item.letter) 的发音 \(item.phoneme)，代表词 \(item.word)")
    }

    private func playChant(_ item: PhonicsLetter) {
        audioPlayer.stop()
        playingLetterId = item.id
        if let url = store.phraseFileURL("audio", "\(item.audio).mp3") {
            audioPlayer.play(url: url)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                if playingLetterId == item.id { playingLetterId = nil }
            }
        } else {
            playingLetterId = nil
        }
    }

    private func playWelcomeAudio() {
        if let url = store.phraseFileURL("audio", "tom_phonics_island.mp3") {
            audioPlayer.play(url: url)
        }
    }

    private func nextLetter(after current: PhonicsLetter) {
        guard let idx = PhonicsCatalog.group1.firstIndex(of: current) else { return }
        let nextIdx = (idx + 1) % PhonicsCatalog.group1.count
        selectedLetter = PhonicsCatalog.group1[nextIdx]
    }
}

// MARK: - 字母音互动详情页（大图 + 动作口诀 + 跟读打卡）

public struct PhonicsLetterDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var store
    let letter: PhonicsLetter
    let onNext: () -> Void

    @State private var audioPlayer = AudioPlayer()
    @State private var tomMood: TomMood = .happy
    @State private var praiseTick = 0
    @State private var didAction = false
    @State private var picBounce = false

    public var body: some View {
        GeometryReader { geo in
            let picSide = min(geo.size.width - 80, geo.size.height * 0.36)
            VStack(spacing: 16) {
                // 顶栏关闭与下一个
                HStack {
                    Button {
                        audioPlayer.stop()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .kidFont(18, .bold)
                            .foregroundStyle(Palette.inkMuted)
                            .frame(width: 44, height: 44)
                            .background(Palette.surface, in: Circle())
                            .overlay { Circle().strokeBorder(Palette.hairline, lineWidth: 1.5) }
                    }
                    Spacer()
                    Button {
                        onNext()
                    } label: {
                        HStack(spacing: 4) {
                            Text("下一个音")
                                .kidFont(16, .heavy)
                            Image(systemName: "arrow.right.circle.fill")
                                .kidFont(20, .bold)
                        }
                        .foregroundStyle(letter.cardTint)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(letter.cardTint.opacity(0.12), in: Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // 核心字母与音标展示
                HStack(spacing: 12) {
                    Text(letter.letter)
                        .kidFont(64, .heavy)
                        .foregroundStyle(letter.cardTint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(letter.phoneme)
                            .kidFont(28, .heavy)
                            .foregroundStyle(letter.cardTint)
                        Text(letter.wordZh)
                            .kidFont(16, .bold)
                            .foregroundStyle(Palette.inkMuted)
                    }
                    Spacer()
                    TomMoodView(mood: tomMood, size: 68)
                }
                .padding(.horizontal, 20)

                // 居中大图与顺口溜
                Button { playChant() } label: {
                    BabyPicture(word: letter.word, size: picSide)
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .strokeBorder(Color.white, lineWidth: 6)
                        }
                        .elevationRaised()
                        .overlay { PraiseBurst(tick: praiseTick, show: didAction) }
                        .scaleEffect(picBounce ? 1.06 : 1.0)
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(letter.word)

                // 顺口溜英文气泡
                Text(letter.chantEn)
                    .kidFont(20, .heavy)
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                // 动作提示卡
                HStack(spacing: 12) {
                    Image(systemName: "figure.dance")
                        .kidFont(26, .bold)
                        .foregroundStyle(letter.cardTint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("跟我做动作")
                            .kidFont(14, .bold)
                            .foregroundStyle(letter.cardTint)
                        Text(letter.actionZh)
                            .kidFont(16, .heavy)
                            .foregroundStyle(Palette.ink)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .elevationGround()
                .padding(.horizontal, 20)

                Spacer(minLength: 0)

                // 底部操作栏：重播顺口溜 + 我做到了！
                HStack(spacing: 16) {
                    Button { playChant() } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .kidFont(26, .bold)
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(Func.infoDeep, in: Circle())
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("再听一遍")

                    Button {
                        completeAction()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .kidFont(26, .bold)
                            Text("我做到了！")
                                .kidFont(20, .heavy)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(letter.cardTint, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .elevationRaised()
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("我做到了")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .creamBackground()
        .onAppear {
            playChant()
        }
        .onDisappear {
            audioPlayer.stop()
        }
    }

    private func playChant() {
        audioPlayer.stop()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { picBounce = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { picBounce = false }
        if let url = store.phraseFileURL("audio", "\(letter.audio).mp3") {
            audioPlayer.play(url: url)
        }
    }

    private func completeAction() {
        didAction = true
        praiseTick += 1
        tomMood = .clap
        if let url = store.phraseFileURL("audio", "prompt_yay.mp3") {
            audioPlayer.play(url: url)
        }
    }
}

// MARK: - 听音辨字母（3 选 1）小测验

public struct PhonicsQuizView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var store
    @State private var audioPlayer = AudioPlayer()
    @State private var rounds: [PhonicsQuizRound] = []
    @State private var currentIdx = 0
    @State private var tomMood: TomMood = .happy
    @State private var solved = false
    @State private var selectedLetterId: String? = nil
    @State private var isDone = false

    public init() {}

    private var currentRound: PhonicsQuizRound? {
        guard currentIdx < rounds.count else { return nil }
        return rounds[currentIdx]
    }

    public var body: some View {
        GeometryReader { geo in
            VStack(spacing: 16) {
                // 顶栏返回与进度
                HStack {
                    Button {
                        audioPlayer.stop()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .kidFont(18, .bold)
                            .foregroundStyle(Palette.inkMuted)
                            .frame(width: 44, height: 44)
                            .background(Palette.surface, in: Circle())
                            .overlay { Circle().strokeBorder(Palette.hairline, lineWidth: 1.5) }
                    }
                    Spacer()
                    // 题目进度圆点
                    HStack(spacing: 6) {
                        ForEach(0..<rounds.count, id: \.self) { i in
                            Circle()
                                .fill(i < currentIdx ? Func.positiveDeep : (i == currentIdx ? Func.accent : Palette.hairline))
                                .frame(width: 10, height: 10)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                if isDone {
                    celebrationView
                } else if let r = currentRound {
                    // Tom 提问栏
                    HStack(spacing: 12) {
                        TomMoodView(mood: tomMood, size: 68)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("听音找一找")
                                .kidFont(16, .bold)
                                .foregroundStyle(Func.accentDeep)
                            Text("哪个字母发出这个声音？")
                                .kidFont(22, .heavy)
                                .foregroundStyle(Palette.ink)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .elevationGround()
                    .padding(.horizontal, 16)

                    Spacer(minLength: 0)

                    // 喇叭听音大按钮
                    Button { playRoundAudio() } label: {
                        VStack(spacing: 10) {
                            Image(systemName: "speaker.wave.3.fill")
                                .kidFont(44, .heavy)
                                .foregroundStyle(.white)
                                .frame(width: 100, height: 100)
                                .background(Func.accentPill, in: Circle())
                                .elevationRaised()
                            Text("点击听发音")
                                .kidFont(16, .bold)
                                .foregroundStyle(Palette.inkMuted)
                        }
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("再听一遍发音")

                    Spacer(minLength: 0)

                    // 3 个选项字母大卡片
                    HStack(spacing: 14) {
                        ForEach(r.options) { option in
                            optionCard(option, target: r.target)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .creamBackground()
        .onAppear {
            startQuiz()
        }
        .onDisappear {
            audioPlayer.stop()
        }
    }

    private func optionCard(_ option: PhonicsLetter, target: PhonicsLetter) -> some View {
        let isSelected = selectedLetterId == option.id
        let isCorrect = option.id == target.id
        let showSuccess = solved && isCorrect
        return Button {
            choose(option, target: target)
        } label: {
            VStack(spacing: 8) {
                Text(option.letter)
                    .kidFont(48, .heavy)
                    .foregroundStyle(showSuccess ? .white : option.cardTint)
                Text(option.phoneme)
                    .kidFont(18, .bold)
                    .foregroundStyle(showSuccess ? .white : Palette.inkMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(showSuccess ? Func.positiveDeep : Palette.surface,
                        in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(showSuccess ? Color.white : (isSelected ? Func.accent : Palette.hairline),
                                  lineWidth: showSuccess ? 4 : 2)
            }
            .elevationRaised()
            .scaleEffect(showSuccess ? 1.08 : 1.0)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(option.letter)
    }

    private var celebrationView: some View {
        VStack(spacing: 20) {
            Spacer()
            TomMoodView(mood: .clap, size: 100)
            Text("太棒了！")
                .kidFont(32, .heavy)
                .foregroundStyle(Func.positiveDeep)
            Text("你已经掌握了这组字母发音！")
                .kidFont(18, .bold)
                .foregroundStyle(Palette.inkMuted)
            Spacer()
            Button {
                audioPlayer.stop()
                dismiss()
            } label: {
                Text("完成测验")
                    .kidFont(22, .heavy)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Func.positiveDeep, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .elevationRaised()
            }
            .buttonStyle(PressableStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func startQuiz() {
        var rng = SeededGenerator(seed: 77)
        rounds = PhonicsEngine.makeQuizRounds(count: 4, using: &rng)
        currentIdx = 0
        solved = false
        selectedLetterId = nil
        isDone = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            playRoundAudio()
        }
    }

    private func playRoundAudio() {
        guard let r = currentRound else { return }
        audioPlayer.stop()
        if let url = store.phraseFileURL("audio", "\(r.target.audio).mp3") {
            audioPlayer.play(url: url)
        }
    }

    private func choose(_ opt: PhonicsLetter, target: PhonicsLetter) {
        guard !solved else { return }
        selectedLetterId = opt.id
        if opt.id == target.id {
            solved = true
            tomMood = .clap
            if let url = store.phraseFileURL("audio", "prompt_great.mp3") {
                audioPlayer.play(url: url)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                if currentIdx + 1 < rounds.count {
                    currentIdx += 1
                    solved = false
                    selectedLetterId = nil
                    tomMood = .happy
                    playRoundAudio()
                } else {
                    isDone = true
                }
            }
        } else {
            tomMood = .thinking
            // 选错友好提示并重放，无红叉
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                playRoundAudio()
            }
        }
    }
}

// MARK: - 启蒙图画页顶部自然拼读横幅

public struct PhonicsIslandBanner: View {
    public init() {}

    public var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [Func.accent, Color(red: 1.0, green: 0.76, blue: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 58, height: 58)
                Image(systemName: "character.book.closed.fill")
                    .kidFont(26, .bold)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("自然拼读 · 字母音探索岛")
                    .kidFont(18, .heavy)
                    .foregroundStyle(Palette.ink)
                HStack(spacing: 4) {
                    ForEach(["s", "a", "t", "i", "p", "n"], id: \.self) { l in
                        Text(l)
                            .kidFont(12, .heavy)
                            .foregroundStyle(Palette.ink)
                            .frame(width: 18, height: 18)
                            .background(Color.white, in: Circle())
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .kidFont(18, .bold)
                .foregroundStyle(Palette.inkMuted)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.99, green: 0.94, blue: 0.86))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Func.accent.opacity(0.35), lineWidth: 1.5)
        }
        .elevationGround()
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}
