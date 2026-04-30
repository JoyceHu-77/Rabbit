//
//  RootTabView.swift
//  Rabbit_iOS — 引导按钮：50×50，顶与屏幕 safeArea.top 对齐，右缘相对屏幕 -10pt（略向外）
//

import SwiftUI

/// 与 rabbit_web_new 底部 Tab 顺序一致：救援 → 活动 → 领养 → 捐换 → 个人
private enum MainTab: Int, CaseIterable, Hashable {
    case rescue, activity, adoption, donation, profile

    var title: String {
        switch self {
        case .rescue: return "爱兔救援"
        case .activity: return "爱兔活动"
        case .adoption: return "爱兔领养"
        case .donation: return "物资捐换"
        case .profile: return "个人页"
        }
    }

    var systemImage: String {
        switch self {
        case .rescue: return "heart.fill"
        case .activity: return "calendar"
        case .adoption: return "person.2.fill"
        case .donation: return "shippingbox.fill"
        case .profile: return "person.fill"
        }
    }
}

/// 新手引导浮动按钮（pt，与 393 设计稿对齐）
private enum GuideButtonLayout {
    static let side: CGFloat = 50
    /// 按钮顶边相对「safeArea.top」的额外下移（0 = 顶边与 safeArea 顶对齐）
    static let topInsetFromSafeAreaTop: CGFloat = 0
    /// 距屏幕右缘：-10 表示相对「右对齐 0」再向外 10pt（更贴边 / 略探出）
    static let trailingOffsetFromScreenRight: CGFloat = -10
}

struct RootTabView: View {
    @State private var appData = AppDataStore()
    @State private var tab: MainTab = .rescue
    @State private var showWelcome = false
    @State private var showWelcomeButton = false

    var body: some View {
        TabView(selection: $tab) {
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

    /// 右缘为 `width`，`trailingOffsetFromScreenRight = -10` 时右缘在 `width + 10`，正方形中心 X = 右缘 - side/2
    private func guideButtonCenterX(width: CGFloat) -> CGFloat {
        let trailingEdgeX = width + GuideButtonLayout.trailingOffsetFromScreenRight
        return trailingEdgeX - GuideButtonLayout.side / 2
    }

    /// 顶边与 safeArea.top 对齐：`centerY = safeTop + topInset + side/2`
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
