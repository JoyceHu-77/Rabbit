//
//  DonationTabView.swift
//  Rabbit_iOS — 物资捐换 Feature
//

import PhotosUI
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
            DonationDetailSheet(post: p, onToast: { toast = $0 }) { updated in
                store.updateDonationPost(updated)
                posts = store.fetchDonationPosts()
                detailPost = updated
            } onDelete: { deleted in
                store.deleteDonationPost(id: deleted.id)
                posts = store.fetchDonationPosts()
                detailPost = nil
                toast = "已删除该捐换帖"
            }
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
                    if p.status == "已完成" || p.status == "进行中" {
                        Text(p.status).font(.caption2.weight(.bold)).padding(.horizontal, 8).padding(.vertical, 4)
                            .background(p.status == "已完成" ? Color.gray : Color.orange, in: Capsule()).foregroundStyle(.white)
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
    @State var post: DonationDisplayPost
    var onToast: (String) -> Void
    var onUpdate: (DonationDisplayPost) -> Void
    var onDelete: (DonationDisplayPost) -> Void
    @Environment(AppDataStore.self) private var store
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
                            if isAvailableForClaim {
                                Button(primaryActionTitle) {
                                    markInProgress()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(post.type == "捐赠" ? .green : .blue)
                            } else if post.status == "进行中" {
                                Text("该物资正在对接中，暂不可重复领取/置换。")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Button("确认已完成") {
                                    markCompleted()
                                }
                                .buttonStyle(.bordered)
                            } else {
                                Label("已完成", systemImage: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                            }
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
                    if store.isAdmin {
                        Divider()
                        Button("管理员删除帖子", role: .destructive) {
                            onDelete(post)
                            dismiss()
                        }
                        .buttonStyle(.bordered)
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

    private var primaryActionTitle: String {
        post.type == "捐赠" ? "我要领取" : "我要置换"
    }

    private var isAvailableForClaim: Bool {
        post.status == "待领取" || post.status == "未完成"
    }

    private func markInProgress() {
        post.status = "进行中"
        onUpdate(post)
        UserInboxStore.append(
            title: "\(post.type)对接中",
            body: "您已发起「\(post.title)」的\(post.type == "捐赠" ? "领取" : "置换")，请在 3 天内与对方确认。"
        )
        AdminNotificationsStore.append(
            AdminNotificationRecord(
                id: "ADM\(Int(Date().timeIntervalSince1970 * 1000))",
                type: "donation",
                title: "物资捐换进入对接",
                content: "[\(post.id)] \(post.title) 已进入进行中，请关注 3 天内确认结果。",
                createdAt: Date(),
                read: false
            )
        )
        onToast("已进入进行中，其他用户暂不可操作")
    }

    private func markCompleted() {
        post.status = "已完成"
        onUpdate(post)
        UserInboxStore.append(title: "捐换已完成", body: "「\(post.title)」已确认完成，感谢您的爱心。")
        onToast("已标记完成")
    }
}

private struct CreateDonationSheet: View {
    @Environment(\.dismiss) private var dismiss
    /// 返回 `nil` 表示成功。
    var onSubmit: (DonationDraft) async -> String?
    @State private var title = ""
    @State private var description = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var type = "捐赠"
    @State private var target = "共享"
    @State private var contactName = ""
    @State private var contactPhone = ""
    @State private var contactWechat = ""
    @State private var alertMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("捐换要求全新未开封，保质期内。")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                TextField("标题", text: $title)
                TextField("描述", text: $description, axis: .vertical)
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
                    .keyboardType(.phonePad)
                TextField("微信", text: $contactWechat)
                    .textInputAutocapitalization(.never)
                Section("物资图片") {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(photoItem == nil ? "从相册选择图片" : "已选择图片，点击重选", systemImage: "photo.on.rectangle.angled")
                    }
                    Text("请上传实物图片，便于审核和领取/置换方判断物资状态。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("发布捐换")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? "发布中..." : "发布") {
                        Task { await submit() }
                    }
                    .disabled(isSubmitting)
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
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let desc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = contactName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = contactPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        let wechat = contactWechat.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { alertMessage = "请输入标题"; return }
        guard !desc.isEmpty else { alertMessage = "请输入描述"; return }
        guard !name.isEmpty else { alertMessage = "请输入联系人"; return }
        guard !phone.isEmpty || !wechat.isEmpty else { alertMessage = "电话和微信至少填写一个"; return }
        guard photoItem != nil else { alertMessage = "请从相册选择物资图片"; return }
        if let err = ChineseContentValidator.validateTitle(t) ?? ChineseContentValidator.validateDescriptionOrComment(desc) {
            alertMessage = err
            return
        }
        guard validateChineseAndNumberQuality(t + desc + name) else {
            alertMessage = "标题、描述和联系人请使用中文、数字或常见标点"
            return
        }
        if !phone.isEmpty, phone.range(of: #"^[0-9+\-\s]{5,20}$"#, options: .regularExpression) == nil {
            alertMessage = "电话格式不正确"
            return
        }
        if !wechat.isEmpty, wechat.range(of: #"^[A-Za-z0-9_\-]{3,30}$"#, options: .regularExpression) == nil {
            alertMessage = "微信号格式不正确"
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        guard let image = await savePickerImageToDisk(photoItem) else {
            alertMessage = "图片保存失败，请重新选择"
            return
        }
        let contact = [
            phone.isEmpty ? nil : "电话：\(phone)",
            wechat.isEmpty ? nil : "微信：\(wechat)",
        ].compactMap { $0 }.joined(separator: "；")
        let draft = DonationDraft(
            title: t,
            description: desc,
            imageURL: image,
            type: type,
            target: target,
            contactName: name,
            contactPhone: contact
        )
        if let err = await onSubmit(draft) {
            alertMessage = err
            return
        }
        dismiss()
    }

    private func validateChineseAndNumberQuality(_ text: String) -> Bool {
        text.range(of: #"^[\u4e00-\u9fa5A-Za-z0-9，。！？、：；（）()《》“”\s+\-]+$"#, options: .regularExpression) != nil
    }

    private func savePickerImageToDisk(_ item: PhotosPickerItem?) async -> String? {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return nil }
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("donation_uploads", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("\(UUID().uuidString).jpg")
        guard (try? data.write(to: file)) != nil else { return nil }
        return file.absoluteString
    }
}
