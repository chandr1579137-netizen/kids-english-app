import SwiftUI

// MARK: - 「说一说」L3 起代码画的卡片：钟表 / 一周 / 月历 / 12 个月 / 四格 / 日子条 / 一排小图 / 蜡笔盒
//
// 参数见 Phrases.swift 的 PhraseCodeParams，数据由 scripts/phrase_code_specs.py 生成。
// 图里不写字、不写数字，太阳和月亮都没有脸；问句用「闪」「轮流亮」「指针转」表示。
// 截图时动画停在最能看懂的那一帧（高亮的格亮着，轮流亮停在第一格）。

struct PhraseTimeCard: View {
    let kind: String
    let params: PhraseCodeParams
    let icon: String?
    let side: CGFloat

    /// 闪、整张卡轻轻闪
    @State private var blinkOn = true
    /// 指针转到位
    @State private var spun = false
    /// 一排小图点亮了几个
    @State private var lit = 0

    private var still: Bool { LaunchOptions.isUIScreenshotRun }

    var body: some View {
        ZStack {
            PhraseColors.paper
            content
        }
        .frame(width: side, height: side)
        .scaleEffect(params.pulse == true && !blinkOn ? 0.96 : 1.0)
        .onAppear(perform: start)
    }

    @ViewBuilder
    private var content: some View {
        switch kind {
        case "clock": clockCard
        case "week": weekCard
        case "calendar": calendarCard
        case "months": monthsCard
        case "quad": quadCard
        case "days": daysCard
        case "row": rowCard
        default: crayonsCard
        }
    }

