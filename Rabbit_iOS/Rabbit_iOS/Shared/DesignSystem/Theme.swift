//
//  Theme.swift
//  Rabbit_iOS — 对齐 rabbit_web Tailwind 主色
//

import SwiftUI

enum Theme {
    static let rose = Color(red: 0.89, green: 0.45, blue: 0.58)
    static let red600 = Color(red: 0.86, green: 0.15, blue: 0.15)
    static let redHeader = LinearGradient(
        colors: [Color(red: 0.86, green: 0.15, blue: 0.15), Color(red: 0.88, green: 0.25, blue: 0.42)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let screenBg = LinearGradient(
        colors: [
            Color(red: 1, green: 0.94, blue: 0.94),
            Color(red: 1, green: 0.92, blue: 0.95),
            Color(red: 1, green: 0.94, blue: 0.97),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let tabBarBg = Color.white.opacity(0.95)
}
