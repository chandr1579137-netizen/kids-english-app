import SwiftUI

@main
struct KidsEnglishApp: App {
    @State private var store = DataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .modifier(UITextSizeOverride())
        }
    }
}

/// 只在截图时覆盖字号；正常运行必须跟随系统设置，
/// 否则会把用户在「设置 · 文字大小」里调的值改回固定档。
private struct UITextSizeOverride: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if LaunchOptions.largeText {
            content.dynamicTypeSize(.accessibility2)
        } else {
            content
        }
    }
}

// MARK: - 5 Tab 定义（背单词 / 单词卡 / 说一说 / 儿歌 / 我的）
//
// 第 3 个 tab 原来是「读短文」，现在是「说一说」口语课（PhrasesView.swift）。
// rawValue 不变（还是 2），CI 的 `-uiTab 2` 参数照用。

/// 底栏的一项：正常模式（AppTab）和宝宝模式（BabyTab）共用同一个底栏样式
protocol KidTabItem: CaseIterable, Identifiable, Hashable {
    var title: String { get }
    var icon: String { get }
    var selectedIcon: String { get }
}

enum AppTab: Int, CaseIterable, Identifiable, KidTabItem {
    case learn, cards, read, phonics, profile

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .learn: return "背单词"
        case .cards: return "单词卡"
        case .read: return "说一说"
        case .phonics: return "启蒙乐园"
        case .profile: return "我的"
        }
    }

    var icon: String {
        switch self {
        case .learn: return "book"
        case .cards: return "rectangle.on.rectangle"
        case .read: return "bubble.left.and.bubble.right"
        case .phonics: return "sparkles"
        case .profile: return "person"
        }
    }

    var selectedIcon: String {
        switch self {
        case .learn: return "book.fill"
        case .cards: return "rectangle.on.rectangle.fill"
        case .read: return "bubble.left.and.bubble.right.fill"
        case .phonics: return "sparkles"
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

    /// `-uiBooksScrolled` 首页单词本横向滚到最右（截图验证 17 本都在）
    static var booksScrolled: Bool { args.contains("-uiBooksScrolled") }

    /// `-uiBook <themeId>` 截图时预选一本书（如 numbers / clothing）
    static var initialBook: String? { value(for: "-uiBook") }

    /// `-uiStudyWord <word>` 学习页第一张卡直接显示这个词（截图核对词图，如双格对比高亮 big / smooth）
    static var studyWord: String? { value(for: "-uiStudyWord") }

    /// `-uiConsolidate` 直接进入巩固练习 —— 游戏页原本不在截图覆盖内，
    /// 里面的旧系统色（Color.green / .blue / .red）因此长期没人看见
    static var forceConsolidate: Bool { args.contains("-uiConsolidate") }


    /// `-uiLargeText` 用最大档文字截图，验证 Dynamic Type 下布局不塌
    static var largeText: Bool { args.contains("-uiLargeText") }

    /// `-uiGuide` 强制展示首次启动的家长说明卡（截图覆盖用）
    static var forceGuide: Bool { args.contains("-uiGuide") }

    /// 是否处于「按参数直达某页」的截图模式。
    /// 截图每次都是全新安装，hasSeenGuide 为 false；如果不区分，
    /// 引导卡会盖住所有页面截图。
    static var isUIScreenshotRun: Bool { args.contains { $0.hasPrefix("-ui") } }

    /// `-uiAlert clear` 直接弹出家长中心「清除进度」确认卡片（截图覆盖用）
    static var alertDemo: String? { value(for: "-uiAlert") }

    // MARK: 截图覆盖补充（每个页面一个参数，都是「直接渲染」而不是 push）

    /// `-uiTheme <id>` 单词卡直接打开某个主题的词表（如 fruits / animals）
    static var themeId: String? { value(for: "-uiTheme") }

    /// `-uiProfile <songs|parent|settings>` 我的页直接打开二级页
    static var profilePage: String? { value(for: "-uiProfile") }

    /// `-uiGame <0..8>` 巩固练习直接进入某个玩法（顺序同 ConsolidationView.Mode）
    static var startingGameMode: ConsolidationView.Mode? {
        guard let raw = value(for: "-uiGame"), let index = Int(raw) else { return nil }
        let all = ConsolidationView.Mode.allCases
        return all.indices.contains(index) ? all[index] : nil
    }
}

// MARK: - 根视图

struct ContentView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: AppTab = LaunchOptions.initialTab

    var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()

            // 底栏是真正的布局兄弟，不是 safeAreaInset 覆盖层。
            // 用 safeAreaInset 时它只把子视图的 safeArea 标成「有底栏」，
            // 但 ScrollView 的视口并不会因此缩短：内容一路画到底栏底下，
            // 绘本末排被压、学习页判定键被切都是这么来的（实测内容到了
            // 840–874pt 的 home indicator 区）。改成 VStack 后可用高度被
            // 真正切走，视口底边 = 底栏顶边。
            if babyActive {
                // 宝宝模式：今天 / 图画 / 说一说 / 儿歌 / 家长（BabyView.swift）
                BabyRootView()
            } else {
                VStack(spacing: 0) {
                    // iPad：内容列限宽居中；iPhone 上 maxWidth(720) 大于屏宽，不生效。
                    content
                        .frame(maxWidth: KidLayout.readableWidth)
                    KidTabBar(selection: $tab)
                }
            }

            if store.timeUp {
                TimeUpOverlay()
            }

            // 多孩子：2 个以上孩子时，打开 App / 离开超过 10 分钟回来，先问「谁来学？」
            if store.whoIsLearningVisible {
                WhoIsLearningView()
                    .transition(.opacity)
            }

            // 首次启动：给家长一页说明。截图模式（任意 -ui* 参数）下不自动弹，
            // 否则全新安装的引导卡会盖住所有页面截图。
            if LaunchOptions.forceGuide
                || (!store.hasSeenGuide && !LaunchOptions.isUIScreenshotRun) {
                FirstRunGuide()
            }
        }
        // 回到前台时核对日期：App 挂着跨过零点不会自动换天，
        // 昨天的用量会被算进今天的限时里。
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.rolloverDayIfNeeded()
                store.noteForeground()
            } else if phase == .background {
                store.noteBackground()
            }
        }
    }

    private var babyActive: Bool { LaunchOptions.isBaby(store) }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .learn:
            LearnWordsView()
        case .cards:
            // 截图覆盖：主题词表原本只能点进去，CI 拍不到
            if let id = LaunchOptions.themeId,
               let theme = store.wordThemes.first(where: { $0.id == id }) {
                NavigationStack { ThemeWordsView(theme: theme) }
            } else {
                WordCardsView()
            }
        case .read:
            PhrasesHomeView()
        case .phonics:
            NavigationStack { BabyPortalView() }
        case .profile:
            // 截图覆盖：儿歌 / 家长验证 / 设置。三个页面各自的容器不同：
            // SongsView、ParentGateView 自带 NavigationStack，设置详情页没有。
            if let page = LaunchOptions.profilePage {
                switch page {
                case "parent":
                    ParentGateView()
                case "favorites":
                    NavigationStack { FavoritesView() }
                case "learned":
                    NavigationStack { LearnedWordsView() }
                case "edit":
                    ProfileView()
                case "parent-dash":
                    // 截图用：跳过数学题直接进家长仪表盘
                    NavigationStack { ParentDashboardView() }
                default:
                    NavigationStack { SettingsDetailView() }
                }
            } else {
                ProfileView()
            }
        }
    }
}

