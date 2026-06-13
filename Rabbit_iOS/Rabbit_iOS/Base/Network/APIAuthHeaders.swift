//
//  APIAuthHeaders.swift
//  Rabbit_iOS — 可选鉴权头；token 存 UserDefaults，后端就绪后写入即可生效。
//

import Foundation

nonisolated enum APIAuthHeaders {
    /// UserDefaults 键，可与登录接口对接后写入。
    static let tokenUserDefaultsKey = "rabbit_api_access_token"
    /// 无正式 token 时，用当前用户昵称作为 Bearer（与后端 `mine`/点赞 viewer 约定一致）。
    static let viewerNameUserDefaultsKey = "rabbit_api_viewer_name"

    static func bearerToken() -> String? {
        let raw = UserDefaults.standard.string(forKey: tokenUserDefaultsKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return raw.isEmpty ? nil : raw
    }

    static func viewerName() -> String? {
        let raw = UserDefaults.standard.string(forKey: viewerNameUserDefaultsKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return raw.isEmpty ? nil : raw
    }

    static func setViewerName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            UserDefaults.standard.removeObject(forKey: viewerNameUserDefaultsKey)
        } else {
            UserDefaults.standard.set(trimmed, forKey: viewerNameUserDefaultsKey)
        }
    }

    /// 附加到 Alamofire / URLRequest。
    static func apply(to request: inout URLRequest) {
        if let t = bearerToken() {
            request.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization")
        } else if let name = viewerName() {
            request.setValue("Bearer \(name)", forHTTPHeaderField: "Authorization")
        }
    }
}
