import Foundation

// MARK: - 启蒙模式 v2（5 岁「每天一课更好玩」）：词包、每日 6 步计划、游戏轮换、复习日、出题（纯 Foundation，便于单测）
//
// 数据在 Resources/baby-path.json。
// 每天一课 6 步 + 领贴纸（见 docs/pm/daily-lesson-v2.md）：
//   1. 唱一唱（儿歌前 35 秒，无儿歌则放 4 拍鼓点 chant）
//   2. 复习（到期旧词最多 4 个，听音选图）
//   3. 学一学（4 个新词，一词一卡跟读 + 回放自己声音）
//   4. 玩一玩（从游戏池轮换 1 个游戏，不连着两天同一种，只出和今天词搭得上的游戏）
//   5. 句子（今天的 1 个句型：先听 Tom 说 → 跟读 → 换今天的另一个词再说一遍）
//   6. 自己说（依次出今天 4 个词的图，不先放音，话筒跳动等孩子独立说出，说完或 6 秒后放示范音）
//   7. 贴纸（今天的贴纸 + Tom 鼓掌庆祝）
// 每学完 4 天，第 5 个学习日是复习日：不学新词，复习这 4 天的词，戳泡泡自选游戏。

struct BabyPack: Codable, Hashable, Identifiable {
    let id: String
    let nameZh: String
    let songId: String?
    /// 默认锁着的包（家长中心可全部解锁；前面的包都学完也会自动打开）
    let locked: Bool
    let words: [String]
    /// 这一包的句型（v2：每天一课加 1 个句型），如 "I like ___."
    var pattern: String? = nil
    /// 每个词一句完整的例句（冠词、复数都写死，不靠程序拼）
    var sentences: [String: String]? = nil
    /// 反义词包：词按一对一对排列（big, small, tall, short…），同一对同一天学、出题时互为干扰项
    var pairs: Bool? = nil
    /// 家长中心「今天」卡片的一句「生活里这样用」提示
    var tipZh: String? = nil
}

struct BabyPathData: Codable, Hashable {
    let version: Int
    /// 发音用的词 → 配图用的词（mom 用 mother 的平涂图）
    let pictures: [String: String]
    let packs: [BabyPack]

    static func decode(_ data: Data) -> BabyPathData? {
        try? JSONDecoder().decode(BabyPathData.self, from: data)
    }

    func picture(for word: String) -> String { pictures[word] ?? word }

    var allWords: [String] { packs.flatMap(\.words) }

    func pack(containing word: String) -> BabyPack? {
        packs.first { $0.words.contains(word) }
    }

    /// 反义词包里和它成对的那个词（big ↔ small）；不在反义词包里返回 nil
    func partner(of word: String) -> String? {
        guard let p = pack(containing: word), p.pairs == true, let i = p.words.firstIndex(of: word) else { return nil }
        let j = i ^ 1
        return p.words.indices.contains(j) ? p.words[j] : nil
    }

    /// 这个词的例句（没有就 nil）
    func sentence(for word: String) -> String? { pack(containing: word)?.sentences?[word] }

    /// 这个词所在词包的家长「生活里这样用」提示
    func tip(for word: String) -> String? { pack(containing: word)?.tipZh }
}

/// 一个词的复习状态：第几格（越大隔得越久）+ 下次该复习的日子（yyyy-MM-dd）
struct BabyWordState: Codable, Equatable {
    var box: Int
    var due: String
}

/// 听音选图 / 拖进影子的一道题（1 个答案 + 3 个选项）
struct BabyRound: Equatable, Hashable {
    let answer: String
    let options: [String]
}

/// 押韵配对（2 个词 + 是否押韵）
struct BabyRhymeRound: Equatable, Hashable {
    let word1: String
    let word2: String
    let rhymes: Bool
}

/// 拍手数音节（1 个词 + 音节数 1..3）
struct BabySyllableRound: Equatable, Hashable {
    let word: String
    let count: Int
}

/// 每天一课的 6 个阶段（顶部 6 个圆点 + 阶段之间 Tom 过场语音）
enum BabyStage: Int, CaseIterable, Hashable {
    case sing = 0      // 1. 唱一唱
    case review = 1    // 2. 复习
    case learn = 2     // 3. 学一学
    case game = 3      // 4. 玩一玩
    case sentence = 4  // 5. 句子
    case sayIt = 5     // 6. 自己说

