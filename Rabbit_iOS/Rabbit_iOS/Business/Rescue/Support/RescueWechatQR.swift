//
//  RescueWechatQR.swift
//  Rabbit_iOS — 微信群二维码编解码（与 rabbit_web_new data URL 对齐）
//

import UIKit

enum RescueWechatQR {
    static let statusFollowSubtitle =
        "您可扫描下方二维码去到微信群查看兔兔最新状态、财务公示或进行物资捐赠、捐款"

    static func dataURL(from imageData: Data, mimeType: String = "image/jpeg") -> String {
        "data:\(mimeType);base64,\(imageData.base64EncodedString())"
    }

    static func uiImage(from stored: String?) -> UIImage? {
        guard let stored else { return nil }
        let s = stored.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }

        if s.hasPrefix("data:"), let comma = s.firstIndex(of: ",") {
            let payload = String(s[s.index(after: comma)...])
            if let data = Data(base64Encoded: payload, options: .ignoreUnknownCharacters) {
                return UIImage(data: data)
            }
            return nil
        }
        if s.hasPrefix("file://"), let url = URL(string: s) {
            return UIImage(contentsOfFile: url.path)
        }
        return nil
    }

    static func hasDisplayableQR(_ stored: String?) -> Bool {
        guard let stored else { return false }
        let s = stored.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return false }
        if uiImage(from: s) != nil { return true }
        return s.hasPrefix("http://") || s.hasPrefix("https://")
    }
}
