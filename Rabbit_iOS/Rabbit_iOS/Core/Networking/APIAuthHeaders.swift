//
//  APIAuthHeaders.swift
//  Rabbit_iOS — 可选鉴权头；token 存 UserDefaults，后端就绪后写入即可生效。
//

import Foundation

nonisolated enum APIAuthHeaders {
    /// UserDefaults 键，可与登录接口对接后写入。
    static let tokenUserDefaultsKey = "rabbit_api_access_token"

    static func bearerToken() -> String? {
        let raw = UserDefaults.standard.string(forKey: tokenUserDefaultsKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return raw.isEmpty ? nil : raw
    }

    /// 附加到 Alamofire / URLRequest。
    static func apply(to request: inout URLRequest) {
        guard let t = bearerToken() else { return }
        request.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization")
    }
}