    var titleZh: String {
        switch self {
        case .sing: return "唱一唱"
        case .review: return "复习"
        case .learn: return "学一学"
        case .game: return "玩一玩"
        case .sentence: return "说句子"
        case .sayIt: return "自己说"
        }
    }

    var promptText: String {
        switch self {
        case .sing: return "Let's sing!"
        case .review: return "Do you remember?"
        case .learn: return "Let's learn!"
        case .game: return "Let's play!"
        case .sentence: return "Say it with me!"
        case .sayIt: return "Your turn!"
        }
    }

    var promptAudio: String {
        switch self {
        case .sing: return "tom_lets_sing"
        case .review: return "tom_lets_review"
        case .learn: return "tom_lets_learn"
        case .game: return "tom_lets_play"
        case .sentence: return "tom_say_with_me"
        case .sayIt: return "tom_your_turn"
        }
    }

    var icon: String {
        switch self {
        case .sing: return "music.note"
        case .review: return "arrow.counterclockwise"
        case .learn: return "sparkles"
        case .game: return "gamecontroller.fill"
        case .sentence: return "text.bubble.fill"
        case .sayIt: return "mic.fill"
        }
    }
}

/// 游戏池（v2：3 个新游戏 + 已有游戏，按词包兼容性与「不连着两天相同」轮换）
enum BabyGameKind: String, CaseIterable, Codable, Hashable, Identifiable {
    case listenChoice = "listen"   // 听音选图（三选一）
    case memoryFlip   = "memory"   // G1 翻牌记忆（6 张牌 = 3 对）
    case shadowDrag   = "shadow"   // G2 拖进影子（3 张图拖进上方剪影）
    case followMe     = "follow"   // G5 跟我做（动作和身体指令，每次 3 个）
    case rhymeMatch   = "rhyme"    // 押韵配对（听两词判断是否押韵）
    case syllableClap = "syllable" // 拍手数音节（听词数 1/2/3 音节）
    case feedAnimal   = "feed"     // 喂小动物（仅食物、水果包）
    case findInScene  = "scene"    // 听音找一找（仅带场景图的词）

    var id: String { rawValue }

    var titleZh: String {
        switch self {
        case .listenChoice: return "听音选图"
        case .memoryFlip: return "翻牌记忆"
        case .shadowDrag: return "拖进影子"
        case .followMe: return "跟我做"
        case .rhymeMatch: return "押韵配对"
        case .syllableClap: return "拍手数音节"
        case .feedAnimal: return "喂小动物" 
        case .findInScene: return "找一找"
        }
    }

    var icon: String {
        switch self {
        case .listenChoice: return "ear.and.waveform"
        case .memoryFlip: return "square.grid.3x2.fill"
        case .shadowDrag: return "sparkles.rectangle.stack.fill"
        case .followMe: return "figure.dance"
        case .rhymeMatch: return "music.note.list"
        case .syllableClap: return "hands.clap.fill"
        case .feedAnimal: return "carrot.fill" 
        case .findInScene: return "magnifyingglass.circle.fill"
        }
    }
}

/// Tom 向导的 3 种表情（§7：用现有头像做缩放和旋转动画，不用新画）
enum TomMood: Equatable, Hashable {
    case normal
    case happy     // 开心（答对）
    case thinking  // 想一想（答错，只是歪一下头）
    case clap      // 鼓掌（完成）
}

enum BabyStep: Equatable, Hashable {
    /// 第 1 步 唱一唱：儿歌（songId != nil）或 chant（songId == nil，依次唱 words）
    case sing(packId: String, songId: String?, words: [String])
    /// 第 2 步 复习：听音选图（旧词）
    case review(BabyRound)
    /// 第 3 步 学新词：一词一卡
    case learn(String)
    /// 复习日：戳泡泡自选游戏（3 个泡泡）
    case pickGame([BabyGameKind])
    /// 第 4 步 小游戏（听音选图）：今天的新词 + 复习词
    case game(BabyRound)
    /// 第 4 步 小游戏（G1 翻牌记忆）：6 张牌（3 对词，已打乱）
    case memoryGame([String])
    /// 第 4 步 小游戏（G2 拖进影子）：上方剪影 + 下方 3 张图
    case shadowGame(BabyRound)
    /// 第 4 步 小游戏（G5 跟我做）：动作或身体指令词
    case followMe(String)
    /// 第 4 步 小游戏（押韵配对）：听两个词判断是否同韵
    case rhymeGame(BabyRhymeRound)
    /// 第 4 步 小游戏（拍手数音节）：听词数 1/2/3 音节
    case syllableGame(BabySyllableRound)
    /// 第 5 步 句子：先听 Tom 说 → 跟读 → 换今天的另一个词再说一遍
    case sentence(word: String, text: String)
    /// 第 6 步 自己说：看图独立说出（不先放音，说完或 6 秒后放示范音）
    case sayIt(String)
    /// 第 7 步 领贴纸 + Tom 庆祝
    case done

