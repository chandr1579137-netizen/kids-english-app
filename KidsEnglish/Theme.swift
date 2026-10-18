import SwiftUI
import UIKit

// MARK: - 风格契约 · Playful Dopamine / 儿童糖果
//
// 档位：StyleKit expressive · dopamine-design + kawaii-minimal
// 在这个档位下「多彩」是要求，不是缺陷；缺陷是「多彩但没有规则」。
//
// REQUIRED（不做到就不算复刻成功）
//   · 大圆角：卡片 20–24，按钮 20–28，缩略图 16
//   · 超粗标题：中文标题 48–52pt / .heavy
//   · 满饱和分类色作卡片底
//   · 按钮糖果厚度：顶部亮边 + 底部暗边（candyEdge）
//   · 5 tab 常驻底栏
//
// FORBIDDEN（做到即判偏离）
//   · 分类色用作文字色、按钮色、描边色 —— 只允许作卡片底
//   · 渐变用于分类卡 —— 只有首页计划卡、「我的」用户卡允许
//   · 阴影用于普通列表行
//   · 小圆角（<16）出现在卡片或按钮上
//
// 可读性硬约束：任何「色底 + 文字」组合必须 ≥ 4.5:1。
// 由 onFill(_:) 自动在白字/深字间选更优者保证，见 contrastRatio()。
// 实测：17 个分类色中 16 个用深字（6.09–11.51:1），紫色用白字（4.66:1）。

// MARK: - 中性阶梯 6 阶

enum Palette {
    /// 页面底：暖白（dopamine 档位允许暖白，儿童 App 温暖感有内容理由）
    static let canvas = Color(red: 1.00, green: 0.97, blue: 0.94)
    /// 首页 / 学习页 / 读短文 / 我的 共用暖米色背景（参考图 #FEF6F2 / #FCF7E9 / #FCF3FF / #FCF5EA）
    static let canvasWarm = Color(red: 0.996, green: 0.965, blue: 0.949)
    /// 单词卡页背景（参考图浅灰 #F3F5F7）
    static let canvasCool = Color(red: 0.953, green: 0.961, blue: 0.969)
    /// 巩固练习页背景（参考图浅蓝 #EAF4FE）
    static let canvasBlue = Color(red: 0.918, green: 0.957, blue: 0.996)
    /// 卡片表面
    static let surface = Color.white
    /// 主文字：深蓝（比纯黑柔和，与分类色同屏不刺眼）
    static let ink = Color(red: 0.10, green: 0.14, blue: 0.47)
    /// 色底上的文字：近黑（压在饱和色上比 navy 更清晰）
    static let inkOnColor = Color(red: 0.10, green: 0.10, blue: 0.14)
    /// 副标题、标签 —— 5.2:1（原来的 .gray 只有 3.5:1）
    static let inkMuted = Color(red: 0.42, green: 0.42, blue: 0.45)
    /// 仅禁用态 / 大字号
    static let inkSubtle = Color(red: 0.60, green: 0.60, blue: 0.63)
    /// 描边、分隔线
    static let hairline = Color(red: 0.91, green: 0.87, blue: 0.80)
}

// MARK: - 功能色（职责唯一，不抢分类色）

enum Func {
    /// 品牌 / tab 选中 / 当前分级 / 关键数据 —— 小面积，配深字
    static let accent = Color(red: 1.00, green: 0.58, blue: 0.00)
    /// 正向语义：主 CTA / 认识 / 完成 —— 小面积配深字
    static let positive = Color(red: 0.30, green: 0.66, blue: 0.33)
    /// 负向语义：不认识 / 错误 / 锁定
    static let negative = Color(red: 0.87, green: 0.32, blue: 0.28)
    /// 信息 / 英文内容 / 链接
    static let info = Color(red: 0.17, green: 0.47, blue: 0.93)

    // 实底按钮专用深版：全部满足白字 ≥ 4.6:1（亮版只有 2.5–3.8:1，不可用于白字）
    static let positiveDeep = Color(red: 0.08, green: 0.54, blue: 0.09)  // 白字 4.60:1
    static let negativeDeep = Color(red: 0.87, green: 0.20, blue: 0.13)  // 白字 4.60:1
    static let infoDeep = Color(red: 0.14, green: 0.44, blue: 0.90)      // 白字 4.60:1
    static let accentDeep = Color(red: 0.72, green: 0.36, blue: 0.05)    // 白底上 4.61:1

