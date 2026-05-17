//
//  PostImageView.swift
//  Rabbit_iOS — 共享网络图片组件（救援卡片、活动横幅、捐换等复用）
//

import SwiftUI

struct PostImageView: View {
    let urlString: String?
    /// 救援帖 ID（如 `R003`），网络失败时按种子数据回退本地图。
    var rescuePostId: String? = nil
    /// 种子兔兔 ID，API 图片地址与种子不一致时的回退键。
    var sourceRabbitId: Int32? = nil

    var body: some View {
        Group {
            if RescueFeedMedia.isBundleImagePath(urlString),
               let local = RescueFeedMedia.uiImage(
                   for: urlString,
                   rescuePostId: rescuePostId,
                   sourceRabbitId: sourceRabbitId
               ) {
                Image(uiImage: local)
                    .resizable()
                    .scaledToFill()
            } else if let u = resolvedHTTPURL(urlString) {
                AsyncImage(url: u) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    case .failure:
                        localOrPlaceholder
                    default:
                        ProgressView()
                    }
                }
            } else if let local = RescueFeedMedia.uiImage(
                for: urlString,
                rescuePostId: rescuePostId,
                sourceRabbitId: sourceRabbitId
            ) {
                Image(uiImage: local)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .accessibilityLabel(L10n.Common.imageContent)
    }

    @ViewBuilder
    private var localOrPlaceholder: some View {
        if let local = RescueFeedMedia.uiImage(
            for: urlString,
            rescuePostId: rescuePostId,
            sourceRabbitId: sourceRabbitId
        ) {
            Image(uiImage: local)
                .resizable()
                .scaledToFill()
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Color(white: 0.95)
            Text("🐰").font(.largeTitle)
        }
        .accessibilityHidden(true)
    }

    private func resolvedHTTPURL(_ s: String?) -> URL? {
        guard let s, !s.isEmpty else { return nil }
        if s.hasPrefix("http://") || s.hasPrefix("https://") { return URL(string: s) }
        if s.hasPrefix("file:") { return URL(string: s) }
        return nil
    }
}

/// 双列网格 1:1 缩略图：`LazyVGrid` 内需明确宽高后再 `scaledToFill`，否则图片会撑破列宽导致重叠。
struct SquareGridThumbnail: View {
    let urlString: String
    var rescuePostId: String? = nil
    var sourceRabbitId: Int32? = nil

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Color(.tertiarySystemFill)
                content(width: w, height: h)
            }
            .frame(width: w, height: h)
            .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func content(width: CGFloat, height: CGFloat) -> some View {
        if RescueFeedMedia.isBundleImagePath(urlString),
           let local = RescueFeedMedia.uiImage(
               for: urlString,
               rescuePostId: rescuePostId,
               sourceRabbitId: sourceRabbitId
           ) {
            Image(uiImage: local)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
        } else if let url = resolvedHTTPURL(urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: width, height: height)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: height)
                        .clipped()
                case .failure:
                    localOrPlaceholder(width: width, height: height)
                @unknown default:
                    Color.clear.frame(width: width, height: height)
                }
            }
        } else if let local = RescueFeedMedia.uiImage(
            for: urlString,
            rescuePostId: rescuePostId,
            sourceRabbitId: sourceRabbitId
        ) {
            Image(uiImage: local)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
        } else {
            placeholder
                .frame(width: width, height: height)
        }
    }

    @ViewBuilder
    private func localOrPlaceholder(width: CGFloat, height: CGFloat) -> some View {
        if let local = RescueFeedMedia.uiImage(
            for: urlString,
            rescuePostId: rescuePostId,
            sourceRabbitId: sourceRabbitId
        ) {
            Image(uiImage: local)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
        } else {
            placeholder
                .frame(width: width, height: height)
        }
    }

    private var placeholder: some View {
        ZStack {
            Color(.tertiarySystemFill)
            Text("🐰").font(.title2)
            Image(systemName: "photo")
                .font(.title3)
                .foregroundStyle(.tertiary)
        }
    }

    private func resolvedHTTPURL(_ raw: String) -> URL? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        if s.hasPrefix("http://") || s.hasPrefix("https://") {
            return URL(string: s)
        }
        if s.hasPrefix("file:") { return URL(string: s) }
        return nil
    }
}
