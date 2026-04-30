//
//  RabbitAPIService.swift
//  Rabbit_iOS — 使用 Alamofire 拉取列表数据；失败时使用 Bundle 种子与本地 mock。
//
//  约定（与后端对齐）：
//  - GET  {base}/v1/rescues   → 纯 JSON 数组，或 `{ data|items|rescues|results, meta? }`；元素与 RescueAPIItem 一致（支持 snake_case）。
//  - GET  {base}/v1/donations → 同上，元素与 DonationAPIItem 一致。
//  - POST {base}/v1/rescues   → 请求体 RescueCreateBody（JSON）；成功 200/201，响应体为单条对象（同 GET 元素）。
//  - PATCH {base}/v1/rescues/{id} → 请求体同 RescueCreateBody；响应单条对象。
//  - POST {base}/v1/donations → 请求体 DonationCreateBody（JSON）；成功 200/201，响应体为单条 DonationAPIItem。
//  - 可选：Authorization: Bearer <token>（见 APIAuthHeaders）。
//

import Alamofire
import Foundation

enum RabbitAPIError: Error, LocalizedError {
    case apiBaseNotConfigured
    case invalidURL
    case serverMessage(String)

    var errorDescription: String? {
        switch self {
        case .apiBaseNotConfigured:
            return "未配置 RABBIT_API_BASE_URL"
        case .invalidURL:
            return "接口地址无效"
        case .serverMessage(let s):
            return s
        }
    }
}

enum RabbitAPIConfiguration {
    /// Info.plist 中 `RABBIT_API_BASE_URL`，须为 `http(s)://` 开头；留空或非法则直接使用本地回退数据。
    nonisolated static var baseURLString: String {
        (Bundle.main.object(forInfoDictionaryKey: "RABBIT_API_BASE_URL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    nonisolated static func normalizedBaseURL() -> String? {
        var b = baseURLString
        guard b.hasPrefix("http") else { return nil }
        while b.hasSuffix("/") { b.removeLast() }
        return b.isEmpty ? nil : b
    }
}

nonisolated private struct RescueAPIItem: Decodable, Sendable {
    let id: String
    let title: String
    let description: String
    let images: [String]
    let location: String
    let city: String
    let district: String
    let date: String
    let status: String
    let finderName: String?
    let finderContact: String?
    let finderIsPublic: Bool?
    let organizerName: String?
    let organizerContact: String?
    let organizerIsPublic: Bool?
    let wechatQR: String?
    let healthStatus: String?
    let sterilizedStatus: String?
    let sourceRabbitId: Int?
    let publisherName: String?
    let moderationStatus: String?
    let auditRejectionReason: String?

    nonisolated func toDisplay() -> RescueDisplayPost {
        RescueDisplayPost(
            id: id,
            title: title,
            description: description,
            images: images,
            location: location,
            city: city,
            district: district,
            date: date,
            status: status,
            finderName: finderName,
            finderContact: finderContact,
            finderIsPublic: finderIsPublic ?? false,
            organizerName: organizerName,
            organizerContact: organizerContact,
            organizerIsPublic: organizerIsPublic ?? false,
            wechatQR: wechatQR,
            healthStatus: healthStatus,
            sterilizedStatus: sterilizedStatus,
            sourceRabbitId: Int32(sourceRabbitId ?? 0),
            publisherName: publisherName,
            moderationStatus: moderationStatus ?? "approved",
            auditRejectionReason: auditRejectionReason
        )
    }
}

/// POST /v1/rescues 的请求体（编码为 JSON；`keyEncodingStrategy = convertToSnakeCase`）。
nonisolated private struct RescueCreateBody: Encodable, Sendable {
    let id: String
    let title: String
    let description: String
    let images: [String]
    let location: String
    let city: String
    let district: String
    let date: String
    let status: String
    let finderName: String?
    let finderContact: String?
    let finderIsPublic: Bool
    let organizerName: String?
    let organizerContact: String?
    let organizerIsPublic: Bool
    let wechatQR: String?
    let healthStatus: String?
    let sterilizedStatus: String?
    let sourceRabbitId: Int
    let publisherName: String?
    let moderationStatus: String
    let auditRejectionReason: String?

    nonisolated init(from post: RescueDisplayPost) {
        id = post.id
        title = post.title
        description = post.description
        images = post.images
        location = post.location
        city = post.city
        district = post.district
        date = post.date
        status = post.status
        finderName = post.finderName
        finderContact = post.finderContact
        finderIsPublic = post.finderIsPublic
        organizerName = post.organizerName
        organizerContact = post.organizerContact
        organizerIsPublic = post.organizerIsPublic
        wechatQR = post.wechatQR
        healthStatus = post.healthStatus
        sterilizedStatus = post.sterilizedStatus
        sourceRabbitId = Int(post.sourceRabbitId)
        publisherName = post.publisherName
        moderationStatus = post.moderationStatus
        auditRejectionReason = post.auditRejectionReason
    }
}

/// POST /v1/donations 的请求体（服务端可返回 id、status、date）。
nonisolated private struct DonationCreateBody: Encodable, Sendable {
    let title: String
    let description: String
    let image: String
    let type: String
    let target: String
    let contactName: String
    let contactPhone: String

    nonisolated init(from draft: DonationDraft) {
        title = draft.title
        description = draft.description
        image = draft.imageURL
        type = draft.type
        target = draft.target
        contactName = draft.contactName
        contactPhone = draft.contactPhone
    }
}

nonisolated private struct DonationAPIItem: Decodable, Sendable {
    let id: String
    let title: String
    let description: String
    let image: String
    let type: String
    let target: String
    let status: String
    let contactName: String
    let contactPhone: String
    let date: String

    nonisolated func toDisplay() -> DonationDisplayPost {
        DonationDisplayPost(
            id: id,
            title: title,
            description: description,
            image: image,
            type: type,
            target: target,
            status: status,
            contactName: contactName,
            contactPhone: contactPhone,
            date: date
        )
    }
}

nonisolated enum RabbitAPIService {
    private nonisolated static func makeJSONDecoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }

    private nonisolated static func makeJSONEncoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }

