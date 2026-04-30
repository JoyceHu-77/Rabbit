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
