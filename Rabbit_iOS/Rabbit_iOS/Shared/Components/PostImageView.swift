//
//  PostImageView.swift
//  Rabbit_iOS — 共享网络图片组件（救援卡片、活动横幅、捐换等复用）
//

import SwiftUI

struct PostImageView: View {
    let urlString: String?

    var body: some View {
        Group {
            if let u = resolvedURL(urlString) {
                AsyncImage(url: u) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    case .failure: placeholder
                    default: ProgressView()
                    }
                }
            } else {
                placeholder
            }
        }
        .accessibilityLabel(L10n.Common.imageContent)
    }

    private var placeholder: some View {
        ZStack {
            Color(white: 0.95)
            Text("🐰").font(.largeTitle)
        }
        .accessibilityHidden(true)
    }

    private func resolvedURL(_ s: String?) -> URL? {
        guard let s, !s.isEmpty else { return nil }
        if s.hasPrefix("http") { return URL(string: s) }
        if s.hasPrefix("file:") { return URL(string: s) }
        if s.hasPrefix("/") { return URL(fileURLWithPath: s) }
        return nil
    }
}

/// 双列网格 1:1 缩略图：`LazyVGrid` 内需明确宽高后再 `scaledToFill`，否则图片会撑破列宽导致重叠。
struct SquareGridThumbnail: View {
    let urlString: String

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
        if let url = resolvedURL(urlString) {
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
                    placeholder
                        .frame(width: width, height: height)
                @unknown default:
                    Color.clear.frame(width: width, height: height)
                }
            }
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

    private func resolvedURL(_ raw: String) -> URL? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        if s.hasPrefix("http://") || s.hasPrefix("https://") {
            return URL(string: s)
        }
        if s.hasPrefix("file:") { return URL(string: s) }
        if s.hasPrefix("/") { return URL(fileURLWithPath: s) }
        return nil
    }
}