    var stage: BabyStage? {
        switch self {
        case .sing: return .sing
        case .review: return .review
        case .learn: return .learn
        case .pickGame, .game, .memoryGame, .shadowGame, .followMe, .rhymeGame, .syllableGame: return .game
        case .sentence: return .sentence
        case .sayIt: return .sayIt
        case .done: return nil
        }
    }
}

enum BabyPlan {
    /// 复习间隔（天）：第 0 格明天复习，之后 2、4、7、14、30 天
    static let defaultNewPerDay = 4
    static let intervals = [1, 2, 4, 7, 14, 30]
    /// 每天最多复习几个旧词
    static let reviewLimit = 4
    /// 小游戏几道题、每题几个选项（大图 3 选 1）
    static let gameRounds = 5
    static let optionCount = 3
    /// 翻牌记忆：3 对 = 6 张牌
    static let memoryPairCount = 3
    /// 跟我做：每次 3 个指令
    static let followMeRounds = 3
    /// 押韵配对与拍手数音节题数
    static let rhymeRounds = 4
    static let syllableRounds = 4

    /// 押韵配对词对池（全部包含在平涂图与标准音频中）
    static let rhymePairs: [(String, String)] = [
        ("cat", "hat"),
        ("dog", "frog"),
        ("red", "bed"),
        ("bear", "pear"),
        ("sun", "run"),
        ("car", "star"),
        ("bee", "tree"),
        ("ball", "doll"),
        ("duck", "truck"),
        ("rain", "train"),
        ("goat", "boat"),
        ("pen", "hen")
    ]

    /// 明显不押韵的词对池（韵尾迥异、语义直观）
    static let nonRhymePairs: [(String, String)] = [
        ("cat", "dog"),
        ("sun", "fish"),
        ("car", "bed"),
        ("apple", "star"),
        ("tree", "duck"),
        ("boat", "bear"),
        ("bee", "frog"),
        ("rain", "hat")
    ]

    /// 拍手数音节词池（1、2、3 音节，发音清晰明快，100% 存在平涂图与音频）
    static let syllableWords: [Int: [String]] = [
        1: ["cat", "dog", "fish", "sun", "star"],
        2: ["apple", "monkey", "rabbit", "water", "flower"],
        3: ["banana", "elephant", "butterfly", "strawberry", "kangaroo"]
    ]
    /// 句子环节：今天练 2 句（先听 Tom 说 → 跟读 → 换成今天的另一个词再说一遍）
    static let sentenceCount = 2
    /// 每学 4 天新课，第 5 天是复习日（周期 = 5）
    static let reviewCycleDays = 5

    /// 「跟我做」（G5）只用身体和动作包的词，指令句型固定
    static let followMeCommands: [String: String] = [
        // body
        "eye": "Touch your eye!", "ear": "Touch your ear!", "nose": "Touch your nose!",
        "mouth": "Touch your mouth!", "hand": "Touch your hand!", "foot": "Touch your foot!",
        "head": "Touch your head!", "hair": "Touch your hair!",
        // body-2
        "arm": "Touch your arm!", "leg": "Touch your leg!", "face": "Touch your face!",
        "teeth": "Show me your teeth!", "finger": "Touch your finger!", "knee": "Touch your knee!",
        // actions
        "run": "Run!", "jump": "Jump!", "eat": "Eat!", "drink": "Drink!",
        "sleep": "Go to sleep!", "look": "Look at me!", "clap": "Clap your hands!", "wash": "Wash your hands!",
        // actions-2
        "swim": "Swim!", "fly": "Fly like a bird!", "sit": "Sit down!", "stand": "Stand up!",
        "sing": "Sing!", "dance": "Dance!", "read": "Read a book!", "draw": "Draw a picture!",
        "walk": "Walk!", "climb": "Climb!",
        // actions-3
        "kick": "Kick the ball!", "throw": "Throw the ball!", "catch": "Catch the ball!",
        "hug": "Give a big hug!", "kiss": "Blow a kiss!", "smile": "Smile!",
        "laugh": "Laugh!", "cry": "Don't cry!", "cook": "Let's cook!", "clean": "Clean up!",
    ]

