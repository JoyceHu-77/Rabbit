//
//  ChineseContentValidator.swift
//  Rabbit_iOS — 救援描述、留言等中文与敏感词校验（与 PRD 一致）
//

import Foundation

enum ChineseContentValidator {
    static func validateDescriptionOrComment(_ text: String) -> String? {
        if text.isEmpty { return nil }
        let inappropriate = ["傻逼", "智障", "脑残", "废物", "垃圾", "操", "艹", "他妈", "你妈", "死全家"]
        for w in inappropriate where text.contains(w) { return "请输入文明用语" }
        return nil
    }

    static func validateTitle(_ text: String) -> String? {
        guard !text.isEmpty else { return nil }
        return validateDescriptionOrComment(text)
    }
}
