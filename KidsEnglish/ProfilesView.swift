import SwiftUI
import UIKit

// MARK: - 多孩子档案的界面（数据和规则在 Profiles.swift，设计见 docs/pm/profiles-v1.md）
//
// 「谁来学？」页、首页左上角的头像、家长中心的孩子切换与管理、添加 / 编辑孩子。

// MARK: 启动参数（CI 截图用；假档案只在内存里，不写存储）

extension LaunchOptions {
    /// `-uiProfiles N`：截图时假装有 N 个孩子（2–4）
    static var demoProfiles: Int { value(for: "-uiProfiles").flatMap { Int($0) } ?? 0 }

    /// `-uiWho`：截图时直接显示「谁来学？」页
    static var forceWho: Bool { ProcessInfo.processInfo.arguments.contains("-uiWho") }

    /// `-uiChildEdit add`：家长中心直接打开添加孩子页
    static var childEdit: String? { value(for: "-uiChildEdit") }

    /// `-uiImportConfirm`：家长中心直接弹出「用备份替换全部孩子」确认框
    static var importConfirmDemo: Bool { ProcessInfo.processInfo.arguments.contains("-uiImportConfirm") }

    /// `-uiDeleteConfirm`：家长中心直接弹出删除孩子确认框
    static var deleteConfirmDemo: Bool { ProcessInfo.processInfo.arguments.contains("-uiDeleteConfirm") }

    static func demoProfileList(_ base: [ChildProfile]) -> [ChildProfile] {
        let names = ["Lily", "Leo", "孩子 3", "孩子 4"]
        let n = min(max(demoProfiles, 1), ProfileRoster.maxCount)
        var list = Array(base.prefix(1))
        if !list.isEmpty { list[0].name = names[0] }
        while list.count < n {
            let i = list.count
            list.append(ChildProfile(id: "demo\(i)", name: names[i], avatar: ProfileRoster.avatars[(i * 3) % 8],
                                     color: i % ProfileRoster.colorCount))
        }
        return list
    }

    /// 截图用的假备份：两个孩子
    static func demoFamilyBackup(_ store: DataStore) -> FamilyBackup? {
        guard case .family(let b) = BackupCodec.parse(store.exportSnapshotJSON()) else { return nil }
        return b
    }
}

enum ProfileColors {
    static let all: [Color] = [
        Color(red: 1.00, green: 0.55, blue: 0.10),  // 橙
        Color(red: 0.20, green: 0.55, blue: 0.95),  // 蓝
        Color(red: 0.30, green: 0.72, blue: 0.35),  // 绿
        Color(red: 0.93, green: 0.35, blue: 0.55),  // 粉
        Color(red: 0.58, green: 0.40, blue: 0.90),  // 紫
        Color(red: 0.95, green: 0.75, blue: 0.10),  // 黄
    ]

    static func color(_ i: Int) -> Color { all[((i % all.count) + all.count) % all.count] }
}

/// 孩子头像：动物平涂词图 + 代表色外圈
struct ProfileAvatarView: View {
    @Environment(DataStore.self) private var store
    let profile: ChildProfile
    var size: CGFloat = 56
    var selected = false

    var body: some View {
        ZStack {
            Circle().fill(Palette.surface)
            if let url = store.iconURL(forWord: profile.avatar), let ui = UIImage(contentsOfFile: url.path) {
                Image(uiImage: ui).resizable().scaledToFill()
                    .frame(width: size * 0.86, height: size * 0.86)
                    .clipShape(Circle())
            }
        }
        .frame(width: size, height: size)
        .overlay { Circle().strokeBorder(ProfileColors.color(profile.color), lineWidth: max(3, size * 0.07)) }
        .overlay {
            if selected {
                Circle().strokeBorder(Color.white, lineWidth: 2).padding(max(3, size * 0.07))
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - 「谁来学？」页

struct WhoIsLearningView: View {
    @Environment(DataStore.self) private var store
    @State private var player = AudioPlayer()
    @State private var bounce = false

    var body: some View {
        ZStack {
            Palette.canvasWarm.ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer(minLength: 0)
                HStack(spacing: 12) {
                    PhraseAvatarView(speaker: "tom", size: 72, active: false)
                    Text("Who's learning today?")
                        .kidFont(26, .heavy)
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 24)

                let cols = store.profiles.count > 2 ? 2 : store.profiles.count
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 18), count: max(cols, 1)),
                          spacing: 22) {
                    ForEach(store.profiles) { p in
                        Button { store.switchProfile(p.id) } label: {
                            VStack(spacing: 8) {
                                ProfileAvatarView(profile: p, size: 132, selected: p.id == store.currentProfileId)
                                    .scaleEffect(bounce ? 1.04 : 1.0)
                                Text(p.name)
                                    .kidFont(22, .heavy)
                                    .foregroundStyle(Palette.ink)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.sheet, style: .continuous))
                            .elevationGround()
                        }
                        .buttonStyle(PressableStyle())
                        .accessibilityLabel(p.name)
                    }
                }
                .padding(.horizontal, 24)
                Spacer(minLength: 0)
            }
        }
        .onAppear {
            guard !LaunchOptions.isUIScreenshotRun else { return }
            if let url = store.phraseFileURL("audio", "prompt_who.mp3") { player.play(url: url) }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { bounce = true }
        }
        .onDisappear { player.stop() }
    }
}

