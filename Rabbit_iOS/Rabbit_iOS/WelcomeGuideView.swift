//
//  WelcomeGuideView.swift
//  Rabbit_iOS — 以 sheet 呈现，符合 iOS 大卡片/可下滑关闭习惯（393 基准宽度）
//

import SwiftUI

private struct WelcomeStep: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let highlights: [String]
    let canZoom: Bool
    let systemImage: String
}

private let welcomeSteps: [WelcomeStep] = [
    WelcomeStep(
        title: "🐰 欢迎来到爱兔会",
        content: "上海爱兔会是一个致力于流浪兔救助、保护和领养的公益组织。我们相信每一只兔兔都值得被爱，都应该拥有温暖的家。",
        highlights: [
            "🏥 专业医疗：与多家宠物医院合作",
            "🏡 寄养网络：提供温暖的临时家园",
            "💝 科学领养：严格筛选，负责到底",
            "📢 科普宣传：传播正确养兔知识",
        ],
        canZoom: false,
        systemImage: "hare.fill"
    ),
    WelcomeStep(
        title: "👥 组内成员分工",
        content: "我们的团队专业而有爱，每个小组都在为兔兔的幸福而努力。从救助到领养，我们提供全流程的专业服务。点击图片可放大查看详情。",
        highlights: [
            "救助侧：现场救援、医疗协调、资源统筹、寄养安顿",
            "财务侧：救助兔兔、义卖",
            "领养侧：领养审核、家庭回访、档案管理",
            "宣传侧：新媒体运营、内容创作",
        ],
        canZoom: true,
        systemImage: "person.3.fill"
    ),
    WelcomeStep(
        title: "🤝 合作伙伴",
        content: "感谢我们的合作伙伴提供医疗支持、宠物用品和专业咨询。共同为兔兔的福祉而努力！点击图片可放大查看，左右滑动查看更多。",
        highlights: [
            "🏥 诺瓦宠物医院：提供优惠医疗服务",
            "🏥 河畔流浪动物体检福利",
            "🏥 内博虎流浪动物体检福利",
            "💼 多家合作机构：资源共享与互助",
        ],
        canZoom: true,
        systemImage: "heart.rectangle.fill"
    ),
]

struct WelcomeGuideView: View {
    @Binding var isPresented: Bool
    let onFinish: () -> Void

    @State private var stepIndex = 0
    @State private var zoomed = false

    private var step: WelcomeStep { welcomeSteps[stepIndex] }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let contentMax = min(geo.size.width - 32, LayoutMetrics.referenceWidth - 32)
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                            Image(systemName: step.systemImage)
                                .font(.system(size: 64))
                                .foregroundStyle(
                                    LinearGradient(colors: [.red.opacity(0.85), Theme.rose], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .padding(32)
                        }
                        .frame(maxWidth: contentMax)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(4 / 3, contentMode: .fit)
                        .onTapGesture {
                            if step.canZoom { zoomed = true }
                        }
                        .overlay(alignment: .bottomTrailing) {
                            if step.canZoom {
                                Label("点击放大", systemImage: "plus.magnifyingglass")
                                    .font(.caption2)
                                    .padding(6)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .padding(8)
                            }
                        }

                        Text(step.title)
                            .font(.title3.bold())
                            .foregroundStyle(.primary)

                        Text(step.content)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: contentMax, alignment: .leading)

                        ForEach(Array(step.highlights.enumerated()), id: \.offset) { _, h in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(Color.red.opacity(0.65))
                                    .frame(width: 5, height: 5)
                                    .padding(.top, 7)
                                Text(h)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }

                        HStack {
                            HStack(spacing: 6) {
                                ForEach(0 ..< welcomeSteps.count, id: \.self) { i in
                                    Capsule()
                                        .fill(i == stepIndex ? Color.accentColor : Color.secondary.opacity(0.25))
                                        .frame(width: i == stepIndex ? 24 : 6, height: 6)
                                }
                            }
                            Spacer(minLength: 8)
                            HStack(spacing: 10) {
                                if stepIndex > 0 {
                                    Button("上一步") { stepIndex -= 1 }
                                        .buttonStyle(.bordered)
                                }
                                Button(stepIndex < welcomeSteps.count - 1 ? "下一步" : "开始使用") {
                                    if stepIndex < welcomeSteps.count - 1 {
                                        stepIndex += 1
                                    } else {
                                        finish()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: contentMax)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, LayoutMetrics.horizontalInset)
                    .padding(.bottom, 24)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("欢迎")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        finish()
                    }
                }
            }
        }
        .sheet(isPresented: $zoomed) {
            NavigationStack {
                ZStack {
                    Color.black.opacity(0.92).ignoresSafeArea()
                    Image(systemName: step.systemImage)
                        .font(.system(size: 100))
                        .foregroundStyle(.white)
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("关闭") { zoomed = false }
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }

    private func finish() {
        onFinish()
        isPresented = false
    }
}