    // 图标与大字数字专用：只服务「≥18.66pt 粗体」的大字号与图形，
    // 按 WCAG 大字号/非文本 3:1 判定。比 Deep 版更鲜亮，不会发棕。
    static let accentVivid = Color(red: 0.85, green: 0.42, blue: 0.00)   // 3.47:1
    /// 等级胶囊等「橙底白字」场景：比 accent 深一档，白字 3.2:1
    static let accentPill = Color(red: 0.90, green: 0.45, blue: 0.00)
    /// 大字号中文释义专用：比 accentVivid 更亮，42pt heavy 属大字号，3:1 达标
    static let accentBright = Color(red: 0.95, green: 0.45, blue: 0.00)
    /// 主 CTA 专用亮绿：只服务 32pt 大字号白字（3.5:1）
    /// 17pt 的「认识」按钮仍用 positiveDeep，不能换这个
    static let ctaGreen = Color(red: 0.10, green: 0.62, blue: 0.18)
    static let positiveVivid = Color(red: 0.18, green: 0.56, blue: 0.22) // 4.13:1
    static let infoVivid = Color(red: 0.14, green: 0.44, blue: 0.90)     // 4.63:1
}

// MARK: - 对比度计算（让可读性成为可校验的规则，而不是靠眼看）

/// WCAG 相对亮度
private func relativeLuminance(_ color: Color) -> Double {
    let ui = UIColor(color)
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    ui.getRed(&r, green: &g, blue: &b, alpha: &a)
    func lin(_ c: CGFloat) -> Double {
        let v = Double(c)
        return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
}

/// WCAG 对比度比值
func contrastRatio(_ a: Color, _ b: Color) -> Double {
    let la = relativeLuminance(a), lb = relativeLuminance(b)
    let hi = max(la, lb), lo = min(la, lb)
    return (hi + 0.05) / (lo + 0.05)
}

/// 给定底色，自动选出更可读的文字色（白 or 近黑）
func onFill(_ background: Color) -> Color {
    let onWhite = contrastRatio(background, .white)
    let onInk = contrastRatio(background, Palette.inkOnColor)
    return onWhite > onInk ? .white : Palette.inkOnColor
}

// MARK: - App 主题（17 个分类色，保留概念设计图原始色值）

enum AppTheme {
    /// 暖米色背景（整 App 统一）
    static let bgCream = Palette.canvas
    /// 标题深蓝
    static let navy = Palette.ink
    /// 亮蓝（英文单词 / 全部单词卡）
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
    /// 今日计划卡的底色基准（渐变左端）
    /// 参考图是满饱和橙 + 白字。为了白字能站住，起点比参考图略深一档
    /// （#E06A00，白字 3.37:1，达大字 3:1 要求），色相不变
    static let planBase = Color(red: 0.878, green: 0.416, blue: 0.0)
    /// 今日计划卡片橙色渐变（分类卡禁用渐变，只有这里允许）
    static let planGradient = LinearGradient(
        colors: [planBase, Color(red: 0.961, green: 0.608, blue: 0.078)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    /// 「我的」用户卡紫色渐变（语义绑定：个人 / 成就）—— 两端对白字均 ≥ 4.7:1
    static let profileGradient = LinearGradient(
        colors: [Color(red: 0.55, green: 0.33, blue: 0.85), Color(red: 0.38, green: 0.28, blue: 0.75)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    /// 主题卡片配色（按主题 id）—— 色值不动，这是复刻基准
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

    /// 主题卡上的文字色 —— 自动选白/深字，保证 ≥ 4.5:1
    static func onColorForTheme(_ themeId: String) -> Color {
        onFill(colorForTheme(themeId))
    }

    /// 单词卡网格用的柔和渐变底（参考图是渐变，不是单色）
    /// 左上一个饱和度高一点的起点，右下一个更浅的终点，文字压在浅色区
    static func gradientForTheme(_ themeId: String) -> LinearGradient {
        let base = colorForTheme(themeId)
        return LinearGradient(
            colors: [base.opacity(0.95), base.opacity(0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - 选词书四色（参考图：满饱和 + 白字）
    // 比分类粉彩色深一档，白字才站得住；色相与参考图一致
    static let bookBlue = Color(red: 0.12, green: 0.48, blue: 0.94)    // 全部单词
    static let bookPink = Color(red: 0.91, green: 0.36, blue: 0.49)    // 水果篇
    static let bookGreen = Color(red: 0.24, green: 0.62, blue: 0.26)   // 动物篇
    static let bookPurple = Color(red: 0.56, green: 0.42, blue: 0.85)  // 交通工具

    /// 读短文页大标题用的亮蓝（参考图不是深蓝）
}

// MARK: - 圆角阶梯（单一基数派生，禁止散装值）

enum Radius {
    static let thumb: CGFloat = 16      // 缩略图
    static let card: CGFloat = 20       // 分类卡 / 判定按钮
    static let sheet: CGFloat = 24      // 内容卡 / 计划卡
    static let pill: CGFloat = 26       // 次按钮
    static let pillLarge: CGFloat = 28  // 主按钮
    static let chip: CGFloat = 22       // 幽灵按钮 / 分级 chip
}

// MARK: - 糖果厚度（用描边模拟，不用阴影）

extension View {
    /// 顶部亮边 + 底部暗边 —— 让按钮读起来「可按」，但不引入阴影
    func candyEdge(_ radius: CGFloat, light: Double = 0.35, dark: Double = 0.12) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: radius)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(light), Color.black.opacity(dark)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
        )
    }
}

// MARK: - 按钮阶梯（4 个层级，共享几何，主次分明）

enum AppButtonTier {
    case primary        // 主 CTA：开始学习
    case secondary      // 次操作：巩固练习
    case ghost          // 导航：上一个 / 下一个
    case judgePositive  // 判定：认识
    case judgeNegative  // 判定：不认识

    var height: CGFloat {
        switch self {
        case .primary: return 56
        case .secondary: return 52
        case .ghost: return 44
        case .judgePositive, .judgeNegative: return 64
        }
    }

    var radius: CGFloat {
        switch self {
        case .primary: return Radius.pillLarge
        case .secondary: return Radius.pill
        case .ghost: return Radius.chip
        case .judgePositive, .judgeNegative: return Radius.card
        }
    }

    var background: Color {
        switch self {
        case .primary: return Func.positiveDeep
        case .secondary: return Func.info.opacity(0.28)
        case .ghost: return .clear
        case .judgePositive: return Func.positiveDeep
        case .judgeNegative: return Func.negativeDeep
        }
    }

    var foreground: Color {
        switch self {
        case .primary, .judgePositive, .judgeNegative: return .white
        case .secondary: return Palette.ink
        case .ghost: return Palette.inkMuted
        }
    }

    var needsCandyEdge: Bool {
        switch self {
        case .primary, .judgePositive, .judgeNegative: return true
        case .secondary, .ghost: return false
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .judgePositive, .judgeNegative: return 22
        default: return 20
        }
    }

    /// 图标比文字略小，视觉重心才不会被图标抢走
    var iconSize: CGFloat {
        switch self {
        case .judgePositive, .judgeNegative: return 22
        case .ghost: return 15
        default: return 18
        }
    }
}

struct AppButton: View {
    let title: String
    /// 只接受 SF Symbol 名 —— 不要传 emoji：模拟器里部分 emoji 会渲染成黑块
    var icon: String? = nil
    var tier: AppButtonTier = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .kidFont(tier.iconSize, .bold)
                        .symbolRenderingMode(.monochrome)
                }
                Text(title)
                    .kidFont(tier.fontSize, .heavy)
            }
            .foregroundStyle(tier.foreground)
            .frame(maxWidth: .infinity)
            .frame(height: tier.height)
            .background(tier.background, in: RoundedRectangle(cornerRadius: tier.radius))
            .overlay {
                RoundedRectangle(cornerRadius: tier.radius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.35), Color.black.opacity(0.12)],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: tier.needsCandyEdge ? 1.5 : 0
                    )
            }
        }
        .buttonStyle(PressableStyle())
    }
}

