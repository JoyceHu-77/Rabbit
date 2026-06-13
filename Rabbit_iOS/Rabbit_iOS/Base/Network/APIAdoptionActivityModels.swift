//
//  APIAdoptionActivityModels.swift
//  Rabbit_iOS — 领养 / 活动 Tab 与后端对齐的领域模型
//

import Foundation

// MARK: - 活动

nonisolated struct ActivityBannerItem: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let imageURL: String
    let sortOrder: Int
    /// `checkin` | `cloud`
    let targetKey: String

    static let fallbackDefaults: [ActivityBannerItem] = [
        ActivityBannerItem(
            id: "checkin",
            title: "只取心滴",
            subtitle: "日行一善公益打卡活动",
            imageURL: "https://images.unsplash.com/photo-1533514114760-4389f572ae26?w=600",
            sortOrder: 0,
            targetKey: "checkin"
        ),
        ActivityBannerItem(
            id: "cloud",
            title: "爱心云养计划",
            subtitle: "公益云养小兔活动",
            imageURL: "https://images.unsplash.com/photo-1591797057589-eb91f36c0a6f?w=600",
            sortOrder: 1,
            targetKey: "cloud"
        ),
    ]
}

nonisolated struct OfflineEventItem: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let title: String
    let date: String
    let location: String
    let imageURL: String
    let bannerURL: String?
    let description: String
    let isPast: Bool

    static let fallbackPast: [OfflineEventItem] = [
        OfflineEventItem(
            id: "OE_SEED_PAST_1",
            title: "春日兔友百人聚 - 上海首场",
            date: "2026-04-05",
            location: "市中心 6600㎡ 超大场馆",
            imageURL: "https://images.unsplash.com/photo-1533514114760-4389f572ae26?w=600",
            bannerURL: "https://images.unsplash.com/photo-1650199321281-978455fbff64?w=600",
            description: "超过 150 位兔友齐聚一堂，分享养兔经验，交流爱心故事。",
            isPast: true
        ),
    ]

    static let fallbackUpcoming: [OfflineEventItem] = [
        OfflineEventItem(
            id: "OE_SEED_UP_1",
            title: "春日兔友百人聚",
            date: "2026-04-29",
            location: "市中心 6600㎡ 超大场馆 | 品牌商家赞助",
            imageURL: "https://images.unsplash.com/photo-1533514114760-4389f572ae26?w=600",
            bannerURL: "https://images.unsplash.com/photo-1765401237810-e403bf6b888d?w=600",
            description: "丰富礼品、专业服务与知识分享，欢迎所有爱兔人士参加。",
            isPast: false
        ),
        OfflineEventItem(
            id: "OE_SEED_UP_2",
            title: "爱兔会公益活动",
            date: "2026-05-15",
            location: "上海市区待定",
            imageURL: "https://images.unsplash.com/photo-1591797057589-eb91f36c0a6f?w=600",
            bannerURL: "https://images.unsplash.com/photo-1649750291679-1ee88c324527?w=600",
            description: "流浪兔救助知识、科学养兔交流、领养咨询与爱心义卖。",
            isPast: false
        ),
    ]
}

nonisolated struct CharityShopProductItem: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let rabbitName: String
    let image: String
    let description: String
    let price: Int
    let badges: Int
    let cloudCoins: Int
}

nonisolated struct CloudAdoptConfirmResult: Sendable {
    let rescueId: String
    let amountYuan: Int
    let cloudCoinsGranted: Int
    let profile: ProfileSnapshot?
}

// MARK: - 领养

nonisolated struct AdoptionIntentDraft: Sendable {
    let rescueId: String
    let applicantName: String
    let applicantPhone: String
    let note: String?
}

nonisolated struct CommunityPostDraft: Sendable {
    let authorName: String
    let title: String
    let content: String
    let images: [String]
}
