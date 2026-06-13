//
//  WelcomeGuideView.swift
//  Rabbit_iOS — 以 sheet 呈现，媒体与 rabbit_web_new WelcomeModal 一致（本地 bundle）
//

import SwiftUI

private enum WelcomeStepMedia {
    case video(URL)
    case images([UIImage])

    var imageCount: Int {
        switch self {
        case .video: 0
        case .images(let list): list.count
        }
    }

    func image(at index: Int) -> UIImage? {
        guard case .images(let list) = self, list.indices.contains(index) else { return nil }
        return list[index]
    }
}

private struct WelcomeStep: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let highlights: [String]
    let canZoom: Bool
    let media: WelcomeStepMedia
}

private enum WelcomeGuideContent {
    static let steps: [WelcomeStep] = {
        func images(_ assets: WelcomeGuideMedia.Asset...) -> WelcomeStepMedia {
            let loaded = assets.compactMap { WelcomeGuideMedia.uiImage(for: $0) }
            return .images(loaded)
        }

        var steps: [WelcomeStep] = []

        if let videoURL = WelcomeGuideMedia.url(for: .welcomeVideo) {
            steps.append(
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
                    media: .video(videoURL)
                )
            )
        }

        let division = WelcomeGuideMedia.uiImage(for: .division)
        if let division {
            steps.append(
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
                    media: .images([division])
                )
            )
        }

        let cooperation = [
            WelcomeGuideMedia.uiImage(for: .cooperation1),
            WelcomeGuideMedia.uiImage(for: .cooperation2),
        ].compactMap { $0 }
        if !cooperation.isEmpty {
            steps.append(
                WelcomeStep(
                    title: "🤝 合作伙伴",
                    content: "感谢我们的合作伙伴提供医疗支持、宠物用品和专业咨询。共同为兔兔的福祉而努力！点击图片可放大查看，左右滑动查看更多。",
                    highlights: [
                        "🏥 河畔流浪动物体检福利",
                        "🏥 内博虎流浪动物体检福利",
                        "💼 多家合作机构：资源共享与互助",
                    ],
                    canZoom: true,
                    media: .images(cooperation)
                )
            )
        }

        return steps
    }()
}

struct WelcomeGuideView: View {
    @Binding var isPresented: Bool
    let onFinish: () -> Void

    @State private var stepIndex = 0
    @State private var imageIndex = 0
    @State private var zoomed = false

    private var steps: [WelcomeStep] { WelcomeGuideContent.steps }

    private var step: WelcomeStep? {
        guard steps.indices.contains(stepIndex) else { return nil }
        return steps[stepIndex]
    }

    var body: some View {
        NavigationStack {
            Group {
                if let step {
                    guideContent(step: step)
                } else {
                    missingMediaFallback
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("欢迎")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { finish() }
                }
            }
        }
        .onChange(of: stepIndex) { _, _ in
            imageIndex = 0
        }
        .sheet(isPresented: $zoomed) {
            if let step {
                WelcomeGuideZoomSheet(
                    step: step,
                    imageIndex: $imageIndex,
                    isPresented: $zoomed
                )
            }
        }
    }

    @ViewBuilder
    private func guideContent(step: WelcomeStep) -> some View {
        GeometryReader { geo in
            let contentMax = min(geo.size.width - 32, LayoutMetrics.referenceWidth - 32)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    mediaSection(step: step, contentMax: contentMax)
                    Text(step.title)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    Text(step.content)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: contentMax, alignment: .leading)
                    ForEach(Array(step.highlights.enumerated()), id: \.offset) { _, h in
                        highlightRow(h)
                    }
                    navigationBar(stepCount: steps.count)
                        .padding(.top, 4)
                }
                .frame(maxWidth: contentMax)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, LayoutMetrics.horizontalInset)
                .padding(.bottom, 24)
            }
        }
    }

    @ViewBuilder
    private func mediaSection(step: WelcomeStep, contentMax: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))

            switch step.media {
            case .video(let url):
                WelcomeGuideVideoView(url: url)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            case .images:
                if let image = step.media.image(at: imageIndex) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(4)
                } else {
                    mediaPlaceholder
                }
            }
        }
        .frame(maxWidth: contentMax)
        .frame(maxWidth: .infinity)
        .aspectRatio(4 / 3, contentMode: .fit)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture {
            if step.canZoom, step.media.image(at: imageIndex) != nil {
                zoomed = true
            }
        }
        .overlay {
            if step.canZoom, step.media.image(at: imageIndex) != nil {
                zoomHint
            }
            if step.media.imageCount > 1 {
                imageCarouselControls(step: step)
            }
        }
    }

    private var zoomHint: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Label("点击放大", systemImage: "plus.magnifyingglass")
                    .font(.caption2)
                    .padding(6)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(8)
            }
        }
    }

    @ViewBuilder
    private func imageCarouselControls(step: WelcomeStep) -> some View {
        let count = step.media.imageCount
        VStack {
            HStack {
                if imageIndex > 0 {
                    carouselButton(systemName: "chevron.left") { imageIndex -= 1 }
                }
                Spacer()
                if imageIndex < count - 1 {
                    carouselButton(systemName: "chevron.right") { imageIndex += 1 }
                }
            }
            .padding(.horizontal, 4)
            Spacer()
            HStack(spacing: 6) {
                ForEach(0 ..< count, id: \.self) { i in
                    Capsule()
                        .fill(i == imageIndex ? Color.red : Color.red.opacity(0.25))
                        .frame(width: i == imageIndex ? 22 : 6, height: 6)
                        .onTapGesture { imageIndex = i }
                }
            }
            .padding(.bottom, 8)
        }
    }

    private func carouselButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func highlightRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.red.opacity(0.65))
                .frame(width: 5, height: 5)
                .padding(.top, 7)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func navigationBar(stepCount: Int) -> some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0 ..< stepCount, id: \.self) { i in
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
                Button(stepIndex < stepCount - 1 ? "下一步" : "开始使用") {
                    if stepIndex < stepCount - 1 {
                        stepIndex += 1
                    } else {
                        finish()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var mediaPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("媒体资源未找到")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var missingMediaFallback: some View {
        VStack(spacing: 16) {
            Text("欢迎引导资源未加载")
                .font(.headline)
            Text("请确认已将 Resources/WelcomeGuide 下的图片与视频加入 App 目标。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("关闭") { finish() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func finish() {
        onFinish()
        isPresented = false
    }
}

// MARK: - 大图

private struct WelcomeGuideZoomSheet: View {
    let step: WelcomeStep
    @Binding var imageIndex: Int
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                TabView(selection: $imageIndex) {
                    ForEach(0 ..< step.media.imageCount, id: \.self) { i in
                        if let image = step.media.image(at: i) {
                            ZoomableUIImageView(image: image)
                                .ignoresSafeArea()
                                .tag(i)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: step.media.imageCount > 1 ? .automatic : .never))
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { isPresented = false }
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}