/// 按下 = 压缩感（X-03），不是放大；同时轻微变暗，不用位移
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - 兼容层（旧组件名保留，内部改走新令牌，避免其余文件一次性全改）

/// 白色圆角卡片 —— 阴影收敛为 elevationGround
struct CardView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.sheet))
            .elevationGround()
    }
}

/// 大胶囊按钮（旧名，走 primary）
struct BigButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    var body: some View {
        AppButton(title: title, tier: .primary, action: action)
    }
}

/// 胶囊小按钮（旧名，走 secondary）
struct PillButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    var body: some View {
        AppButton(title: title, tier: .secondary, action: action)
    }
}

// MARK: - 阴影两族（深度只解释层级，不做装饰）

extension View {
    /// 贴地阴影：列表卡、分类卡
    func elevationGround() -> some View {
        shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    /// 抬升阴影：只给首页计划卡、「我的」用户卡、弹层
    func elevationRaised() -> some View {
        shadow(color: .black.opacity(0.10), radius: 14, y: 6)
    }

    /// 暖米色页面背景（首页/学习页/读短文/我的）
    func creamBackground() -> some View {
        background(Palette.canvasWarm.ignoresSafeArea())
    }

    /// 单词卡页背景（浅灰）
    func coolBackground() -> some View {
        background(Palette.canvasCool.ignoresSafeArea())
    }

    /// 巩固练习页背景（浅蓝）
    func blueBackground() -> some View {
        background(Palette.canvasBlue.ignoresSafeArea())
    }

    /// 固定高度的图片容器。
    /// 直接给图片 `.frame(height:)` 只约束高度，宽度会由图片自己决定，
    /// 放在 ScrollView 里就会撑破父级、被居中裁掉 —— 页边距等于没加。
    /// 这里用 Rectangle 当宽度权威：宽度严格等于父级提案，图片画在上层再裁切。
    func imageFrame(height: CGFloat, corner: CGFloat) -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: height)
            .overlay { self }
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }

    /// 标准白卡：贴地阴影 + 统一圆角
    func whiteCard() -> some View {
        background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.sheet))
            .elevationGround()
    }

    /// 页面大标题骨架（参考图为 61pt 超粗）
    func pageTitleStyle() -> some View {
        font(.system(size: 60, weight: .heavy))
            .foregroundStyle(Palette.ink)
    }

    /// 页面副标题骨架
    func pageSubtitleStyle() -> some View {
        font(.system(size: 21, weight: .medium))
            .foregroundStyle(Palette.inkMuted)
    }

    /// 二级页大标题：比 tab 页的 60pt 小一档，返回键、标题、内容能同屏
    func subPageTitleStyle() -> some View {
        font(.system(size: 32, weight: .heavy))
            .foregroundStyle(Palette.ink)
    }

    /// 二级页副标题
    func subPageSubtitleStyle() -> some View {
        font(.system(size: 16, weight: .medium))
            .foregroundStyle(Palette.inkMuted)
    }
}

