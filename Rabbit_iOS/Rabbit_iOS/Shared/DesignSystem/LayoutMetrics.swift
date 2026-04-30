//
//  LayoutMetrics.swift
//  Rabbit_iOS — 以 iPhone 逻辑分辨率 393×852 为基准的 iOS 风格布局常量
//

import SwiftUI

/// 设计基准（与 iPhone 14/15 竖屏逻辑尺寸一致）
enum LayoutMetrics {
    /// 参考逻辑宽度（pt）
    static let referenceWidth: CGFloat = 393
    /// 参考逻辑高度（pt）
    static let referenceHeight: CGFloat = 852

    /// TabView 子页面布局已避开 TabBar，悬浮按钮仅需距底部安全区少量留白
    static let fabBottomMargin: CGFloat = 20

    /// 水平边距（相对 393 宽度略收紧，接近系统列表边距）
    static let horizontalInset: CGFloat = 16

    /// 将设计稿宽度映射到当前屏宽（不超过 1）
    static func clampedWidth(_ width: CGFloat) -> CGFloat {
        min(width, referenceWidth)
    }
}
