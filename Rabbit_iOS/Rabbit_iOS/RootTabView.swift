//
//  RootTabView.swift
//  Rabbit_iOS — App 根视图：Tab + 新手引导悬浮按钮（MVVM：路由由 MainTabCoordinator 持有）
//

import SwiftUI

struct RootTabView: View {
    @State private var tabCoordinator = MainTabCoordinator()

    var body: some View {
        TabView(selection: $tabCoordinator.selectedTab) {
            ForEach(MainTab.prdOrderedTabs, id: \.self) { tab in
                tabRoot(for: tab)
                    .tabItem { Label(tab.title, systemImage: tab.systemImage) }
                    .tag(tab)
            }
        }
        .tint(Color(red: 0.86, green: 0.15, blue: 0.15))
        .environment(tabCoordinator)
    }

    @ViewBuilder
    private func tabRoot(for tab: MainTab) -> some View {
        switch tab {
        case .rescue: RescueTabView()
        case .activity: ActivityTabView()
        case .adoption: AdoptionTabView()
        case .donation: DonationTabView()
        case .profile: ProfileTabView()
        }
    }
}