// MARK: - UI 图标加载（Resources/ui-icons/）

/// 从 Resources/ui-icons 加载图标。
/// 该目录是「文件夹引用」（blue folder），文件落在 <bundle>/ui-icons/<name>.png，
/// 用 Image("ui-icons/x") 解析不到 —— 必须按路径读。
/// 三级兜底 + 可见占位：失败时显示问号方块，避免静默空白（这次就是靠截图才发现的）。
func uiIcon(_ name: String) -> Image {
    if let path = Bundle.main.path(forResource: name, ofType: "png", inDirectory: "ui-icons"),
       let ui = UIImage(contentsOfFile: path) {
        return Image(uiImage: ui)
    }
    if let ui = UIImage(named: "ui-icons/\(name)") ?? UIImage(named: name) {
        return Image(uiImage: ui)
    }
    return Image(systemName: "questionmark.square.dashed")
}

/// 二级页统一顶栏：自绘「‹ 返回」。
/// 系统导航栏在中文 App 里会露出英文 "Back"，所以主流程一律自绘。
struct SubPageHeader: View {
    var backTitle: String = "返回"
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .kidFont(17, .bold)
                    Text(backTitle)
                        .kidFont(17, .semibold)
                }
                .foregroundStyle(Func.infoDeep)
                .frame(height: 40)
            }
            .buttonStyle(PressableStyle())
            Spacer(minLength: 0)
        }
        .padding(.horizontal)
    }
}

/// 主题 id 到图标名的映射。
/// time / functions 两个主题已从低龄词表移除，对应分支一并删掉，
/// 避免留下永远走不到的死映射。
func themeIconName(for themeId: String) -> String {
    switch themeId {
    case "fruits": return "theme-apple"
    case "animals": return "theme-cat"
    case "vehicles": return "theme-car"
    case "colors": return "theme-palette"
    case "numbers": return "theme-abacus"
    case "body": return "theme-hand"
    case "foods": return "theme-burger"
    case "family": return "theme-family"
    case "stationery": return "theme-stationery"
    case "toys": return "theme-teddy"
    case "nature": return "theme-tree"
    case "home": return "theme-house"
    case "places": return "theme-pin"
    case "actions": return "theme-runner"
    case "adjectives": return "theme-sparkles"
    default: return "theme-dots"
    }
}


// MARK: - 字号：跟随「设置 · 显示与亮度 · 文字大小」，但有上限
//
// 全站原本是 .font(.system(size:)) 硬编码字号，系统放大字号完全不生效。
// 现在统一走 kidFont(...)：基础字号不变，按 Dynamic Type 档位等比例放大，
// 最多 1.35 倍 —— 再大，糖果卡片的圆角、两列网格、底栏高度都会挤坏。
// 目标用户是 4–6 岁，宁可放大有限，也不能让按钮错位。