// MARK: - 自定义底栏（复刻参考图：圆角方块图标底 + 下方文字）

struct KidTabBar<Tab: KidTabItem>: View {
    @Binding var selection: Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(Tab.allCases)) { item in
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
                                .kidFont(22, .semibold)
                                .foregroundStyle(.white)
                        }
                        Text(item.title)
                            .kidFont(11, .semibold)
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
        .background {
            // 白底要铺进底部安全区：否则 home indicator 那 34pt 会露出
            // 底栏下方滚过去的页面内容，看起来像「底栏后面还有一截」。
            Palette.surface
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Palette.hairline)
                        .frame(height: 0.5)
                }
                .ignoresSafeArea(edges: .bottom)
        }
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
                Text("🌙").kidFont(80)
                Text("今天学得够多啦！")
                    .kidFont(28, .bold)
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


// MARK: - 首次启动：家长说明卡
//
// 第一次打开时的家长需要知道四件事：计划怎么走、家长中心在哪、
// 每日限时默认开着、进度能导出。点一次就记进 UserDefaults，不再出现。
struct FirstRunGuide: View {
    @Environment(DataStore.self) private var store

    private struct Item: Identifiable {
        let id = UUID()
        let emoji: String
        let title: String
        let detail: String
    }

    private var items: [Item] { LaunchOptions.isBaby(store) ? babyItems : normalItems }

    private let babyItems: [Item] = [
        Item(emoji: "🌱", title: "启蒙模式：不识字也能自己玩",
             detail: "孩子点「今天」的大按钮：复习、学几个新词、听音选图，做完得一张贴纸"),
        Item(emoji: "👨‍👩‍👧", title: "家长中心在「家长」页签",
             detail: "进入前要答一道数学题；可改每天新词数、解锁全部词包，也能切回正常模式"),
        Item(emoji: "⏰", title: "每日限时默认 20 分钟",
             detail: "到时间会锁屏，需要家长在家长中心解锁或调整"),
        Item(emoji: "💾", title: "进度可以导出备份",
             detail: "换手机前在家长中心导出文本；恢复会覆盖当前进度"),
    ]

    private let normalItems: [Item] = [
        Item(emoji: "📚", title: "每天 10 个新词",
             detail: "首页「开始学习」按每日计划走；词由 15 个主题交错排，每天都有新主题"),
        Item(emoji: "👨‍👩‍👧", title: "家长中心在「我的」页底部",
             detail: "进入前要答一道数学题，可改每日限时、新词数、游戏难度"),
        Item(emoji: "⏰", title: "每日限时默认 20 分钟",
             detail: "到时间会锁屏，需要家长在家长中心解锁或调整"),
        Item(emoji: "💾", title: "进度可以导出备份",
             detail: "换手机前在家长中心导出文本；恢复会覆盖当前进度"),
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("👋 欢迎使用英语小伙伴")
                    .kidFont(22, .heavy)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(items) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Text(item.emoji).kidFont(22, maxScale: 1.1)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .kidFont(17, .bold)
                                    .foregroundStyle(Palette.ink)
                                Text(item.detail)
                                    .kidFont(14, .medium)
                                    .foregroundStyle(Palette.inkMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                AppButton(title: "知道啦", icon: "checkmark") {
                    store.markGuideSeen()
                }
                .padding(.top, 4)
            }
            .padding(22)
            .frame(maxWidth: 360)
            .background(Palette.surface,
                        in: RoundedRectangle(cornerRadius: Radius.sheet, style: .continuous))
            .elevationRaised()
            .padding(24)
        }
    }
}
