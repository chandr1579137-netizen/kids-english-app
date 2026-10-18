// swift-tools-version:5.9
import PackageDescription

// 只为了在 CI 上跑模型层单元测试：
// 把 Models.swift（纯 Foundation）单独编进一个 target，不依赖 UIKit / SwiftUI，
// 因此不需要给 Xcode 工程加 test target，也不需要模拟器。
let package = Package(
    name: "KidsEnglishCore",
    platforms: [.macOS(.v12)],
    targets: [
        .target(
            name: "KidsEnglishCore",
            path: "KidsEnglish/KidsEnglish",
            sources: ["Models.swift", "WordStemmer.swift", "ProgressKit.swift"]
        ),
        .testTarget(
            name: "KidsEnglishCoreTests",
            dependencies: ["KidsEnglishCore"],
            path: "Tests/KidsEnglishCoreTests"
        ),
    ]
)
