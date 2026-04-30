//
//  RabbitSeedModels.swift
//  Rabbit_iOS
//

import Foundation

struct RabbitSeedJSON: Codable {
    let id: Int
    let registrationDate: String
    let name: String
    let gender: String
    let photo: String
    let location: String
    let age: String
    let sterilized: String
    let status: String
    let description: String?
    let finder: PersonSeed?
    let organizer: PersonSeed?
    let wechatQRCode: String?

    struct PersonSeed: Codable {
        let name: String
        let contact: String
        let isPublic: Bool
    }
}