    private func start() {
        if still {
            spun = true
            lit = params.count ?? 0
            return
        }
        withAnimation(.easeOut(duration: 1.4)) { spun = true }
        if params.blink != nil || params.pulse == true || params.bold != nil {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { blinkOn = false }
        }
        if let n = params.count {
            for i in 1...max(n, 1) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i - 1) * 0.4) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { lit = i }
                }
            }
        }
    }

    // MARK: 格子状态

    private func has(_ list: [Int]?, _ i: Int) -> Bool { list?.contains(i) == true }

    /// 轮流亮：每 0.8 秒换一格；截图停在第一格
    private func cycleIndex(_ date: Date, count: Int) -> Int {
        guard !still, count > 0 else { return 0 }
        return Int(date.timeIntervalSinceReferenceDate / 0.8) % count
    }

    private func highlighted(_ i: Int, cycle: Int?) -> Bool {
        has(params.glow, i) || (has(params.blink, i) && blinkOn) || cycle == i
    }

    // MARK: - 钟表

    private var clockCard: some View {
        let main = PhraseClock.parse(params.time ?? "") ?? (hour: 12, minute: 0)
        let accessory = params.cross != nil || params.pair != nil || icon != nil
            || params.sun == true || params.weekend == true
        let size = side * (params.pair != nil ? 0.44 : (accessory ? 0.6 : 0.7))
        return ZStack {
            if let pair = params.pair.flatMap(PhraseClock.parse) {
                HStack(spacing: side * 0.06) {
                    clockFace(main, size: size, faded: false)
                    clockFace(pair, size: size, faded: false, diffFrom: main)
                }
            } else {
                clockFace(main, size: size, faded: false)
                    .offset(x: accessory ? -side * 0.1 : 0, y: accessory ? -side * 0.06 : 0)
                if let cross = params.cross.flatMap(PhraseClock.parse) {
                    crossedClock(cross).position(x: side * 0.8, y: side * 0.76)
                }
                if params.sun == true {
                    PhraseSun(size: side * 0.18).position(x: side * 0.82, y: side * 0.2)
                }
                if params.weekend == true {
                    HStack(spacing: side * 0.015) {
                        weekTile(["play"], index: 5, width: side * 0.11, cycle: nil, forceGlow: true)
                        weekTile(["play"], index: 6, width: side * 0.11, cycle: nil, forceGlow: true)
                    }
                    .position(x: side * 0.24, y: side * 0.84)
                }
                if let icon {
                    PhraseIconTile(word: icon, size: side * 0.3).position(x: side * 0.78, y: side * 0.76)
                }
            }
        }
    }

    private func clockFace(_ t: (hour: Int, minute: Int), size: CGFloat, faded: Bool,
                           diffFrom: (hour: Int, minute: Int)? = nil) -> some View {
        let a = PhraseClock.angles(hour: t.hour, minute: t.minute)
        let face = params.face ?? "plain"
        return ZStack {
            if face == "wall" { pendulum(size: size) }
            if face == "watch" { strap(size: size) }
            Circle()
                .fill(Color.white)
                .overlay { Circle().strokeBorder(rimColor(face), lineWidth: size * (face == "plain" ? 0.05 : 0.08)) }
                .frame(width: size, height: size)
            if face == "party" { partyDots(size: size) }
            if let sweep = params.sweep {
                PhraseSector(minutes: sweep)
                    .fill(Func.accent.opacity(params.pulse == true && !blinkOn ? 0.18 : 0.38))
                    .frame(width: size * 0.82, height: size * 0.82)
            }
            if let from = diffFrom {
                // 快了几分钟：两针之间那几小格涂色
                PhraseSector(minutes: t.minute - from.minute, startMinute: from.minute)
                    .fill(Func.accent.opacity(0.45))
                    .frame(width: size * 0.86, height: size * 0.86)
            }
            ticks(size: size)
            if params.hourHand != false {
                hand(length: size * 0.25, width: size * 0.065, angle: a.hour, spinTurns: 1,
                     bold: params.bold == "hour")
            }
            hand(length: size * 0.37, width: size * 0.04, angle: a.minute, spinTurns: 3,
                 bold: params.bold == "minute")
            Circle().fill(PhraseColors.outline).frame(width: size * 0.08, height: size * 0.08)
        }
        .frame(width: size, height: size)
        .opacity(faded ? 0.5 : 1)
    }

    private func rimColor(_ face: String) -> Color {
        switch face {
        case "wall": return Color(red: 0.62, green: 0.42, blue: 0.24)
        case "watch": return Color(red: 0.42, green: 0.45, blue: 0.52)
        case "party": return Color(red: 0.98, green: 0.45, blue: 0.62)
        default: return PhraseColors.outline
        }
    }

    /// 12 个刻度，3/6/9/12 粗一点；不写数字
    private func ticks(size: CGFloat) -> some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                let major = i % 3 == 0
                Capsule()
                    .fill(PhraseColors.outline)
                    .frame(width: size * (major ? 0.035 : 0.02), height: size * (major ? 0.09 : 0.055))
                    .offset(y: -size * 0.36)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
        }
    }

    private func hand(length: CGFloat, width: CGFloat, angle: Double, spinTurns: Double, bold: Bool) -> some View {
        let shown = params.spin == true && !spun ? angle - 360 * spinTurns : angle
        return Capsule()
            .fill(bold && blinkOn ? Func.accent : PhraseColors.outline)
            .frame(width: bold ? width * 1.5 : width, height: length)
            .offset(y: -length / 2)
            .rotationEffect(.degrees(shown))
    }

    private func pendulum(size: CGFloat) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(rimColor("wall")).frame(width: size * 0.03, height: size * 0.32)
            Circle().fill(PhraseColors.sun)
                .overlay { Circle().stroke(PhraseColors.outline, lineWidth: 2) }
                .frame(width: size * 0.16, height: size * 0.16)
        }
        .rotationEffect(.degrees(spun || still ? 0 : 12), anchor: .top)
        .offset(y: size * 0.62)
    }

    private func strap(size: CGFloat) -> some View {
        let color = params.strap == true ? Color(red: 0.98, green: 0.55, blue: 0.3) : Color(red: 0.36, green: 0.6, blue: 0.92)
        return RoundedRectangle(cornerRadius: size * 0.08)
            .fill(color)
            .overlay { RoundedRectangle(cornerRadius: size * 0.08).stroke(PhraseColors.outline, lineWidth: 2) }
            .frame(width: size * 0.5, height: size * 1.55)
    }

    private func partyDots(size: CGFloat) -> some View {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
        return ZStack {
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(colors[i % colors.count])
                    .frame(width: size * 0.07, height: size * 0.07)
                    .offset(y: -size * 0.5 + size * 0.04)
                    .rotationEffect(.degrees(Double(i) * 30 + 15))
            }
        }
    }

    /// 被划掉的小钟（不是这个时间）
    private func crossedClock(_ t: (hour: Int, minute: Int)) -> some View {
        let size = side * 0.3
        let a = PhraseClock.angles(hour: t.hour, minute: t.minute)
        return ZStack {
            Circle().fill(Color.white)
                .overlay { Circle().strokeBorder(PhraseColors.outline, lineWidth: size * 0.05) }
            Capsule().fill(PhraseColors.outline).frame(width: size * 0.07, height: size * 0.25)
                .offset(y: -size * 0.125).rotationEffect(.degrees(a.hour))
            Capsule().fill(PhraseColors.outline).frame(width: size * 0.045, height: size * 0.37)
                .offset(y: -size * 0.185).rotationEffect(.degrees(a.minute))
            Capsule().fill(Color(red: 0.9, green: 0.27, blue: 0.27))
                .frame(width: size * 0.1, height: size * 1.2)
                .rotationEffect(.degrees(45))
        }
        .frame(width: size, height: size)
        .opacity(0.9)
    }

    // MARK: - 一周 7 格

    private var weekCard: some View {
        let slots = params.slots ?? []
        let width = side * 0.118
        return TimelineView(.periodic(from: .now, by: 0.8)) { context in
            let cycle: Int? = params.cycle == true ? cycleIndex(context.date, count: 7) : nil
            VStack(spacing: side * 0.07) {
                HStack(alignment: .center, spacing: side * 0.012) {
                    ForEach(0..<7, id: \.self) { i in
                        weekTile(i < slots.count ? [slots[i]] : [], index: i, width: width, cycle: cycle)
                    }
                }
                if params.arrowBack == true { backArrow }
            }
        }
    }

    private func weekTile(_ slot: [String], index i: Int, width: CGFloat, cycle: Int?,
                          forceGlow: Bool = false) -> some View {
        let on = forceGlow || highlighted(i, cycle: cycle)
        let weekend = i >= 5
        let items = slot.flatMap(PhraseSlot.parse)
        let big = on && items.contains { if case .icon = $0 { return true } else { return false } }
        return ZStack {
            RoundedRectangle(cornerRadius: width * 0.22, style: .continuous)
                .fill(weekend ? Color(red: 1.0, green: 0.93, blue: 0.78) : Color(red: 0.88, green: 0.94, blue: 1.0))
            RoundedRectangle(cornerRadius: width * 0.22, style: .continuous)
                .strokeBorder(on ? Func.accent : PhraseColors.outline.opacity(0.5), lineWidth: on ? 4 : 1.5)
            slotContent(items, size: width * 0.78)
        }
        .frame(width: width, height: width * 1.7)
        .overlay(alignment: .topTrailing) {
            if has(params.star, i) { PhraseStarSticker(size: width * 0.55).offset(x: width * 0.2, y: -width * 0.25) }
        }
        .opacity(has(params.faded, i) ? 0.35 : 1)
        .scaleEffect(big ? 1.35 : (on ? 1.12 : 1))
        .zIndex(on ? 1 : 0)
    }

    // MARK: - 月历

    private var calendarCard: some View {
        calendarPage(width: side * 0.78)
            .overlay(alignment: .topTrailing) {
                if let icon { PhraseIconTile(word: icon, size: side * 0.24).offset(x: side * 0.06, y: -side * 0.08) }
            }
            .opacity(params.pulse == true && !blinkOn ? 0.75 : 1)
    }

    /// 一整页 = 一个月：顶上两个挂环、红色页眉、7×5 空白格子
    fileprivate func calendarPage(width: CGFloat) -> some View {
        let cell = width / 7.6
        return VStack(spacing: 0) {
            ZStack {
                Rectangle().fill(Color(red: 0.92, green: 0.33, blue: 0.3))
                HStack(spacing: width * 0.4) {
                    Capsule().fill(PhraseColors.outline).frame(width: width * 0.04, height: width * 0.12)
                    Capsule().fill(PhraseColors.outline).frame(width: width * 0.04, height: width * 0.12)
                }
                .offset(y: -width * 0.07)
            }
            .frame(height: width * 0.14)
            VStack(spacing: cell * 0.08) {
                ForEach(0..<5, id: \.self) { r in
                    HStack(spacing: cell * 0.08) {
                        ForEach(0..<7, id: \.self) { c in calendarCell(r * 7 + c, size: cell) }
                    }
                }
            }
            .padding(cell * 0.2)
        }
        .frame(width: width)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: width * 0.05))
        .overlay { RoundedRectangle(cornerRadius: width * 0.05).stroke(PhraseColors.outline, lineWidth: 2.5) }
    }

    private func calendarCell(_ i: Int, size: CGFloat) -> some View {
        let blinking = has(params.blink, i)
        return ZStack {
            RoundedRectangle(cornerRadius: size * 0.18)
                .fill(blinking && blinkOn ? Func.accent.opacity(0.55) : Color(red: 0.95, green: 0.95, blue: 0.93))
            if has(params.sticker, i) {
                Circle().fill(Color(red: 0.9, green: 0.27, blue: 0.27)).padding(size * 0.12)
            }
        }
        .frame(width: size, height: size)
        .overlay {
            if has(params.star, i) { PhraseStarSticker(size: size * 1.5) }
        }
        .zIndex(has(params.star, i) ? 1 : 0)
    }

    // MARK: - 12 个月一圈

    private var monthsCard: some View {
        let slots = params.slots ?? []
        let radius = side * 0.36
        let dot = side * 0.14
        return TimelineView(.periodic(from: .now, by: 0.8)) { context in
            let cycle: Int? = params.cycle == true ? cycleIndex(context.date, count: 12) : nil
            ZStack {
                ForEach(0..<12, id: \.self) { i in
                    // 第 12 格在最上面（像钟的 12 点），顺时针一格一个月
                    let angle = Double(i + 1) * 30 * Double.pi / 180
                    monthDot(i, slot: i < slots.count ? slots[i] : "", size: dot, cycle: cycle)
                        .offset(x: CGFloat(sin(angle)) * radius, y: -CGFloat(cos(angle)) * radius)
                }
                if let icon { PhraseIconTile(word: icon, size: side * 0.3) }
            }
        }
    }

    /// 按季节上色：冬蓝、春粉、夏黄、秋橙
    private func seasonColor(month i: Int) -> Color {
        switch i {
        case 11, 0, 1: return Color(red: 0.7, green: 0.85, blue: 1.0)
        case 2, 3, 4: return Color(red: 1.0, green: 0.78, blue: 0.85)
        case 5, 6, 7: return Color(red: 1.0, green: 0.88, blue: 0.45)
        default: return Color(red: 1.0, green: 0.7, blue: 0.45)
        }
    }

    private func monthDot(_ i: Int, slot: String, size: CGFloat, cycle: Int?) -> some View {
        let on = highlighted(i, cycle: cycle)
        let items = PhraseSlot.parse(slot)
        return ZStack {
            Circle().fill(seasonColor(month: i))
            Circle().strokeBorder(on ? Func.accent : PhraseColors.outline.opacity(0.6), lineWidth: on ? 4 : 1.5)
            if !items.isEmpty { slotContent(items, size: size * 0.72) }
        }
        .frame(width: size, height: size)
        .scaleEffect(on ? (items.isEmpty ? 1.25 : 1.6) : 1)
        .zIndex(on ? 1 : 0)
    }

    // MARK: - 四格（四季 / 天气）

    private var quadCard: some View {
        let slots = params.slots ?? []
        let cell = side * 0.38
        return TimelineView(.periodic(from: .now, by: 0.8)) { context in
            let cycle: Int? = params.cycle == true ? cycleIndex(context.date, count: 4) : nil
            ZStack {
                VStack(spacing: side * 0.03) {
                    ForEach(0..<2, id: \.self) { r in
                        HStack(spacing: side * 0.03) {
                            ForEach(0..<2, id: \.self) { c in
                                let i = r * 2 + c
                                quadTile(i, slot: i < slots.count ? slots[i] : "", size: cell, cycle: cycle)
                            }
                        }
                    }
                }
                if params.arrowBack == true {
                    backArrow.scaleEffect(0.8).position(x: side * 0.16, y: side * 0.9)
                }
            }
        }
    }

    private func quadTile(_ i: Int, slot: String, size: CGFloat, cycle: Int?) -> some View {
        let on = highlighted(i, cycle: cycle)
        return ZStack {
            RoundedRectangle(cornerRadius: size * 0.14, style: .continuous).fill(Color.white)
            slotContent(PhraseSlot.parse(slot), size: size * 0.78)
            RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                .strokeBorder(on ? Func.accent : PhraseColors.outline.opacity(0.4), lineWidth: on ? 6 : 1.5)
        }
        .frame(width: size, height: size)
        .opacity(params.glow != nil && !on ? 0.55 : 1)
        .scaleEffect(on ? 1.06 : 1)
        .zIndex(on ? 1 : 0)
    }

    // MARK: - 日子条（今天 → 明天 → 后天）

    private var daysCard: some View {
        let slots = params.slots ?? []
        let n = max(slots.count, 1)
        let tile = side * (n <= 2 ? 0.36 : (n == 3 ? 0.25 : 0.19))
        return HStack(spacing: side * 0.015) {
            ForEach(0..<slots.count, id: \.self) { i in
                if i > 0 {
                    Image(systemName: "arrow.right")
                        .font(.system(size: tile * 0.22, weight: .black))
                        .foregroundStyle(PhraseColors.outline)
                }
                dayTile(i, slot: slots[i], size: tile)
            }
        }
    }

    private func dayTile(_ i: Int, slot: String, size: CGFloat) -> some View {
        let on = highlighted(i, cycle: nil)
        return ZStack {
            RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
                .fill(on ? Color(red: 1.0, green: 0.95, blue: 0.75) : Color.white)
            slotContent(PhraseSlot.parse(slot), size: size * 0.78)
            RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
                .strokeBorder(on ? Func.accent : PhraseColors.outline.opacity(0.45), lineWidth: on ? 5 : 1.5)
        }
        .frame(width: size, height: size * 1.15)
        .scaleEffect(on ? 1.08 : 1)
    }

    // MARK: - 一排小图，逐个点亮（five days）

    private var rowCard: some View {
        let n = params.count ?? 1
        let size = side * min(0.17, 0.86 / CGFloat(n) - 0.02)
        return HStack(spacing: side * 0.02) {
            ForEach(0..<n, id: \.self) { i in
                Group {
                    if let icon { PhraseIconTile(word: icon, size: size) } else { PhraseSun(size: size) }
                }
                .saturation(i < lit ? 1 : 0)
                .opacity(i < lit ? 1 : 0.35)
                .scaleEffect(i < lit ? 1 : 0.85)
            }
        }
    }

    // MARK: - 蜡笔盒（粉色那支弹起来）

    private var crayonsCard: some View {
        let colors: [Color] = [
            Color(red: 0.9, green: 0.25, blue: 0.25), Color(red: 1.0, green: 0.6, blue: 0.2),
            Color(red: 1.0, green: 0.85, blue: 0.2), Color(red: 0.35, green: 0.75, blue: 0.35),
            Color(red: 0.3, green: 0.55, blue: 0.95), Color(red: 1.0, green: 0.55, blue: 0.75),
            Color(red: 0.6, green: 0.4, blue: 0.85), Color(red: 0.55, green: 0.35, blue: 0.2),
        ]
        let w = side * 0.075
        return ZStack {
            HStack(alignment: .bottom, spacing: side * 0.012) {
                ForEach(0..<PhraseCodeCardSpec.crayonCount, id: \.self) { i in
                    let on = highlighted(i, cycle: nil)
                    PhraseCrayon(color: colors[i % colors.count], width: w)
                        .offset(y: on ? -side * (blinkOn || still ? 0.16 : 0.12) : 0)
                        .scaleEffect(on ? 1.15 : 1, anchor: .bottom)
                }
            }
            .offset(y: -side * 0.02)
            // 盒子前脸挡住蜡笔下半截
            RoundedRectangle(cornerRadius: side * 0.03)
                .fill(Color(red: 0.36, green: 0.6, blue: 0.92))
                .overlay { RoundedRectangle(cornerRadius: side * 0.03).stroke(PhraseColors.outline, lineWidth: 2.5) }
                .frame(width: side * 0.8, height: side * 0.3)
                .offset(y: side * 0.2)
        }
        .onAppear {
            guard !still else { return }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { blinkOn = false }
        }
    }

    // MARK: - 零件

    @ViewBuilder
    private func slotContent(_ items: [PhraseSlot], size: CGFloat) -> some View {
        let each = items.count > 1 ? size * 0.6 : size
        HStack(spacing: size * 0.04) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                switch item {
                case .bag:
                    Image(systemName: "backpack.fill")
                        .font(.system(size: each * 0.62, weight: .bold))
                        .foregroundStyle(Color(red: 0.3, green: 0.5, blue: 0.9))
                case .play: PhraseKite(size: each * 0.8)
                case .sun: PhraseSun(size: each * 0.72)
                case .moon: PhraseMoon(size: each * 0.6)
                case .star: PhraseStarSticker(size: each * 0.8)
                case .icon(let word): PhraseIconTile(word: word, size: each)
                }
            }
        }
    }

    /// 向左的「过去」箭头
    private var backArrow: some View {
        ZStack {
            Circle().fill(Color(red: 0.55, green: 0.5, blue: 0.85))
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: side * 0.08, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(width: side * 0.17, height: side * 0.17)
        .overlay { Circle().strokeBorder(Color.white, lineWidth: 3) }
    }
}

