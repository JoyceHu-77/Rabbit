//
//  L10n.swift
//  Rabbit_iOS — 可本地化字符串集中入口（逐步从视图中抽离硬编码）
//

import Foundation

enum L10n {
    enum Common {
        static var imageContent: String { String(localized: "内容图片", comment: "Image placeholder accessibility") }
    }
}
