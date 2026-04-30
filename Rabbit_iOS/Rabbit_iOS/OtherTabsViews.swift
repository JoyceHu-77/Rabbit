//
//  OtherTabsViews.swift
//  Rabbit_iOS — 领养 / 捐换 / 活动 / 个人页
//

import SwiftUI

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

private enum AdoptionSection: Int, CaseIterable {
    case process
    case storybook
    case adoptionCommunity
    case rabbitCommunity

    var title: String {
        switch self {
        case .process: return "领养流程"
        case .storybook: return "兔兔故事书"
        case .adoptionCommunity: return "领养社区"
        case .rabbitCommunity: return "爱兔社区"
        }
    }
}

struct AdoptionTabView: View {
    @Environment(AppDataStore.self) private var store
    @State private var section: AdoptionSection = .process
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
            ScrollView {
                Group {
                    switch section {
                    case .process: adoptionProcess
                    case .storybook: storybookFromRescue
                    case .adoptionCommunity: adoptionCommunityGrid
                    case .rabbitCommunity: rabbitCommunityView
                    }
                }
                .padding()
            }
        }
        .task { await refreshAdoptionData() }
        .onChange(of: section) { _, _ in
            Task { await refreshAdoptionData() }
        }
        .sheet(isPresented: $showCreateRabbitPost) {
            CreateRabbitCommunityPostSheet {
                rabbitPosts = RabbitCommunityStore.load()
            }
        }
        .sheet(item: $adoptionTarget) { post in
            AdoptionIntentSheet(post: post) {
                toast = "领养意向已提交（演示）"
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

    private func deleteCommunityPost(id: String) {
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
                        section = sec
                    } label: {
                        Text(sec.title)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                section == sec
                                    ? LinearGradient(colors: [Color.red.opacity(0.9), Theme.rose.opacity(0.88)], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [Color.white], startPoint: .leading, endPoint: .trailing),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .foregroundStyle(section == sec ? Color.white : Color.secondary)
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
        let all = store.fetchRescuePosts()
        storybookSource = all.filter { $0.status != "寄养中" }
        fosterRabbits = all.filter { $0.status == "寄养中" }
        rabbitPosts = RabbitCommunityStore.load()
    }

    private var storybookFromRescue: some View {
        VStack(spacing: 16) {
            Text("兔兔故事书").font(.title2.bold())
            Text("记录每一只兔兔的救援之路（数据来自救援列表，不含「寄养中」）")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if storybookSource.isEmpty {
                Text("暂无数据，请确认已加载救援列表").foregroundStyle(.secondary)
            } else {
                ForEach(storybookSource) { p in
                    storyCardFromPost(p)
                }
            }
        }
    }

    private func storyCardFromPost(_ p: RescueDisplayPost) -> some View {
        storyCard(
            name: rabbitShortName(p),
            status: p.status,
            date: p.date,
            loc: p.location,
            rescuer: p.finderName ?? p.organizerName ?? "志愿者",
            story: p.description,
            image: p.images.first ?? ""
        )
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
            Text("这些兔兔正在等待一个温暖的家（「寄养中」）").font(.caption).foregroundStyle(.secondary)
            if fosterRabbits.isEmpty {
                Text("当前没有寄养中的兔兔").foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(fosterRabbits) { p in
                        fosterCard(p)
                    }
                }
            }
            adoptionNoticeBlock
        }
    }

    private func fosterCard(_ p: RescueDisplayPost) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                PostImageView(urlString: p.images.first)
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
                Text("寄养中")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple, in: Capsule())
                    .foregroundStyle(.white)
                    .padding(8)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(rabbitShortName(p)).font(.subheadline.weight(.semibold))
                Text(truncate(p.description, limit: 72))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                Button("我要领养") {
                    adoptionTarget = p
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.purple)
                .frame(maxWidth: .infinity)
            }
            .padding(10)
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
        .shadow(radius: 3)
    }

    private func truncate(_ s: String, limit: Int) -> String {
        if s.count <= limit { return s }
        let idx = s.index(s.startIndex, offsetBy: limit)
        return String(s[..<idx]) + "…"
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
                .frame(height: 160)
                .overlay(Text("首月饲养礼包示意图").foregroundStyle(.secondary))
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

    private func storyCard(name: String, status: String, date: String, loc: String, rescuer: String, story: String, image: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                PostImageView(urlString: image)
                    .frame(height: 200)
                    .clipped()
                Text(status)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(10)
            }
            VStack(alignment: .leading, spacing: 10) {
                Label(name, systemImage: "heart.fill")
                    .font(.title3.bold())
                HStack {
                    Label(date, systemImage: "calendar")
                    Spacer()
                    Label(loc, systemImage: "mappin.and.ellipse")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                Label("救助人：\(rescuer)", systemImage: "person")
                    .font(.caption)
                Text(story).font(.subheadline)
                Button("了解领养流程") { section = .process }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
            }
            .padding()
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 4)
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

// MARK: - 捐换

struct DonationTabView: View {
    @Environment(AppDataStore.self) private var store
    @State private var posts: [DonationDisplayPost] = []
    @State private var showCreate = false
    @State private var toast: String?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                headerRose(title: "物资捐换", subtitle: "分享爱心，物尽其用")
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(posts) { p in
                            donationCard(p)
                        }
                    }
                    .padding()
                }
            }
            Button {
                showCreate = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Theme.redHeader, in: Circle())
                    .shadow(radius: 6)
            }
            .padding(.trailing, LayoutMetrics.horizontalInset)
            .padding(.bottom, LayoutMetrics.fabBottomMargin)
        }
        .task {
            await store.refreshDonations()
            posts = store.fetchDonationPosts()
        }
        .sheet(isPresented: $showCreate) {
            CreateDonationSheet { draft in
                let err = await store.addDonation(draft)
                if err == nil {
                    posts = store.fetchDonationPosts()
                }
                return err
            }
        }
        .overlay(alignment: .top) {
            if let t = toast {
                Text(t).padding().background(.thinMaterial, in: Capsule()).padding(.top, 8)
                    .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toast = nil } }
            }
        }
    }

    private func donationCard(_ p: DonationDisplayPost) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                DonationSquareThumbnail(urlString: p.image)
                HStack(spacing: 6) {
                    Text(p.type)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(p.type == "捐赠" ? Color.green : Color.blue, in: Capsule())
                        .foregroundStyle(.white)
                    if p.status == "已完成" {
                        Text(p.status).font(.caption2.weight(.bold)).padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.gray, in: Capsule()).foregroundStyle(.white)
                    }
                }
                .padding(8)
            }
            .overlay(alignment: .topTrailing) {
                if p.target == "爱兔会" {
                    Image(systemName: "gift.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                        .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 6) {
                Text(p.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                Text(p.description).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                Text("联系人：\(p.contactName)").font(.caption2)
                Text("联系方式：\(p.contactPhone)").font(.caption2)
                if p.status != "已完成", p.target != "爱兔会" {
                    Button(p.type == "捐赠" ? "领取" : "置换") {
                        if p.target == "爱兔会" {
                            toast = "该物资已指定捐赠给爱兔会"
                        } else {
                            toast = p.type == "捐赠" ? "已提交领取申请" : "已提交置换申请"
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(p.type == "捐赠" ? Color.green : Color.blue, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)
                }
                if p.target == "爱兔会" {
                    Text("已指定捐赠给爱兔会 ❤️").font(.caption2).foregroundStyle(.orange)
                }
            }
            .padding(10)
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 3)
    }

    private func headerRose(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.largeTitle.bold()).foregroundStyle(.white)
            Text(subtitle).font(.subheadline).foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.vertical, 26)
        .background(LinearGradient(colors: [Theme.rose, Color.red.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}

/// 捐换网格 1:1 缩略图：`LazyVGrid` 内需明确宽高后再 `scaledToFill`，否则 `AsyncImage` 会按原图比例撑破布局
private struct DonationSquareThumbnail: View {
    let urlString: String

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Color(.tertiarySystemFill)
                content(width: w, height: h)
            }
            .frame(width: w, height: h)
            .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func content(width: CGFloat, height: CGFloat) -> some View {
        if let url = resolvedURL(urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: width, height: height)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: height)
                        .clipped()
                case .failure:
                    placeholder
                        .frame(width: width, height: height)
                @unknown default:
                    Color.clear.frame(width: width, height: height)
                }
            }
        } else {
            placeholder
                .frame(width: width, height: height)
        }
    }

    private var placeholder: some View {
        ZStack {
            Color(.tertiarySystemFill)
            Text("🐰").font(.title2)
            Image(systemName: "photo")
                .font(.title3)
                .foregroundStyle(.tertiary)
        }
    }

    private func resolvedURL(_ raw: String) -> URL? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        if s.hasPrefix("http://") || s.hasPrefix("https://") {
            return URL(string: s)
        }
        return nil
    }
}

