//
//  AgeCalculator.swift
//  Rabbit_iOS — 与 rabbit_web/src/utils/ageCalculator.ts 对齐
//

import Foundation

enum AgeCalculator {
    /// 与 Web 一致：当前时间 2026 年 4 月
    private static let currentYear = 2026
    private static let currentMonth = 4

    static func displayAge(registrationDate: String, originalAge: String, status: String) -> String {
        if status == "已去世" {
            return "再也不会老去的天使👼"
        }
        return calculateCurrentAge(rescueDate: registrationDate, originalAge: originalAge)
    }

    static func calculateCurrentAge(rescueDate: String, originalAge: String) -> String {
        if rescueDate.isEmpty || originalAge.isEmpty || rescueDate == "未知" {
            return originalAge
        }
        let pattern = #"(\d{4})年(\d{1,2})月"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: rescueDate, range: NSRange(rescueDate.startIndex..., in: rescueDate)),
              match.numberOfRanges >= 3,
              let yRange = Range(match.range(at: 1), in: rescueDate),
              let mRange = Range(match.range(at: 2), in: rescueDate),
              let rescueYear = Int(rescueDate[yRange]),
              let rescueMonth = Int(rescueDate[mRange])
        else {
            return originalAge
        }

        let monthsPassed = (currentYear - rescueYear) * 12 + (currentMonth - rescueMonth)
        var totalMonths = 0
        let ns = originalAge as NSString
        let full = NSRange(location: 0, length: ns.length)

        if let re = try? NSRegularExpression(pattern: #"(\d+)岁"#),
           let m = re.firstMatch(in: originalAge, range: full),
           m.numberOfRanges > 1 {
            let y = Int(ns.substring(with: m.range(at: 1))) ?? 0
            totalMonths += y * 12
        }
        if let re = try? NSRegularExpression(pattern: #"(\d+)个月"#),
           let m = re.firstMatch(in: originalAge, range: full),
           m.numberOfRanges > 1 {
            totalMonths += Int(ns.substring(with: m.range(at: 1))) ?? 0
        }

        totalMonths += monthsPassed
        let years = totalMonths / 12
        let months = totalMonths % 12

        if years == 0 {
            return "\(months)个月"
        }
        if months == 0 {
            return "\(years)岁"
        }
        return "\(years)岁\(months)个月"
    }
}
