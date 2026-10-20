import XCTest
@testable import KidsEnglishCore

/// 模型层测试：直接吃仓库里的真实资源文件。
/// 目的不是覆盖率，而是拦住「JSON 改了但 Swift 解不出来」这类静默丢数据。
final class ModelDecodingTests: XCTestCase {

    private var resources: URL {
        URL(fileURLWithPath: #filePath)          // Tests/KidsEnglishCoreTests/xxx.swift
            .deletingLastPathComponent()          // Tests/KidsEnglishCoreTests
            .deletingLastPathComponent()          // Tests
            .deletingLastPathComponent()          // 仓库根
            .appendingPathComponent("KidsEnglish/KidsEnglish/Resources")
    }

    private func load<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
        let url = resources.appendingPathComponent(name)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func allWords() throws -> [WordEntry] {
        var words: [WordEntry] = []
        for part in ["a", "b", "c", "d"] {
            words += try load("words-\(part).json", as: [WordEntry].self)
        }
        return words
    }

    // MARK: - 词库

    func testWordsDecode() throws {
        let words = try allWords()
        XCTAssertEqual(words.count, 1347, "词库总数变了，确认是有意改动")
        XCTAssertEqual(Set(words.map { $0.word }).count, words.count, "存在重复词条")
        for word in words {
            XCTAssertFalse(word.word.isEmpty)
            XCTAssertFalse((word.meaningCn ?? "").isEmpty, "\(word.word) 缺中文释义")
        }
    }

    func testThemesAreCoveredByDictionary() throws {
        let themes = try load("word-themes.json", as: [WordTheme].self)
        let index = Set(try allWords().map { $0.word.lowercased() })

        XCTAssertEqual(themes.count, 16)
        var seen = Set<String>()
        for theme in themes {
            XCTAssertFalse(theme.words.isEmpty, "\(theme.id) 是空主题")
            for word in theme.words {
                XCTAssertTrue(index.contains(word.lowercased()),
                              "主题 \(theme.id) 的 \(word) 不在词库里")
                XCTAssertTrue(seen.insert(word.lowercased()).inserted,
                              "\(word) 出现在多个主题里")
            }
        }
        XCTAssertEqual(seen.count, 573, "低龄白名单（口语词换成正式词后为 491，数字补充到 100 后为 569，服装与火补词后为 573）")
    }

    // MARK: - 课文

    func testLessonsDecode() throws {
        var lessons: [Lesson] = []
        for level in 1...7 {
            let page = try load("lessons-l\(level).json", as: [Lesson].self)
            XCTAssertFalse(page.isEmpty, "L\(level) 没有课文")
            for lesson in page {
                XCTAssertEqual(lesson.level, level, "\(lesson.id) 的 level 与文件名不符")
            }
            lessons += page
        }
        XCTAssertEqual(lessons.count, 90)
        XCTAssertEqual(Set(lessons.map { $0.id }).count, lessons.count, "课文 id 重复")

        for lesson in lessons {
            XCTAssertFalse(lesson.content.isEmpty, "\(lesson.id) 没有正文")
            for paragraph in lesson.content {
                XCTAssertFalse(paragraph.text.isEmpty)
                XCTAssertFalse(paragraph.translation.isEmpty)
                XCTAssertGreaterThanOrEqual(paragraph.audioStart, 0)
            }
        }
    }

    func testQuizItemsDecodeByType() throws {
        var counts: [String: Int] = [:]
        for level in 1...7 {
            let lessons = try load("lessons-l\(level).json", as: [Lesson].self)
            for lesson in lessons {
                for quiz in lesson.quiz {
                    counts[quiz.type, default: 0] += 1
                    XCTAssertFalse(quiz.qid.isEmpty)
                    XCTAssertFalse(quiz.question.isEmpty)

                    switch quiz.type {
                    case "fill_blank", "image_choice":
                        let options = try XCTUnwrap(quiz.options, "\(quiz.qid) 缺选项")
                        XCTAssertFalse(options.isEmpty)
                        XCTAssertTrue(options.contains { $0.value == quiz.correctAnswer },
                                      "\(quiz.qid) 的正确答案不在选项里")
                    case "word_builder":
                        let letters = try XCTUnwrap(quiz.shuffledWords).joined().lowercased()
                        XCTAssertEqual(letters.sorted(), (quiz.correctAnswer ?? "").lowercased().sorted(),
                                       "\(quiz.qid) 的字母积木与答案对不上")
                    case "sentence_order":
                        let shuffled = try XCTUnwrap(quiz.shuffledWords)
                        let ordered = try XCTUnwrap(quiz.correctOrder)
                        XCTAssertEqual(shuffled.sorted(), ordered.sorted(),
                                       "\(quiz.qid) 的乱序词与正确语序不是同一组")
                    default:
                        XCTFail("未知题型 \(quiz.type)（\(quiz.qid)）")
                    }
                }
            }
        }
        XCTAssertGreaterThan(counts["fill_blank"] ?? 0, 0)
        XCTAssertGreaterThan(counts["image_choice"] ?? 0, 0)
        XCTAssertGreaterThan(counts["word_builder"] ?? 0, 0)
        XCTAssertGreaterThan(counts["sentence_order"] ?? 0, 0)
    }

    // MARK: - 音频

    func testAudioMapKeys() throws {
        let map = try load("audio-map.json", as: [String: String].self)
        XCTAssertFalse(map.isEmpty)
        for (key, file) in map {
            XCTAssertTrue(key.contains("#"), "\(key) 不是 lessonId#paragraphId 形式")
            XCTAssertTrue(file.hasSuffix(".mp3"), "\(file) 不是 mp3")
        }
    }
}
