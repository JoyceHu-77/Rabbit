//
//  LocalAuthCatalog.swift
//  Rabbit_iOS — 端内演示账号（暂不接入登录接口）
//

import Foundation

struct LocalAuthAccount: Equatable, Sendable {
    let id: String
    let displayName: String
    let roleTitle: String
    let bio: String
    let isAdmin: Bool
    let badges: Int
    let cloudCoins: Int
    let capabilitySummary: String
}

enum LocalAuthCatalog {
    static let admin = LocalAuthAccount(
        id: "1",
        displayName: "爱兔管理员",
        roleTitle: "管理员",
        bio: "负责审核救援帖、管理通知与线下活动",
        isAdmin: true,
        badges: 5,
        cloudCoins: 99,
        capabilitySummary: "救援审核与编辑、爱兔社区删帖、线下活动新增、橱窗收款、管理通知"
    )

    static let member = LocalAuthAccount(
        id: "2",
        displayName: "爱心用户",
        roleTitle: "普通用户",
        bio: "热爱兔兔，致力于救助流浪动物",
        isAdmin: false,
        badges: 3,
        cloudCoins: 15,
        capabilitySummary: "浏览与发布救援、捐换、领养及社区互动"
    )

    static let all: [LocalAuthAccount] = [admin, member]

    static func account(for userId: String) -> LocalAuthAccount? {
        let trimmed = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        return all.first { $0.id == trimmed }
    }
}
