//
//  RescueDraftStore.swift
//  Rabbit_iOS — 救援发帖草稿（失败或未登录时自动保存）
//

import Foundation

struct RescueDraftPayload: Codable, Equatable {
    var title: String
    var description: String
    var location: String
    var dateText: String
    var finderName: String
    var finderContact: String
    var finderIsPublic: Bool
    var healthStatus: String
    var sterilizedStatus: String
}

enum RescueDraftStore {
    private static let key = "rescueDraftPayload"

    static func save(_ draft: RescueDraftPayload) {
        guard let data = try? JSONEncoder().encode(draft) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func load() -> RescueDraftPayload? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let d = try? JSONDecoder().decode(RescueDraftPayload.self, from: data)
        else { return nil }
        return d
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