    private nonisolated struct PaginationMetaDecoder: Decodable, Sendable {
        let total: Int?
        let page: Int?
        let perPage: Int?
        let hasMore: Bool?
    }

    private nonisolated static func decodeRescueList(_ data: Data) throws -> RescuesFetchResult {
        let dec = makeJSONDecoder()
        if let arr = try? dec.decode([RescueAPIItem].self, from: data) {
            return RescuesFetchResult(posts: arr.map { $0.toDisplay() }, meta: nil)
        }
        struct Envelope: Decodable {
            let data: [RescueAPIItem]?
            let items: [RescueAPIItem]?
            let rescues: [RescueAPIItem]?
            let results: [RescueAPIItem]?
            let meta: PaginationMetaDecoder?
        }
        let env = try dec.decode(Envelope.self, from: data)
        let raw = env.data ?? env.items ?? env.rescues ?? env.results ?? []
        let meta = env.meta.map {
            PaginationMeta(total: $0.total, page: $0.page, perPage: $0.perPage, hasMore: $0.hasMore)
        }
        return RescuesFetchResult(posts: raw.map { $0.toDisplay() }, meta: meta)
    }

    private nonisolated static func decodeDonationList(_ data: Data) throws -> DonationsFetchResult {
        let dec = makeJSONDecoder()
        if let arr = try? dec.decode([DonationAPIItem].self, from: data) {
            return DonationsFetchResult(posts: arr.map { $0.toDisplay() }, meta: nil)
        }
        struct Envelope: Decodable {
            let data: [DonationAPIItem]?
            let items: [DonationAPIItem]?
            let donations: [DonationAPIItem]?
            let results: [DonationAPIItem]?
            let meta: PaginationMetaDecoder?
        }
        let env = try dec.decode(Envelope.self, from: data)
        let raw = env.data ?? env.items ?? env.donations ?? env.results ?? []
        let meta = env.meta.map {
            PaginationMeta(total: $0.total, page: $0.page, perPage: $0.perPage, hasMore: $0.hasMore)
        }
        return DonationsFetchResult(posts: raw.map { $0.toDisplay() }, meta: meta)
    }

