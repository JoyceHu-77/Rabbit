//
//  RescueDetailView.swift
//  Rabbit_iOS — 对应 RescueDetail.tsx 主要区块（状态流转、编辑、留言）
//

import PhotosUI
import SwiftUI

struct RescueDetailView: View {
    @Environment(AppDataStore.self) private var store

    @State var post: RescueDisplayPost
    let viewerUserName: String
    var onSave: () -> Void

    @State private var newComment = ""
    @State private var comments: [(author: String, content: String, date: String)] = [
        ("爱心志愿者", "已经联系发现人，明天去现场查看情况", "2025-03-15 14:30"),
    ]
    @State private var showRescueApply = false
    @State private var rescueName = ""
    @State private var rescueContact = ""
    @State private var showAdminQR = false
    @State private var tempWechatQR = ""
    @State private var qrPickerItem: PhotosPickerItem?
    @State private var showEdit = false
    @State private var toast: String?
    @State private var showRejectSheet = false
    @State private var rejectReason = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroSection

                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(post.title)
                            .font(.title2.bold())

                        Text("编号 \(post.id)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(.tertiarySystemFill), in: Capsule())
                    }

                    moderationBanners
                    infoGrid
                    descriptionSection

                    if let name = post.finderName, !name.isEmpty {
                        finderSection(name: name)
                    }

                    if RescueWechatQR.hasDisplayableQR(post.wechatQR) {
                        statusFollowSection
                    }

                    commentsSection

