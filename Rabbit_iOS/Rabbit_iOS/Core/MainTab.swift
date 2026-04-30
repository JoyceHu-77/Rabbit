//
//  MainTab.swift
//  Rabbit_iOS — 根级 Tab 枚举（与 rabbit_web_new 底部导航顺序一致）
//

import Foundation

/// 底部 Tab：救援 → 活动 → 领养 → 捐换 → 个人
enum MainTab: Int, CaseIterable, Hashable {
    case rescue
    case activity
    case adoption
    case donation
    case profile

    var title: String {
        switch self {
        case .rescue: return "爱兔救援"
        case .activity: return "爱兔活动"
        case .adoption: return "爱兔领养"
        case .donation: return "物资捐换"
        case .profile: return "个人页"
        }
    }

    var systemImage: String {
        switch self {
        case .rescue: return "heart.fill"
        case .activity: return "calendar"
        case .adoption: return "person.2.fill"
        case .donation: return "shippingbox.fill"
        case .profile: return "person.fill"
        }
    }
}
