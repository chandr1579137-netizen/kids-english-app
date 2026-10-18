import Foundation

/// 词形还原：课文里点到的往往是变形（stars / had / deeper），词库只有原形。
/// 这里按「不规则表 → 精确 → 规则后缀」给出候选，交给调用方按顺序查词库。
///
/// 独立成文件的原因：它不依赖 SwiftUI/UIKit，可以进 SwiftPM 测试 target。
enum WordStemmer {
    /// 不规则动词 / 常见时态变形
    static let irregular: [String: String] = [
        "was": "be", "were": "be", "been": "be", "being": "be", "is": "be", "are": "be", "am": "be",
        "had": "have", "has": "have", "having": "have",
        "went": "go", "gone": "go", "did": "do", "done": "do", "does": "do", "doing": "do",
        "forgot": "forget", "forgotten": "forget",
        "said": "say", "says": "say",
        "made": "make", "came": "come", "found": "find", "flew": "fly", "flown": "fly",
        "saw": "see", "seen": "see", "took": "take", "taken": "take",
        "gave": "give", "given": "give", "told": "tell", "thought": "think",
        "knew": "know", "known": "know", "grew": "grow", "grown": "grow",
        "fell": "fall", "fallen": "fall", "felt": "feel", "left": "leave",
        "held": "hold", "brought": "bring", "bought": "buy", "ran": "run",
        "swam": "swim", "swum": "swim", "sang": "sing", "sung": "sing",
        "drank": "drink", "drunk": "drink", "ate": "eat", "eaten": "eat",
        "slept": "sleep", "woke": "wake", "woken": "wake",
        "wrote": "write", "written": "write", "drew": "draw", "drawn": "draw",
        "threw": "throw", "thrown": "throw", "caught": "catch", "taught": "teach",
        "sent": "send", "spent": "spend", "built": "build", "kept": "keep",
        "met": "meet", "paid": "pay", "sat": "sit", "stood": "stand",
        "understood": "understand", "wore": "wear", "worn": "wear",
        "won": "win", "lost": "lose", "heard": "hear", "became": "become",
        "began": "begin", "begun": "begin", "broke": "break", "broken": "break",
        "spoke": "speak", "spoken": "speak", "chose": "choose", "chosen": "choose",
        "drove": "drive", "driven": "drive", "rode": "ride", "ridden": "ride",
        "hid": "hide", "hidden": "hide", "blew": "blow", "blown": "blow",
        "led": "lead", "rose": "rise", "shook": "shake", "shaken": "shake",
        "shone": "shine", "shot": "shoot", "showed": "show", "shown": "show",
        "sank": "sink", "stole": "steal", "stuck": "stick", "struck": "strike",
        "swept": "sweep", "swung": "swing", "lay": "lie", "lain": "lie",
        "meant": "mean", "fought": "fight", "fed": "feed", "dug": "dig",
        "hung": "hang", "worst": "bad", "best": "good",

    ]

    /// 不规则复数
    static let plural: [String: String] = [
        "children": "child", "people": "person", "mice": "mouse",
        "feet": "foot", "teeth": "tooth", "men": "man", "women": "woman",
        "geese": "goose", "sheep": "sheep", "fish": "fish",
    ]

    /// 给出候选原形，按可能性从高到低。
    /// 调用方依次查词库，命中即止 —— 这样不需要判断哪条规则一定对。
    static func candidates(for raw: String) -> [String] {
        let trimmed = raw.trimmingCharacters(in: CharacterSet(charactersIn: "'’.,!?;:\"()"))
        let word = trimmed.lowercased()
        guard word.count > 1 else { return [] }

        var out: [String] = []
        func add(_ candidate: String) {
            guard candidate.count > 1, candidate != word, !out.contains(candidate) else { return }
            out.append(candidate)
        }

        add(irregular[word] ?? "")
        add(plural[word] ?? "")

        if word.hasSuffix("'s") || word.hasSuffix("’s") {
            add(String(word.dropLast(2)))
        }
        if word.hasSuffix("ies") {
            add(String(word.dropLast(3)) + "y")
        }
        if word.hasSuffix("ves") {
            add(String(word.dropLast(3)) + "f")
            add(String(word.dropLast(3)) + "fe")
        }
        if word.hasSuffix("es") {
            add(String(word.dropLast(2)))
        }
        if word.hasSuffix("s"), !word.hasSuffix("ss"), !word.hasSuffix("us") {
            add(String(word.dropLast()))
        }

        for suffix in ["ing", "ed", "er", "est"] where word.hasSuffix(suffix) {
            let base = String(word.dropLast(suffix.count))
            guard base.count > 1 else { continue }
            add(base)
            add(base + "e")
            add(base + "y")
            if base.hasSuffix("i") { add(String(base.dropLast()) + "y") }
            if base.count > 2 {
                let chars = Array(base)
                if chars[chars.count - 1] == chars[chars.count - 2] {
                    add(String(chars.dropLast()))
                }
            }
        }

        if word.hasSuffix("d") {
            add(String(word.dropLast()))
        }
        return out
    }
}