// MARK: - 小零件（全是形状，没有字）

/// 长针从 startMinute 走过 minutes 分钟的扇形（从 12 点方向顺时针）
struct PhraseSector: Shape {
    let minutes: Int
    var startMinute = 0

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        var p = Path()
        p.move(to: c)
        p.addArc(center: c, radius: r,
                 startAngle: .degrees(Double(startMinute) * 6 - 90),
                 endAngle: .degrees(Double(startMinute + minutes) * 6 - 90), clockwise: false)
        p.closeSubpath()
        return p
    }
}

struct PhraseSun: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Capsule()
                    .fill(PhraseColors.sun)
                    .overlay { Capsule().stroke(PhraseColors.outline, lineWidth: 1.2) }
                    .frame(width: size * 0.1, height: size * 0.24)
                    .offset(y: -size * 0.46)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            Circle()
                .fill(PhraseColors.sun)
                .overlay { Circle().stroke(PhraseColors.outline, lineWidth: 2) }
                .frame(width: size * 0.62, height: size * 0.62)
        }
        .frame(width: size, height: size)
    }
}

struct PhraseMoon: View {
    let size: CGFloat

    var body: some View {
        Image(systemName: "moon.fill")
            .font(.system(size: size * 0.8))
            .foregroundStyle(PhraseColors.moon)
            .shadow(color: PhraseColors.outline.opacity(0.5), radius: 0.5)
            .frame(width: size, height: size)
    }
}

