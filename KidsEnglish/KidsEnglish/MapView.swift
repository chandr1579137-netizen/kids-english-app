import SwiftUI

/// 封面图：异步加载本地文件，避免主线程解码卡顿
struct CoverImage: View {
    let url: URL?
    let fallbackText: String

    var body: some View {
        // 用 Color.clear 当尺寸权威：父级给多大就是多大。
        // 之前直接放 AsyncImage + aspectRatio(.fill)，图片的固有宽度会反过来撑宽
        // 网格单元，导致 3 列封面溢出到屏幕边缘、并吃掉 16pt 页边距。
        Color.clear
            .overlay { content }
            .clipped()
    }

    @ViewBuilder
    private var content: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: .fill)
                default:
                    fallback
                }
            }
        } else {
            fallback
        }
    }

    private var fallback: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(LinearGradient(
                colors: [.orange.opacity(0.7), .pink.opacity(0.7)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(Text(fallbackText).font(.largeTitle))
    }
}
