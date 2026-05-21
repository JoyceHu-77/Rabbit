//
//  WechatQRImageView.swift
//  Rabbit_iOS — 微信群二维码展示（data URL / file / http）
//

import SwiftUI

struct WechatQRImageView: View {
    let stored: String?
    var maxHeight: CGFloat = 200

    var body: some View {
        Group {
            if let local = RescueWechatQR.uiImage(from: stored) {
                Image(uiImage: local)
                    .resizable()
                    .scaledToFit()
            } else if let url = httpURL(from: stored) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFit()
                    case .failure:
                        emptyPlaceholder
                    default:
                        ProgressView()
                    }
                }
            } else {
                emptyPlaceholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: maxHeight)
    }

    private var emptyPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "qrcode")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("暂无二维码")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func httpURL(from stored: String?) -> URL? {
        guard let s = stored?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        if s.hasPrefix("http://") || s.hasPrefix("https://") { return URL(string: s) }
        return nil
    }
}
