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
    @State private var selectedGroup: Int = LaunchOptions.phonicsGroup2 ? 2 : 1

    public init() {}

    private var currentGroupLetters: [PhonicsLetter] {
        selectedGroup == 2 ? PhonicsCatalog.group2 : PhonicsCatalog.group1
    }

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

                    // 阶段 3 入口：滑音小火车特色横幅
                    NavigationLink {
                        PhonicsBlendingTrainView()
                    } label: {
                        blendingTrainBanner
                    }
                    .buttonStyle(PressableStyle())
                    .padding(.horizontal, 16)

                    // 分组选择器：第 1 组 (s a t i p n) 与 第 2 组 (c e h r m d)
                    groupSelector

                    // 6 个字母卡片网格（2 列 × 3 行）
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                        ForEach(currentGroupLetters) { item in
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
                PhonicsQuizView(pool: currentGroupLetters)
            }
            .onAppear {
                guard !LaunchOptions.isUIScreenshotRun else { return }
                playGroupWelcomeAudio(selectedGroup)
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    bounce = true
                }
            }
            .onDisappear {
                audioPlayer.stop()
            }
        }
    }

    private var blendingTrainBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [Color.orange, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 58, height: 58)
                Image(systemName: "tram.fill")
                    .kidFont(28, .bold)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("🚂 滑音小火车")
                        .kidFont(19, .heavy)
                        .foregroundStyle(Palette.ink)
                    Text("CVC 拼读")
                        .kidFont(12, .heavy)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange, in: Capsule())
                }
                Text("开动小火车 · 连音读出声 · 拼出新单词")
                    .kidFont(14, .bold)
                    .foregroundStyle(Palette.inkMuted)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .kidFont(18, .bold)
                .foregroundStyle(Palette.inkMuted)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 1.0, green: 0.96, blue: 0.90))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.4), lineWidth: 1.5)
        }
        .elevationGround()
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

    private var groupSelector: some View {
        HStack(spacing: 8) {
            groupButton(group: 1, title: "第 1 组", letters: "s a t i p n")
            groupButton(group: 2, title: "第 2 组", letters: "c e h r m d")
        }
        .padding(4)
        .background(Palette.surface, in: Capsule())
        .overlay {
            Capsule().strokeBorder(Palette.hairline, lineWidth: 1.5)
        }
        .padding(.horizontal, 16)
    }

    private func groupButton(group: Int, title: String, letters: String) -> some View {
        let isSelected = selectedGroup == group
        return Button {
            guard selectedGroup != group else { return }
            audioPlayer.stop()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedGroup = group
            }
            if !LaunchOptions.isUIScreenshotRun {
                playGroupWelcomeAudio(group)
            }
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .kidFont(15, .heavy)
                    .foregroundStyle(isSelected ? .white : Palette.ink)
                Text(letters)
                    .kidFont(13, .bold)
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : Palette.inkMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected ? Func.accent : Color.clear,
                in: Capsule()
            )
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("\(title), 包含字母 \(letters)")
    }

    private func playGroupWelcomeAudio(_ group: Int) {
        let soundName = group == 2 ? "tom_phonics_group2.mp3" : "tom_phonics_island.mp3"
        if let url = store.phraseFileURL("audio", soundName) {
            audioPlayer.play(url: url)
        }
    }

    private func nextLetter(after current: PhonicsLetter) {
        let pool = PhonicsCatalog.group2.contains(current) ? PhonicsCatalog.group2 : PhonicsCatalog.group1
        guard let idx = pool.firstIndex(of: current) else { return }
        let nextIdx = (idx + 1) % pool.count
        selectedLetter = pool[nextIdx]
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
    let pool: [PhonicsLetter]

    @State private var audioPlayer = AudioPlayer()
    @State private var rounds: [PhonicsQuizRound] = []
    @State private var currentIdx = 0
    @State private var tomMood: TomMood = .happy
    @State private var solved = false
    @State private var selectedLetterId: String? = nil
    @State private var isDone = false

    public init(pool: [PhonicsLetter] = PhonicsCatalog.group1) {
        self.pool = pool
    }

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
        rounds = PhonicsEngine.makeQuizRounds(count: 4, pool: pool, using: &rng)
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

// MARK: - 自然拼读阶段 3：滑音小火车（Sound Blending Train）

public struct PhonicsBlendingTrainView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var store
    @State private var audioPlayer = AudioPlayer()
    @State private var selectedWord: PhonicsBlendWord = PhonicsCatalog.cvcGroup1[0]
    @State private var activeCarIndex: Int? = nil
    @State private var isBlending = false
    @State private var showCargoQuiz = LaunchOptions.phonicsCargoQuiz
    @State private var praiseTick = 0
    @State private var showWordResult = false
    @State private var trainBounce = false

    public init() {}

    public var body: some View {
        NavigationStack {
            KidScrollView {
                VStack(spacing: 16) {
                    // 顶栏返回与拼词小挑战入口
                    HStack {
                        SubPageHeader(onBack: {
                            audioPlayer.stop()
                            dismiss()
                        })
                        Spacer(minLength: 0)
                        Button {
                            audioPlayer.stop()
                            showCargoQuiz = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "shippingbox.fill")
                                    .kidFont(16, .heavy)
                                Text("装车厢挑战")
                                    .kidFont(16, .heavy)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.95, green: 0.42, blue: 0.35), in: Capsule())
                            .elevationRaised()
                        }
                        .buttonStyle(PressableStyle())
                        .accessibilityLabel("装车厢挑战测验")
                        .padding(.trailing, 16)
                    }

                    // 探索岛主标题栏
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(colors: [Color.orange, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .frame(width: 68, height: 68)
                            Image(systemName: "tram.fill")
                                .kidFont(32, .heavy)
                                .foregroundStyle(.white)
                                .offset(y: trainBounce ? -4 : 0)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("滑音小火车")
                                .kidFont(24, .heavy)
                                .foregroundStyle(Palette.ink)
                            Text("连音读出声 · 拼出新单词")
                                .kidFont(14, .bold)
                                .foregroundStyle(Palette.inkMuted)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .elevationGround()
                    .padding(.horizontal, 16)

                    // 6 个 CVC 拼读词水平选择卡
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(PhonicsCatalog.cvcGroup1) { w in
                                let isSelected = selectedWord.id == w.id
                                Button {
                                    selectWord(w)
                                } label: {
                                    VStack(spacing: 2) {
                                        Text(w.word)
                                            .kidFont(18, .heavy)
                                        Text(w.meaningZh)
                                            .kidFont(12, .bold)
                                    }
                                    .foregroundStyle(isSelected ? .white : Palette.ink)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? w.cardTint : Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(isSelected ? Color.clear : Palette.hairline, lineWidth: 1.5)
                                    }
                                    .elevationGround()
                                }
                                .buttonStyle(PressableStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // 小火车轨道与车厢主体区域
                    trainPlatformView
                        .padding(.horizontal, 16)

                    // 开动小火车（Blend!）大按钮
                    Button {
                        startTrainBlending()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: isBlending ? "waveform" : "play.circle.fill")
                                .kidFont(28, .bold)
                            Text(isBlending ? "正在拼读中..." : "开动小火车（Blend!）")
                                .kidFont(20, .heavy)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            LinearGradient(colors: [Func.accent, Color(red: 0.95, green: 0.55, blue: 0.15)],
                                           startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                        )
                        .elevationRaised()
                    }
                    .buttonStyle(PressableStyle())
                    .disabled(isBlending)
                    .padding(.horizontal, 16)

                    // 拼读单词结果卡片（到站弹出）
                    if showWordResult {
                        wordResultCard
                            .padding(.horizontal, 16)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.bottom, 24)
            }
            .creamBackground()
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showCargoQuiz) {
                PhonicsTrainCargoQuizView()
            }
            .onAppear {
                playIntro()
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    trainBounce = true
                }
            }
            .onDisappear {
                audioPlayer.stop()
            }
        }
    }

    // MARK: 小火车轨道平台与车厢
    private var trainPlatformView: some View {
        VStack(spacing: 0) {
            // 火车车头 + 3 节字母车厢
            HStack(alignment: .bottom, spacing: 6) {
                // 车头
                trainEngineView

                // 3 节车厢
                ForEach(0..<selectedWord.letters.count, id: \.self) { idx in
                    let letter = selectedWord.letters[idx]
                    let phoneme = selectedWord.phonemes[idx]
                    let isActive = activeCarIndex == idx

                    trainCar(letter: letter, phoneme: phoneme, index: idx, isActive: isActive)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 6)

            // 双铁轨与枕木
            railTrackView
        }
        .padding(16)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .elevationGround()
    }

    // 火车头
    private var trainEngineView: some View {
        VStack(spacing: 2) {
            // 烟囱冒烟
            HStack {
                Spacer()
                Circle()
                    .fill(Color.gray.opacity(0.35))
                    .frame(width: isBlending ? 14 : 10, height: isBlending ? 14 : 10)
                    .offset(y: isBlending ? -8 : 0)
                    .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: isBlending)
                Spacer()
            }
            .frame(height: 16)

            // 红色蒸汽机车头
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(colors: [Color.red, Color(red: 0.85, green: 0.2, blue: 0.15)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 58, height: 68)

                VStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .kidFont(16, .bold)
                        .foregroundStyle(Color.yellow)
                    Text("🚂")
                        .kidFont(22, .bold)
                }
            }

            // 车轮
            HStack(spacing: 6) {
                Circle().fill(Color.black).frame(width: 14, height: 14)
                Circle().fill(Color.black).frame(width: 14, height: 14)
            }
        }
    }

    // 字母车厢
    private func trainCar(letter: String, phoneme: String, index: Int, isActive: Bool) -> some View {
        Button {
            playCarSound(letter: letter, index: index)
        } label: {
            VStack(spacing: 2) {
                // 车厢箱体
                VStack(spacing: 2) {
                    Text(letter)
                        .kidFont(32, .heavy)
                        .foregroundStyle(isActive ? .white : selectedWord.cardTint)
                    Text(phoneme)
                        .kidFont(13, .heavy)
                        .foregroundStyle(isActive ? .white : Palette.inkMuted)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 68)
                .background(
                    isActive ? selectedWord.cardTint : Palette.surface,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(isActive ? Color.white : Palette.hairline, lineWidth: isActive ? 3 : 1.5)
                }
                .elevationRaised()
                .offset(y: isActive ? -10 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isActive)

                // 车轮
                HStack(spacing: 12) {
                    Circle().fill(Color.black).frame(width: 12, height: 12)
                    Circle().fill(Color.black).frame(width: 12, height: 12)
                }
            }
        }
        .buttonStyle(PressableStyle())
    }

    // 铁轨
    private var railTrackView: some View {
        VStack(spacing: 4) {
            // 上铁轨
            Rectangle().fill(Color.gray.opacity(0.6)).frame(height: 4)
            // 枕木
            HStack(spacing: 10) {
                ForEach(0..<18, id: \.self) { _ in
                    Rectangle().fill(Color(red: 0.45, green: 0.32, blue: 0.22)).frame(width: 6, height: 8)
                }
            }
            // 下铁轨
            Rectangle().fill(Color.gray.opacity(0.6)).frame(height: 4)
        }
        .padding(.horizontal, 4)
    }

    // 到站拼读结果大卡片
    private var wordResultCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // 平涂大图
                BabyPicture(word: selectedWord.word, size: 88)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.white, lineWidth: 3)
                    }
                    .elevationRaised()

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(selectedWord.word.uppercased())
                            .kidFont(28, .heavy)
                            .foregroundStyle(selectedWord.cardTint)
                        Text(selectedWord.meaningZh)
                            .kidFont(16, .bold)
                            .foregroundStyle(Palette.inkMuted)
                    }
                    Text(selectedWord.chantEn)
                        .kidFont(15, .bold)
                        .foregroundStyle(Palette.ink)
                }
                Spacer()

                Button {
                    playWordChant()
                } label: {
                    Image(systemName: "speaker.wave.3.fill")
                        .kidFont(20, .bold)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(selectedWord.cardTint, in: Circle())
                }
                .buttonStyle(PressableStyle())
            }
            .padding(14)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay { PraiseBurst(tick: praiseTick, show: showWordResult) }
            .elevationRaised()
        }
    }

    private func selectWord(_ w: PhonicsBlendWord) {
        audioPlayer.stop()
        selectedWord = w
        activeCarIndex = nil
        showWordResult = false
    }

    private func playIntro() {
        if let url = store.phraseFileURL("audio", "tom_train_intro.mp3") {
            audioPlayer.play(url: url)
        }
    }

    private func playCarSound(letter: String, index: Int) {
        audioPlayer.stop()
        activeCarIndex = index
        let chantName = "phonics_chant_\(letter.lowercased())"
        if let url = store.phraseFileURL("audio", "\(chantName).mp3") {
            audioPlayer.play(url: url)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                if activeCarIndex == index { activeCarIndex = nil }
            }
        } else {
            activeCarIndex = nil
        }
    }

    private func startTrainBlending() {
        audioPlayer.stop()
        isBlending = true
        showWordResult = false
        activeCarIndex = nil

        // 1. 鸣笛开动
        if let whistleUrl = store.phraseFileURL("audio", "train_whistle.mp3") {
            audioPlayer.play(url: whistleUrl)
        }

        // 2. 依次点亮发音
        for (i, letter) in selectedWord.letters.enumerated() {
            let delay = 0.8 + Double(i) * 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                activeCarIndex = i
                let chantName = "phonics_chant_\(letter.lowercased())"
                if let url = store.phraseFileURL("audio", "\(chantName).mp3") {
                    audioPlayer.play(url: url)
                }
            }
        }

        // 3. 到站整词拼读
        let totalBlendDelay = 0.8 + Double(selectedWord.letters.count) * 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + totalBlendDelay) {
            activeCarIndex = nil
            showWordResult = true
            praiseTick += 1
            playWordChant()
            isBlending = false
        }
    }

    private func playWordChant() {
        if let url = store.phraseFileURL("audio", "\(selectedWord.audio).mp3") {
            audioPlayer.play(url: url)
        }
    }
}

