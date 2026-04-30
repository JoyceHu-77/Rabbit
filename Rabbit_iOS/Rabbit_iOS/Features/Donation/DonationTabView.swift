//
//  DonationTabView.swift
//  Rabbit_iOS — 物资捐换 Feature
//

import SwiftUI


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
