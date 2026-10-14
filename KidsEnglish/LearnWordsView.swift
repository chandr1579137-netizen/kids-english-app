import SwiftUI

/// 单词正面：大图、单词、音标、中文。背单词和主题闪卡共用。
struct FlashCardFace: View {
    let entry: WordEntry

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 1, green: 0.97, blue: 0.86), Color(red: 1, green: 0.93, blue: 0.75)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                WordIconView(word: entry.word, size: 168)
            }
            .frame(height: 210)
            .padding(.bottom, 6)

            Text(entry.word)
                .font(.system(size: 52, weight: .heavy))
                .foregroundStyle(AppTheme.brightBlue)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            if let phonetic = entry.phonetic, !phonetic.isEmpty {
                Text(phonetic)
                    .font(.title3)
                    .foregroundStyle(.gray)
            }
            Text(entry.meaningCn ?? "")
                .font(.system(size: 36, weight: .heavy))
                .foregroundStyle(AppTheme.wordOrange)
                .multilineTextAlignment(.center)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
    }
}

struct WordAudioButtons: View {
    @Environment(DataStore.self) private var store
    var player: AudioPlayer
    let entry: WordEntry

    var body: some View {
        HStack(spacing: 16) {
            PillButton(title: "🔊 正常", color: AppTheme.brightBlue) {
                play(slow: false)
            }
            PillButton(title: "🐢 慢速", color: AppTheme.green) {
                play(slow: true)
            }
        }
    }

    private func play(slow: Bool) {
        if slow, let slowURL = store.slowAudioURL(forWord: entry.word) {
            player.play(url: slowURL, rate: 1, spokenFallback: entry.word)
        } else {
            player.play(
                url: store.bestAudioURL(forWord: entry.word),
                rate: slow ? 0.75 : 1,
                spokenFallback: entry.word
            )
        }
    }
}

/// 背单词：今日计划 → 选词书 → 开始学习 / 巩固练习
struct LearnWordsView: View {
    @Environment(DataStore.self) private var store
    private let player = AudioPlayer.shared