// MARK: - 小火车拼词小挑战（Train Cargo Quiz 缺字母 3 选 1）

public struct PhonicsTrainCargoQuizView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var store
    @State private var audioPlayer = AudioPlayer()
    @State private var rounds: [PhonicsCargoRound] = []
    @State private var currentIdx = 0
    @State private var tomMood: TomMood = .happy
    @State private var solved = false
    @State private var chosenLetter: String? = nil
    @State private var isDone = false

    public init() {}

    private var currentRound: PhonicsCargoRound? {
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
                    // 进度点
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
                    cargoCelebrationView
                } else if let r = currentRound {
                    // 题目提示栏
                    HStack(spacing: 12) {
                        TomMoodView(mood: tomMood, size: 68)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("装车厢拼词")
                                .kidFont(16, .bold)
                                .foregroundStyle(Color(red: 0.95, green: 0.42, blue: 0.35))
                            Text("缺了哪个字母车厢？")
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

                    // 目标单词图片与含义
                    VStack(spacing: 8) {
                        BabyPicture(word: r.targetWord.word, size: min(geo.size.width * 0.45, 140))
                            .overlay {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .strokeBorder(Color.white, lineWidth: 4)
                            }
                            .elevationRaised()
                        Text(r.targetWord.meaningZh)
                            .kidFont(18, .heavy)
                            .foregroundStyle(Palette.inkMuted)
                    }

                    Spacer(minLength: 0)

                    // 站台上的拼装火车（含空缺车厢）
                    cargoTrainView(round: r)
                        .padding(.horizontal, 16)

                    Spacer(minLength: 0)

                    // 3 选 1 备选字母车厢球
                    HStack(spacing: 16) {
                        ForEach(r.options, id: \.self) { opt in
                            cargoOptionButton(letter: opt, round: r)
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

    private func cargoTrainView(round: PhonicsCargoRound) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            // 车头
            VStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.orange)
                    .frame(width: 48, height: 56)
                    .overlay { Text("🚂").kidFont(18, .bold) }
                HStack(spacing: 4) {
                    Circle().fill(Color.black).frame(width: 10, height: 10)
                    Circle().fill(Color.black).frame(width: 10, height: 10)
                }
            }

            // 3 节车厢（缺 1 节）
            ForEach(0..<round.targetWord.letters.count, id: \.self) { idx in
                let isMissing = idx == round.missingIndex
                let displayLetter: String = {
                    if isMissing {
                        return solved ? round.correctLetter : "?"
                    } else {
                        return round.targetWord.letters[idx]
                    }
                }()

                VStack(spacing: 2) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isMissing && !solved ? Palette.surface : round.targetWord.cardTint)
                            .frame(height: 58)

                        if isMissing && !solved {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.orange, style: StrokeStyle(lineWidth: 2.5, dash: [6, 4]))
                        }

                        Text(displayLetter)
                            .kidFont(30, .heavy)
                            .foregroundStyle(isMissing && !solved ? Color.orange : Color.white)
                    }
                    .elevationRaised()

                    HStack(spacing: 8) {
                        Circle().fill(Color.black).frame(width: 10, height: 10)
                        Circle().fill(Color.black).frame(width: 10, height: 10)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(14)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .elevationGround()
    }

    private func cargoOptionButton(letter: String, round: PhonicsCargoRound) -> some View {
        let isChosen = chosenLetter == letter
        let isCorrect = letter == round.correctLetter
        let showSuccess = solved && isCorrect
        return Button {
            choose(letter, round: round)
        } label: {
            VStack {
                Text(letter)
                    .kidFont(38, .heavy)
                    .foregroundStyle(showSuccess ? .white : Color.orange)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(showSuccess ? Func.positiveDeep : Palette.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(showSuccess ? Color.white : (isChosen ? Color.orange : Palette.hairline),
                                  lineWidth: showSuccess ? 4 : 2)
            }
            .elevationRaised()
            .scaleEffect(showSuccess ? 1.08 : 1.0)
        }
        .buttonStyle(PressableStyle())
    }

    private var cargoCelebrationView: some View {
        VStack(spacing: 20) {
            Spacer()
            TomMoodView(mood: .clap, size: 100)
            Text("小火车全线贯通！")
                .kidFont(32, .heavy)
                .foregroundStyle(Func.positiveDeep)
            Text("你已经能够熟练拼出这组核心单词！")
                .kidFont(18, .bold)
                .foregroundStyle(Palette.inkMuted)
            Spacer()
            Button {
                audioPlayer.stop()
                dismiss()
            } label: {
                Text("完成挑战")
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
        var rng = SeededGenerator(seed: 88)
        rounds = PhonicsEngine.makeCargoRounds(count: 4, using: &rng)
        currentIdx = 0
        solved = false
        chosenLetter = nil
        isDone = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            playQuestionAudio()
        }
    }

    private func playQuestionAudio() {
        if let url = store.phraseFileURL("audio", "tom_train_missing.mp3") {
            audioPlayer.play(url: url)
        }
    }

    private func choose(_ letter: String, round: PhonicsCargoRound) {
        guard !solved else { return }
        chosenLetter = letter
        if letter == round.correctLetter {
            solved = true
            tomMood = .clap
            if let url = store.phraseFileURL("audio", "\(round.targetWord.audio).mp3") {
                audioPlayer.play(url: url)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                if currentIdx + 1 < rounds.count {
                    currentIdx += 1
                    solved = false
                    chosenLetter = nil
                    tomMood = .happy
                    playQuestionAudio()
                } else {
                    isDone = true
                }
            }
        } else {
            tomMood = .thinking
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                playQuestionAudio()
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