struct PhraseStarSticker: View {
    let size: CGFloat

    var body: some View {
        Image(systemName: "star.fill")
            .font(.system(size: size * 0.8))
            .foregroundStyle(PhraseColors.gold)
            .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
            .frame(width: size, height: size)
    }
}

/// 菱形风筝 + 一条小尾巴（周末去玩）
struct PhraseKite: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: size * 0.5, y: size * 0.62))
                p.addQuadCurve(to: CGPoint(x: size * 0.62, y: size * 0.98), control: CGPoint(x: size * 0.4, y: size * 0.82))
            }
            .stroke(PhraseColors.outline, lineWidth: 1.5)
            Path { p in
                p.move(to: CGPoint(x: size * 0.5, y: 0))
                p.addLine(to: CGPoint(x: size * 0.82, y: size * 0.3))
                p.addLine(to: CGPoint(x: size * 0.5, y: size * 0.62))
                p.addLine(to: CGPoint(x: size * 0.18, y: size * 0.3))
                p.closeSubpath()
            }
            .fill(Color(red: 0.95, green: 0.4, blue: 0.4))
            .overlay {
                Path { p in
                    p.move(to: CGPoint(x: size * 0.5, y: 0))
                    p.addLine(to: CGPoint(x: size * 0.82, y: size * 0.3))
                    p.addLine(to: CGPoint(x: size * 0.5, y: size * 0.62))
                    p.addLine(to: CGPoint(x: size * 0.18, y: size * 0.3))
                    p.closeSubpath()
                }
                .stroke(PhraseColors.outline, lineWidth: 1.5)
            }
        }
        .frame(width: size, height: size)
    }
}