    @State private var session: [WordEntry] = []
    @State private var queue: [Int] = []
    @State private var cursor = 0
    @State private var known: Set<String> = []
    @State private var learnedToday: [WordEntry] = []
    @State private var finished = false
    @State private var showStudy = false
    @State private var goConsolidate = false
    @State private var forwards = true
    @State private var showSuccess = false
    @State private var locked = false
    @State private var successTick = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    planCard
                        .padding(.horizontal)
                    bookPicker
                    BigButton(title: "开始学习 ▶", color: AppTheme.green) {
                        startStudy()
                    }
                    .padding(.horizontal)
                    BigButton(title: "巩固练习 · 9 种玩法 🎮", color: Color(red: 0.42, green: 0.66, blue: 0.98)) {
                        goConsolidate = true
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            .creamBackground()
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { refreshSessionPreview() }
            .onChange(of: store.selectedThemeId) { _, _ in refreshSessionPreview() }
            .onChange(of: store.dailyNewWords) { _, _ in refreshSessionPreview() }
            .fullScreenCover(isPresented: $showStudy) {
                studyScreen
                    .onDisappear { player.stop() }
            }
            .navigationDestination(isPresented: $goConsolidate) {
                ConsolidationView(words: learnedToday.isEmpty ? (store.planDays().first ?? []) : learnedToday)
            }
        }
    }

    private var todayPreview: [WordEntry] {
        store.planDays().first ?? []
    }

    private var dayNumber: Int {
        let perDay = max(1, store.dailyNewWords)
        return store.learnedWords.count / perDay + 1
    }

    private var planCard: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("今日计划")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))
                Text("Day \(dayNumber)")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundStyle(.white)
                Text("新学 \(todayPreview.count) 个词")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text("已学 \(store.learnedWords.count) / \(store.words.count)")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.92))
            }
            Spacer(minLength: 8)
            uiIcon("rocket")
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 92)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(AppTheme.planGradient)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .orange.opacity(0.35), radius: 14, y: 8)
    }

    private var bookPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选词书")
                .font(.system(size: 32, weight: .heavy))
                .foregroundStyle(AppTheme.navy)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    bookCard(
                        title: "全部单词",
                        subtitle: "\(store.words.count) 词",
                        color: AppTheme.brightBlue,
                        iconName: "book",
                        selected: store.selectedThemeId == nil
                    ) {
                        store.selectedThemeId = nil
                        store.saveProgress()
                    }
                    bookCard(themeId: "fruits", title: "水果篇", iconName: "strawberry", color: AppTheme.pink)
                    bookCard(themeId: "animals", title: "动物篇", iconName: "panda", color: AppTheme.green)
                    bookCard(themeId: "vehicles", title: "交通工具", iconName: "bus", color: AppTheme.purple)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
    }

    private func bookCard(themeId: String, title: String, iconName: String, color: Color) -> some View {
        let total = store.themeProgress(themeId: themeId).total
        return bookCard(
            title: title,
            subtitle: "\(total) 词",
            color: color,
            iconName: iconName,
            selected: store.selectedThemeId == themeId
        ) {
            store.selectedThemeId = themeId
            store.saveProgress()
        }
    }

    private func bookCard(title: String, subtitle: String, color: Color, iconName: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(Motion.spring) { action() }
        } label: {
            VStack(spacing: 8) {
                uiIcon(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(width: 124, height: 156)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white, lineWidth: selected ? 5 : 0)
            )
            .shadow(color: color.opacity(0.35), radius: 8, y: 4)
            .scaleEffect(selected ? 1.05 : 1)
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: - 学习全屏

    private var studyScreen: some View {
        VStack(spacing: 12) {
            if finished {
                celebration
            } else if queue.isEmpty {
                Text("今天没有新单词啦，换一本词书或明天再来吧")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.navy)
                    .padding()
                    .whiteCard()
                    .padding()
                Button("返回") { showStudy = false }
                    .font(.title3.bold())
            } else if let entry = currentEntry {
                studyHeader
                FlashCardFace(entry: entry)
                    .padding(.horizontal, 18)
                    .id(entry.id)
                    .transition(.asymmetric(
                        insertion: .move(edge: forwards ? .trailing : .leading).combined(with: .opacity),
                        removal: .move(edge: forwards ? .leading : .trailing).combined(with: .opacity)
                    ))
                    .overlay {
                        if showSuccess {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 120))
                                .foregroundStyle(.green)
                                .shadow(color: .green.opacity(0.35), radius: 12, y: 4)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                WordAudioButtons(player: player, entry: entry)
                    .padding(.horizontal, 20)
                actionRow
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .creamBackground()
        .sensoryFeedback(.success, trigger: successTick)
        .animation(Motion.spring, value: cursor)
        .animation(Motion.spring, value: showSuccess)
        .animation(Motion.spring, value: finished)
    }

    private var currentEntry: WordEntry? {
        guard queue.indices.contains(cursor) else { return nil }
        let index = queue[cursor]
        guard session.indices.contains(index) else { return nil }
        return session[index]
    }

    private var studyHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button {
                    player.stop()
                    showStudy = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.navy)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(PressableStyle())
                Text("背单词 · 第 \(displayNumber) 个")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(AppTheme.brightBlue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer()
                Button {
                    if let entry = currentEntry {
                        player.play(url: store.bestAudioURL(forWord: entry.word), spokenFallback: entry.word)
                    }
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.brightBlue)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(PressableStyle())
            }
            ProgressView(value: session.isEmpty ? 0 : Double(known.count), total: Double(max(session.count, 1)))
                .tint(.orange)
                .scaleEffect(x: 1, y: 1.6, anchor: .center)
            Text("学习进度 \(known.count)/\(session.count)")
                .font(.subheadline.bold())
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 18)
    }

    private var displayNumber: Int {
        guard let entry = currentEntry,
              let index = session.firstIndex(where: { $0.id == entry.id }) else { return 1 }
        return index + 1
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            studyAction("← 上一个", color: AppTheme.grayBtn) { goPrevious() }
            studyAction("认识 ✓", color: AppTheme.green) { markKnown() }
            studyAction("不认识 ✕", color: AppTheme.red) { markUnknown() }
            studyAction("下一个 →", color: AppTheme.grayBtn) { goNext() }
        }
        .padding(.horizontal, 12)
    }

    private func studyAction(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressableStyle())
        .disabled(locked)
    }

    private var celebration: some View {
        VStack(spacing: 22) {
            Text("🎉")
                .font(.system(size: 88))
            Text("今天学完啦！")
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.navy)
            Text("你认识了 \(known.count) 个单词")
                .font(.title2)
                .foregroundStyle(.gray)
            BigButton(title: "去巩固 🎮", color: AppTheme.brightBlue) {
                showStudy = false
                goConsolidate = true
            }
            BigButton(title: "返回首页", color: AppTheme.green) {
                showStudy = false
            }
        }
        .padding(28)
        .whiteCard()
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    // MARK: - 流程

    private func refreshSessionPreview() {
        if !showStudy {
            session = store.planDays().first ?? []
        }
    }

    private func startStudy() {
        let today = store.planDays().first ?? []
        session = today
        queue = Array(today.indices)
        cursor = 0
        known = []
        learnedToday = []
        finished = false
        forwards = true
        showSuccess = false
        locked = false
        guard !today.isEmpty else {
            showStudy = true
            return
        }
        showStudy = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            guard showStudy, !finished else { return }
            playCurrent()
        }
    }

    private func playCurrent() {
        guard showStudy, let entry = currentEntry else { return }
        player.play(url: store.bestAudioURL(forWord: entry.word), spokenFallback: entry.word)
    }

    private func playAfterTransition() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            guard showStudy, !finished, !showSuccess else { return }
            playCurrent()
        }
    }

    private func markKnown() {
        guard !locked, let entry = currentEntry, queue.indices.contains(cursor) else { return }
        locked = true
        forwards = true
        store.markLearned(entry.word)
        store.saveProgress()
        known.insert(entry.id)
        if !learnedToday.contains(where: { $0.id == entry.id }) {
            learnedToday.append(entry)
        }
        withAnimation(Motion.spring) { showSuccess = true }
        successTick += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(Motion.spring) {
                showSuccess = false
                queue.remove(at: cursor)
                if queue.isEmpty {
                    finished = true
                    player.stop()
                } else if cursor >= queue.count {
                    cursor = 0
                }
            }
            locked = false
            if !finished { playAfterTransition() }
        }
    }

    private func markUnknown() {
        guard !locked, let entry = currentEntry, queue.indices.contains(cursor) else { return }
        player.play(url: store.bestAudioURL(forWord: entry.word), rate: 0.75, spokenFallback: entry.word)
        guard queue.count > 1 else { return }
        locked = true
        let token = entry.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            guard queue.indices.contains(cursor),
                  session.indices.contains(queue[cursor]),
                  session[queue[cursor]].id == token else {
                locked = false
                return
            }
            forwards = true
            withAnimation(Motion.spring) {
                let item = queue.remove(at: cursor)
                queue.append(item)
                if cursor >= queue.count { cursor = 0 }
            }
            locked = false
            playAfterTransition()
        }
    }

    private func goNext() {
        guard !locked, queue.count > 1, queue.indices.contains(cursor) else {
            playCurrent()
            return
        }
        forwards = true
        withAnimation(Motion.spring) {
            let item = queue.remove(at: cursor)
            queue.append(item)
            if cursor >= queue.count { cursor = 0 }
        }
        playAfterTransition()
    }

    private func goPrevious() {
        guard !locked, queue.count > 1 else { return }
        forwards = false
        withAnimation(Motion.spring) {
            cursor = cursor == 0 ? queue.count - 1 : cursor - 1
        }
        playAfterTransition()
    }
}
