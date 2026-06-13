//
//  RabbitAPIService+Profile.swift
//  Rabbit_iOS — 个人页接口
//

import Alamofire
import Foundation

extension RabbitAPIService {
    nonisolated static func fetchProfile() async throws -> ProfileSnapshot {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL(),
              let url = URL(string: "\(base)/v1/profile/me")
        else { throw RabbitAPIError.apiBaseNotConfigured }
        let data = try await performProfileDataRequest(url: url, method: "GET")
        let item = try makeJSONDecoder().decode(ProfileAPIItem.self, from: data)
        return item.toSnapshot()
    }

    nonisolated static func patchProfile(_ patch: ProfileSnapshot) async throws -> ProfileSnapshot {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL(),
              let url = URL(string: "\(base)/v1/profile/me")
        else { throw RabbitAPIError.apiBaseNotConfigured }
        let body = ProfilePatchBody(
            userName: patch.userName,
            userBio: patch.userBio,
            badges: patch.badges,
            cloudCoins: patch.cloudCoins,
            isAdmin: patch.isAdmin,
            isLoggedIn: patch.isLoggedIn,
            shippingAddress: patch.shippingAddress
        )
        let data = try await performProfileDataRequest(url: url, method: "PATCH", body: body)
        let item = try makeJSONDecoder().decode(ProfileAPIItem.self, from: data)
        return item.toSnapshot()
    }

    nonisolated static func adjustWallet(badgesDelta: Int, cloudCoinsDelta: Int) async throws -> ProfileSnapshot {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL(),
              let url = URL(string: "\(base)/v1/profile/wallet/adjust")
        else { throw RabbitAPIError.apiBaseNotConfigured }
        let data = try await performProfileDataRequest(
            url: url,
            method: "POST",
            body: WalletAdjustBody(badgesDelta: badgesDelta, cloudCoinsDelta: cloudCoinsDelta)
        )
        let item = try makeJSONDecoder().decode(ProfileAPIItem.self, from: data)
        return item.toSnapshot()
    }

    nonisolated static func fetchProfileInbox() async throws -> [ProfileInboxItem] {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL(),
              let url = URL(string: "\(base)/v1/profile/inbox")
        else { throw RabbitAPIError.apiBaseNotConfigured }
        let data = try await performProfileDataRequest(url: url, method: "GET")
        let items = try makeJSONDecoder().decode([InboxAPIItem].self, from: data)
        return items.map { $0.toDomain() }
    }

    nonisolated static func markProfileInboxRead(messageId: String) async throws {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL() else {
            throw RabbitAPIError.apiBaseNotConfigured
        }
        let idPath = messageId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? messageId
        guard let url = URL(string: "\(base)/v1/profile/inbox/\(idPath)/read") else {
            throw RabbitAPIError.invalidURL
        }
        _ = try await performProfileDataRequest(url: url, method: "POST")
    }

    nonisolated static func fetchAdminNotifications() async throws -> [ProfileAdminNoticeItem] {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL(),
              let url = URL(string: "\(base)/v1/profile/admin-notifications")
        else { throw RabbitAPIError.apiBaseNotConfigured }
        let data = try await performProfileDataRequest(url: url, method: "GET")
        let items = try makeJSONDecoder().decode([AdminNoticeAPIItem].self, from: data)
        return items.map { $0.toDomain() }
    }

    nonisolated static func markAdminNotificationRead(id: String) async throws {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL() else {
            throw RabbitAPIError.apiBaseNotConfigured
        }
        let idPath = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
        guard let url = URL(string: "\(base)/v1/profile/admin-notifications/\(idPath)/read") else {
            throw RabbitAPIError.invalidURL
        }
        _ = try await performProfileDataRequest(url: url, method: "POST")
    }

    nonisolated static func fetchProfileOrders() async throws -> [ProfileOrderItem] {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL(),
              let url = URL(string: "\(base)/v1/profile/orders")
        else { throw RabbitAPIError.apiBaseNotConfigured }
        let data = try await performProfileDataRequest(url: url, method: "GET")
        let items = try makeJSONDecoder().decode([OrderAPIItem].self, from: data)
        return items.map { $0.toDomain() }
    }

    nonisolated static func payProfileOrder(orderId: String) async throws -> OrderPayResult {
        guard let base = RabbitAPIConfiguration.normalizedBaseURL() else {
            throw RabbitAPIError.apiBaseNotConfigured
        }
        let idPath = orderId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? orderId
        guard let url = URL(string: "\(base)/v1/profile/orders/\(idPath)/pay") else {
            throw RabbitAPIError.invalidURL
        }
        let data = try await performProfileDataRequest(url: url, method: "POST")
        let item = try makeJSONDecoder().decode(OrderPayAPIItem.self, from: data)
        return item.toDomain()
    }

    nonisolated private static func performProfileDataRequest(
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
}
