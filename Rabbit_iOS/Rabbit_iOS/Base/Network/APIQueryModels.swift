//
//  APIQueryModels.swift
//  Rabbit_iOS — 与 GET /v1/rescues、GET /v1/donations 的查询参数约定（均为可选，未传则与旧版无参 GET 行为一致）
//

import Foundation

/// GET `/v1/rescues` 查询参数（snake_case 由 Alamofire/URLQueryItem 传入）。
nonisolated struct RescueListQuery: Equatable, Sendable {
    var page: Int?
    /// 服务端字段名建议：`per_page` 或 `page_size`，此处统一编码为 `per_page`。
    var perPage: Int?
    /// 例如：`date_desc`、`date_asc`、`created_at_desc`（与后端约定其一即可）。
    var sort: String?
    var q: String?
    /// 多个状态用英文逗号拼接，如 `待救援,救援中`。
    var status: String?
    /// 多个区用逗号拼接。
    var district: String?
    /// ISO8601 日期 `yyyy-MM-dd`。
    var dateFrom: String?
    var dateTo: String?
    /// 仅看我发布的帖子：`1` / `0`。
    var mine: Int?
    /// 与发帖人昵称筛选（部分后端用 `publisher_name`）。
    var publisherName: String?

    static let empty = RescueListQuery()

    func queryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let page { items.append(URLQueryItem(name: "page", value: "\(page)")) }
        if let perPage { items.append(URLQueryItem(name: "per_page", value: "\(perPage)")) }
        if let sort, !sort.isEmpty { items.append(URLQueryItem(name: "sort", value: sort)) }
        if let q, !q.isEmpty { items.append(URLQueryItem(name: "q", value: q)) }
        if let status, !status.isEmpty { items.append(URLQueryItem(name: "status", value: status)) }
        if let district, !district.isEmpty { items.append(URLQueryItem(name: "district", value: district)) }
        if let dateFrom, !dateFrom.isEmpty { items.append(URLQueryItem(name: "date_from", value: dateFrom)) }
        if let dateTo, !dateTo.isEmpty { items.append(URLQueryItem(name: "date_to", value: dateTo)) }
        if let mine { items.append(URLQueryItem(name: "mine", value: "\(mine)")) }
        if let publisherName, !publisherName.isEmpty {
            items.append(URLQueryItem(name: "publisher_name", value: publisherName))
        }
        return items
    }
}

/// GET `/v1/donations` 查询参数。
nonisolated struct DonationListQuery: Equatable, Sendable {
    var page: Int?
    var perPage: Int?
    var type: String?
    var target: String?
    var status: String?
    var q: String?

    static let empty = DonationListQuery()

    func queryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let page { items.append(URLQueryItem(name: "page", value: "\(page)")) }
        if let perPage { items.append(URLQueryItem(name: "per_page", value: "\(perPage)")) }
        if let type, !type.isEmpty { items.append(URLQueryItem(name: "type", value: type)) }
        if let target, !target.isEmpty { items.append(URLQueryItem(name: "target", value: target)) }
        if let status, !status.isEmpty { items.append(URLQueryItem(name: "status", value: status)) }
        if let q, !q.isEmpty { items.append(URLQueryItem(name: "q", value: q)) }
        return items
    }
}

/// 分页元信息（若后端仅返回数组，则各字段为 nil）。
struct PaginationMeta: Equatable, Sendable {
    var total: Int?
    var page: Int?
    var perPage: Int?
    var hasMore: Bool?
}

/// 列表拉取结果：帖子 + 可选分页（供后续 UI 使用）。
struct RescuesFetchResult: Sendable {
    let posts: [RescueDisplayPost]
    let meta: PaginationMeta?
}

struct DonationsFetchResult: Sendable {
    let posts: [DonationDisplayPost]
    let meta: PaginationMeta?
}
