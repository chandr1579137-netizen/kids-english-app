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

// MARK: - 根视图

struct ContentView: View {
    @Environment(DataStore.self) private var store
    @State private var tab: AppTab = .learn

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

// MARK: - 自定义底栏（原生 TabView 无法改选中态底色，故自建）

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
                    VStack(spacing: 4) {
                        Image(systemName: isSelected ? item.selectedIcon : item.icon)
                            .font(.system(size: 21, weight: .semibold))
                            .frame(height: 24)
                        Text(item.title)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    // 选中态：持久、结构性（浅色底 + 强调色），与按下态（压缩）走不同通道
                    .foregroundStyle(isSelected ? Func.accent : Palette.inkSubtle)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.thumb)
                            .fill(isSelected ? Func.accent.opacity(0.14) : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .background(Palette.surface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Palette.hairline)
                .frame(height: 0.5)
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
