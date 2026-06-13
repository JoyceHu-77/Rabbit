//
//  TabOrderSettings.swift
//  Rabbit_iOS — 底部 Tab 固定 PRD 顺序
//

import Foundation

extension MainTab {
    /// PRD：爱兔救援 → 爱兔领养 → 物资捐换 → 爱兔活动 → 个人页
    static let prdOrderedTabs: [MainTab] = [.rescue, .adoption, .donation, .activity, .profile]
}
