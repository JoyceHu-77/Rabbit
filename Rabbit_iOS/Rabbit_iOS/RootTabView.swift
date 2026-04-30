//
//  RootTabView.swift
//  Rabbit_iOS — App 根视图：Tab + 新手引导悬浮按钮（MVVM：路由由 MainTabCoordinator 持有）
//

import SwiftUI

/// 新手引导浮动按钮（pt，与 393 设计稿对齐）
private enum GuideButtonLayout {
    static let side: CGFloat = 50
    static let topInsetFromSafeAreaTop: CGFloat = 0
    static let trailingOffsetFromScreenRight: CGFloat = -10
}

struct RootTabView: View {
    @State private var appData = AppDataStore()
    @State private var tabCoordinator = MainTabCoordinator()
    @State private var showWelcome = false
    @State private var showWelcomeButton = false

    var body: some View {
        TabView(selection: $tabCoordinator.selectedTab) {
            RescueTabView()
                .tabItem { Label(MainTab.rescue.title, systemImage: MainTab.rescue.systemImage) }
                .tag(MainTab.rescue)

            ActivityTabView()
                .tabItem { Label(MainTab.activity.title, systemImage: MainTab.activity.systemImage) }
                .tag(MainTab.activity)

            AdoptionTabView()
                .tabItem { Label(MainTab.adoption.title, systemImage: MainTab.adoption.systemImage) }
                .tag(MainTab.adoption)

            DonationTabView()
                .tabItem { Label(MainTab.donation.title, systemImage: MainTab.donation.systemImage) }
                .tag(MainTab.donation)

            ProfileTabView()
                .tabItem { Label(MainTab.profile.title, systemImage: MainTab.profile.systemImage) }
                .tag(MainTab.profile)
        }
        .tint(Color(red: 0.86, green: 0.15, blue: 0.15))
        .environment(appData)
        .overlay {
            GeometryReader { geo in
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
                    .overlay {
                        if showWelcomeButton && !showWelcome {
                            welcomeInfoButton
                                .frame(width: GuideButtonLayout.side, height: GuideButtonLayout.side)
                                .position(
                                    x: guideButtonCenterX(width: geo.size.width),
                                    y: guideButtonCenterY(in: geo)
                                )
                        }
                    }
            }
        }
        .sheet(isPresented: $showWelcome) {
            WelcomeGuideView(isPresented: $showWelcome) {
                appData.markWelcomeSeen()
                showWelcomeButton = true
            }
            .environment(appData)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(16)
        }
        .onAppear {
            evaluateWelcomeVisibility()
        }
    }

    private func guideButtonCenterX(width: CGFloat) -> CGFloat {
        let trailingEdgeX = width + GuideButtonLayout.trailingOffsetFromScreenRight
        return trailingEdgeX - GuideButtonLayout.side / 2
    }

    private func guideButtonCenterY(in geo: GeometryProxy) -> CGFloat {
        geo.safeAreaInsets.top + GuideButtonLayout.topInsetFromSafeAreaTop + GuideButtonLayout.side / 2
    }

    private var welcomeInfoButton: some View {
        Button {
            showWelcome = true
            showWelcomeButton = false
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.92), Theme.rose],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(.white)
                if appData.isAdmin {
                    Text("A")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(Color(red: 0.45, green: 0.35, blue: 0.05))
                        .frame(width: 18, height: 18)
                        .background(Color.yellow.opacity(0.95), in: Circle())
                        .offset(x: 17, y: -17)
                }
            }
            .frame(width: GuideButtonLayout.side, height: GuideButtonLayout.side)
            .shadow(color: .black.opacity(0.14), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("新手引导")
    }

    private func evaluateWelcomeVisibility() {
        if appData.shouldShowWelcomeModal() {
            showWelcome = true
            showWelcomeButton = false
        } else {
            showWelcomeButton = true
        }
    }
}