private struct CreateDonationSheet: View {
    @Environment(\.dismiss) private var dismiss
    /// 返回 `nil` 表示成功。
    var onSubmit: (DonationDraft) async -> String?
    @State private var title = ""
    @State private var description = ""
    @State private var imageURL = ""
    @State private var type = "捐赠"
    @State private var target = "共享"
    @State private var contactName = ""
    @State private var contactPhone = ""
    @State private var alertMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("标题", text: $title)
                TextField("描述", text: $description, axis: .vertical)
                TextField("图片 URL", text: $imageURL)
                Picker("类型", selection: $type) {
                    Text("捐赠").tag("捐赠")
                    Text("置换").tag("置换")
                }
                Picker("对象", selection: $target) {
                    Text("共享").tag("共享")
                    Text("爱兔会").tag("爱兔会")
                }
                TextField("联系人", text: $contactName)
                TextField("电话", text: $contactPhone)
            }
            .navigationTitle("发布捐换")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("发布") {
                        Task { await submit() }
                    }
                }
            }
            .alert("提示", isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private func submit() async {
        let draft = DonationDraft(
            title: title.isEmpty ? "未命名" : title,
            description: description,
            imageURL: imageURL.isEmpty ? "https://images.unsplash.com/photo-1578164252938-1da0cd4caa30?w=400" : imageURL,
            type: type,
            target: target,
            contactName: contactName.isEmpty ? "匿名" : contactName,
            contactPhone: contactPhone.isEmpty ? "—" : contactPhone
        )
        if let err = await onSubmit(draft) {
            alertMessage = err
            return
        }
        dismiss()
    }
}

