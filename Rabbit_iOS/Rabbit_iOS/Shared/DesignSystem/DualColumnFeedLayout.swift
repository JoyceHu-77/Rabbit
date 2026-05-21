//
//  DualColumnFeedLayout.swift
//  Rabbit_iOS — 双列 feed 网格常量（与 DonationTabView 一致）
//

import SwiftUI

/// 物资捐换 tab 使用的双列信息流规格，其它 Feature 的双列 feed 应与此对齐。
enum DualColumnFeedLayout {
    static let spacing: CGFloat = 12
    static let cardCornerRadius: CGFloat = 12

    static var columns: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }

    static var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
    }
}

/// 标准双列 `LazyVGrid` 容器。
struct DualColumnFeedGrid<Content: View>: View {
    @ViewBuilder private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        LazyVGrid(columns: DualColumnFeedLayout.columns, spacing: DualColumnFeedLayout.spacing) {
            content()
        }
    }
}
