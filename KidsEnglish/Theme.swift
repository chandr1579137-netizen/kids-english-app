import SwiftUI

// MARK: - App 主题（按 7 张概念设计图提取）

/// 全局配色
enum AppTheme {
    /// 暖米色背景（整 App 统一）
    static let bgCream = Color(red: 1.0, green: 0.97, blue: 0.90)
    /// 标题深蓝
    static let navy = Color(red: 0.10, green: 0.14, blue: 0.49)
    /// 亮蓝（英文单词 / 正常按钮 / 全部单词卡）
    static let brightBlue = Color(red: 0.17, green: 0.5, blue: 1.0)
    /// 粉红（水果篇）
    static let pink = Color(red: 1.0, green: 0.71, blue: 0.76)
    /// 绿色（动物篇 / 开始学习 / 认识 / 慢速）
    static let green = Color(red: 0.3, green: 0.69, blue: 0.31)
    /// 紫色（交通工具）
    static let purple = Color(red: 0.61, green: 0.35, blue: 0.71)
    /// 红色（不认识）
    static let red = Color(red: 0.91, green: 0.3, blue: 0.24)
    /// 灰色（上一个/下一个）
    static let grayBtn = Color(red: 0.74, green: 0.74, blue: 0.74)
    /// 中文释义橙色
    static let wordOrange = Color.orange
    /// 今日计划卡片橙色渐变
    static let planGradient = LinearGradient(
        colors: [Color.orange, Color(red: 1.0, green: 0.72, blue: 0.1)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    /// 主题卡片配色（按主题 id 轮换）
    static func colorForTheme(_ themeId: String) -> Color {
        switch themeId {
        case "fruits": return pink
        case "animals": return green
        case "vehicles": return purple
        case "colors": return brightBlue
        case "numbers": return Color(red: 1.0, green: 0.8, blue: 0.2)
        case "body": return Color(red: 1.0, green: 0.6, blue: 0.4)
        case "foods": return Color(red: 1.0, green: 0.55, blue: 0.35)
        case "family": return Color(red: 0.4, green: 0.7, blue: 1.0)
        case "nature": return Color(red: 0.35, green: 0.75, blue: 0.5)
        case "time": return Color(red: 0.55, green: 0.5, blue: 0.9)
        case "stationery": return Color(red: 0.45, green: 0.65, blue: 1.0)
        case "toys": return Color(red: 1.0, green: 0.65, blue: 0.55)
        case "home": return Color(red: 0.65, green: 0.55, blue: 0.85)
        case "places": return Color(red: 0.4, green: 0.8, blue: 0.75)
        case "actions": return Color(red: 1.0, green: 0.7, blue: 0.3)
        case "adjectives": return Color(red: 0.75, green: 0.55, blue: 1.0)
        case "functions": return Color(red: 0.5, green: 0.6, blue: 0.7)
        default: return brightBlue
        }
    }
}

// MARK: - 通用组件

/// 白色圆角卡片
struct CardView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
}

/// 大胶囊按钮
struct BigButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(color)
                .cornerRadius(30)
                .shadow(color: color.opacity(0.35), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

/// 胶囊小按钮（如发音按钮）
struct PillButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(color)
                .cornerRadius(25)
                .shadow(color: color.opacity(0.3), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - View 扩展

extension View {
    /// 暖米色页面背景（整 App 统一用）
    func creamBackground() -> some View {
        self.background(AppTheme.bgCream.ignoresSafeArea())
    }

    /// 标准白卡样式
    func whiteCard() -> some View {
        self
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
}