// MARK: - 活动

struct ActivityTabView: View {
    @Environment(AppDataStore.self) private var store
    @State private var topTab = 0
    @State private var bannerIndex = 0

    private let banners: [(title: String, subtitle: String, image: String)] = [
        ("只取心滴", "日行一善公益打卡活动", "https://images.unsplash.com/photo-1533514114760-4389f572ae26?w=600"),
        ("爱心云养计划", "公益云养小兔活动", "https://images.unsplash.com/photo-1591797057589-eb91f36c0a6f?w=600"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            headerActivity
            Picker("", selection: $topTab) {
                Text("活动").tag(0)
                Text("线下活动").tag(1)
                Text("爱心橱窗").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color.white)

            ScrollView {
                switch topTab {
                case 0:
                    VStack(alignment: .leading, spacing: 18) {
                        activityBanners
                        if bannerIndex == 0 {
                            CheckinActivityContent()
                        } else {
                            CloudAdoptActivityContent()
                        }
                    }
                    .padding(.bottom, 20)
                case 1:
                    OfflineEventsContent(isAdmin: store.isAdmin)
                        .padding(.vertical, 12)
                default:
                    CharityShopContent(isAdmin: store.isAdmin)
                        .padding(.vertical, 12)
                }
            }
        }
    }

    private var headerActivity: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("爱兔活动").font(.largeTitle.bold()).foregroundStyle(.white)
            Text("参与活动，传递爱心").font(.subheadline).foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.vertical, 26)
        .background(LinearGradient(colors: [Color.red, Theme.rose, Color.pink.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private var activityBanners: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Array(banners.enumerated()), id: \.offset) { i, b in
                        Button {
                            bannerIndex = i
                        } label: {
                            ZStack(alignment: .bottomLeading) {
                                PostImageView(urlString: b.image)
                                    .frame(width: 240, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                LinearGradient(colors: [.clear, Color.red.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(b.title).font(.headline).foregroundStyle(.white)
                                    Text(b.subtitle).font(.caption).foregroundStyle(.white.opacity(0.95))
                                }
                                .padding(12)
                            }
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(bannerIndex == i ? Color.red : .clear, lineWidth: 4))
                        }
                    }
                }
                .padding(.horizontal)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("「\(banners[bannerIndex].title)」").font(.headline)
                Text("在下方完成打卡或云养流程，奖章与云养币将写入「个人页」。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

// MARK: - 个人页

struct ProfileTabView: View {
    @Environment(AppDataStore.self) private var store
    @State private var showMessages = false
    @State private var showAddress = false
    @State private var showOrders = false
    @State private var toast: String?

    var body: some View {
        Group {
            if !store.isLoggedIn {
                loggedOutCard
            } else {
                loggedInContent
            }
        }
        .sheet(isPresented: $showOrders) {
            OrdersListSheet { earned in
                store.cloudCoins += earned
                toast = "\(earned) 云养币已到账！"
            }
        }
        .sheet(isPresented: $showMessages) {
            MessagesSheet(isAdmin: store.isAdmin)
        }
        .sheet(isPresented: $showAddress) {
            NavigationStack {
                Form {
                    Section {
                        Text("默认地址：上海市浦东新区××路××号").font(.subheadline)
                    }
                }
                .navigationTitle("收货地址")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { showAddress = false } } }
            }
        }
        .overlay(alignment: .top) {
            if let t = toast {
                Text(t).padding().background(.thinMaterial, in: Capsule()).padding(.top, 8)
                    .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toast = nil } }
            }
        }
    }

    private var loggedOutCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 64))
                .foregroundStyle(.red.opacity(0.7))
            Text("欢迎来到爱兔会").font(.title2.bold())
            Text("登录后享受更多功能").foregroundStyle(.secondary)
            Button("立即登录") {
                store.isLoggedIn = true
                toast = "登录成功"
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
        }
        .padding(32)
        .frame(maxWidth: 320)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [Color.pink.opacity(0.15), Color.purple.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private var loggedInContent: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 14) {
                        Circle()
                            .fill(.white.opacity(0.25))
                            .frame(width: 72, height: 72)
                            .overlay(Text(String(store.userName.prefix(1))).font(.title).foregroundStyle(.white))
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(store.userName).font(.title2.bold())
                                if store.isAdmin {
                                    Label("管理员", systemImage: "shield.fill")
                                        .font(.caption2.weight(.bold))
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Color.orange, in: Capsule())
                                }
                            }
                            Text(store.userBio).font(.caption).foregroundStyle(.white.opacity(0.85))
                        }
                    }
                    HStack {
                        statBox(icon: "rosette", value: "\(store.badges)", label: "爱兔奖章")
                        statBox(icon: "bitcoinsign.circle", value: "\(store.cloudCoins)", label: "云养币")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient(colors: [Color.pink, Color.purple.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18))

                VStack(spacing: 0) {
                    profileRow("bell", "我的消息", badge: messageBadgeCount) { showMessages = true }
                    profileRow("bag", "我的订单", badge: nil) { showOrders = true }
                    profileRow("heart", "我的发布", badge: nil) { toast = "查看我的发布" }
                    profileRow("mappin.and.ellipse", "收货地址", badge: nil) { showAddress = true }
                    profileRow("gearshape", "设置", badge: nil) { toast = "打开设置" }
                }
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 4)

                VStack(alignment: .leading, spacing: 12) {
                    Text("开发者选项").font(.headline)
                    Toggle("管理员模式", isOn: Binding(get: { store.isAdmin }, set: { store.isAdmin = $0 }))
                    Text("开启后可使用救援详情里的编辑与状态流转、爱兔社区删帖、线下活动新增、橱窗收款管理及「管理通知」。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))

                Button("退出登录", role: .destructive) {
                    store.isLoggedIn = false
                    toast = "已退出登录"
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(LinearGradient(colors: [Color.pink.opacity(0.12), Color.purple.opacity(0.1), Color.orange.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    /// 未读角标：用户消息（示意 2）+ 管理员未读通知（仅管理员模式）
    private var messageBadgeCount: Int? {
        guard store.isLoggedIn else { return nil }
        let userUnread = 2
        let adminUnread = store.isAdmin ? AdminNotificationsStore.load().filter { !$0.read }.count : 0
        let total = userUnread + adminUnread
        return total > 0 ? total : nil
    }

    private func statBox(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3)
            Text(value).font(.title.bold())
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }

    private func profileRow(_ icon: String, _ title: String, badge: Int?, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack {
                    Image(systemName: icon).foregroundStyle(.secondary)
                    Text(title)
                    Spacer()
                    if let b = badge {
                        Text("\(b)")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red, in: Capsule())
                            .foregroundStyle(.white)
                    }
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
                .padding()
            }
            .buttonStyle(.plain)
            Divider()
                .padding(.leading)
        }
    }
}

// MARK: - 消息（用户 / 管理员双通道，对齐 Web MessagesDialog）

private struct MessagesSheet: View {
    @Environment(\.dismiss) private var dismiss
    let isAdmin: Bool

    private enum MsgTab: Hashable {
        case user, admin
    }

    @State private var tab: MsgTab = .user
    @State private var adminList: [AdminNotificationRecord] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isAdmin {
                    Picker("", selection: $tab) {
                        Text("用户消息").tag(MsgTab.user)
                        Text("管理通知").tag(MsgTab.admin)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }

                if tab == .user || !isAdmin {
                    List {
                        Section("未读") {
                            Label("恭喜获得爱兔奖章（只取心滴）", systemImage: "rosette")
                            Label("商品已发货：电子照片订单", systemImage: "shippingbox")
                            Label("系统：您的领养申请已进入审核", systemImage: "bell")
                        }
                        Section("更早") {
                            Text("欢迎加入爱兔会，让我们一起守护兔兔。")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    List {
                        if adminList.isEmpty {
                            Section {
                                Text("暂无待处理事项；用户支付完成后会在此出现通知。")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ForEach(adminList) { n in
                                Button {
                                    AdminNotificationsStore.markRead(id: n.id)
                                    adminList = AdminNotificationsStore.load()
                                } label: {
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: iconName(for: n.type))
                                            .foregroundStyle(.orange)
                                            .frame(width: 22)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(n.title).font(.subheadline.weight(.semibold))
                                            Text(n.content).font(.caption).foregroundStyle(.secondary)
                                            Text(n.createdAt.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                        Spacer(minLength: 0)
                                        if !n.read {
                                            Circle()
                                                .fill(Color.orange)
                                                .frame(width: 8, height: 8)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .onAppear {
                adminList = AdminNotificationsStore.load()
                if isAdmin {
                    tab = .admin
                }
            }
        }
    }

    private var titleText: String {
        if !isAdmin || tab == .user {
            return "我的消息"
        }
        return "管理通知"
    }

    private func iconName(for type: String) -> String {
        switch type {
        case "payment": return "creditcard"
        case "order": return "bag"
        case "cloudAdopt": return "cloud"
        case "adopt": return "heart.fill"
        default: return "bell.badge"
        }
    }
}

// MARK: - 领养意向 / 爱兔社区发帖 / 订单

private struct AdoptionIntentSheet: View {
    let post: RescueDisplayPost
    let onSubmitted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(rabbitName).font(.headline)
                }
                TextField("您的姓名", text: $name)
                TextField("联系电话", text: $phone)
                    .keyboardType(.phonePad)
            }
            .navigationTitle("领养意向")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("提交") {
                        onSubmitted()
                        dismiss()
                    }
                }
            }
        }
    }

    private var rabbitName: String {
        if let r = post.title.range(of: " - ") {
            return String(post.title[..<r.lowerBound])
        }
        return post.title
    }
}

private struct CreateRabbitCommunityPostSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSaved: () -> Void

    @State private var title = ""
    @State private var content = ""
    @State private var author = ""
    @State private var imageURL = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("标题", text: $title)
                TextField("昵称", text: $author)
                TextField("正文", text: $content, axis: .vertical)
                TextField("图片 URL（可选）", text: $imageURL)
            }
            .navigationTitle("发布动态")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("发布") {
                        let p = RabbitCommunityPost(
                            id: "RC\(Int(Date().timeIntervalSince1970 * 1000))",
                            authorName: author.isEmpty ? "爱心网友" : author,
                            title: title.isEmpty ? "分享" : title,
                            content: content,
                            images: imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [] : [imageURL],
                            createdAt: Date(),
                            likes: 0,
                            likedByUser: false
                        )
                        RabbitCommunityStore.append(p)
                        onSaved()
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct OrdersListSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onCloudCoinsEarned: (Int) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("待支付") {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("爱心橱窗 · 电子照片")
                            Text("¥5 · 演示订单").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("模拟支付完成") {
                            onCloudCoinsEarned(5)
                            AdminNotificationsStore.appendOrderPaymentNotification(
                                title: "爱心橱窗订单待核对",
                                amountDescription: "¥5（用户端已发放 5 云养币）"
                            )
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                Section("已完成") {
                    Text("暂无").foregroundStyle(.secondary)
                }
            }
            .navigationTitle("我的订单")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}