                    if store.isAdmin {
                        moderationSection
                        adminSection
                    }
                }
                .padding(.horizontal, LayoutMetrics.horizontalInset)
                .padding(.top, 20)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.06), radius: 16, y: -6)
                }
                .padding(.top, -22)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.screenBg.ignoresSafeArea())
        .navigationTitle("救援详情")
        .navigationBarTitleDisplayMode(.inline)
        .rescueDetailChrome()
        .toolbar {
            if store.isAdmin {
                ToolbarItem(placement: .primaryAction) {
                    Button("编辑") { showEdit = true }
                        .fontWeight(.semibold)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !store.isAdmin, post.status == "待救援", post.moderationStatus == "approved" {
                rescueCTABar
            }
        }
        .sheet(isPresented: $showRescueApply) {
            NavigationStack {
                Form {
                    TextField("您的称呼", text: $rescueName)
                    TextField("联系方式", text: $rescueContact)
                }
                .navigationTitle("救援申请")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("取消") { showRescueApply = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("提交") {
                            guard !rescueName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            guard !rescueContact.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            showRescueApply = false
                            UserInboxStore.append(
                                title: "救援申请已提交",
                                body: "我们已收到您对 \(post.id) 的救援意向，将通知发现人与管理员。"
                            )
                            let n = AdminNotificationRecord(
                                id: "ADM\(Int(Date().timeIntervalSince1970 * 1000))",
                                type: "rescue",
                                title: "新救援申请",
                                content: "帖子 \(post.id)（\(post.title)）有用户申请参与救援。",
                                createdAt: Date(),
                                read: false
                            )
                            AdminNotificationsStore.append(n)
                            toast = "已提交救援申请，已通知管理员"
                            rescueName = ""
                            rescueContact = ""
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showAdminQR) {
            adminQRUploadSheet
        }
        .sheet(isPresented: $showEdit) {
            EditRescuePostView(post: $post) {
                store.upsertRescue(post)
                onSave()
                showEdit = false
            }
        }
        .sheet(isPresented: $showRejectSheet) {
            NavigationStack {
                Form {
                    Section("驳回原因（将通知发帖人）") {
                        TextField("请填写原因", text: $rejectReason, axis: .vertical)
                            .lineLimit(3 ... 8)
                    }
                }
                .navigationTitle("驳回审核")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            showRejectSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("确认驳回") {
                            post.moderationStatus = "rejected"
                            post.auditRejectionReason = rejectReason.trimmingCharacters(in: .whitespacesAndNewlines)
                            persist()
                            UserInboxStore.append(
                                title: "救援帖未通过审核",
                                body: "「\(post.title)」(\(post.id))：\(post.auditRejectionReason ?? "")"
                            )
                            showRejectSheet = false
                            rejectReason = ""
                            toast = "已驳回并通知发帖人"
                        }
                        .disabled(rejectReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .overlay(alignment: .top) {
            if let t = toast {
                Text(t)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 8)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toast = nil }
                    }
            }
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            TabView {
                ForEach(post.images, id: \.self) { u in
                    PostImageView(
                        urlString: u,
                        rescuePostId: post.id,
                        sourceRabbitId: post.sourceRabbitId
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: post.images.count > 1 ? .always : .never))
            .frame(height: 300)

            LinearGradient(
                colors: [.clear, .black.opacity(0.45)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            HStack(alignment: .bottom) {
                Text(post.status)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(statusAccent.foreground)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusAccent.background, in: Capsule())
                    .overlay(Capsule().strokeBorder(.white.opacity(0.35)))
                Spacer()
            }
            .padding(16)
        }
        .frame(height: 300)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 20,
                bottomTrailingRadius: 20,
                topTrailingRadius: 0,
                style: .continuous
            )
        )
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }

    @ViewBuilder
    private var moderationBanners: some View {
        if post.moderationStatus == "pending" {
            Label("该帖待管理员审核，仅发帖人与管理员可见完整流程", systemImage: "clock.fill")
                .font(.subheadline)
                .foregroundStyle(.orange)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        if post.moderationStatus == "rejected" {
            VStack(alignment: .leading, spacing: 6) {
                Label("审核未通过", systemImage: "xmark.circle.fill")
                    .foregroundStyle(Theme.red600)
                if let r = post.auditRejectionReason, !r.isEmpty {
                    Text(r).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.red600.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var infoGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            infoChip(icon: "mappin.and.ellipse", text: post.location, tint: Theme.red600, fill: Theme.red600.opacity(0.08))
            infoChip(icon: "calendar", text: post.date, tint: Theme.red600, fill: Theme.red600.opacity(0.08))
            if let h = post.healthStatus, !h.isEmpty {
                infoChip(icon: "heart.fill", text: h, tint: .green, fill: Color.green.opacity(0.1))
            }
            if let s = post.sterilizedStatus, !s.isEmpty {
                infoChip(icon: "checkmark.circle.fill", text: s, tint: .blue, fill: Color.blue.opacity(0.1))
            }
            if let org = post.organizerName, !org.isEmpty {
                infoChip(icon: "person.fill", text: "主理人 \(org)", tint: .purple, fill: Color.purple.opacity(0.1))
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("详细描述", icon: "text.alignleft")
            Text(post.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .detailCard()
    }

    private func finderSection(name: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("发现人信息", icon: "person.crop.circle")
            VStack(alignment: .leading, spacing: 8) {
                Label(displayFinderName(name), systemImage: "person")
                if let c = post.finderContact, !c.isEmpty {
                    Label(displayFinderContact(c), systemImage: "phone")
                }
                if !store.isAdmin, !post.finderIsPublic {
                    Text("* 关键信息已脱敏，仅管理员可见")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .detailCard(fill: Theme.red600.opacity(0.05), stroke: Theme.red600.opacity(0.15))
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("评论区", icon: "bubble.left.and.bubble.right", trailing: "\(comments.count)")

            if comments.isEmpty {
                Text("暂无评论，兔兔在这里等你哦～")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(Array(comments.enumerated()), id: \.offset) { _, c in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.rose, Color.orange.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                            .overlay {
                                Text(String(c.author.prefix(1)))
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(c.author).font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(c.date).font(.caption2).foregroundStyle(.tertiary)
                            }
                            Text(c.content)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                TextField("写下留言…", text: $newComment, axis: .vertical)
                    .lineLimit(2 ... 6)
                    .padding(12)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button {
                    submitComment()
                } label: {
                    Label("发送留言", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.red600)
            }
        }
        .detailCard()
    }

    private var rescueCTABar: some View {
        Button {
            showRescueApply = true
        } label: {
            Label("我要救援", systemImage: "hands.sparkles.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.red600)
        .padding(.horizontal, LayoutMetrics.horizontalInset)
        .padding(.vertical, 14)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Theme.red600.opacity(0.35))
                        .frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var statusAccent: (background: Color, foreground: Color) {
        switch post.status {
        case "待救援": return (Theme.red600.opacity(0.9), .white)
        case "救援中": return (Color.orange.opacity(0.92), .white)
        case "已救援": return (Color.blue.opacity(0.88), .white)
        case "寄养中": return (Color.purple.opacity(0.88), .white)
        case "已领养": return (Color.green.opacity(0.88), .white)
        default: return (Color.gray.opacity(0.75), .white)
        }
    }

    private func sectionTitle(_ title: String, icon: String, trailing: String? = nil) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.red600)
            Text(title)
                .font(.headline)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemFill), in: Capsule())
            }
        }
    }

    private func infoChip(icon: String, text: String, tint: Color, fill: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(tint)
            Text(text)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func submitComment() {
        let t = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        if let err = ChineseContentValidator.validateDescriptionOrComment(t) {
            toast = err
            return
        }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        comments.append(("我", t, f.string(from: Date())))
        newComment = ""
        toast = "留言已发送"
    }

    private var statusFollowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("状态跟进", icon: "qrcode")
            Text(RescueWechatQR.statusFollowSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
            WechatQRImageView(stored: post.wechatQR, maxHeight: 160)
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Theme.red600.opacity(0.08), radius: 8, y: 2)
        }
        .detailCard(fill: Theme.red600.opacity(0.05), stroke: Theme.red600.opacity(0.18))
    }

    private var adminQRUploadSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("请上传兔兔状态跟进微信群的二维码，上传后将在帖子详情页展示")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                PhotosPicker(selection: $qrPickerItem, matching: .images) {
                    Label(tempWechatQR.isEmpty ? "选择图片" : "重新选择图片", systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)

                if RescueWechatQR.hasDisplayableQR(tempWechatQR) {
                    WechatQRImageView(stored: tempWechatQR, maxHeight: 160)
                        .frame(width: 160, height: 160)
                        .padding(8)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    submitAdminQRAndAdvanceStatus()
                } label: {
                    Text("确认上传并更新状态")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(tempWechatQR.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)

                Spacer(minLength: 0)
            }
            .padding(.top, 20)
            .navigationTitle("上传微信群二维码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showAdminQR = false
                        qrPickerItem = nil
                    }
                }
            }
            .onChange(of: qrPickerItem) { _, item in
                guard let item else { return }
                Task { await loadQRFromPicker(item) }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func loadQRFromPicker(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let jpeg = image.jpegData(compressionQuality: 0.85)
        else { return }
        await MainActor.run {
            tempWechatQR = RescueWechatQR.dataURL(from: jpeg)
        }
    }

    private func submitAdminQRAndAdvanceStatus() {
        guard RescueWechatQR.hasDisplayableQR(tempWechatQR),
              let next = RescuePostLogic.statusFlowNext(post.status)
        else { return }
        post.status = next
        post.wechatQR = tempWechatQR
        persist()
        toast = "状态已更新为「\(next)」"
        showAdminQR = false
        qrPickerItem = nil
        tempWechatQR = ""
    }

    private func displayFinderName(_ raw: String) -> String {
        if store.isAdmin || post.finderIsPublic { return raw }
        if raw.count <= 1 { return "*" }
        return String(raw.prefix(1)) + String(repeating: "*", count: max(1, raw.count - 1))
    }

    private func displayFinderContact(_ raw: String) -> String {
        if store.isAdmin || post.finderIsPublic { return raw }
        return String(repeating: "*", count: min(11, max(4, raw.count)))
    }

    @ViewBuilder
    private var moderationSection: some View {
        if post.moderationStatus == "pending" {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("内容审核", icon: "checkmark.seal")
                HStack(spacing: 12) {
                    Button("通过审核") {
                        post.moderationStatus = "approved"
                        persist()
                        UserInboxStore.append(title: "救援帖已通过审核", body: "「\(post.title)」（\(post.id)）现已对外展示。")
                        toast = "已通过审核"
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    Button("驳回") {
                        showRejectSheet = true
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
            .detailCard(fill: Color.green.opacity(0.08), stroke: Color.green.opacity(0.2))
        }
    }

    @ViewBuilder
    private var adminSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("管理员操作", icon: "shield.lefthalf.filled")
            if post.moderationStatus == "approved" {
                if let next = RescuePostLogic.statusFlowNext(post.status) {
                    Button(RescuePostLogic.adminCompleteLabel(for: post.status)) {
                        if RescuePostLogic.completeRequiresWeChatQR(post.status) {
                            tempWechatQR = post.wechatQR ?? ""
                            showAdminQR = true
                        } else {
                            post.status = next
                            persist()
                            toast = "状态已更新为「\(next)」"
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
                if post.status != "已领养", post.status != "已去世" {
                    Button("标记已去世", role: .destructive) {
                        post.status = "已去世"
                        persist()
                        toast = "状态已更新为「已去世」"
                    }
                    .buttonStyle(.bordered)
                }
            } else if post.moderationStatus == "pending" {
                Text("请先完成上方「内容审核」后再进行状态流转。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .detailCard(fill: Color.orange.opacity(0.08), stroke: Color.orange.opacity(0.22))
    }

    private func persist() {
        store.upsertRescue(post)
        onSave()
        guard RabbitAPIConfiguration.normalizedBaseURL() != nil else { return }
        Task {
            do {
                let updated = try await RabbitAPIService.updateRescue(post)
                await MainActor.run {
                    post = updated
                    store.upsertRescue(updated)
                }
            } catch {
                await MainActor.run {
                    toast = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }
}

// MARK: - 详情页卡片样式

private extension View {
    func detailCard(
        fill: Color = Color(.secondarySystemGroupedBackground),
        stroke: Color = Color(.separator).opacity(0.35)
    ) -> some View {
        padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(stroke, lineWidth: 1)
            }
    }
}

private struct EditRescuePostView: View {
    @Binding var post: RescueDisplayPost
    @Environment(\.dismiss) private var dismiss
    var onDone: () -> Void

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var location: String = ""
    @State private var status: String = ""
    @State private var health: String = ""
    @State private var steril: String = ""
    @State private var orgName: String = ""
    @State private var wechatQR: String = ""
    @State private var qrPickerItem: PhotosPickerItem?

    private let statuses = ["待救援", "救援中", "已救援", "寄养中", "已领养", "已去世"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("标题", text: $title)
                TextField("地点", text: $location)
                Picker("状态", selection: $status) {
                    ForEach(statuses, id: \.self) { Text($0).tag($0) }
                }
                TextField("健康状况摘要", text: $health)
                TextField("绝育状况摘要", text: $steril)
                TextField("主理人", text: $orgName)
                TextField("描述", text: $description, axis: .vertical)
                    .lineLimit(4 ... 14)
                Section("微信群二维码") {
                    PhotosPicker(selection: $qrPickerItem, matching: .images) {
                        Label(
                            RescueWechatQR.hasDisplayableQR(wechatQR) ? "修改二维码" : "上传二维码",
                            systemImage: "qrcode"
                        )
                    }
                    if RescueWechatQR.hasDisplayableQR(wechatQR) {
                        WechatQRImageView(stored: wechatQR, maxHeight: 80)
                            .frame(width: 80, height: 80)
                        Button("删除二维码", role: .destructive) {
                            wechatQR = ""
                            qrPickerItem = nil
                        }
                    }
                }
            }
            .onAppear {
                title = post.title
                description = post.description
                location = post.location
                status = post.status
                health = post.healthStatus ?? ""
                steril = post.sterilizedStatus ?? ""
                orgName = post.organizerName ?? ""
                wechatQR = post.wechatQR ?? ""
            }
            .onChange(of: qrPickerItem) { _, item in
                guard let item else { return }
                Task {
                    guard let data = try? await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data),
                          let jpeg = image.jpegData(compressionQuality: 0.85)
                    else { return }
                    await MainActor.run {
                        wechatQR = RescueWechatQR.dataURL(from: jpeg)
                    }
                }
            }
            .navigationTitle("编辑帖子")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        post.title = title
                        post.description = description
                        post.location = location
                        let parts = location.split(separator: "-").map(String.init)
                        post.city = parts.first ?? location
                        post.district = parts.count > 1 ? parts[1] : ""
                        post.status = status
                        post.healthStatus = health.isEmpty ? nil : health
                        post.sterilizedStatus = steril.isEmpty ? nil : steril
                        post.organizerName = orgName.isEmpty ? nil : orgName
                        post.wechatQR = wechatQR.isEmpty ? nil : wechatQR
                        onDone()
                        dismiss()
                    }
                }
            }
        }
    }
}