    /// 能抠出清晰单物体剪影的词包（排除数字卡、纯色块、整幅风景/场所、抽象反义词和多人动作图）
    static let shadowCompatiblePacks: Set<String> = [
        "family", "animals", "food", "body", "clothes",
        "fruits-2", "farm", "zoo", "sea", "bugs-birds", "food-2",
        "toys", "home", "kitchen", "school-things", "vehicles", "body-2", "family-2",
    ]

    /// 喂小动物只出现在食物、水果包里（§2）
    static let feedCompatiblePacks: Set<String> = ["food", "fruits-2", "food-2"]

    /// 听音找一找场景里有的词（与 Resources/scenes/scenes.json 对齐）
    static let sceneWords: Set<String> = [
        "cow", "pig", "horse", "sheep", "duck", "hen", "rabbit", "dog", "cat", "bird",
        "apple", "banana", "milk", "bread", "egg", "cake", "cup", "plate", "spoon", "chair",
        "tree", "flower", "ball", "kite", "bike", "dog", "bird", "sun", "cloud",
        "bed", "lamp", "clock", "book", "teddy", "doll", "box", "shoes", "hat",
    ]

    static func isShadowCompatible(_ word: String, data: BabyPathData) -> Bool {
        guard let p = data.pack(containing: word) else { return false }
        return shadowCompatiblePacks.contains(p.id)
    }

    static func isFollowMeCompatible(_ word: String) -> Bool {
        followMeCommands[word] != nil
    }

    // MARK: - 复习日判断（§5）

    /// 每学 4 天新课，下一天（第 5 天，即已完成天数 % 5 == 4）是复习日
    static func isReviewDay(completedDays: Int) -> Bool {
        completedDays >= 4 && (completedDays % reviewCycleDays == reviewCycleDays - 1)
    }

    // MARK: - 游戏兼容与轮换（§2）

    /// 根据今天的词判断哪些游戏搭得上
    static func compatibleGames(for words: [String], data: BabyPathData, includeCoreOnly: Bool = false) -> [BabyGameKind] {
        guard !words.isEmpty else { return [.listenChoice] }
        var result: [BabyGameKind] = [.listenChoice, .memoryFlip, .rhymeMatch, .syllableClap]
        if words.contains(where: { isShadowCompatible($0, data: data) }) {
            result.append(.shadowDrag)
        }
        if words.contains(where: isFollowMeCompatible) {
            result.append(.followMe)
        }
        if !includeCoreOnly {
            let packIds = Set(words.compactMap { data.pack(containing: $0)?.id })
            if !packIds.isDisjoint(with: feedCompatiblePacks) {
                result.append(.feedAnimal)
            }
            if words.contains(where: { sceneWords.contains($0) }) {
                result.append(.findInScene)
            }
        }
        return result
    }

    /// 每天轮换 1 个游戏：同一个游戏不连着两天出现，且只选和今天的词搭得上的课内游戏
    static func pickGame(for words: [String], data: BabyPathData, lastGame: BabyGameKind?,
                         using rng: inout some RandomNumberGenerator) -> BabyGameKind {
        let compatible = compatibleGames(for: words, data: data, includeCoreOnly: true)
        let filtered = compatible.filter { $0 != lastGame }
        let pool = filtered.isEmpty ? compatible : filtered
        // 如果今天正好是身体/动作包且昨天没玩「跟我做」，优先让孩子玩到专属动作游戏
        if pool.contains(.followMe) && lastGame != .followMe {
            return .followMe
        }
        return pool.randomElement(using: &rng) ?? .listenChoice
    }

