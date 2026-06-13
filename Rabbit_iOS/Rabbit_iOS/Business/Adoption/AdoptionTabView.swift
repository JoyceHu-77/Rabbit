//
//  AdoptionTabView.swift
//  Rabbit_iOS — 爱兔领养 Feature
//

import SwiftUI
import UIKit

// MARK: - 领养

private let adoptionSteps = [
    "浏览寄养中的兔兔",
    "提交领养意向问卷",
    "管理员审核",
    "缴纳押金",
    "带兔兔回家",
    "定期回访",
    "申请退还押金",
]

private struct StorybookRabbitImageView: View {
    let urlString: String
    var rescuePostId: String?
    var sourceRabbitId: Int32?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.secondarySystemBackground)
                if let localImage = RescueFeedMedia.uiImage(
                    for: urlString,
                    rescuePostId: rescuePostId,
                    sourceRabbitId: sourceRabbitId
                ) {
                    orientedImage(localImage, in: geo.size)
                } else if let remoteURL = resolvedURL(urlString) {
                    RemoteStorybookRabbitImage(url: remoteURL, size: geo.size)
                } else {
                    Text("🐰").font(.title)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
    }

    @ViewBuilder
    private func orientedImage(_ image: UIImage, in size: CGSize) -> some View {
        if image.size.width >= image.size.height {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: size.width, height: size.height, alignment: .center)
        } else {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height, alignment: .center)
                .clipped()
        }
    }

    private func resolvedURL(_ raw: String) -> URL? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        if s.hasPrefix("http://") || s.hasPrefix("https://") || s.hasPrefix("file:") {
            return URL(string: s)
        }
        return nil
    }
}

private struct RemoteStorybookRabbitImage: View {
    let url: URL
    let size: CGSize
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                orientedImage(image)
            } else {
                ProgressView()
            }
        }
        .task(id: url) {
            image = await loadImage(from: url)
        }
    }

    @ViewBuilder
    private func orientedImage(_ image: UIImage) -> some View {
        if image.size.width >= image.size.height {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: size.width, height: size.height, alignment: .center)
        } else {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height, alignment: .center)
                .clipped()
        }
    }

    private func loadImage(from url: URL) async -> UIImage? {
        if url.isFileURL {
            guard let data = try? Data(contentsOf: url) else { return nil }
            return UIImage(data: data)
        }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        return UIImage(data: data)
    }
}

