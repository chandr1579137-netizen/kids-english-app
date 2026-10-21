import Foundation
import XCTest
@testable import KidsEnglishCore

/// 听音找一找：直接读仓库里的 Resources/scenes/scenes.json 和产品经理归档的 spots json，
/// 检查空位坐标没抄错、台面物品贴台面线、卧室墙上只挂能挂的东西。
final class SceneTests: XCTestCase {

    private var root: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
    private var resources: URL { root.appendingPathComponent("KidsEnglish/KidsEnglish/Resources") }

    private func loadScenes() throws -> [FindScene] {
        let data = try Data(contentsOf: resources.appendingPathComponent("scenes/scenes.json"))
        let scenes = try JSONDecoder().decode([FindScene].self, from: data)
        XCTAssertEqual(SceneCatalog.decode(data), scenes)
        return scenes
    }

    private func scene(_ id: String) throws -> FindScene {
        try XCTUnwrap(try loadScenes().first { $0.id == id }, "缺少场景 \(id)")
    }

    func testFourScenesLoadAndAreValid() throws {
        let scenes = try loadScenes()
        XCTAssertEqual(scenes.map(\.id), ["farm", "kitchen", "park", "bedroom"])

        let themes = try JSONDecoder().decode([WordTheme].self,
            from: Data(contentsOf: resources.appendingPathComponent("word-themes.json")))
        let vocabulary = Set(themes.flatMap { $0.words }.map { $0.lowercased() })
        let fm = FileManager.default
        for s in scenes {
            XCTAssertEqual(SceneLayout.problems(in: s), [], s.id)
            XCTAssertGreaterThanOrEqual(s.items.count, 5, "\(s.id): 每轮 5 题，物品不能少于 5 个")
            XCTAssertTrue(fm.fileExists(atPath: resources.appendingPathComponent("scenes/\(s.background)").path),
                          "\(s.id): 背景图不存在")
            for item in s.items {
                XCTAssertTrue(vocabulary.contains(item.word.lowercased()), "\(s.id)/\(item.word) 不在 word-themes.json")
                let icon = root.appendingPathComponent("assets/word-icons-overrides/\(item.word.replacingOccurrences(of: " ", with: "_")).jpg")
                XCTAssertTrue(fm.fileExists(atPath: icon.path), "\(item.word) 没有平涂词图")
            }
        }
    }

    /// scenes.json 里的面板框和空位坐标必须和产品经理验收的 spots_all.json 一致
    func testSpotsMatchAcceptedSpotsFile() throws {
        let url = root.appendingPathComponent("docs/pm/assets/scenes/spots_all.json")
        let raw = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [[String: Any]])
        for s in try loadScenes() {
            let src = try XCTUnwrap(raw.first { ($0["file"] as? String) == s.background }, s.background)
            XCTAssertEqual((src["panel_bbox_px"] as? [Double]) ?? [], s.panel, s.id)
            let spots = try XCTUnwrap(src["spots"] as? [[String: Any]])
            XCTAssertEqual(spots.count, s.spots.count, s.id)
            for p in spots {
                let id = try XCTUnwrap(p["id"] as? Int)
                let mine = try XCTUnwrap(s.spots.first { $0.id == id }, "\(s.id) 缺空位 \(id)")
                XCTAssertEqual(mine.x, try XCTUnwrap(p["x"] as? Double), "\(s.id)#\(id)")
                XCTAssertEqual(mine.y, try XCTUnwrap(p["y"] as? Double), "\(s.id)#\(id)")
                let area = (p["area"] as? String ?? "").lowercased()
                let expected: SceneSpotKind = area.contains("counter") ? .counter : (area.contains("wall") ? .wall : .ground)
                XCTAssertEqual(mine.kind, expected, "\(s.id)#\(id) \(area)")
            }
        }
    }

    func testKitchenCounterItemsStandOnCounterLine() throws {
        let kitchen = try scene("kitchen")
        XCTAssertEqual(kitchen.counterTopY, 1010)
        let onCounter = SceneLayout.placements(for: kitchen).filter { $0.kind == .counter }
        XCTAssertEqual(onCounter.count, 3, "厨房台面有 3 个空位")
        for p in onCounter {
            // 画面底边 = 物品框底边 - PNG 底部留白，换回原图像素
            let visualBottom = p.bottomY - SceneLayout.itemImageBottomPadding * p.height
            let px = kitchen.panel[1] + visualBottom * kitchen.panelHeight
            XCTAssertEqual(px, 1010, accuracy: 0.5, "\(p.word) 没有站在台面上")
        }
    }

    func testBedroomWallSpotsOnlyTakeWallHangableItems() throws {
        let bedroom = try scene("bedroom")
        let wallSpots = Set(bedroom.spots.filter { $0.kind == .wall }.map(\.id))
        XCTAssertEqual(wallSpots.count, 2, "卧室墙面有 2 个空位")
        let onWall = bedroom.items.filter { wallSpots.contains($0.spot) }
        XCTAssertEqual(onWall.count, 2)
        for item in onWall {
            XCTAssertTrue(SceneLayout.wallHangable.contains(item.word), "\(item.word) 挂不上墙")
        }
        // 规则本身：玩具不能上墙，钟可以；地面什么都能放
        XCTAssertFalse(SceneLayout.canPlace("teddy", on: .wall))
        XCTAssertTrue(SceneLayout.canPlace("clock", on: .wall))
        XCTAssertTrue(SceneLayout.canPlace("teddy", on: .ground))
        // 数据写错时 problems 能抓到
        let broken = FindScene(id: "bad", background: bedroom.background, sourceSize: bedroom.sourceSize,
                               panel: bedroom.panel, itemSize: bedroom.itemSize, counterTopY: nil,
                               spots: bedroom.spots,
                               items: [SceneItem(word: "teddy", spot: try XCTUnwrap(wallSpots.first))])
        XCTAssertFalse(SceneLayout.problems(in: broken).isEmpty)
    }

    func testPlacementsStayInsidePanelAndAreBigEnoughToTap() throws {
        for s in try loadScenes() {
            // 最窄的 iPhone 上面板约 343pt 宽；可点区域 ≥ 64pt（界面里点击区另有 64pt 下限）
            XCTAssertGreaterThanOrEqual(s.itemSize * 360, 64, s.id)
            let placements = SceneLayout.placements(for: s)
            XCTAssertEqual(placements.count, s.items.count, s.id)
            for p in placements {
                XCTAssertGreaterThanOrEqual(p.centerX - p.width / 2, 0, "\(s.id)/\(p.word)")
                XCTAssertLessThanOrEqual(p.centerX + p.width / 2, 1, "\(s.id)/\(p.word)")
                XCTAssertGreaterThanOrEqual(p.centerY - p.height / 2, 0, "\(s.id)/\(p.word)")
                XCTAssertLessThanOrEqual(p.bottomY, 1, "\(s.id)/\(p.word)")
            }
        }
    }
}
