//
//  UserInboxStore.swift
//  Rabbit_iOS — 用户站内信（收件箱），与 AdminNotificationsStore 对称
//

import Foundation

struct UserInboxRecord: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var title: String
    var body: String
    var createdAt: Date
    var read: Bool
}

enum UserInboxStore {
    private static let key = "userInboxMessages"

    static func load() -> [UserInboxRecord] {
        if let data = UserDefaults.standard.data(forKey: key),
           let list = try? JSONDecoder().decode([UserInboxRecord].self, from: data) {
            if list.isEmpty { return seedIfEmpty() }
            return list.sorted { $0.createdAt > $1.createdAt }
        }
        return seedIfEmpty()
    }

    /// 无服务端或列表为空时，保证本地有可点的演示站内信。
    static func ensureDemoSeedIfNeeded() {
        if load().isEmpty { _ = seedIfEmpty() }
    }

    static func unreadCount() -> Int {
        load().filter { !$0.read }.count
    }

    static func save(_ items: [UserInboxRecord]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func append(title: String, body: String) {
        let r = UserInboxRecord(
            id: "UM\(Int(Date().timeIntervalSince1970 * 1000))",
            title: title,
            body: body,
            createdAt: Date(),
            read: false
        )
        var all = load()
        all.insert(r, at: 0)
        save(all)
    }

    static func markRead(id: String) {
        var all = load()
        guard let i = all.firstIndex(where: { $0.id == id }) else { return }
        all[i].read = true
        save(all)
    }

    private static func seedIfEmpty() -> [UserInboxRecord] {
        let now = Date()
        let items: [UserInboxRecord] = [
            UserInboxRecord(
                id: "UM_SEED_WELCOME",
                title: "欢迎加入爱兔会",
                body: "感谢您成为爱兔会的一员，让我们一起为兔兔的幸福而努力！可在「爱兔救援」发布或浏览救助信息。",
                createdAt: now.addingTimeInterval(-3 * 24 * 3600),
                read: true
            ),
            UserInboxRecord(
                id: "UM_SEED_REWARD",
                title: "恭喜获得爱兔奖章",
                body: "参与爱心活动可获得爱兔奖章与云养币，用于兑换橱窗商品或支持云养。",
                createdAt: now.addingTimeInterval(-2 * 3600),
                read: false
            ),
            UserInboxRecord(
                id: "UM_SEED_ORDER",
                title: "订单待支付提醒",
                body: "您有一笔「爱心橱窗 · 电子照片」待支付，完成支付后可获得云养币奖励。",
                createdAt: now.addingTimeInterval(-30 * 60),
                read: false
            ),
        ]
        save(items)
        return items
    }
}
