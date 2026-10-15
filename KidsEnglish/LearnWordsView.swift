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
    var parentLibrary: Bool = false
    @Environment(DataStore.self) private var store
    private let player = AudioPlayer.shared

    @State private var session: [WordEntry] = []
    @State private var queue: [Int] = []
    @State private var cursor = 0
    @State private var known: Set<String> = []
    @State private var learnedToday: [WordEntry] = []
    @State private var finished = false
    @State private var showStudy = false
    @State private var showBooks = false
    @State private var showWrongBook = false
    @State private var gameMode: ConsolidationView.Mode? = nil
    @State private var sessionKind: SessionKind = .learn
    @State private var forwards = true
    @State private var showSuccess = false
    @State private var locked = false
    @State private var successTick = 0

    private enum SessionKind { case learn, review, wrong }

    var body: some View {
        Group {
            if parentLibrary {
                homeRoot
            } else {
                NavigationStack { homeRoot }
            }
        }
    }

    private var homeRoot: some View {
        ScrollView {
            if parentLibrary {
                libraryHome
            } else {
                age4Home
            }
        }
            .creamBackground()
            .navigationTitle(parentLibrary ? "全部词书" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(parentLibrary ? .automatic : .hidden, for: .navigationBar)
            .onAppear { refreshSessionPreview() }
            .onChange(of: store.selectedBookId) { _, _ in refreshSessionPreview() }
            .onChange(of: store.dailyNewWords) { _, _ in refreshSessionPreview() }
            .fullScreenCover(isPresented: $showStudy) {
                studyScreen
                    .onDisappear {
                        player.stop()
                        refreshSessionPreview()
                    }
            }
            .sheet(isPresented: $showBooks) {
                BookPickerSheet()
            }
            .navigationDestination(isPresented: $showWrongBook) {
                WrongWordBookView()
            }
            .navigationDestination(item: $gameMode) { mode in
                ConsolidationView(
                    words: parentLibrary ? gameWords : childGameWords,
                    startMode: mode,
                    choicePool: parentLibrary ? nil : store.age4UnlockedWords()
                )
            }
    }

    private var libraryHome: some View {
        VStack(spacing: 16) {
            bookCard
                .padding(.horizontal)
            HStack(spacing: 12) {
                homeButton("开始学习", color: AppTheme.green) { startSession(.learn) }
                homeButton("复习", color: Color(red: 1, green: 0.62, blue: 0.2)) { startSession(.review) }
            }
            .padding(.horizontal)
            Button { showWrongBook = true } label: {
                HStack {
                    Image(systemName: "book.closed.fill")
                    Text("错词本")
                    Spacer()
                    Text("\(store.wrongBookCount) 个")
                    Image(systemName: "chevron.right")
                }
                .font(.headline.bold())
                .foregroundStyle(AppTheme.navy)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(PressableStyle())
            .padding(.horizontal)
            homeGameGrid
            HStack(spacing: 12) {
                NavigationLink { MapView() } label: {
                    entryChip("🗺️", "学习地图")
                }
                .buttonStyle(PressableStyle())
                NavigationLink { WordsView() } label: {
                    entryChip("📚", "单词乐园")
                }
                .buttonStyle(PressableStyle())
            }
            .padding(.horizontal)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var age4Home: some View {
        let today = store.age4Today()
        return VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("今天听 \(today.count) 个")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(.white)
                if today.isEmpty {
                    Text("今天的新单词学完啦")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                } else {
                    HStack(spacing: 10) {
                        ForEach(today) { entry in
                            VStack(spacing: 6) {
                                WordIconView(word: entry.word, size: 86)
                                Text(entry.word)
                                    .font(.headline.bold())
                                    .foregroundStyle(AppTheme.navy)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(.horizontal)

            homeButton("听一听，说一说", color: AppTheme.green) { startSession(.learn) }
                .padding(.horizontal)
            homeButton("再看昨天的", color: Color(red: 1, green: 0.62, blue: 0.2)) { startSession(.review) }
                .padding(.horizontal)

            Button { gameMode = .audioToImage } label: {
                HStack(spacing: 12) {
                    Image(systemName: "ear.fill")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color(red: 0.49, green: 0.83, blue: 0.57)))
                    Text("听音选图")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.navy)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(PressableStyle())
            .padding(.horizontal)

            if let song = store.age4Song() {
                NavigationLink {
                    SongsView(childMode: true, focusSongId: song.id)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.purple))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("今天的儿歌")
                                .font(.caption.bold())
                                .foregroundStyle(.gray)
                            Text(song.titleCn)
                                .font(.title3.bold())
                                .foregroundStyle(AppTheme.navy)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.gray)
                    }
                    .padding(14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(PressableStyle())
                .padding(.horizontal)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var childGameWords: [WordEntry] {
        let today = store.age4Today()
        if !today.isEmpty { return today }
        return Array(store.age4UnlockedWords().prefix(max(1, store.dailyNewWords)))
    }

    private var gameWords: [WordEntry] {
        if !learnedToday.isEmpty { return learnedToday }
        if let today = store.planDays().first, !today.isEmpty { return today }
        let review = store.reviewEntries()
        if !review.isEmpty { return review }
        return Array(store.wordsForCurrentBook().prefix(max(1, store.dailyNewWords)))
    }

    private var todayPreview: [WordEntry] {
        store.planDays().first ?? []
    }

    private var bookCard: some View {
        Button { showBooks = true } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("词书")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(store.currentBookTitle())
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text("今日新学 \(todayPreview.count) 个 · 已学 \(store.learnedWords.count)/\(bookTotal)")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.95))
                    Text("换一本 ›")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
                Spacer(minLength: 8)
                uiIcon("book")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.planGradient)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .orange.opacity(0.35), radius: 14, y: 8)
        }
        .buttonStyle(PressableStyle())
    }

    private var bookTotal: Int {
        store.wordsForCurrentBook().count
    }

    private func homeButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(color)
                .clipShape(Capsule())
                .shadow(color: color.opacity(0.35), radius: 8, y: 4)
        }
        .buttonStyle(PressableStyle())
    }

    private func entryChip(_ icon: String, _ title: String) -> some View {
        HStack(spacing: 8) {
            Text(icon)
            Text(title)
                .font(.headline.bold())
                .foregroundStyle(AppTheme.navy)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.bold())
                .foregroundStyle(.gray)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var homeGameGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("巩固")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(AppTheme.navy)
                .padding(.horizontal)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ConsolidationView.Mode.allCases) { mode in
                    Button { gameMode = mode } label: {
                        VStack(spacing: 8) {
                            uiIcon(mode.iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                            Text(mode.rawValue)
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.navy)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text(mode.difficulty)
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(mode.color)
                                .clipShape(Capsule())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(mode.color.opacity(0.28))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - 学习全屏

    private var studyScreen: some View {
        VStack(spacing: 12) {
            if finished {
                celebration
            } else if queue.isEmpty {
                Text(emptyMessage)
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
                if !parentLibrary {
                    Text(store.age4Sentence(for: entry))
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.navy)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
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
                Text("\(sessionTitle) · 第 \(displayNumber) 个")
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
            Text(sessionKind == .review ? "复习完啦！" : "今天学完啦！")
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.navy)
            Text("你认识了 \(known.count) 个单词")
                .font(.title2)
                .foregroundStyle(.gray)
            BigButton(title: "返回首页", color: AppTheme.brightBlue) {
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
            session = parentLibrary ? (store.planDays().first ?? []) : store.age4Today()
        }
    }

    private var sessionTitle: String {
        if !parentLibrary {
            switch sessionKind {
            case .learn: return "听一听"
            case .review: return "再看昨天的"
            case .wrong: return "错词本"
            }
        }
        switch sessionKind {
        case .learn: return "背单词"
        case .review: return "复习"
        case .wrong: return "错词本"
        }
    }

    private var emptyMessage: String {
        switch sessionKind {
        case .learn:
            return parentLibrary
                ? "今天没有新单词啦，换一本词书或明天再来吧"
                : "今天的新单词学完啦，明天再来听三个"
        case .review: return "今天没有要复习的单词"
        case .wrong: return "错词本是空的，去学习或玩游戏后再来吧"
        }
    }

    private func startSession(_ kind: SessionKind) {
        sessionKind = kind
        let today: [WordEntry]
        switch kind {
        case .learn:
            today = parentLibrary ? (store.planDays().first ?? []) : store.age4Today()
        case .review:
            today = parentLibrary ? store.reviewEntries() : store.age4Review()
        case .wrong:
            today = store.wrongBookEntries()
        }
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
        store.markWrong(entry.word)
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

struct BookPickerSheet: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    bookRow(title: "全部单词", subtitle: "\(store.words.count) 词", selected: store.selectedBookId == nil) {
                        store.selectBook(nil)
                        dismiss()
                    }
                    ForEach(store.wordBookGroups) { group in
                        Text(group.nameCn)
                            .font(.title2.bold())
                            .foregroundStyle(AppTheme.navy)
                            .padding(.top, 8)
                        ForEach(group.books) { book in
                            let count = store.entries(forBook: book.id).count
                            bookRow(
                                title: book.nameCn,
                                subtitle: "\(count) 词",
                                selected: store.selectedBookId == book.id
                            ) {
                                store.selectBook(book.id)
                                dismiss()
                            }
                        }
                    }
                    if !store.bookCitation.isEmpty {
                        Text(store.bookCitation)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                }
                .padding(16)
            }
            .creamBackground()
            .navigationTitle("选词书")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private func bookRow(title: String, subtitle: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.navy)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.green)
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressableStyle())
    }
}

