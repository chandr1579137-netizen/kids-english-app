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

struct ContentView: View {
    @Environment(DataStore.self) private var store

    var body: some View {
        ZStack {
            TabView {
                MapView()
                    .tabItem { Label("学地图", systemImage: "map.fill") }
                WordsView()
                    .tabItem { Label("单词", systemImage: "text.book.closed.fill") }
                SongsView()
                    .tabItem { Label("儿歌", systemImage: "music.note") }
                ParentGateView()
                    .tabItem { Label("家长", systemImage: "person.fill") }
            }
            .tint(.orange)

            if store.timeUp {
                TimeUpOverlay()
            }
        }
    }
}

/// 到时间锁定遮罩
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
                    .foregroundColor(.white)
                Text("休息一下，保护眼睛，明天再来玩吧")
                    .foregroundColor(.white.opacity(0.85))
                Button("家长解锁") { showParentUnlock = true }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
            }
            .padding(40)
            .background(Color(.systemBackground))
            .cornerRadius(24)
            .padding()
        }
        .sheet(isPresented: $showParentUnlock) {
            ParentUnlockView(onUnlock: { store.resetTimeUp() })
        }
    }
}