struct PhraseCrayon: View {
    let color: Color
    let width: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Path { p in
                p.move(to: CGPoint(x: width * 0.5, y: 0))
                p.addLine(to: CGPoint(x: width, y: width * 0.7))
                p.addLine(to: CGPoint(x: 0, y: width * 0.7))
                p.closeSubpath()
            }
            .fill(color)
            .frame(width: width, height: width * 0.7)
            RoundedRectangle(cornerRadius: width * 0.15)
                .fill(color)
                .overlay {
                    Rectangle().fill(Color.white.opacity(0.35)).frame(height: width * 0.4)
                }
                .overlay { RoundedRectangle(cornerRadius: width * 0.15).stroke(PhraseColors.outline, lineWidth: 1.5) }
                .frame(width: width, height: width * 3.6)
        }
    }
}

/// 现成词图小方块：白边 + 阴影
struct PhraseIconTile: View {
    let word: String
    let size: CGFloat

    var body: some View {
        WordIconView(word: word, size: size)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white, lineWidth: 3)
            }
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }
}

/// 对勾叠在小月历上（Yes, it is!：一月一日贴着红贴纸）
struct PhraseMiniCalendar: View {
    let params: PhraseCodeParams
    let side: CGFloat

    var body: some View {
        PhraseTimeCard(kind: "calendar", params: PhraseCodeParams(sticker: params.sticker), icon: nil, side: side)
    }
}

