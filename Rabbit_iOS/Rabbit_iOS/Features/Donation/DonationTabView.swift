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
    @State private var detailPost: DonationDisplayPost?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                headerRose(title: "物资捐换", subtitle: "分享爱心，物尽其用")
                ScrollView {
                    DualColumnFeedGrid {
                        ForEach(posts) { p in
                            Button {
                                detailPost = p
                            } label: {
                                donationCard(p)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
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
        .sheet(item: $detailPost) { p in
            DonationDetailSheet(post: p, onToast: { toast = $0 })
        }
    }

    private func donationCard(_ p: DonationDisplayPost) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                SquareGridThumbnail(urlString: p.image)
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
            .clipShape(DualColumnFeedLayout.cardShape)
            VStack(alignment: .leading, spacing: 6) {
                Text(p.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                Text(p.description).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                Text("联系人：\(p.contactName)").font(.caption2)
                Text("联系方式：\(maskedContactBrief(p.contactPhone))").font(.caption2)
                if p.status != "已完成", p.target != "爱兔会" {
                    Text("进入详情查看联系方式")
                        .font(.caption2.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(p.type == "捐赠" ? Color.green.opacity(0.15) : Color.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(p.type == "捐赠" ? Color.green : Color.blue)
                }
                if p.target == "爱兔会" {
                    Text("已指定捐赠给爱兔会 ❤️").font(.caption2).foregroundStyle(.orange)
                }
            }
            .padding(10)
        }
        .background(Color.white, in: DualColumnFeedLayout.cardShape)
        .shadow(radius: 3)
    }

    private func maskedContactBrief(_ raw: String) -> String {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard s.count > 4 else { return "****" }
        return String(s.prefix(3)) + "****" + String(s.suffix(min(4, s.count - 3)))
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

private struct DonationDetailSheet: View {
    let post: DonationDisplayPost
    var onToast: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var revealed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SquareGridThumbnail(urlString: post.image)
                    Text(post.title).font(.title2.bold())
                    Text(post.description).font(.body).foregroundStyle(.secondary)
                    Label(post.date, systemImage: "calendar").font(.caption).foregroundStyle(.tertiary)
                    Divider()
                    if post.target == "爱兔会" {
                        Text("该物资指定捐赠爱兔会，由工作人员对接。")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    } else if revealed {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("联系人：\(post.contactName)").font(.headline)
                            Text("联系方式：\(post.contactPhone)").font(.title3)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    } else {
                        Button {
                            revealed = true
                            UserInboxStore.append(
                                title: "已查看联系方式",
                                body: "您已查看捐换帖 \(post.id) 的联系人信息，请文明沟通。"
                            )
                            onToast("请通过电话或微信友好联系对方")
                        } label: {
                            Label("查看联系方式（领取/置换）", systemImage: "phone.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
                .padding()
            }
            .navigationTitle("物资详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
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
