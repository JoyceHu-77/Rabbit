//
//  RescueDetailView.swift
//  Rabbit_iOS — 对应 RescueDetail.tsx 主要区块（状态流转、编辑、留言）
//

import SwiftUI

struct RescueDetailView: View {
    @Environment(AppDataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

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
    @State private var showEdit = false
    @State private var toast: String?
    @State private var showRejectSheet = false
    @State private var rejectReason = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    imageCarousel

                    Text(post.title)
                        .font(.title2.bold())

                    if post.moderationStatus == "pending" {
                        Label("该帖待管理员审核，仅发帖人与管理员可见完整流程", systemImage: "clock.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                    }
                    if post.moderationStatus == "rejected" {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("审核未通过", systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            if let r = post.auditRejectionReason, !r.isEmpty {
                                Text(r).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    }

                    metaRow(icon: "mappin.and.ellipse", text: post.location)
                    metaRow(icon: "calendar", text: post.date)
                    if let org = post.organizerName {
                        metaRow(icon: "person", text: "主理人：\(org)")
                    }

                    if let h = post.healthStatus {
                        Label(h, systemImage: "heart.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                    if let s = post.sterilizedStatus {
                        Label(s, systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }

                    Text(post.description)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    if let name = post.finderName, !name.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("发现人").font(.headline)
                            Text("称呼：\(displayFinderName(name))")
                            if let c = post.finderContact, !c.isEmpty {
                                Text("联系方式：\(displayFinderContact(c))")
                                    .font(.subheadline)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                    }

                    if ["已救援", "寄养中"].contains(post.status) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("状态跟进（微信群）").font(.headline)
                            if let qr = post.wechatQR, !qr.isEmpty, qr.hasPrefix("http") {
                                AsyncImage(url: URL(string: qr)) { img in
                                    img.resizable().scaledToFit()
                                } placeholder: { ProgressView() }
                                .frame(maxHeight: 200)
                            } else {
                                Text("管理员尚未上传微信群二维码，请稍后再来查看或联系协会。")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Divider()

                    Text("留言").font(.headline)
                    ForEach(Array(comments.enumerated()), id: \.offset) { _, c in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(c.author).font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(c.date).font(.caption2).foregroundStyle(.tertiary)
                            }
                            Text(c.content).font(.subheadline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    }

                    TextField("写下留言…", text: $newComment, axis: .vertical)
                        .lineLimit(2 ... 6)
                    Button("发送留言") {
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
                    .buttonStyle(.borderedProminent)
                    .tint(.red)

                    if store.isAdmin {
                        moderationSection
                        adminSection
                    }
                }
                .padding()
            }
            .navigationTitle("救援详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                if store.isAdmin {
                    ToolbarItem(placement: .primaryAction) {
                        Button("编辑") { showEdit = true }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !store.isAdmin, post.status == "待救援", post.moderationStatus == "approved" {
                    Button {
                        showRescueApply = true
                    } label: {
                        Label("我要救援", systemImage: "hands.sparkles.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .padding()
                    .background(.ultraThinMaterial)
                }
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
            NavigationStack {
                Form {
                    Text("完成该步骤需填写微信群二维码图片链接（https）")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    TextField("二维码图片 URL", text: $tempWechatQR)
                        .textInputAutocapitalization(.never)
                }
                .navigationTitle("上传二维码")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("取消") { showAdminQR = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("确认") {
                            if let next = RescuePostLogic.statusFlowNext(post.status) {
                                post.status = next
                                if !tempWechatQR.isEmpty { post.wechatQR = tempWechatQR }
                                persist()
                                toast = "状态已更新为「\(next)」"
                            }
                            showAdminQR = false
                        }
                    }
                }
            }
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

    private var imageCarousel: some View {
        TabView {
            ForEach(post.images, id: \.self) { u in
                PostImageView(urlString: u)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .tabViewStyle(.page(indexDisplayMode: post.images.count > 1 ? .always : .never))
        .frame(height: 260)
    }

    private func metaRow(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.subheadline)
            .foregroundStyle(.secondary)
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
                Text("内容审核").font(.headline)
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
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private var adminSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("管理员操作").font(.headline)
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
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private func persist() {
        store.upsertRescue(post)
        onSave()
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
            }
            .onAppear {
                title = post.title
                description = post.description
                location = post.location
                status = post.status
                health = post.healthStatus ?? ""
                steril = post.sterilizedStatus ?? ""
                orgName = post.organizerName ?? ""
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
                        onDone()
                        dismiss()
                    }
                }
            }
        }
    }
}