// MARK: - 截图验收用：L3–L7 代码卡预览（-uiCodePreview 第几页）

extension LaunchOptions {
    static var codePreviewPage: Int? { value(for: "-uiCodePreview").flatMap { Int($0) } }
}

struct PhraseCodePreviewView: View {
    @Environment(DataStore.self) private var store
    let page: Int
    static let perPage = 6

    var body: some View {
        let lines = preview?.lines ?? []
        let start = page * Self.perPage
        let shown = Array(lines.dropFirst(start).prefix(Self.perPage))
        return VStack(alignment: .leading, spacing: 8) {
            Text("代码卡预览 \(page + 1) / \(max((lines.count + Self.perPage - 1) / Self.perPage, 1))")
                .kidFont(18, .heavy)
                .foregroundStyle(Palette.ink)
                .padding(.horizontal)
            GeometryReader { geo in
                let w = (geo.size.width - 12 * 3) / 2
                LazyVGrid(columns: [GridItem(.fixed(w), spacing: 12), GridItem(.fixed(w), spacing: 12)], spacing: 10) {
                    ForEach(shown) { line in
                        VStack(spacing: 4) {
                            PhrasePicture(line: line, side: w * 0.92, corner: 14)
                            Text("\(line.id)  \(line.en)")
                                .kidFont(12, .bold, maxScale: 1.0)
                                .foregroundStyle(Palette.ink)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(height: 30)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.top, 4)
    }

    private var preview: PhraseCodePreview? {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("phrases/code-preview.json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return PhraseCodePreview.decode(data)
    }
}
