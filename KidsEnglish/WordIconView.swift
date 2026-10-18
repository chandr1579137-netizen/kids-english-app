import SwiftUI

/// 单词图标：加载本地/资源包中的 3D 单词图标。
/// 失败或无图时显示首字母兜底（不用 emoji 猜）。
struct WordIconView: View {
    @Environment(DataStore.self) private var store

    let word: String
    var size: CGFloat = 120

    var body: some View {
        if let url = store.iconURL(forWord: word) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    fallbackView
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            fallbackView
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    /// 首字母兜底：浅色背景 + 大字
    private var fallbackView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
            Text(String(word.prefix(1)).uppercased())
                .kidFont(size * 0.45, .bold)
                .foregroundColor(.accentColor)
        }
    }
}
