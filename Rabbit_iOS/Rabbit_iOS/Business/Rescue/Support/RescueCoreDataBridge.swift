//
//  RescueCoreDataBridge.swift
//  Rabbit_iOS
//

import CoreData
import Foundation

enum RescueCoreDataBridge {
    static func imagesFromJSON(_ s: String?) -> [String] {
        guard let data = s?.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [String]
        else { return [] }
        return arr
    }

    static func imagesToJSON(_ urls: [String]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: urls),
              let str = String(data: data, encoding: .utf8)
        else { return "[]" }
        return str
    }

    static func apply(_ post: RescueDisplayPost, to entity: RescuePostEntity) {
        entity.postID = post.id
        entity.title = post.title
        entity.detailText = post.description
        entity.imagesJSON = imagesToJSON(post.images)
        entity.location = post.location
        entity.city = post.city
        entity.district = post.district
        entity.registrationDate = post.date
        entity.status = post.status
        entity.finderName = post.finderName
        entity.finderContact = post.finderContact
        entity.finderIsPublic = post.finderIsPublic
        entity.organizerName = post.organizerName
        entity.organizerContact = post.organizerContact
        entity.organizerIsPublic = post.organizerIsPublic
        entity.wechatQR = post.wechatQR
        entity.healthStatus = post.healthStatus
        entity.sterilizedStatus = post.sterilizedStatus
        entity.sourceRabbitId = post.sourceRabbitId
    }

    static func display(from entity: RescuePostEntity) -> RescueDisplayPost {
        RescueDisplayPost(
            id: entity.postID ?? "",
            title: entity.title ?? "",
            description: entity.detailText ?? "",
            images: imagesFromJSON(entity.imagesJSON),
            location: entity.location ?? "",
            city: entity.city ?? "",
            district: entity.district ?? "",
            date: entity.registrationDate ?? "",
            status: entity.status ?? "寄养中",
            finderName: entity.finderName,
            finderContact: entity.finderContact,
            finderIsPublic: entity.finderIsPublic,
            organizerName: entity.organizerName,
            organizerContact: entity.organizerContact,
            organizerIsPublic: entity.organizerIsPublic,
            wechatQR: entity.wechatQR,
            healthStatus: entity.healthStatus,
            sterilizedStatus: entity.sterilizedStatus,
            sourceRabbitId: entity.sourceRabbitId,
            publisherName: nil,
            moderationStatus: "approved",
            auditRejectionReason: nil
        )
    }
}
