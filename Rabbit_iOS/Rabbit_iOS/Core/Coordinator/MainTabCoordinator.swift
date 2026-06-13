//
//  MainTabCoordinator.swift
//  Rabbit_iOS — 根 Tab 路由状态（Coordinator 薄层，供后续深链接 / 编程切换 Tab）
//

import Observation

@Observable @MainActor
final class MainTabCoordinator {
    var selectedTab: MainTab = MainTab.prdOrderedTabs.first ?? .rescue
    /// 切换到救援 Tab 后自动打开「我的发布」筛选。
    var openRescueMyPostsOnNextAppear = false

    func select(_ tab: MainTab) {
        selectedTab = tab
    }

    func openMyRescuePosts() {
        openRescueMyPostsOnNextAppear = true
        select(.rescue)
    }
}
