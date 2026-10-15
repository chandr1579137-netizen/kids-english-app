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

enum AppTab: String, CaseIterable, Identifiable {
    case today, pictures, songs, parent
    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "今天"
        case .pictures: return "图画"
        case .songs: return "儿歌"
        case .parent: return "家长"
        }
    }

    var icon: String {
        switch self {
        case .today: return "sun.max.fill"
        case .pictures: return "photo.on.rectangle.angled"
        case .songs: return "music.note"
        case .parent: return "lock.fill"
        }
    }
}

struct ContentView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: AppTab = .today

    var body: some View {
        ZStack {
            ZStack {
                LearnWordsView()
                    .opacity(tab == .today ? 1 : 0)
                    .allowsHitTesting(tab == .today)
                    .accessibilityHidden(tab != .today)
                Age4PicturesView()
                    .opacity(tab == .pictures ? 1 : 0)
                    .allowsHitTesting(tab == .pictures)
                    .accessibilityHidden(tab != .pictures)
                NavigationStack {
                    SongsView(childMode: true)
                }
                .opacity(tab == .songs ? 1 : 0)
                .allowsHitTesting(tab == .songs)
                .accessibilityHidden(tab != .songs)
                ParentRootView()
                    .opacity(tab == .parent ? 1 : 0)
                    .allowsHitTesting(tab == .parent)
                    .accessibilityHidden(tab != .parent)
            }
            .animation(Motion.spring, value: tab)

            if store.timeUp {
                TimeUpOverlay()
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(Motion.spring, value: store.timeUp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !store.timeUp {
                KidTabBar(tab: $tab)
            }
        }
        .onAppear { store.setForeground(scenePhase == .active) }
        .onChange(of: scenePhase) { _, phase in
            store.setForeground(phase == .active)
        }
    }
}

struct KidTabBar: View {
    @Binding var tab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { item in
                Button {
                    withAnimation(Motion.spring) { tab = item }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(tab == item ? Color.white : Color.gray)
                            .frame(width: 52, height: 34)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(tab == item ? Color.orange : Color.gray.opacity(0.12))
                            )
                        Text(item.title)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(tab == item ? Color.orange : Color.gray)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PressableStyle())
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 22, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 22)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

/// 到时间锁定遮罩
struct TimeUpOverlay: View {
    @Environment(DataStore.self) private var store
    @State private var showParentUnlock = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("🌙").font(.system(size: 80))
                Text("今天学得够多啦！")
                    .font(.title.bold())
                    .foregroundColor(AppTheme.navy)
                Text("休息一下，保护眼睛，明天再来玩吧")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button("家长解锁") { showParentUnlock = true }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
            }
            .padding(40)
            .background(Color.white)
            .cornerRadius(24)
            .padding()
        }
        .sheet(isPresented: $showParentUnlock) {
            ParentUnlockView(onUnlock: { store.grantExtraTime() })
        }
    }
}