    /// 复习日泡泡自选：给孩子 3 个不重复的泡泡选想玩的游戏
    static func bubbleGames(for words: [String], data: BabyPathData) -> [BabyGameKind] {
        var list = compatibleGames(for: words, data: data, includeCoreOnly: true)
        // 优先把好玩的新游戏排前面，凑齐 3 个泡泡
        let priority: [BabyGameKind] = [.rhymeMatch, .syllableClap, .followMe, .memoryFlip, .shadowDrag, .listenChoice]
        list.sort { (priority.firstIndex(of: $0) ?? 99) < (priority.firstIndex(of: $1) ?? 99) }
        return Array(list.prefix(3))
    }

    // MARK: - 解锁

    /// 能学的包：没锁的 + 家长全部解锁 + 前面的包都学完后，按顺序打开下一个锁着的包
    static func openPacks(_ data: BabyPathData, known: Set<String>, unlockAll: Bool) -> [BabyPack] {
        if unlockAll { return data.packs }
        var open = data.packs.filter { !$0.locked }
        let allOpenKnown = open.allSatisfy { $0.words.allSatisfy(known.contains) }
        if allOpenKnown, let next = data.packs.first(where: { $0.locked && !$0.words.allSatisfy(known.contains) }) {
            open.append(next)
        }
        // 已经学过词的锁包也算开着（家长中途关掉「全部解锁」时，学过的不收回）
        for p in data.packs where p.locked && !open.contains(p) && p.words.contains(where: known.contains) {
            open.append(p)
        }
        return data.packs.filter { open.contains($0) }
    }

    // MARK: - 每日计划

    /// 今天的新词：按包的顺序，跳过学过的，取 count 个。
    /// 反义词一对必须同一天学：取到一对里的一个，就把另一个也带上（可能比 count 多 1 个）
    static func newWords(_ data: BabyPathData, known: Set<String>, unlockAll: Bool, count: Int = defaultNewPerDay) -> [String] {
        let pool = openPacks(data, known: known, unlockAll: unlockAll).flatMap(\.words).filter { !known.contains($0) }
        var out: [String] = []
        for w in pool where out.count < max(0, count) && !out.contains(w) {
            out.append(w)
            if let p = data.partner(of: w), !known.contains(p), !out.contains(p) { out.append(p) }
        }
        return out
    }

    /// 今天到期的旧词：先复习最早到期的，同一天到期的先复习格子小的（记得最不牢的）
    static func dueReviews(_ states: [String: BabyWordState], today: String, limit: Int = reviewLimit) -> [String] {
        states
            .filter { $0.value.due <= today }
            .sorted { ($0.value.due, $0.value.box, $0.key) < ($1.value.due, $1.value.box, $1.key) }
            .prefix(limit)
            .map(\.key)
    }

    /// 复习日用的词池：从已学词里按词包顺序取最近学的 16 个词（4 天 × 4 个词）
    static func reviewDayPool(_ data: BabyPathData, known: Set<String>, limit: Int = 16) -> [String] {
        let learnedInOrder = data.allWords.filter { known.contains($0) }
        return Array(learnedInOrder.suffix(limit))
    }

    /// 刚学会的新词：放进第 0 格，明天复习
    static func learned(today: Date, timeZone: TimeZone) -> BabyWordState {
        BabyWordState(box: 0, due: dayKey(today, plus: intervals[0], timeZone: timeZone))
    }

    /// 答题之后：一次答对升一格（隔得更久），答错回到第 0 格明天再来
    static func after(_ state: BabyWordState, correct: Bool, today: Date, timeZone: TimeZone) -> BabyWordState {
        let box = correct ? min(state.box + 1, intervals.count - 1) : 0
        return BabyWordState(box: box, due: dayKey(today, plus: intervals[box], timeZone: timeZone))
    }

