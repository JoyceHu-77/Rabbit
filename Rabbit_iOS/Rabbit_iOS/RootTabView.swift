//
//  RootTabView.swift
//  Rabbit_iOS — App 根视图：Tab + 新手引导悬浮按钮（MVVM：路由由 MainTabCoordinator 持有）
//

import SwiftUI

struct RootTabView: View {
    @Environment(AppDataStore.self) private var appData
    @State private var tabCoordinator = MainTabCoordinator()

    var body: some View {
        TabView(selection: $tabCoordinator.selectedTab) {
            ForEach(TabOrderSettings.orderedTabs(), id: \.self) { tab in
                tabRoot(for: tab)
                    .tabItem { Label(tab.title, systemImage: tab.systemImage) }
                    .tag(tab)
            }
        }
        .id(appData.tabBarConfigurationEpoch)
        .tint(Color(red: 0.86, green: 0.15, blue: 0.15))
        .environment(tabCoordinator)
        .onChange(of: appData.tabBarConfigurationEpoch) { _, _ in
            let tabs = TabOrderSettings.orderedTabs()
            if !tabs.contains(tabCoordinator.selectedTab) {
                tabCoordinator.selectedTab = tabs.first ?? .rescue
            }
        }
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
