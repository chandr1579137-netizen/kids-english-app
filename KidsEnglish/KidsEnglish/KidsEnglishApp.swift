import SwiftUI

@main
struct KidsEnglishApp: App {
    @State private var store = DataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}

// MARK: - 5 Tab 定义（复刻截图结构：背单词 / 单词卡 / 读短文 / 绘本 / 我的）

enum AppTab: Int, CaseIterable, Identifiable {
    case learn, cards, read, picture, profile

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .learn: return "背单词"
        case .cards: return "单词卡"
        case .read: return "读短文"
        case .picture: return "绘本"
        case .profile: return "我的"
        }
    }

    var icon: String {
        switch self {
        case .learn: return "book"
        case .cards: return "rectangle.on.rectangle"
        case .read: return "doc.text"
        case .picture: return "book.closed"
        case .profile: return "person"
        }
    }

    var selectedIcon: String {
        switch self {
        case .learn: return "book.fill"
        case .cards: return "rectangle.on.rectangle.fill"
        case .read: return "doc.text.fill"
        case .picture: return "book.closed.fill"
        case .profile: return "person.fill"
        }
    }
}

// MARK: - 启动参数（供 CI 截图定位页面；正常运行无影响）

enum LaunchOptions {
    private static var args: [String] { ProcessInfo.processInfo.arguments }

    static func value(for key: String) -> String? {
        guard let i = args.firstIndex(of: key), args.indices.contains(i + 1) else { return nil }
        return args[i + 1]
    }

    /// `-uiTab 0..4` 指定首屏 tab
    static var initialTab: AppTab {
        if let raw = value(for: "-uiTab"), let i = Int(raw), let t = AppTab(rawValue: i) {
            return t
        }
        return .learn
    }

    /// `-uiStudy` 直接进入背单词的学习页
    static var forceStudy: Bool { args.contains("-uiStudy") }

    /// `-uiConsolidate` 直接进入巩固练习 —— 游戏页原本不在截图覆盖内，
    /// 里面的旧系统色（Color.green / .blue / .red）因此长期没人看见
    static var forceConsolidate: Bool { args.contains("-uiConsolidate") }

    /// `-uiLesson` 直接打开读短文的第一课
    static var forceLesson: Bool { args.contains("-uiLesson") }
}

// MARK: - 根视图

struct ContentView: View {
    @Environment(DataStore.self) private var store
    @State private var tab: AppTab = LaunchOptions.initialTab

    var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()

            content
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    KidTabBar(selection: $tab)
                }

            if store.timeUp {
                TimeUpOverlay()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .learn: LearnWordsView()
        case .cards: WordCardsView()
        case .read: ReadView()
        case .picture: PictureBookView()
        case .profile: ProfileView()
        }
    }
}

// MARK: - 自定义底栏（复刻参考图：圆角方块图标底 + 下方文字）

struct KidTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { item in
                let isSelected = selection == item
                Button {
                    guard selection != item else { return }
                    selection = item
                } label: {
                    VStack(spacing: 5) {
                        // 参考图：图标放在一个圆角方块里，选中橙底、未选中灰底
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isSelected ? Func.accent : Color(red: 0.88, green: 0.88, blue: 0.89))
                                .frame(width: 46, height: 46)
                            Image(systemName: isSelected ? item.selectedIcon : item.icon)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        Text(item.title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(isSelected ? Func.accent : Palette.inkMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 76)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 6)
        .background(
            Palette.surface
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Palette.hairline)
                        .frame(height: 0.5)
                }
        )
    }
}

// MARK: - 到时间锁定遮罩

struct TimeUpOverlay: View {
    @Environment(DataStore.self) private var store
    @State private var showParentUnlock = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("🌙").font(.system(size: 80))
                Text("今天学得够多啦！")
                    .font(.title.bold())
                    .foregroundStyle(Palette.ink)
                Text("休息一下，保护眼睛，明天再来玩吧")
                    .foregroundStyle(Palette.inkMuted)
                AppButton(title: "家长解锁", tier: .secondary) {
                    showParentUnlock = true
                }
            }
            .padding(40)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.sheet))
            .elevationRaised()
            .padding()
        }
        .sheet(isPresented: $showParentUnlock) {
            ParentUnlockView(onUnlock: { store.resetTimeUp() })
        }
    }
}
