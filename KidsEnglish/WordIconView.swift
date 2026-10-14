import SwiftUI

/// 单词图标：优先用资源包里的图，没有图时用词条 emoji，再没有才显示首字母。
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

    private var fallbackView: some View {
        let emoji = store.lookupWord(word)?.emoji
        return ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
            if let emoji, !emoji.isEmpty {
                Text(emoji)
                    .font(.system(size: size * 0.48))
            } else {
                Text(String(word.prefix(1)).uppercased())
                    .font(.system(size: size * 0.45, weight: .bold))
                    .foregroundColor(.accentColor)
            }
        }
    }
}
