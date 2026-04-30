
//
//  RescueCardView.swift
//  Rabbit_iOS — 对应 RescueCard.tsx
//

import SwiftUI

struct RescueCardView: View {
    let post: RescueDisplayPost

    private var statusBackground: Color {
        switch post.status {
        case "待救援": return Color.red.opacity(0.15)
        case "救援中": return Color.orange.opacity(0.18)
        case "已救援": return Color.blue.opacity(0.15)
        case "寄养中": return Color.purple.opacity(0.15)
        case "已领养": return Color.green.opacity(0.18)
        default: return Color.gray.opacity(0.15)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                PostImageView(urlString: post.images.first)
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
                Text(post.status)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusBackground, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.gray.opacity(0.25)))
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(post.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                HStack {
                    Label(post.location, systemImage: "mappin.and.ellipse")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Label(post.date, systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let org = post.organizerName, !org.isEmpty {
                    Label("主理人：\(org)", systemImage: "person")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 6) {
                    if let h = post.healthStatus, !h.isEmpty {
                        Label(h, systemImage: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                    }
                    if let s = post.sterilizedStatus, !s.isEmpty {
                        Label(s, systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                    }
                }

                Text(post.description)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
            .padding(10)
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }
}
