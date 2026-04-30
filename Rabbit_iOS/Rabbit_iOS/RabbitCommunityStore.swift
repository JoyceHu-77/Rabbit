//
//  RabbitCommunityStore.swift
//  Rabbit_iOS — 与 Web「爱兔社区」localStorage 对齐：UserDefaults 持久化帖子。
//

import Foundation

struct RabbitCommunityPost: Codable, Identifiable, Equatable {
    var id: String
    var authorName: String
    var title: String
    var content: String
    var images: [String]
    var createdAt: Date
    var likes: Int
    var likedByUser: Bool
}

enum RabbitCommunityStore {
    private static let key = "savedRabbitCommunityPosts"

    static func load() -> [RabbitCommunityPost] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let posts = try? JSONDecoder().decode([RabbitCommunityPost].self, from: data)
        else { return [] }
        return posts.sorted { $0.createdAt > $1.createdAt }
    }

    static func save(_ posts: [RabbitCommunityPost]) {
        guard let data = try? JSONEncoder().encode(posts) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func append(_ post: RabbitCommunityPost) {
        var all = load()
        all.insert(post, at: 0)
        save(all)
    }

    static func replaceAll(_ posts: [RabbitCommunityPost]) {
        save(posts)
    }
}