/// 首页左上角：当前孩子的头像。有 2 个以上孩子时点一下回到「谁来学？」页；只有 1 个时点了没反应
struct HomeProfileButton: View {
    @Environment(DataStore.self) private var store
    var size: CGFloat = 48
    var showName = true

    var body: some View {
        if let p = store.currentProfile {
            Button {
                if store.profiles.count >= 2 { store.whoIsLearningVisible = true }
            } label: {
                HStack(spacing: 8) {
                    ProfileAvatarView(profile: p, size: size)
                    if showName {
                        Text(p.name)
                            .kidFont(17, .heavy)
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel(store.profiles.count >= 2 ? "换一个孩子" : p.name)
        }
    }
}

// MARK: - 家长中心：孩子切换 + 管理

struct ParentChildrenCard: View {
    @Environment(DataStore.self) private var store
    @State private var editing: ChildProfile?
    @State private var adding = LaunchOptions.childEdit == "add"
    @State private var deleting: ChildProfile?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("孩子")
                .kidFont(18, .heavy)
                .foregroundStyle(Palette.ink)
            Text("点头像切换：下面的学习报告和设置都是这个孩子的")
                .kidFont(13, .medium)
                .foregroundStyle(Palette.inkMuted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(store.profiles) { p in
                        Button { store.switchProfile(p.id) } label: {
                            VStack(spacing: 4) {
                                ProfileAvatarView(profile: p, size: 58, selected: p.id == store.currentProfileId)
                                    .opacity(p.id == store.currentProfileId ? 1 : 0.55)
                                Text(p.name)
                                    .kidFont(14, p.id == store.currentProfileId ? .heavy : .semibold)
                                    .foregroundStyle(p.id == store.currentProfileId ? Palette.ink : Palette.inkMuted)
                                    .lineLimit(1)
                            }
                            .frame(width: 74)
                        }
                        .buttonStyle(PressableStyle())
                    }
                    if ProfileRoster.canAdd(store.profiles) {
                        Button { adding = true } label: {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle().strokeBorder(Palette.inkSubtle, style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                                    Image(systemName: "plus").kidFont(22, .bold).foregroundStyle(Palette.inkMuted)
                                }
                                .frame(width: 58, height: 58)
                                Text("添加").kidFont(14, .semibold).foregroundStyle(Palette.inkMuted)
                            }
                            .frame(width: 74)
                        }
                        .buttonStyle(PressableStyle())
                        .accessibilityLabel("添加孩子")
                    }
                }
                .padding(.vertical, 2)
            }
            if let p = store.currentProfile {
                HStack(spacing: 10) {
                    Button { editing = p } label: {
                        Label("改名 / 换头像", systemImage: "pencil")
                            .kidFont(15, .bold)
                            .foregroundStyle(Func.infoDeep)
                            .frame(maxWidth: .infinity).frame(height: 40)
                            .background(Func.info.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(PressableStyle())
                    if ProfileRoster.canDelete(store.profiles) {
                        Button { deleting = p } label: {
                            Label("删除这个孩子", systemImage: "trash")
                                .kidFont(15, .bold)
                                .foregroundStyle(Func.negativeDeep)
                                .frame(maxWidth: .infinity).frame(height: 40)
                                .background(Func.negative.opacity(0.10), in: Capsule())
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
            }
        }
        .sheet(isPresented: $adding) { ChildEditView(profile: nil) }
        .sheet(item: $editing) { p in ChildEditView(profile: p) }
        .onAppear {
            if LaunchOptions.deleteConfirmDemo, deleting == nil, store.profiles.count > 1 { deleting = store.profiles.last }
        }
        .fullScreenCover(item: $deleting) { p in
            ZStack {
                Color.black.opacity(0.001).ignoresSafeArea()
                ConfirmCard(emoji: "🗑️",
                            title: "删除「\(p.name)」？",
                            message: "这个孩子的学习进度会被删除，不能撤销。",
                            confirmTitle: "删除",
                            destructive: true,
                            onConfirm: {
                                store.deleteProfile(p.id)
                                deleting = nil
                            },
                            onCancel: { deleting = nil })
            }
            .presentationBackground(.black.opacity(0.4))
        }
    }
}

/// 添加 / 编辑孩子：名字、8 个动物头像、6 种颜色
struct ChildEditView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let profile: ChildProfile?
    @State private var name = ""
    @State private var avatar = ProfileRoster.avatars[0]
    @State private var color = 0

    private var isNew: Bool { profile == nil }

    var body: some View {
        NavigationStack {
            KidScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Spacer()
                        ProfileAvatarView(profile: ChildProfile(id: "preview", name: name, avatar: avatar, color: color),
                                          size: 110)
                        Spacer()
                    }
                    Text("名字（可以不填）")
                        .kidFont(18, .heavy)
                        .foregroundStyle(Palette.ink)
                    TextField(ProfileRoster.defaultName(existing: store.profiles.filter { $0.id != profile?.id }),
                              text: $name)
                        .kidFont(22, .bold)
                        .padding(14)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
                        .onChange(of: name) { _, v in if v.count > 10 { name = String(v.prefix(10)) } }

                    Text("头像")
                        .kidFont(18, .heavy)
                        .foregroundStyle(Palette.ink)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                        ForEach(ProfileRoster.avatars, id: \.self) { a in
                            Button { avatar = a } label: {
                                ProfileAvatarView(profile: ChildProfile(id: a, name: "", avatar: a, color: color),
                                                  size: 66, selected: a == avatar)
                                    .opacity(a == avatar ? 1 : 0.6)
                                    .scaleEffect(a == avatar ? 1.08 : 1)
                            }
                            .buttonStyle(PressableStyle())
                            .accessibilityLabel(a)
                        }
                    }

                    Text("颜色")
                        .kidFont(18, .heavy)
                        .foregroundStyle(Palette.ink)
                    HStack(spacing: 12) {
                        ForEach(0..<ProfileRoster.colorCount, id: \.self) { i in
                            Button { color = i } label: {
                                Circle().fill(ProfileColors.color(i))
                                    .frame(width: 40, height: 40)
                                    .overlay { Circle().strokeBorder(Color.white, lineWidth: i == color ? 4 : 0).padding(2) }
                                    .overlay { Circle().strokeBorder(Palette.ink.opacity(i == color ? 0.6 : 0), lineWidth: 2) }
                            }
                            .buttonStyle(PressableStyle())
                            .accessibilityLabel("颜色 \(i + 1)")
                        }
                    }

                    AppButton(title: isNew ? "添加" : "保存", icon: "checkmark", tier: .primary) {
                        save()
                        dismiss()
                    }
                    .padding(.top, 6)
                }
                .padding(16)
            }
            .creamBackground()
            .navigationTitle(isNew ? "添加孩子" : "编辑孩子")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
            }
            .onAppear {
                if let p = profile {
                    name = p.name; avatar = p.avatar; color = p.color
                } else {
                    let fresh = ProfileRoster.newProfile(existing: store.profiles, id: "new")
                    avatar = fresh.avatar; color = fresh.color
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if var p = profile {
            p.name = trimmed.isEmpty ? ProfileRoster.defaultName(existing: store.profiles.filter { $0.id != p.id }) : trimmed
            p.avatar = avatar
            p.color = color
            store.updateProfile(p)
        } else {
            store.addProfile(name: trimmed, avatar: avatar, color: color)
        }
    }
}
