//
//  UserInboxStore.swift
//  Rabbit_iOS — 用户站内信（收件箱），与 AdminNotificationsStore 对称
//

import Foundation

struct UserInboxRecord: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var body: String
    var createdAt: Date
    var read: Bool
}

enum UserInboxStore {
    private static let key = "userInboxMessages"

    static func load() -> [UserInboxRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([UserInboxRecord].self, from: data)
        else { return seedIfEmpty() }
        return list.sorted { $0.createdAt > $1.createdAt }
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
        []
    }
}