    /// 从接口获取救援列表；`query` 为 nil 时与旧版无参 GET 一致；失败时回退种子数据。
    nonisolated static func fetchRescues(query: RescueListQuery? = nil) async -> RescuesFetchResult {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL() else {
            return RescuesFetchResult(posts: fallbackRescuePosts(), meta: nil)
        }
        var components = URLComponents(string: "\(base)/v1/rescues")
        let q = query?.queryItems() ?? []
        if !q.isEmpty { components?.queryItems = q }
        guard let url = components?.url else {
            return RescuesFetchResult(posts: fallbackRescuePosts(), meta: nil)
        }
        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 12
            APIAuthHeaders.apply(to: &req)
            let data = try await AF.request(req)
                .validate(statusCode: 200 ..< 300)
                .serializingData()
                .value
            return try decodeRescueList(data)
        } catch {
            return RescuesFetchResult(posts: fallbackRescuePosts(), meta: nil)
        }
    }

    /// 从接口获取捐换列表；失败时使用内置 mock。
    nonisolated static func fetchDonations(query: DonationListQuery? = nil) async -> DonationsFetchResult {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL() else {
            return DonationsFetchResult(posts: fallbackDonationPosts(), meta: nil)
        }
        var components = URLComponents(string: "\(base)/v1/donations")
        let q = query?.queryItems() ?? []
        if !q.isEmpty { components?.queryItems = q }
        guard let url = components?.url else {
            return DonationsFetchResult(posts: fallbackDonationPosts(), meta: nil)
        }
        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 12
            APIAuthHeaders.apply(to: &req)
            let data = try await AF.request(req)
                .validate(statusCode: 200 ..< 300)
                .serializingData()
                .value
            return try decodeDonationList(data)
        } catch {
            return DonationsFetchResult(posts: fallbackDonationPosts(), meta: nil)
        }
    }

    nonisolated static func fallbackRescuePosts() -> [RescueDisplayPost] {
        guard let url = Bundle.main.url(forResource: "rabbit_seed", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rabbits = try? JSONDecoder().decode([RabbitSeedJSON].self, from: data)
        else { return [] }
        return rabbits.map { RescuePostLogic.convertRabbitSeed($0) }
    }

    nonisolated static func fallbackDonationPosts() -> [DonationDisplayPost] {
        [
            DonationDisplayPost(id: "D001", title: "兔粮500g × 3包", description: "多买了几包兔粮，家里兔兔吃不完，希望能帮助到需要的兔兔", image: "https://images.unsplash.com/photo-1578164252938-1da0cd4caa30?w=400", type: "捐赠", target: "共享", status: "待领取", contactName: "李女士", contactPhone: "138****1234", date: "2026-04-10"),
            DonationDisplayPost(id: "D002", title: "兔笼 + 饮水器", description: "九成新兔笼，配饮水器和食盆，可置换其他用品或捐赠", image: "https://images.unsplash.com/photo-1695826809879-6bc04b19e56d?w=400", type: "置换", target: "共享", status: "待领取", contactName: "王先生", contactPhone: "139****5678", date: "2026-04-09"),
            DonationDisplayPost(id: "D003", title: "干草 2kg", description: "指定捐赠给爱兔会，用于救助兔兔", image: "https://images.unsplash.com/photo-1695826809742-b3e2e7483efd?w=400", type: "捐赠", target: "爱兔会", status: "已完成", contactName: "张女士", contactPhone: "136****9012", date: "2026-04-08"),
            DonationDisplayPost(id: "D004", title: "兔兔玩具套装", description: "咬咬球、草编玩具等，家里兔兔不喜欢，可以置换其他玩具", image: "https://images.unsplash.com/photo-1564326140-fa771b2c0c5d?w=400", type: "置换", target: "共享", status: "待领取", contactName: "陈女士", contactPhone: "137****3456", date: "2026-04-07"),
        ]
    }

    /// 创建救援帖；需已配置 `RABBIT_API_BASE_URL`。
    nonisolated static func createRescue(_ post: RescueDisplayPost) async throws -> RescueDisplayPost {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL(),
              let url = URL(string: "\(base)/v1/rescues")
        else { throw RabbitAPIError.apiBaseNotConfigured }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30
        APIAuthHeaders.apply(to: &req)
        let body = RescueCreateBody(from: post)
        req.httpBody = try makeJSONEncoder().encode(body)

        let data = try await AF.request(req)
            .validate(statusCode: 200 ..< 300)
            .serializingData()
            .value
        do {
            let item = try makeJSONDecoder().decode(RescueAPIItem.self, from: data)
            return item.toDisplay()
        } catch {
            let snippet = String(data: data.prefix(200), encoding: .utf8) ?? ""
            throw RabbitAPIError.serverMessage("无法解析创建救援的响应：\(snippet)")
        }
    }

    /// 更新救援帖 `PATCH /v1/rescues/{id}`；需已配置 `RABBIT_API_BASE_URL`。
    nonisolated static func updateRescue(_ post: RescueDisplayPost) async throws -> RescueDisplayPost {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL() else {
            throw RabbitAPIError.apiBaseNotConfigured
        }
        let idPath = post.id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? post.id
        guard let url = URL(string: "\(base)/v1/rescues/\(idPath)") else {
            throw RabbitAPIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30
        APIAuthHeaders.apply(to: &req)
        req.httpBody = try makeJSONEncoder().encode(RescueCreateBody(from: post))
        let data = try await AF.request(req)
            .validate(statusCode: 200 ..< 300)
            .serializingData()
            .value
        do {
            let item = try makeJSONDecoder().decode(RescueAPIItem.self, from: data)
            return item.toDisplay()
        } catch {
            let snippet = String(data: data.prefix(200), encoding: .utf8) ?? ""
            throw RabbitAPIError.serverMessage("无法解析更新救援的响应：\(snippet)")
        }
    }

    /// 创建捐换帖；需已配置 `RABBIT_API_BASE_URL`。
    nonisolated static func createDonation(_ draft: DonationDraft) async throws -> DonationDisplayPost {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL(),
              let url = URL(string: "\(base)/v1/donations")
        else { throw RabbitAPIError.apiBaseNotConfigured }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30
        APIAuthHeaders.apply(to: &req)
        let body = DonationCreateBody(from: draft)
        req.httpBody = try makeJSONEncoder().encode(body)

        let data = try await AF.request(req)
            .validate(statusCode: 200 ..< 300)
            .serializingData()
            .value
        do {
            let item = try makeJSONDecoder().decode(DonationAPIItem.self, from: data)
            return item.toDisplay()
        } catch {
            let snippet = String(data: data.prefix(200), encoding: .utf8) ?? ""
            throw RabbitAPIError.serverMessage("无法解析创建捐换的响应：\(snippet)")
        }
    }
}
