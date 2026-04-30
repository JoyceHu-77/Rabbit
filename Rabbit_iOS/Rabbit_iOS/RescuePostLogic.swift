//
//  RescuePostLogic.swift
//  Rabbit_iOS — 与 RescueTab.tsx 中解析/转换逻辑对齐
//

import Foundation

struct RescueDisplayPost: Identifiable, Equatable, Hashable, Sendable {
    var id: String
    var title: String
    var description: String
    var images: [String]
    var location: String
    var city: String
    var district: String
    var date: String
    var status: String
    var finderName: String?
    var finderContact: String?
    var finderIsPublic: Bool
    var organizerName: String?
    var organizerContact: String?
    var organizerIsPublic: Bool
    var wechatQR: String?
    var healthStatus: String?
    var sterilizedStatus: String?
    var sourceRabbitId: Int32
}

enum RescuePostLogic {
    static func parseChineseDate(_ dateStr: String) -> Date {
        let pattern = #"(\d{4})年(\d{1,2})月(\d{1,2})?日?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: dateStr, range: NSRange(dateStr.startIndex..., in: dateStr)),
              match.numberOfRanges >= 3,
              let yRange = Range(match.range(at: 1), in: dateStr),
              let mRange = Range(match.range(at: 2), in: dateStr)
        else {
            return Date(timeIntervalSince1970: -2_208_988_800)
        }
        let year = Int(dateStr[yRange]) ?? 1900
        let month = Int(dateStr[mRange]) ?? 1
        var day = 1
        if match.numberOfRanges >= 4, let dRange = Range(match.range(at: 3), in: dateStr), dRange.lowerBound != dRange.upperBound {
            day = Int(dateStr[dRange]) ?? 1
        }
        var c = DateComponents()
        c.year = year
        c.month = month
        c.day = day
        return Calendar.current.date(from: c) ?? Date(timeIntervalSince1970: 0)
    }

    nonisolated static func convertRabbitSeed(_ rabbit: RabbitSeedJSON) -> RescueDisplayPost {
        let parts = rabbit.location.split(separator: "-").map(String.init)
        let city = parts.first ?? rabbit.location
        let district = parts.count > 1 ? parts[1] : ""

        let displayAge = AgeCalculator.displayAge(
            registrationDate: rabbit.registrationDate,
            originalAge: rabbit.age,
            status: rabbit.status
        )

        var health: String?
        var steril: String?
        if let desc = rabbit.description {
            let ns = desc as NSString
            let full = NSRange(location: 0, length: ns.length)
            if let re = try? NSRegularExpression(pattern: "健康状况：([^；]+)"),
               let m = re.firstMatch(in: desc, range: full), m.numberOfRanges > 1 {
                health = ns.substring(with: m.range(at: 1))
            }
            if let re = try? NSRegularExpression(pattern: "绝育状态：([^；]+)"),
               let m = re.firstMatch(in: desc, range: full), m.numberOfRanges > 1 {
                steril = ns.substring(with: m.range(at: 1))
            }
        }

        var clean = rabbit.description ?? ""
        for pattern in ["健康状况：[^；]+；?", "绝育状态：[^；]+；?"] {
            if let re = try? NSRegularExpression(pattern: pattern) {
                let r = NSRange(clean.startIndex..., in: clean)
                clean = re.stringByReplacingMatches(in: clean, options: [], range: r, withTemplate: "")
            }
        }
        if let re = try? NSRegularExpression(pattern: #"；\s*$"#) {
            let r = NSRange(clean.startIndex..., in: clean)
            clean = re.stringByReplacingMatches(in: clean, options: [], range: r, withTemplate: "")
        }
        clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)

        let title = rabbit.name.isEmpty ? displayAge : "\(rabbit.name) - \(displayAge)"
        let pid = String(format: "R%03d", rabbit.id)

        return RescueDisplayPost(
            id: pid,
            title: title,
            description: clean,
            images: [rabbit.photo],
            location: rabbit.location,
            city: city,
            district: district,
            date: rabbit.registrationDate,
            status: rabbit.status,
            finderName: rabbit.finder?.name,
            finderContact: rabbit.finder?.contact,
            finderIsPublic: rabbit.finder?.isPublic ?? false,
            organizerName: rabbit.organizer?.name,
            organizerContact: rabbit.organizer?.contact,
            organizerIsPublic: rabbit.organizer?.isPublic ?? false,
            wechatQR: rabbit.wechatQRCode,
            healthStatus: health,
            sterilizedStatus: steril,
            sourceRabbitId: Int32(rabbit.id)
        )
    }

    static func statusFlowNext(_ status: String) -> String? {
        switch status {
        case "待救援": return "救援中"
        case "救援中": return "已救援"
        case "已救援": return "寄养中"
        case "寄养中": return "已领养"
        default: return nil
        }
    }

    static func adminCompleteLabel(for status: String) -> String {
        switch status {
        case "待救援", "救援中": return "救援完成"
        case "已救援": return "寄养完成"
        case "寄养中": return "领养完成"
        default: return ""
        }
    }

    static func completeRequiresWeChatQR(_ status: String) -> Bool {
        ["待救援", "救援中", "已救援"].contains(status)
    }
}