struct WrongWordBookView: View {
    @Environment(DataStore.self) private var store
    @State private var practicing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("还要再练 \(store.wrongBookCount) 个 · 今天错了 \(store.wrongWordsToday().count) 个")
                    .font(.headline)
                    .foregroundStyle(AppTheme.navy)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if store.wrongBookEntries().isEmpty {
                    Text("错词本是空的。学习时点「不认识」，或游戏里答错，单词会来到这里。认识了就可以移出。")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.navy)
                        .padding()
                        .whiteCard()
                } else {
                    ForEach(store.wrongBookEntries()) { entry in
                        HStack(spacing: 12) {
                            WordIconView(word: entry.word, size: 54)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.word)
                                    .font(.title3.bold())
                                    .foregroundStyle(AppTheme.brightBlue)
                                Text(entry.meaningCn ?? "")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.wordOrange)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    BigButton(title: "开始练习", color: AppTheme.green) {
                        practicing = true
                    }
                }
            }
            .padding(16)
        }
        .creamBackground()
        .navigationTitle("错词本")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $practicing) {
            WrongWordPracticeView()
        }
    }
}

struct WrongWordPracticeView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    private let player = AudioPlayer.shared
    @State private var queue: [WordEntry] = []
    @State private var cursor = 0
    @State private var known = 0
    @State private var finished = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.navy)
                        .frame(width: 40, height: 40)
                }
                Text("错词练习")
                    .font(.title.bold())
                    .foregroundStyle(AppTheme.navy)
                Spacer()
            }
            .padding(.horizontal)
            if finished || queue.isEmpty {
                Text(queue.isEmpty && known == 0 ? "错词本是空的" : "这些错词都认识啦")
                    .font(.title.bold())
                    .foregroundStyle(AppTheme.navy)
                    .padding()
                    .whiteCard()
                    .padding()
                BigButton(title: "返回", color: AppTheme.green) { dismiss() }
                    .padding(.horizontal)
            } else {
                FlashCardFace(entry: queue[cursor])
                    .padding(.horizontal)
                WordAudioButtons(player: player, entry: queue[cursor])
                HStack(spacing: 12) {
                    Button { miss() } label: {
                        Text("不认识 ✕")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.red)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    Button { hit() } label: {
                        Text("认识 ✓")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.green)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal)
                Text("认识后会移出错词本")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .creamBackground()
        .onAppear {
            queue = store.wrongBookEntries()
            if let first = queue.first {
                player.play(url: store.bestAudioURL(forWord: first.word), spokenFallback: first.word)
            }
        }
        .onDisappear { player.stop() }
    }

    private func hit() {
        guard queue.indices.contains(cursor) else { return }
        let entry = queue[cursor]
        store.markLearned(entry.word)
        known += 1
        queue.remove(at: cursor)
        if cursor >= queue.count { cursor = 0 }
        if queue.isEmpty { finished = true }
        else { playCurrent() }
    }

    private func miss() {
        guard queue.indices.contains(cursor) else { return }
        let entry = queue[cursor]
        store.markWrong(entry.word)
        player.play(url: store.bestAudioURL(forWord: entry.word), rate: 0.75, spokenFallback: entry.word)
        if queue.count > 1 {
            let item = queue.remove(at: cursor)
            queue.append(item)
            if cursor >= queue.count { cursor = 0 }
        }
    }

    private func playCurrent() {
        guard queue.indices.contains(cursor) else { return }
        let entry = queue[cursor]
        player.play(url: store.bestAudioURL(forWord: entry.word), spokenFallback: entry.word)
    }
}
