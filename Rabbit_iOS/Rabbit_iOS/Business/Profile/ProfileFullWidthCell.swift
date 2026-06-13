//
//  ProfileFullWidthCell.swift
//  Rabbit_iOS — 个人页列表/菜单整行可点
//

import SwiftUI

extension View {
    /// 将内容区域扩展为整行命中（用于 ScrollView 内菜单行、List 内自定义行）。
    func profileCellHitArea() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
    }

    /// 整行 Button 包裹（个人页一级菜单等）。
    func profileFullWidthCellTap(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            self.profileCellHitArea()
        }
        .buttonStyle(.plain)
    }
}
