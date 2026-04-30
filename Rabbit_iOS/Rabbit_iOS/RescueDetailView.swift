//
//  RescueDetailView.swift
//  Rabbit_iOS — 对应 RescueDetail.tsx 主要区块（状态流转、编辑、留言）
//

import SwiftUI

struct RescueDetailView: View {
    @Environment(AppDataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State var post: RescueDisplayPost
    let isAdmin: Bool
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    imageCarousel

                    Text(post.title)
                        .font(.title2.bold())

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

                    if let qr = post.wechatQR, !qr.isEmpty, qr.hasPrefix("http") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("微信群二维码").font(.headline)
                            AsyncImage(url: URL(string: qr)) { img in
                                img.resizable().scaledToFit()
                            } placeholder: { ProgressView() }
                            .frame(maxHeight: 200)
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
                        guard !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        let f = DateFormatter()
                        f.dateFormat = "yyyy-MM-dd HH:mm"
                        comments.append(("我", newComment, f.string(from: Date())))
                        newComment = ""
                        toast = "留言已发送"
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)

                    if isAdmin {
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
                if isAdmin {
                    ToolbarItem(placement: .primaryAction) {
                        Button("编辑") { showEdit = true }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !isAdmin, post.status != "已领养", post.status != "已去世" {
                    Button {
                        showRescueApply = true
                    } label: {
                        Label("我要参与救援", systemImage: "hands.sparkles.fill")
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
                            toast = "已提交救援申请"
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

    @ViewBuilder
    private var adminSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("管理员操作").font(.headline)
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
