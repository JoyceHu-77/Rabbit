//
//  AppRootView.swift
//  Rabbit_iOS — 登录门控 + 主界面
//

import SwiftUI

struct AppRootView: View {
    @State private var appData = AppDataStore()

    var body: some View {
        Group {
            if appData.isLoggedIn {
                RootTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appData.isLoggedIn)
        .welcomeGuideOverlay(reservesTabBarSpace: appData.isLoggedIn)
        .environment(appData)
    }
}

#Preview("已登录") {
    AppRootView()
}
