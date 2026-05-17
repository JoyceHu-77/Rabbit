//
//  WelcomeGuideOverlay.swift
//  Rabbit_iOS — 登录页与主界面共用的欢迎引导 sheet + 可拖拽悬浮按钮
//

import SwiftUI

/// 新手引导浮动按钮（pt，与 393 设计稿对齐）
enum WelcomeGuideButtonLayout {
    static let side: CGFloat = 50
    static let topInsetFromSafeAreaTop: CGFloat = 0
    static let horizontalInset: CGFloat = 10
    static let bottomInsetAboveTabBar: CGFloat = 8
    static let tabBarHeight: CGFloat = 49
    static let bottomInsetOnLoginScreen: CGFloat = 24
    static let tapDragThreshold: CGFloat = 10
}

/// 悬浮按钮可移动区域（仅右侧贴边，纵向滑动）
struct WelcomeGuideButtonCenterBounds {
    let anchorX: CGFloat
    let minY: CGFloat
    let maxY: CGFloat

    func snapToRightEdge(_ point: CGPoint) -> CGPoint {
        CGPoint(x: anchorX, y: min(max(point.y, minY), maxY))
    }

    func normalizedY(for center: CGPoint) -> Double {
        let rangeY = max(maxY - minY, 1)
        return Double((center.y - minY) / rangeY)
    }

    func center(normalizedY: Double) -> CGPoint {
        let rangeY = maxY - minY
        return CGPoint(x: anchorX, y: minY + CGFloat(normalizedY) * rangeY)
    }
}

private struct WelcomeGuideOverlayModifier: ViewModifier {
    @Environment(AppDataStore.self) private var appData
    let reservesTabBarSpace: Bool

    @State private var showWelcome = false
    @AppStorage("welcomeGuideButtonNormY") private var storedNormY = -1.0
    @State private var dragTranslation: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showWelcome) {
                WelcomeGuideView(isPresented: $showWelcome) {
                    appData.markWelcomeSeen()
                }
                .environment(appData)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(16)
            }
            .overlay {
                GeometryReader { geo in
                    floatingButton(in: geo)
                }
                .allowsHitTesting(true)
            }
            .onAppear {
                evaluateWelcomeVisibility()
            }
    }

    @ViewBuilder
    private func floatingButton(in geo: GeometryProxy) -> some View {
        let bounds = buttonCenterBounds(in: geo)
        let restingCenter = resolvedButtonCenter(bounds: bounds)
        let displayCenter = bounds.snapToRightEdge(
            CGPoint(
                x: restingCenter.x,
                y: restingCenter.y + dragTranslation.height
            )
        )

        welcomeInfoButton
            .frame(width: WelcomeGuideButtonLayout.side, height: WelcomeGuideButtonLayout.side)
            .position(displayCenter)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragTranslation = value.translation
                    }
                    .onEnded { value in
                        let moved = hypot(value.translation.width, value.translation.height)
                        if moved < WelcomeGuideButtonLayout.tapDragThreshold {
                            showWelcome = true
                        } else {
                            let finalCenter = bounds.snapToRightEdge(
                                CGPoint(
                                    x: restingCenter.x,
                                    y: restingCenter.y + value.translation.height
                                )
                            )
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                storedNormY = bounds.normalizedY(for: finalCenter)
                            }
                        }
                        dragTranslation = .zero
                    }
            )
    }

    private func buttonCenterBounds(in geo: GeometryProxy) -> WelcomeGuideButtonCenterBounds {
        let half = WelcomeGuideButtonLayout.side / 2
        let anchorX = geo.size.width - half - WelcomeGuideButtonLayout.horizontalInset
        let minY = geo.safeAreaInsets.top
            + WelcomeGuideButtonLayout.topInsetFromSafeAreaTop
            + half
        let bottomReserved = reservesTabBarSpace
            ? geo.safeAreaInsets.bottom
                + WelcomeGuideButtonLayout.tabBarHeight
                + WelcomeGuideButtonLayout.bottomInsetAboveTabBar
            : geo.safeAreaInsets.bottom + WelcomeGuideButtonLayout.bottomInsetOnLoginScreen
        let maxY = geo.size.height - bottomReserved - half
        return WelcomeGuideButtonCenterBounds(
            anchorX: anchorX,
            minY: minY,
            maxY: max(maxY, minY)
        )
    }

    private func resolvedButtonCenter(bounds: WelcomeGuideButtonCenterBounds) -> CGPoint {
        let normY = storedNormY >= 0 ? storedNormY : 0
        return bounds.center(normalizedY: normY)
    }

    private var welcomeInfoButton: some View {
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
        .frame(width: WelcomeGuideButtonLayout.side, height: WelcomeGuideButtonLayout.side)
        .shadow(color: .black.opacity(0.14), radius: 4, y: 2)
        .contentShape(Rectangle())
        .accessibilityLabel("新手引导")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            showWelcome = true
        }
    }

    private func evaluateWelcomeVisibility() {
        if appData.shouldShowWelcomeModal() {
            showWelcome = true
        }
    }
}

extension View {
    /// 在登录页与主 Tab 之上展示欢迎 sheet 与可拖拽悬浮按钮
    func welcomeGuideOverlay(reservesTabBarSpace: Bool) -> some View {
        modifier(WelcomeGuideOverlayModifier(reservesTabBarSpace: reservesTabBarSpace))
    }
}
