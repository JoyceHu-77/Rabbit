//
//  RabbitAPIService+AdoptionActivity.swift
//  Rabbit_iOS — 领养 / 活动 Tab 接口（无 Base URL 时回退本地种子）
//

import Alamofire
import Foundation

extension RabbitAPIService {
    // MARK: - 活动

    nonisolated static func fetchActivityBanners() async -> [ActivityBannerItem] {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL(),
              let url = URL(string: "\(base)/v1/activity/banners")
        else { return ActivityBannerItem.fallbackDefaults }
        do {
            let data = try await performDataRequest(url: url, method: "GET")
            let items = try makeJSONDecoder().decode([ActivityBannerAPIItem].self, from: data)
            let mapped = items.map { $0.toDomain() }.sorted { $0.sortOrder < $1.sortOrder }
            return mapped.isEmpty ? ActivityBannerItem.fallbackDefaults : mapped
        } catch {
            return ActivityBannerItem.fallbackDefaults
        }
    }

    nonisolated static func fetchOfflineEvents(isPast: Bool?) async -> [OfflineEventItem] {
        let fallback = isPast == true
            ? OfflineEventItem.fallbackPast
            : (isPast == false ? OfflineEventItem.fallbackUpcoming : OfflineEventItem.fallbackPast + OfflineEventItem.fallbackUpcoming)
        guard let base = RabbitAPIConfiguration.normalizedBaseURL() else { return fallback }
        var components = URLComponents(string: "\(base)/v1/activity/offline-events")
        if let isPast {
            components?.queryItems = [URLQueryItem(name: "is_past", value: isPast ? "true" : "false")]
        }
        guard let url = components?.url else { return fallback }
        do {
            let data = try await performDataRequest(url: url, method: "GET")
            let items = try decodeArrayOrEnvelope(OfflineEventAPIItem.self, from: data)
            let mapped = items.map { $0.toDomain() }
            return mapped.isEmpty ? fallback : mapped
        } catch {
            return fallback
        }
    }

    nonisolated static func createOfflineEvent(
        title: String,
        date: String,
        location: String,
        description: String
    ) async throws -> OfflineEventItem {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL(),
              let url = URL(string: "\(base)/v1/activity/offline-events")
        else { throw RabbitAPIError.apiBaseNotConfigured }
        struct Body: Encodable {
            let title: String
            let date: String
            let location: String
            let description: String
            let isPast: Bool = false
        }
        let data = try await performDataRequest(
            url: url,
            method: "POST",
            body: Body(title: title, date: date, location: location, description: description)
        )
        let item = try makeJSONDecoder().decode(OfflineEventAPIItem.self, from: data)
        return item.toDomain()
    }

    nonisolated static func fetchCharityProducts() async -> [CharityShopProductItem] {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL(),
              let url = URL(string: "\(base)/v1/activity/charity/products")
        else { return charityProductsFromLocalRescues() }
        do {
            let data = try await performDataRequest(url: url, method: "GET")
            let items = try makeJSONDecoder().decode([CharityProductAPIItem].self, from: data)
            let mapped = items.map { $0.toDomain() }
            return mapped.isEmpty ? charityProductsFromLocalRescues() : mapped
        } catch {
            return charityProductsFromLocalRescues()
        }
    }

    nonisolated static func confirmCloudAdopt(rescueId: String, amountYuan: Int) async throws -> CloudAdoptConfirmResult {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL(),
              let url = URL(string: "\(base)/v1/activity/cloud-adopt/confirm")
        else { throw RabbitAPIError.apiBaseNotConfigured }
        struct Body: Encodable {
            let rescueId: String
            let amountYuan: Int
        }
        let data = try await performDataRequest(
            url: url,
            method: "POST",
            body: Body(rescueId: rescueId, amountYuan: amountYuan)
        )
        let out = try makeJSONDecoder().decode(CloudAdoptConfirmAPIItem.self, from: data)
        return CloudAdoptConfirmResult(
            rescueId: out.rescueId,
            amountYuan: out.amountYuan,
            cloudCoinsGranted: out.cloudCoinsGranted,
            profile: out.profile?.toSnapshot()
        )
    }

    // MARK: - 领养

    nonisolated static func createAdoptionIntent(_ draft: AdoptionIntentDraft) async throws {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL(),
              let url = URL(string: "\(base)/v1/adoption/intents")
        else { throw RabbitAPIError.apiBaseNotConfigured }
        struct Body: Encodable {
            let rescueId: String
            let applicantName: String
            let applicantPhone: String
            let note: String?
        }
        _ = try await performDataRequest(
            url: url,
            method: "POST",
            body: Body(
                rescueId: draft.rescueId,
                applicantName: draft.applicantName,
                applicantPhone: draft.applicantPhone,
                note: draft.note
            )
        )
    }

    nonisolated static func fetchCommunityPosts() async -> [RabbitCommunityPost] {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL(),
              let url = URL(string: "\(base)/v1/adoption/community/posts")
        else { return RabbitCommunityStore.load() }
        do {
            let data = try await performDataRequest(url: url, method: "GET")
            let items = try decodeArrayOrEnvelope(CommunityPostAPIItem.self, from: data)
            return items.map { $0.toDomain() }
        } catch {
            return RabbitCommunityStore.load()
        }
    }