    static func dayKey(_ date: Date, plus days: Int, timeZone: TimeZone) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let shifted = cal.date(byAdding: .day, value: days, to: date) ?? date
        return DayKey.key(for: shifted, timeZone: timeZone)
    }

    // MARK: - 各游戏的出题规则

    /// 听音选图 / 拖进影子单题：答案 + 从 pool 里挑干扰项（跳过易混词，配图也不能撞），选项顺序打乱
    static func round(answer: String, pool: [String], data: BabyPathData,
                      using rng: inout some RandomNumberGenerator) -> BabyRound {
        var chosen: [String] = []
        // 反义词：同一对的另一个词优先当干扰项（听 big 时，small 一定在选项里）
        var candidates = pool.shuffled(using: &rng)
        if let p = data.partner(of: answer), let i = candidates.firstIndex(of: p) {
            candidates.remove(at: i)
            candidates.insert(p, at: 0)
        }
        for candidate in candidates {
            if chosen.count >= optionCount - 1 { break }
            if candidate == answer || chosen.contains(candidate) { continue }
            let clash = ([answer] + chosen).contains { other in
                Confusables.conflict(candidate, other)
                    || Confusables.conflict(data.picture(for: candidate), data.picture(for: other))
                    || data.picture(for: candidate) == data.picture(for: other)
            }
            if clash { continue }
            chosen.append(candidate)
        }
        return BabyRound(answer: answer, options: ([answer] + chosen).shuffled(using: &rng))
    }

    /// G1 翻牌记忆出题：挑 3 个不互混、不同图的词，每个词 2 张牌，共 6 张打乱
    static func makeMemoryCards(targets: [String], pool: [String], data: BabyPathData,
                                using rng: inout some RandomNumberGenerator) -> [String] {
        var picked: [String] = []
        let candidates = targets + pool.shuffled(using: &rng)
        for w in candidates {
            if picked.count >= memoryPairCount { break }
            if picked.contains(w) { continue }
            let clash = picked.contains { other in
                Confusables.conflict(w, other)
                    || Confusables.conflict(data.picture(for: w), data.picture(for: other))
                    || data.picture(for: w) == data.picture(for: other)
            }
            if clash { continue }
            picked.append(w)
        }
        while picked.count < memoryPairCount, let fallback = (targets + pool).first(where: { !picked.contains($0) }) {
            picked.append(fallback)
        }
        let pairs = picked + picked
        return pairs.shuffled(using: &rng)
    }

    /// G2 拖进影子出题：挑可生成剪影的词出 5 题，同一个词不连着考
    static func makeShadowRounds(targets: [String], reviews: [String], pool: [String], data: BabyPathData,
                                 using rng: inout some RandomNumberGenerator) -> [BabyRound] {
        let shadowTargets = targets.filter { isShadowCompatible($0, data: data) }
        let shadowReviews = reviews.filter { isShadowCompatible($0, data: data) }
        let shadowPool = pool.filter { isShadowCompatible($0, data: data) }
        let base = !shadowTargets.isEmpty ? shadowTargets : (!shadowReviews.isEmpty ? shadowReviews : shadowPool)
        guard !base.isEmpty else { return [] }
        let ordered = nonConsecutiveTargets(primary: base, secondary: shadowReviews + shadowPool,
                                            count: gameRounds, using: &rng)
        let optionPool = shadowPool.count >= optionCount ? shadowPool : pool
        return ordered.map { round(answer: $0, pool: optionPool, data: data, using: &rng) }
    }

    /// G5 跟我做出题：只取动作和身体词，每次 3 个指令，同一个词不连着出现
    static func makeFollowMeWords(targets: [String], reviews: [String], pool: [String],
                                  using rng: inout some RandomNumberGenerator) -> [String] {
        let primary = targets.filter(isFollowMeCompatible)
        let secondary = (reviews + pool).filter(isFollowMeCompatible)
        let fallback = Array(followMeCommands.keys).sorted()
        let base = !primary.isEmpty ? primary : (!secondary.isEmpty ? secondary : fallback)
        return nonConsecutiveTargets(primary: base, secondary: secondary + fallback,
                                     count: followMeRounds, using: &rng)
    }

    /// 押韵配对出题：通常出 4 题（2 题押韵 + 2 题不押韵），打乱顺序
    static func makeRhymeRounds(count: Int = rhymeRounds,
                                using rng: inout some RandomNumberGenerator) -> [BabyRhymeRound] {
        let rhymingHalf = count / 2
        let nonRhymingHalf = max(1, count - rhymingHalf)
        let pickedRhymes = rhymePairs.shuffled(using: &rng).prefix(rhymingHalf).map {
            BabyRhymeRound(word1: $0.0, word2: $0.1, rhymes: true)
        }
        let pickedNonRhymes = nonRhymePairs.shuffled(using: &rng).prefix(nonRhymingHalf).map {
            BabyRhymeRound(word1: $0.0, word2: $0.1, rhymes: false)
        }
        let combined = Array(pickedRhymes) + Array(pickedNonRhymes)
        return combined.shuffled(using: &rng)
    }

    /// 拍手数音节出题：从 1、2、3 音节词中挑选，确保覆盖不同音节数
    static func makeSyllableRounds(count: Int = syllableRounds,
                                   using rng: inout some RandomNumberGenerator) -> [BabySyllableRound] {
        var rounds: [BabySyllableRound] = []
        // 保证 1, 2, 3 音节各至少出 1 题
        for syl in [1, 2, 3] {
            if let w = syllableWords[syl]?.randomElement(using: &rng) {
                rounds.append(BabySyllableRound(word: w, count: syl))
            }
        }
        // 补充剩余题目至 count
        var allFlattened: [(Int, String)] = []
        for (syl, words) in syllableWords {
            for w in words { allFlattened.append((syl, w)) }
        }
        var shuffled = allFlattened.shuffled(using: &rng)
        while rounds.count < count, !shuffled.isEmpty {
            let item = shuffled.removeFirst()
            if !rounds.contains(where: { $0.word == item.1 }) {
                rounds.append(BabySyllableRound(word: item.1, count: item.0))
            }
        }
        return rounds.shuffled(using: &rng)
    }

    /// 构造指定游戏种类的步骤列表
    static func gameSteps(kind: BabyGameKind, newWords: [String], reviews: [String], pool: [String],
                          data: BabyPathData, using rng: inout some RandomNumberGenerator) -> [BabyStep] {
        let activeWords = !newWords.isEmpty ? newWords : reviews
        switch kind {
        case .memoryFlip:
            let cards = makeMemoryCards(targets: activeWords, pool: pool, data: data, using: &rng)
            return cards.isEmpty ? [] : [.memoryGame(cards)]
        case .shadowDrag:
            let rounds = makeShadowRounds(targets: activeWords, reviews: reviews, pool: pool, data: data, using: &rng)
            if !rounds.isEmpty { return rounds.map { .shadowGame($0) } }
            return listenGameSteps(newWords: activeWords, reviews: reviews, pool: pool, data: data, using: &rng)
        case .followMe:
            let cmds = makeFollowMeWords(targets: activeWords, reviews: reviews, pool: pool, using: &rng)
            return cmds.map { .followMe($0) }
        case .rhymeMatch:
            let rounds = makeRhymeRounds(using: &rng)
            return rounds.map { .rhymeGame($0) }
        case .syllableClap:
            let rounds = makeSyllableRounds(using: &rng)
            return rounds.map { .syllableGame($0) }
        case .listenChoice, .feedAnimal, .findInScene:
            return listenGameSteps(newWords: activeWords, reviews: reviews, pool: pool, data: data, using: &rng)
        }
    }

    private static func listenGameSteps(newWords: [String], reviews: [String], pool: [String],
                                        data: BabyPathData, using rng: inout some RandomNumberGenerator) -> [BabyStep] {
        guard !newWords.isEmpty || !reviews.isEmpty else { return [] }
        let ordered = nonConsecutiveTargets(primary: newWords, secondary: reviews, count: gameRounds, using: &rng)
        return ordered.map { .game(round(answer: $0, pool: pool, data: data, using: &rng)) }
    }

    private static func nonConsecutiveTargets(primary: [String], secondary: [String], count: Int,
                                              using rng: inout some RandomNumberGenerator) -> [String] {
        var targets = primary
        var extra = secondary.shuffled(using: &rng) + primary.shuffled(using: &rng)
        while targets.count < count, !extra.isEmpty {
            targets.append(extra.removeFirst())
        }
        while targets.count < count, let any = (primary + secondary).randomElement(using: &rng) {
            targets.append(any)
        }
        targets = Array(targets.prefix(count))
        var ordered: [String] = []
        var rest = targets.shuffled(using: &rng)
        while !rest.isEmpty {
            let i = rest.firstIndex { $0 != ordered.last } ?? 0
            ordered.append(rest.remove(at: i))
        }
        return ordered
    }

    // MARK: - 一次「今天」的全部步骤（6 步 + 领贴纸）

    static func session(_ data: BabyPathData, newWords: [String], reviews: [String], known: Set<String>,
                        unlockAll: Bool, gameKind: BabyGameKind = .listenChoice, reviewDay: Bool = false,
                        using rng: inout some RandomNumberGenerator) -> [BabyStep] {
        let pool = openPacks(data, known: known.union(newWords), unlockAll: unlockAll).flatMap(\.words)
        let focusWords = reviewDay ? (reviews.isEmpty ? reviewDayPool(data, known: known, limit: 4) : reviews)
                                   : (!newWords.isEmpty ? newWords : reviews)
        var steps: [BabyStep] = []

        // 第 1 步：唱一唱（儿歌或今天 4 个词的 chant）
        if let firstWord = focusWords.first, let pack = data.pack(containing: firstWord) {
            steps.append(.sing(packId: pack.id, songId: pack.songId, words: Array(focusWords.prefix(4))))
        }

        // 第 2 步：复习（到期旧词，最多 4 个）
        steps += reviews.map { .review(round(answer: $0, pool: pool, data: data, using: &rng)) }

        // 第 3 步：学一学（复习日不学新词）
        if !reviewDay {
            steps += newWords.map { .learn($0) }
        }

        // 第 4 步：玩一玩（复习日先戳泡泡选游戏）
        if reviewDay {
            let bubbles = bubbleGames(for: focusWords, data: data)
            steps.append(.pickGame(bubbles))
            let defaultGame = bubbles.first ?? gameKind
            steps += gameSteps(kind: defaultGame, newWords: focusWords, reviews: reviews, pool: pool, data: data, using: &rng)
        } else {
            steps += gameSteps(kind: gameKind, newWords: newWords, reviews: reviews, pool: pool, data: data, using: &rng)
        }

        // 第 5 步：句子（今天的 1 个句型：先听 Tom 说 → 跟读 → 换成今天的另一个词再说一遍，共 2 句）
        let sentenceWords = Array(focusWords.prefix(sentenceCount))
        for w in sentenceWords {
            if let text = data.sentence(for: w) {
                steps.append(.sentence(word: w, text: text))
            }
        }

        // 第 6 步：自己说（依次出今天 4 个词的图，不先放读音，等孩子独立说出）
        for w in focusWords.prefix(4) {
            steps.append(.sayIt(w))
        }

        // 第 7 步：领贴纸 + Tom 庆祝
        steps.append(.done)
        return steps
    }

    /// 今天已经完成后「再玩一次」：只玩第 4 步（换一个游戏），从学过的词里出题，不改复习进度、不再发贴纸（§1）
    static func replay(_ data: BabyPathData, known: Set<String>, unlockAll: Bool,
                       gameKind: BabyGameKind = .listenChoice,
                       using rng: inout some RandomNumberGenerator) -> [BabyStep] {
        let pool = openPacks(data, known: known, unlockAll: unlockAll).flatMap(\.words)
        let learned = data.allWords.filter(known.contains)
        guard !learned.isEmpty else { return [.done] }
        var picks = Array(learned.shuffled(using: &rng).prefix(gameRounds))
        while picks.count < gameRounds { picks.append(learned.randomElement(using: &rng)!) }
        let gSteps = gameSteps(kind: gameKind, newWords: picks, reviews: [], pool: pool, data: data, using: &rng)
        return gSteps + [.done]
    }

    /// 今天的贴纸：今天学的第一个新词；没有新词就用今天复习或出题的第一个词
    static func sticker(for steps: [BabyStep]) -> String? {
        for s in steps { if case .learn(let w) = s { return w } }
        for s in steps { if case .sayIt(let w) = s { return w } }
        for s in steps { if case .review(let r) = s { return r.answer } }
        for s in steps { if case .game(let r) = s { return r.answer } }
        for s in steps { if case .shadowGame(let r) = s { return r.answer } }
        for s in steps { if case .memoryGame(let cards) = s, let first = cards.first { return first } }
        for s in steps { if case .followMe(let w) = s { return w } }
        for s in steps { if case .rhymeGame(let r) = s { return r.word1 } }
        for s in steps { if case .syllableGame(let r) = s { return r.word } }
        return nil
    }
}

// 可复现随机数 SeededGenerator 用 Models.swift 里已有的那份（SplitMix64）
