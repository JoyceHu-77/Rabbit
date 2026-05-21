//
//  Theme.swift
//  Rabbit_iOS — 对齐 rabbit_web Tailwind 主色
//

import SwiftUI
import UIKit

enum Theme {
    static let rose = Color(red: 0.89, green: 0.45, blue: 0.58)
    static let red600 = Color(red: 0.86, green: 0.15, blue: 0.15)
    static let redHeader = LinearGradient(
        colors: [Color(red: 0.86, green: 0.15, blue: 0.15), Color(red: 0.88, green: 0.25, blue: 0.42)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let screenBg = LinearGradient(
        colors: [
            Color(red: 1, green: 0.94, blue: 0.94),
            Color(red: 1, green: 0.92, blue: 0.95),
            Color(red: 1, green: 0.94, blue: 0.97),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let tabBarBg = Color.white.opacity(0.95)
}

enum RescueNavBarMetrics {
    static var barHeight: CGFloat {
        let top = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .safeAreaInsets.top ?? 0
        return top + 44
    }
}

enum RescueNavBarStyler {
    @MainActor
    static func gradientImage(width: CGFloat, height: CGFloat) -> UIImage? {
        let content = Theme.redHeader
            .frame(width: max(width, 1), height: max(height, 1))
        let renderer = ImageRenderer(content: content)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    @MainActor
    static func styledAppearance() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.12)
        let width = UIScreen.main.bounds.width
        if let image = gradientImage(width: width, height: RescueNavBarMetrics.barHeight) {
            appearance.backgroundImage = image
        }
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
        ]
        appearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        return appearance
    }

    @MainActor
    static func defaultAppearance() -> UINavigationBarAppearance {
        let a = UINavigationBarAppearance()
        a.configureWithDefaultBackground()
        return a
    }

    @MainActor
    static func apply(to bar: UINavigationBar) {
        let appearance = styledAppearance()
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactAppearance = appearance
        bar.tintColor = .white
    }

    @MainActor
    static func restore(to bar: UINavigationBar) {
        let appearance = defaultAppearance()
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactAppearance = appearance
        bar.tintColor = nil
    }

    @MainActor
    static func restoreVisibleNavigationBar() {
        guard let nav = visibleNavigationController() else { return }
        restore(to: nav.navigationBar)
    }

    @MainActor
    private static func visibleNavigationController() -> UINavigationController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
        return findNavigationController(from: root)
    }

    @MainActor
    private static func findNavigationController(from controller: UIViewController?) -> UINavigationController? {
        if let nav = controller as? UINavigationController { return nav }
        for child in controller?.children ?? [] {
            if let nav = findNavigationController(from: child) { return nav }
        }
        if let presented = controller?.presentedViewController {
            return findNavigationController(from: presented)
        }
        return nil
    }
}

private struct RescueDetailNavBarStyleInjector: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> RescueDetailNavBarStyleController {
        RescueDetailNavBarStyleController()
    }
    func updateUIViewController(_ uiViewController: RescueDetailNavBarStyleController, context: Context) {}
}

private final class RescueDetailNavBarStyleController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let bar = navigationController?.navigationBar else { return }
        RescueNavBarStyler.apply(to: bar)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let bar = navigationController?.navigationBar else { return }
        RescueNavBarStyler.restore(to: bar)
    }
}

extension View {
    /// 救援详情：红色渐变导航栏（与爱兔救援 header 一致），隐藏底 Tab。
    func rescueDetailChrome() -> some View {
        toolbar(.hidden, for: .tabBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .tint(.white)
            .background {
                RescueDetailNavBarStyleInjector()
                    .frame(width: 0, height: 0)
            }
            .onDisappear {
                RescueNavBarStyler.restoreVisibleNavigationBar()
            }
    }
}
