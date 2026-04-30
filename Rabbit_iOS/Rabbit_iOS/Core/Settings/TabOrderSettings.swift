//
//  TabOrderSettings.swift
//  Rabbit_iOS — 底部 Tab 顺序持久化（PRD：可配置，默认五 Tab PRD 顺序）
//

import Foundation

extension MainTab {
    /// PRD：爱兔救援 → 爱兔领养 → 物资捐换 → 爱兔活动 → 个人页
    static let prdOrderedTabs: [MainTab] = [.rescue, .adoption, .donation, .activity, .profile]
}

enum TabOrderSettings {
    private static let orderKey = "mainTabOrderRawValues"

    static func orderedTabs() -> [MainTab] {
        guard let raw = UserDefaults.standard.array(forKey: orderKey) as? [Int],
              raw.count == MainTab.allCases.count
        else {
            return MainTab.prdOrderedTabs
        }
        let tabs = raw.compactMap { MainTab(rawValue: $0) }
        guard tabs.count == MainTab.allCases.count,
              Set(tabs) == Set(MainTab.allCases)
        else {
            return MainTab.prdOrderedTabs
        }
        return tabs
    }

    static func saveOrderedTabs(_ tabs: [MainTab]) {
        guard tabs.count == MainTab.allCases.count,
              Set(tabs) == Set(MainTab.allCases)
        else { return }
        UserDefaults.standard.set(tabs.map(\.rawValue), forKey: orderKey)
    }

    static func resetToPRDDefault() {
        saveOrderedTabs(MainTab.prdOrderedTabs)
    }

    /// 将「个人页」移到中间（第 3 位）或末尾（第 5 位），其余保持当前相对顺序（不含个人时的顺序）。
    static func applyProfilePositionMiddle() {
        var rest = orderedTabs().filter { $0 != .profile }
        if rest.count != 4 { rest = MainTab.prdOrderedTabs.filter { $0 != .profile } }
        let insertAt = min(2, rest.count)
        rest.insert(.profile, at: insertAt)
        saveOrderedTabs(rest)
    }

    static func applyProfilePositionTrailing() {
        var rest = orderedTabs().filter { $0 != .profile }
        if rest.count != 4 { rest = MainTab.prdOrderedTabs.filter { $0 != .profile } }
        rest.append(.profile)
        saveOrderedTabs(rest)
    }
}
