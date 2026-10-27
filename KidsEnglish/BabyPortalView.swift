import SwiftUI

/// 启蒙乐园（将启蒙模式与自然拼读提拔为一级入口，彻底替代儿歌）
struct BabyPortalView: View {
    @Environment(DataStore.self) private var store

    var body: some View {
        KidScrollView {
            VStack(spacing: 20) {
                header

                // 核心卡片 1：自然拼读探索岛
                NavigationLink {
                    PhonicsIslandView()
                } label: {
                    portalCard(
                        title: "自然拼读探索岛",
                        subtitle: "字母音岛屿 · 拼读启蒙",
                        tag: "核心拼读",
                        color: Color(red: 0.98, green: 0.52, blue: 0.08),
                        accentColor: Color(red: 1.0, green: 0.72, blue: 0.2),
                        icon: "sparkles",
                        emoji: "🏝️"
                    )
                }
                .buttonStyle(PressableStyle())

                // 核心卡片 2：CVC 滑音小火车
                NavigationLink {
                    PhonicsBlendingTrainView()
                } label: {
                    portalCard(
                        title: "CVC 滑音小火车",
                        subtitle: "双组 7 词 · 12 字母车厢挑战",
                        tag: "互动拼读",
                        color: Color(red: 0.38, green: 0.42, blue: 0.88),
                        accentColor: Color(red: 0.60, green: 0.65, blue: 1.0),
                        icon: "tram.fill",
                        emoji: "🚂"
                    )
                }
                .buttonStyle(PressableStyle())

                // 核心卡片 3：宝宝启蒙图画馆
                NavigationLink {
                    BabyPicturesView()
                } label: {
                    portalCard(
                        title: "宝宝启蒙图画馆",
                        subtitle: "高频生活主题 · 纯正母语认知",
                        tag: "认知扩展",
                        color: Color(red: 0.22, green: 0.68, blue: 0.45),
                        accentColor: Color(red: 0.45, green: 0.85, blue: 0.65),
                        icon: "photo.on.rectangle.angled",
                        emoji: "🎨"
                    )
                }
                .buttonStyle(PressableStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .creamBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("启蒙乐园")
                        .kidFont(30, .heavy)
                        .foregroundStyle(Palette.ink)
                    Text("🌟")
                        .kidFont(24)
                }
                Text("听音 · 辨形 · 滑音拼读 · 快乐启蒙")
                    .kidFont(14, .bold)
                    .foregroundStyle(Palette.inkMuted)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func portalCard(title: String,
                            subtitle: String,
                            tag: String,
                            color: Color,
                            accentColor: Color,
                            icon: String,
                            emoji: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(tag)
                        .kidFont(12, .heavy)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.18), in: Capsule())
                }

                Text(title)
                    .kidFont(22, .heavy)
                    .foregroundStyle(.white)

                Text(subtitle)
                    .kidFont(13, .bold)
                    .foregroundStyle(.white.opacity(0.92))
            }

            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 72, height: 72)
                Text(emoji)
                    .kidFont(38)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, minHeight: 125)
        .background(
            LinearGradient(
                colors: [color, color.opacity(0.85), accentColor.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}