/// 故事书卡片：通过 `AdoptionTabCoordinator` 切换子 Tab；图片区禁用点击，避免 ScrollView 内布局吞掉按钮。
private struct RabbitStoryCardView: View {
    var coordinator: AdoptionTabCoordinator
    let name: String
    let status: String
    let date: String
    let loc: String
    let rescuer: String
    let story: String
    let image: String
    var rescuePostId: String?
    var sourceRabbitId: Int32?
    @State private var isExpanded = false

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        HStack(alignment: .top, spacing: 0) {
            ZStack(alignment: .topLeading) {
                Color(.secondarySystemBackground)
                StorybookRabbitImageView(
                    urlString: image,
                    rescuePostId: rescuePostId,
                    sourceRabbitId: sourceRabbitId
                )
                .padding(6)
                .allowsHitTesting(false)

                Text(status)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(10)
            }
            .frame(width: 128, height: 178)
            .clipped()

            VStack(alignment: .leading, spacing: 10) {
                Label(name, systemImage: "heart.fill")
                    .font(.title3.bold())
                VStack(alignment: .leading, spacing: 4) {
                    Label(date, systemImage: "calendar")
                    Label(loc, systemImage: "mappin.and.ellipse")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                Label("救助人：\(rescuer)", systemImage: "person")
                    .font(.caption)
                let displayStory = cleanStoryText(story)
                Text(displayStory)
                    .font(.subheadline)
                    .lineLimit(isExpanded ? nil : 3)
                if displayStory.count > 48 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Label(isExpanded ? "收起" : "展开", systemImage: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.purple)
                }
            }
            .padding()
            .zIndex(1)
        }
        .background(Color.white)
        .clipShape(cardShape)
        .shadow(radius: 4)
    }

    private func cleanStoryText(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: #"^健康状况：[^；]*；绝育状态：[^；]*；"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"[（(][^）)]*(?:逻辑|状态|底层)[^）)]*[）)]"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct AdoptionTabView: View {
    @Environment(AppDataStore.self) private var store
    @State private var coordinator = AdoptionTabCoordinator()
    @State private var storybookSource: [RescueDisplayPost] = []
    @State private var fosterRabbits: [RescueDisplayPost] = []
    @State private var rabbitPosts: [RabbitCommunityPost] = []
    @State private var showCreateRabbitPost = false
    @State private var adoptionTarget: RescueDisplayPost?
    @State private var toast: String?
    /// 删除爱兔社区帖子（仅管理员，与 Web RabbitCommunity 一致）
    @State private var postIdPendingDelete: String?

    var body: some View {
        VStack(spacing: 0) {
            headerPurple(title: "爱兔领养", subtitle: "给每只兔兔一个温暖的家")
            adoptionSectionBar
            Group {
                switch coordinator.section {
                case .process:
                    adoptionScrollContent { adoptionProcess }
                case .storybook:
                    adoptionScrollContent { storybookFromRescue }
                case .adoptionCommunity:
                    adoptionScrollContent { adoptionCommunityGrid }
                case .rabbitCommunity:
                    adoptionScrollContent { rabbitCommunityView }
                }
            }
        }
        .environment(coordinator)
        .task { await refreshAdoptionData() }
        .onChange(of: coordinator.section) { _, _ in
            Task { await refreshAdoptionData() }
        }
        .sheet(isPresented: $showCreateRabbitPost) {
            CreateRabbitCommunityPostSheet {
                Task { await refreshAdoptionData() }
            }
        }
        .sheet(item: $adoptionTarget) { post in
            AdoptionIntentSheet(post: post) { message in
                toast = message
            }
        }
        .confirmationDialog("删除这条动态？", isPresented: Binding(
            get: { postIdPendingDelete != nil },
            set: { if !$0 { postIdPendingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                if let id = postIdPendingDelete {
                    deleteCommunityPost(id: id)
                }
                postIdPendingDelete = nil
            }
            Button("取消", role: .cancel) {
                postIdPendingDelete = nil
            }
        } message: {
            Text("删除后无法恢复")
        }
        .overlay(alignment: .top) {
            if let t = toast {
                Text(t)
                    .padding()
                    .background(.thinMaterial, in: Capsule())
                    .padding(.top, 8)
                    .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toast = nil } }
            }
        }
    }

    @ViewBuilder
    private func adoptionScrollContent<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            content()
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .id(coordinator.section)
    }

    private func deleteCommunityPost(id: String) {
        Task {
            await performDeleteCommunityPost(id: id)
        }
    }

    @MainActor
    private func performDeleteCommunityPost(id: String) async {
        if RabbitAPIConfiguration.normalizedBaseURL() != nil {
            do {
                try await RabbitAPIService.deleteCommunityPost(id: id)
                rabbitPosts = await RabbitAPIService.fetchCommunityPosts()
                RabbitCommunityStore.replaceAll(rabbitPosts)
                toast = "已删除该动态"
                return
            } catch {
                toast = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                return
            }
        }
        var all = RabbitCommunityStore.load()
        all.removeAll { $0.id == id }
        RabbitCommunityStore.replaceAll(all)
        rabbitPosts = all
        toast = "已删除该动态"
    }

    private var adoptionSectionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AdoptionSection.allCases, id: \.rawValue) { sec in
                    Button {
                        coordinator.section = sec
                    } label: {
                        Text(sec.title)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                coordinator.section == sec
                                    ? LinearGradient(colors: [Color.red.opacity(0.9), Theme.rose.opacity(0.88)], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [Color.white], startPoint: .leading, endPoint: .trailing),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .foregroundStyle(coordinator.section == sec ? Color.white : Color.secondary)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.purple.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color.white)
    }

    private func refreshAdoptionData() async {
        await store.refreshRescues()
        let all = store.visibleRescuePosts(isAdmin: store.isAdmin, viewerUserName: store.userName)
            .filter { $0.moderationStatus == "approved" }
        storybookSource = all
        fosterRabbits = all.filter { $0.status == "寄养中" }
        let posts = await RabbitAPIService.fetchCommunityPosts()
        rabbitPosts = posts
        RabbitCommunityStore.replaceAll(posts)
    }

    private var storybookFromRescue: some View {
        VStack(spacing: 16) {
            Text("兔兔故事书").font(.title2.bold())
            Text("记录每一只兔兔的救援之路")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if storybookSource.isEmpty {
                Text("暂无数据，请确认已加载救援列表").foregroundStyle(.secondary)
            } else {
                ForEach(storybookSource) { p in
                    RabbitStoryCardView(
                        coordinator: coordinator,
                        name: rabbitShortName(p),
                        status: p.status,
                        date: p.date,
                        loc: p.location,
                        rescuer: p.finderName ?? p.organizerName ?? "志愿者",
                        story: p.description,
                        image: p.images.first ?? "",
                        rescuePostId: p.id,
                        sourceRabbitId: p.sourceRabbitId
                    )
                }
            }
        }
    }

    private func rabbitShortName(_ p: RescueDisplayPost) -> String {
        if let r = p.title.range(of: " - ") {
            return String(p.title[..<r.lowerBound])
        }
        return p.title
    }

    private var adoptionCommunityGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("领养社区").font(.title2.bold())
            Text("这些兔兔正在等待一个温暖的家").font(.caption).foregroundStyle(.secondary)
            if fosterRabbits.isEmpty {
                Text("当前没有寄养中的兔兔").foregroundStyle(.secondary)
            } else {
                DualColumnFeedGrid {
                    ForEach(fosterRabbits) { p in
                        fosterCard(p)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            adoptionNoticeBlock
        }
    }

    /// 双列 feed 卡片布局与 `DonationTabView.donationCard` 一致（1:1 缩略图 + 白底圆角阴影）。
    private func fosterCard(_ p: RescueDisplayPost) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                SquareGridThumbnail(
                    urlString: p.images.first ?? "",
                    rescuePostId: p.id,
                    sourceRabbitId: p.sourceRabbitId
                )
                Text("寄养中")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple, in: Capsule())
                    .foregroundStyle(.white)
                    .padding(8)
            }
            .clipShape(DualColumnFeedLayout.cardShape)
            VStack(alignment: .leading, spacing: 6) {
                Text(rabbitShortName(p))
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(cleanRabbitDescription(p.description))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Button {
                    adoptionTarget = p
                } label: {
                    Label("我要领养", systemImage: "heart.fill")
                        .font(.caption2.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .background(Color.purple.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.purple)
            }
            .padding(10)
        }
        .background(Color.white, in: DualColumnFeedLayout.cardShape)
        .shadow(radius: 3)
    }

    private var adoptionNoticeBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("领养须知", systemImage: "bubble.left.and.bubble.right")
                .font(.headline)
            Text("• 领养需填写意向并通过审核")
            Text("• 需缴纳押金并完成家访（如有）")
            Text("• 领养后请善待兔兔，接受回访")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
    }

    private var rabbitCommunityView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("爱兔社区").font(.title2.bold())
                Spacer()
                Button {
                    showCreateRabbitPost = true
                } label: {
                    Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(.red)
                }
                .accessibilityLabel("发布动态")
            }
            Text("分享你与兔兔的日常").font(.caption).foregroundStyle(.secondary)
            if rabbitPosts.isEmpty {
                Text("还没有动态，点击右上角发布一条吧").foregroundStyle(.secondary)
            }
            ForEach(rabbitPosts) { post in
                rabbitPostCard(post)
            }
        }
    }

    private func rabbitPostCard(_ post: RabbitCommunityPost) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.authorName).font(.subheadline.weight(.semibold))
                    Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                if store.isAdmin {
                    Button {
                        postIdPendingDelete = post.id
                    } label: {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("删除帖子")
                }
            }
            Text(post.title).font(.headline)
            if let first = post.images.first, !first.isEmpty {
                PostImageView(urlString: first)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Text(post.content).font(.subheadline)
            Button {
                toggleLike(post)
            } label: {
                Label("\(post.likes)", systemImage: post.likedByUser ? "heart.fill" : "heart")
            }
            .font(.caption)
            .foregroundStyle(post.likedByUser ? .red : .secondary)
        }
        .padding()
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
        .shadow(radius: 2)
    }

    private func toggleLike(_ post: RabbitCommunityPost) {
        Task {
            await performToggleLike(post)
        }
    }

    private func cleanRabbitDescription(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: #"^健康状况：[^；]*；绝育状态：[^；]*；"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"[（(][^）)]*(?:逻辑|状态|底层)[^）)]*[）)]"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @MainActor
    private func performToggleLike(_ post: RabbitCommunityPost) async {
        if RabbitAPIConfiguration.normalizedBaseURL() != nil {
            do {
                _ = try await RabbitAPIService.toggleCommunityPostLike(id: post.id)
                rabbitPosts = await RabbitAPIService.fetchCommunityPosts()
                RabbitCommunityStore.replaceAll(rabbitPosts)
                return
            } catch {
                toast = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                return
            }
        }
        var all = RabbitCommunityStore.load()
        guard let i = all.firstIndex(where: { $0.id == post.id }) else { return }
        var p = all[i]
        if p.likedByUser {
            p.likes = max(0, p.likes - 1)
        } else {
            p.likes += 1
        }
        p.likedByUser.toggle()
        all[i] = p
        RabbitCommunityStore.replaceAll(all)
        rabbitPosts = all
    }

    @ViewBuilder
    private var adoptionGiftPackageImage: some View {
        if let image = AdoptionMedia.uiImage(for: .giftPackage) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .accessibilityLabel("首月饲养礼包")
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
                .frame(height: 160)
                .overlay(Text("首月饲养礼包示意图").foregroundStyle(.secondary))
        }
    }

    private var adoptionProcess: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("为什么要领养？")
                    .font(.title2.bold())
                    .foregroundStyle(Color.purple.opacity(0.85))
                Text("每一只流浪兔都曾经历过被遗弃的痛苦。通过领养，您不仅为它们提供了第二次生命的机会，更传递了爱与责任。")
                Text("领养代替购买，让更多人关注流浪动物问题，共同营造一个更有爱的社会。")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [Color.pink.opacity(0.25), Color.purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 16)
            )

            Text("领养流程").font(.title3.bold())
            ForEach(Array(adoptionSteps.enumerated()), id: \.offset) { i, step in
                HStack(alignment: .center, spacing: 12) {
                    Text("\(i + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Theme.redHeader, in: Circle())
                    Text(step)
                        .font(.subheadline)
                    Spacer()
                }
                .padding()
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 2)
            }

            Text("领养后享受的权益").font(.title3.bold())
            adoptionGiftPackageImage
            benefitCard(title: "首月领养礼包", items: [
                ("收助者", "免费获取粮草、兔粮包等，减轻初期养护负担"),
                ("领养人", "免费救护车服务、兔粮赠品分享"),
            ], colors: [Color.pink, Color.red.opacity(0.8)])
            benefitCard(title: "礼包内容", items: [
                ("兔粮", "小佩鸭、速溶胡萝卜"),
                ("玩具", "咬胶、草编球"),
                ("装备", "厕所训练、宠粮剩余"),
                ("医疗券", "年费、草药袋等"),
                ("其他商品", "其他合作商精选礼包"),
            ], colors: [Color.red, Color.orange.opacity(0.85)])
        }
    }

    private func benefitCard(title: String, items: [(String, String)], colors: [Color]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title).font(.headline).foregroundStyle(.white)
                Spacer()
            }
            .padding()
            .background(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, it in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(it.0).font(.subheadline.weight(.semibold))
                            Text(it.1).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
        .shadow(radius: 3)
    }

    private func headerPurple(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.largeTitle.bold()).foregroundStyle(.white)
            Text(subtitle).font(.subheadline).foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.vertical, 26)
        .background(LinearGradient(colors: [Color.red.opacity(0.85), Color.purple.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}
