//
//  APIProfileModels.swift
//  Rabbit_iOS — 个人页 API 模型
//

import Foundation

nonisolated struct ProfileSnapshot: Sendable, Equatable {
    var viewerKey: String
    var userName: String
    var userBio: String
    var badges: Int
    var cloudCoins: Int
    var isAdmin: Bool
    var isLoggedIn: Bool
    var shippingAddress: String
}

nonisolated struct ProfileOrderItem: Identifiable, Sendable, Equatable {
    var id: String
    var title: String
    var subtitle: String
    var status: String
    var cloudCoinsReward: Int
    var createdAt: Date

    var isPending: Bool { status == "pending" }
}

nonisolated struct ProfileInboxItem: Identifiable, Sendable, Equatable {
    var id: String
    var title: String
    var body: String
    var createdAt: Date
    var read: Bool
}

nonisolated struct ProfileAdminNoticeItem: Identifiable, Sendable, Equatable {
    var id: String
    var type: String
    var title: String
    var content: String
    var createdAt: Date
    var read: Bool
}

nonisolated struct OrderPayResult: Sendable {
    var orderId: String
    var cloudCoinsGranted: Int
    var profile: ProfileSnapshot
}

nonisolated struct ProfileAPIItem: Decodable, Sendable {
    let viewerKey: String?
    let userName: String
    let userBio: String
    let badges: Int
    let cloudCoins: Int
    let isAdmin: Bool
    let isLoggedIn: Bool
    let shippingAddress: String

    nonisolated func toSnapshot() -> ProfileSnapshot {
        ProfileSnapshot(
            viewerKey: viewerKey ?? "",
            userName: userName,
            userBio: userBio,
            badges: badges,
            cloudCoins: cloudCoins,
            isAdmin: isAdmin,
            isLoggedIn: isLoggedIn,
            shippingAddress: shippingAddress
        )
    }
}

nonisolated struct ProfilePatchBody: Encodable, Sendable {
    var userName: String?
    var userBio: String?
    var badges: Int?
    var cloudCoins: Int?
    var isAdmin: Bool?
    var isLoggedIn: Bool?
    var shippingAddress: String?
}

nonisolated struct WalletAdjustBody: Encodable, Sendable {
    let badgesDelta: Int
    let cloudCoinsDelta: Int
}

nonisolated struct InboxAPIItem: Decodable, Sendable {
    let id: String
    let title: String
    let body: String
    let createdAt: Date
    let read: Bool

    nonisolated func toDomain() -> ProfileInboxItem {
        ProfileInboxItem(id: id, title: title, body: body, createdAt: createdAt, read: read)
    }
}

nonisolated struct AdminNoticeAPIItem: Decodable, Sendable {
    let id: String
    let type: String
    let title: String
    let content: String
    let createdAt: Date
    let read: Bool

    nonisolated func toDomain() -> ProfileAdminNoticeItem {
        ProfileAdminNoticeItem(
            id: id,
            type: type,
            title: title,
            content: content,
            createdAt: createdAt,
            read: read
        )
    }
}

nonisolated struct OrderAPIItem: Decodable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let status: String
    let cloudCoinsReward: Int
    let createdAt: Date

    nonisolated func toDomain() -> ProfileOrderItem {
        ProfileOrderItem(
            id: id,
            title: title,
            subtitle: subtitle,
            status: status,
            cloudCoinsReward: cloudCoinsReward,
            createdAt: createdAt
        )
    }
}

nonisolated struct OrderPayAPIItem: Decodable, Sendable {
    let orderId: String
    let cloudCoinsGranted: Int
    let profile: ProfileAPIItem

    nonisolated func toDomain() -> OrderPayResult {
        OrderPayResult(
            orderId: orderId,
            cloudCoinsGranted: cloudCoinsGranted,
            profile: profile.toSnapshot()
        )
    }
}
