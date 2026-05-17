//
//  RescueFeedMedia.swift
//  Rabbit_iOS — 救援 feed 本地图片（与 rabbit_web_new public/images 对齐）
//

import UIKit

enum RescueFeedMedia {
    private static let subdirectory = "Resources/RescueFeed"

    private static let seedLookup: [String: String] = buildSeedLookup()

    /// 从 `/images/Good白.png` 或完整 URL 解析 bundle 内文件名。
    static func bundleFileName(from urlString: String) -> String? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let hit = seedLookup[trimmed] { return hit }
        if trimmed.contains("/images/") {
            return (trimmed as NSString).lastPathComponent
        }
        return nil
    }

    static func uiImage(
        for urlString: String?,
        rescuePostId: String? = nil,
        sourceRabbitId: Int32? = nil
    ) -> UIImage? {
        if let urlString, let name = bundleFileName(from: urlString), let img = load(named: name) {
            return img
        }
        if let rescuePostId, let name = seedLookup[rescuePostId], let img = load(named: name) {
            return img
        }
        if let sourceRabbitId, sourceRabbitId > 0 {
            let key = String(format: "R%03d", sourceRabbitId)
            if let name = seedLookup[key], let img = load(named: name) {
                return img
            }
        }
        return nil
    }

    static func isBundleImagePath(_ urlString: String?) -> Bool {
        guard let urlString else { return false }
        return urlString.contains("/images/")
    }

    private static func load(named fileName: String) -> UIImage? {
        let ns = fileName as NSString
        let stem = ns.deletingPathExtension
        let ext = ns.pathExtension.isEmpty ? nil : ns.pathExtension
        if let url = Bundle.main.url(forResource: stem, withExtension: ext, subdirectory: subdirectory)
            ?? Bundle.main.url(forResource: stem, withExtension: ext),
           let img = UIImage(contentsOfFile: url.path) {
            return img
        }
        return nil
    }

    private static func buildSeedLookup() -> [String: String] {
        guard let url = Bundle.main.url(forResource: "rabbit_seed", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rabbits = try? JSONDecoder().decode([RabbitSeedJSON].self, from: data)
        else { return [:] }

        var map: [String: String] = [:]
        for rabbit in rabbits {
            guard rabbit.photo.contains("/images/") else { continue }
            let localName = (rabbit.photo as NSString).lastPathComponent
            map[rabbit.photo] = localName
            map[String(format: "R%03d", rabbit.id)] = localName
        }
        return map
    }
}
