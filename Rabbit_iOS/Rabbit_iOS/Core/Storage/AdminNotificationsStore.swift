//
//  AdminNotificationsStore.swift
//  Rabbit_iOS — 与 Web MessagesDialog 中 adminNotifications / localStorage 对齐。
//

import Foundation

struct AdminNotificationRecord: Codable, Identifiable, Equatable {
    var id: String
    /// payment | order | adopt | cloudAdopt
    var type: String
    var title: String
    var content: String
    var createdAt: Date
    var read: Bool
}

enum AdminNotificationsStore {
    private static let key = "adminNotifications"

    static func load() -> [AdminNotificationRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([AdminNotificationRecord].self, from: data)
        else { return [] }
        return list.sorted { $0.createdAt > $1.createdAt }
    }

    static func save(_ items: [AdminNotificationRecord]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func append(_ item: AdminNotificationRecord) {
        var all = load()
        all.insert(item, at: 0)
        save(all)
    }

    static func markRead(id: String) {
        var all = load()
        guard let i = all.firstIndex(where: { $0.id == id }) else { return }
        all[i].read = true
        save(all)
    }

    /// 用户完成订单支付时，给管理员一条待处理通知（与 Web sendAdminNotification 场景一致）
    static func appendOrderPaymentNotification(title: String, amountDescription: String) {
        let n = AdminNotificationRecord(
            id: "NOTIF\(Int(Date().timeIntervalSince1970 * 1000))",
            type: "payment",
            title: title,
            content: "用户已完成支付：\(amountDescription)。请在管理后台核对收款与发货。",
            createdAt: Date(),
            read: false
        )
        append(n)
    }
}
