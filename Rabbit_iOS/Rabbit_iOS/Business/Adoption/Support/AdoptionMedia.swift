//
//  AdoptionMedia.swift
//  Rabbit_iOS — 领养模块本地资源（与 rabbit_web_new AdoptionProcess 对齐）
//

import UIKit

enum AdoptionMedia {
    enum Asset: String {
        case giftPackage = "adoption_gift_package"
    }

    private static let subdirectory = "Resources/Adoption"

    static func url(for asset: Asset) -> URL? {
        if let url = Bundle.main.url(
            forResource: asset.rawValue,
            withExtension: "png",
            subdirectory: subdirectory
        ) {
            return url
        }
        return Bundle.main.url(
            forResource: asset.rawValue,
            withExtension: "png"
        )
    }

    static func uiImage(for asset: Asset) -> UIImage? {
        guard let url = url(for: asset) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}