    nonisolated static func createCommunityPost(_ draft: CommunityPostDraft) async throws -> RabbitCommunityPost {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL(),
              let url = URL(string: "\(base)/v1/adoption/community/posts")
        else { throw RabbitAPIError.apiBaseNotConfigured }
        struct Body: Encodable {
            let authorName: String
            let title: String
            let content: String
            let images: [String]
        }
        let data = try await performDataRequest(
            url: url,
            method: "POST",
            body: Body(
                authorName: draft.authorName,
                title: draft.title,
                content: draft.content,
                images: draft.images
            )
        )
        let item = try makeJSONDecoder().decode(CommunityPostAPIItem.self, from: data)
        return item.toDomain()
    }

    nonisolated static func deleteCommunityPost(id: String) async throws {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL() else {
            throw RabbitAPIError.apiBaseNotConfigured
        }
        let idPath = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
        guard let url = URL(string: "\(base)/v1/adoption/community/posts/\(idPath)") else {
            throw RabbitAPIError.invalidURL
        }
        _ = try await performDataRequest(url: url, method: "DELETE")
    }

    nonisolated static func toggleCommunityPostLike(id: String) async throws -> RabbitCommunityPost {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL() else {
            throw RabbitAPIError.apiBaseNotConfigured
        }
        let idPath = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
        guard let url = URL(string: "\(base)/v1/adoption/community/posts/\(idPath)/like") else {
            throw RabbitAPIError.invalidURL
        }
        let data = try await performDataRequest(url: url, method: "POST")
        let item = try makeJSONDecoder().decode(CommunityPostAPIItem.self, from: data)
        return item.toDomain()
    }

    // MARK: - 内部

    nonisolated private static func charityProductsFromLocalRescues() -> [CharityShopProductItem] {
        fallbackRescuePosts()
            .filter { $0.status != "已去世" && $0.status != "已领养" }
            .map { r in
                let name = rabbitShortName(from: r.title)
                return CharityShopProductItem(
                    id: r.id,
                    title: "\(name)的电子照片",
                    rabbitName: name,
                    image: r.images.first ?? "",
                    description: "云养\(name)兔兔的一点心意，用于粮草、医疗与生活支出。",
                    price: 5,
                    badges: 1,
                    cloudCoins: 5
                )
            }
    }

    nonisolated private static func rabbitShortName(from title: String) -> String {
        if let range = title.range(of: " - ") {
            return String(title[..<range.lowerBound])
        }
        return title
    }

    nonisolated private static func performDataRequest(
        url: URL,
        method: String,
        body: (any Encodable)? = nil
    ) async throws -> Data {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = 20
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try makeJSONEncoder().encode(body)
        }
        APIAuthHeaders.apply(to: &req)
        let response = await AF.request(req)
            .validate(statusCode: 200 ..< 300)
            .serializingData(emptyResponseCodes: [200, 201, 204])
            .response
        if let error = response.error {
            throw error
        }
        return response.data ?? Data()
    }

    nonisolated private static func decodeArrayOrEnvelope<T: Decodable>(
        _ type: T.Type,
        from data: Data
    ) throws -> [T] {
        let dec = makeJSONDecoder()
        if let arr = try? dec.decode([T].self, from: data) {
            return arr
        }
        let env = try dec.decode(APIListEnvelope<T>.self, from: data)
        return env.data ?? env.items ?? env.results ?? []
    }
}

nonisolated private struct APIListEnvelope<T: Decodable>: Decodable {
    let data: [T]?
    let items: [T]?
    let results: [T]?
}

// MARK: - API DTO

nonisolated private struct ActivityBannerAPIItem: Decodable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let imageUrl: String?
    let imageURL: String?
    let sortOrder: Int
    let targetKey: String

    nonisolated func toDomain() -> ActivityBannerItem {
        ActivityBannerItem(
            id: id,
            title: title,
            subtitle: subtitle,
            imageURL: imageUrl ?? imageURL ?? "",
            sortOrder: sortOrder,
            targetKey: targetKey
        )
    }
}

nonisolated private struct OfflineEventAPIItem: Decodable, Sendable {
    let id: String
    let title: String
    let date: String
    let location: String
    let imageUrl: String?
    let imageURL: String?
    let bannerUrl: String?
    let bannerURL: String?
    let description: String
    let isPast: Bool

    nonisolated func toDomain() -> OfflineEventItem {
        OfflineEventItem(
            id: id,
            title: title,
            date: date,
            location: location,
            imageURL: imageUrl ?? imageURL ?? "",
            bannerURL: bannerUrl ?? bannerURL,
            description: description,
            isPast: isPast
        )
    }
}

nonisolated private struct CharityProductAPIItem: Decodable, Sendable {
    let id: String
    let title: String
    let rabbitName: String
    let image: String
    let description: String
    let price: Int
    let badges: Int
    let cloudCoins: Int

    nonisolated func toDomain() -> CharityShopProductItem {
        CharityShopProductItem(
            id: id,
            title: title,
            rabbitName: rabbitName,
            image: image,
            description: description,
            price: price,
            badges: badges,
            cloudCoins: cloudCoins
        )
    }
}

nonisolated private struct CloudAdoptConfirmAPIItem: Decodable, Sendable {
    let rescueId: String
    let amountYuan: Int
    let cloudCoinsGranted: Int
    let profile: ProfileAPIItem?
}

nonisolated private struct CommunityPostAPIItem: Decodable, Sendable {
    let id: String
    let authorName: String
    let title: String
    let content: String
    let images: [String]
    let createdAt: Date
    let likes: Int
    let likedByUser: Bool

    nonisolated func toDomain() -> RabbitCommunityPost {
        RabbitCommunityPost(
            id: id,
            authorName: authorName,
            title: title,
            content: content,
            images: images,
            createdAt: createdAt,
            likes: likes,
            likedByUser: likedByUser
        )
    }
}
