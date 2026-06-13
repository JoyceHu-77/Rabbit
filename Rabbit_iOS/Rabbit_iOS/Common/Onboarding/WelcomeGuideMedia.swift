//
//  WelcomeGuideMedia.swift
//  Rabbit_iOS — 欢迎引导本地资源（与 rabbit_web_new WelcomeModal 对齐）
//

import UIKit

enum WelcomeGuideMedia {
    enum Asset: String, CaseIterable {
        case welcomeVideo = "welcome_video"
        case badge = "welcome_badge"
        case division = "welcome_division"
        case cooperation1 = "welcome_cooperation_1"
        case cooperation2 = "welcome_cooperation_2"

        var fileExtension: String {
            switch self {
            case .welcomeVideo: "mp4"
            case .badge: "jpeg"
            case .division, .cooperation1, .cooperation2: "jpg"
            }
        }
    }

    private static let subdirectory = "Resources/WelcomeGuide"

    static func url(for asset: Asset) -> URL? {
        if let url = Bundle.main.url(
            forResource: asset.rawValue,
            withExtension: asset.fileExtension,
            subdirectory: subdirectory
        ) {
            return url
        }
        return Bundle.main.url(
            forResource: asset.rawValue,
            withExtension: asset.fileExtension
        )
    }

    static func uiImage(for asset: Asset) -> UIImage? {
        guard let url = url(for: asset) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}