enum KidTextScale {
    /// 上限：约等于系统「辅助功能 · 大」档位的放大率
    static let maximum: CGFloat = 1.35

    static func factor(for size: DynamicTypeSize) -> CGFloat {
        let raw: CGFloat
        switch size {
        case .xSmall: raw = 0.88
        case .small: raw = 0.94
        case .medium: raw = 0.97
        case .large: raw = 1.00
        case .xLarge: raw = 1.06
        case .xxLarge: raw = 1.12
        case .xxxLarge: raw = 1.20
        case .accessibility1: raw = 1.28
        default: raw = maximum
        }
        return min(maximum, raw)
    }
}

private struct KidFontModifier: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    /// 该处的放大上限：窄卡片里的标签不能跟到全局 1.35，否则 4 个字会被截成「身…」
    let maxScale: CGFloat
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        let factor = min(maxScale, KidTextScale.factor(for: dynamicTypeSize))
        let scaled = size * factor
        return content.font(.system(size: scaled, weight: weight, design: design))
    }
}

extension View {
    /// 替代 `.font(.system(size:weight:design:))`：基础字号不变，但跟随系统文字大小。
    func kidFont(_ size: CGFloat,
                 _ weight: Font.Weight = .regular,
                 maxScale: CGFloat = KidTextScale.maximum,
                 design: Font.Design = .default) -> some View {
        modifier(KidFontModifier(size: size, weight: weight, design: design, maxScale: maxScale))
    }
}

// MARK: - 版心宽度（iPad）

enum KidLayout {
    /// iPad 上内容列的最大宽度。iPhone（≈390pt）不会触发。
    /// 直接全屏铺开时两列卡片会长到 500pt、课文行长超过 120 字符，反而更难读。
    static let readableWidth: CGFloat = 720
}


// MARK: - 面向孩子的提示卡片
//
// 系统 Alert 的按钮、字号、圆角完全由系统控制，和 App 的糖果风格不搭；
// 而且全站字号封顶 1.35 后，系统弹窗在超大字号下会突然比全站大一圈。
// 孩子看得到的提示统一用这个卡片；家长侧（清空进度确认）保留系统弹窗。
struct KidAlert: View {
    let emoji: String
    let title: String
    let message: String
    let primaryTitle: String
    let primaryAction: () -> Void
    var secondaryTitle: String? = nil
    var secondaryAction: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture { }

            VStack(spacing: 14) {
                Text(emoji).kidFont(52, maxScale: 1.1)

                Text(title)
                    .kidFont(24, .heavy)
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.center)

                Text(message)
                    .kidFont(17, .medium)
                    .foregroundStyle(Palette.inkMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    AppButton(title: primaryTitle, tier: .primary, action: primaryAction)
                    if let secondaryTitle, let secondaryAction {
                        AppButton(title: secondaryTitle, tier: .secondary, action: secondaryAction)
                    }
                }
                .padding(.top, 4)
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(Palette.surface,
                        in: RoundedRectangle(cornerRadius: Radius.sheet, style: .continuous))
            .elevationRaised()
            .padding(24)
        }
    }
}


// MARK: - 家长侧确认卡片
//
// 系统 confirmationDialog 的按钮/字号/圆角全由系统决定，超大字号下会脱离
// 全站节奏，也和「清空进度」这种危险操作的视觉分量不匹配。
// 孩子看得到的提示用 KidAlert；家长侧的确认用这个更克制的卡片。
struct ConfirmCard: View {
    let emoji: String
    let title: String
    let message: String
    let confirmTitle: String
    var destructive: Bool = false
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Text(emoji).kidFont(30, maxScale: 1.1)
                    Text(title)
                        .kidFont(20, .heavy)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(message)
                    .kidFont(15, .medium)
                    .foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Button(action: onCancel) {
                        Text("取消")
                            .kidFont(17, .bold)
                            .foregroundStyle(Palette.ink)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 46)
                            .background(Palette.canvas,
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    Button(action: onConfirm) {
                        Text(confirmTitle)
                            .kidFont(17, .bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 46)
                            .background(destructive ? Func.negativeDeep : Func.positiveDeep,
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.top, 6)
            }
            .padding(20)
            .frame(maxWidth: 340)
            .background(Palette.surface,
                        in: RoundedRectangle(cornerRadius: Radius.sheet, style: .continuous))
            .elevationRaised()
            .padding(24)
        }
    }
}
