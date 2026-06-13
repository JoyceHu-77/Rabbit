//
//  ProfileNavigation.swift
//  Rabbit_iOS — 个人页一级入口路由（Push，避免 Sheet 内嵌导航失效）
//

import SwiftUI

enum ProfileRoute: Hashable {
    case messages
    case orders
    case myPosts
    case address
    case chat
    case profileEdit
}
