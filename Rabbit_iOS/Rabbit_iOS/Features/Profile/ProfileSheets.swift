//
//  ProfileSheets.swift
//  Rabbit_iOS — 消息 / 订单 / 领养意向 / 社区发帖 Sheet
//

import SwiftUI


struct MessagesSheet: View {
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
                        let msgs = UserInboxStore.load()
                        if msgs.isEmpty {
                            Section {
                                Text("暂无站内信")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ForEach(msgs) { m in
                                Button {
                                    UserInboxStore.markRead(id: m.id)
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(m.title).font(.subheadline.weight(.semibold))
                                            Spacer()
                                            if !m.read {
                                                Circle().fill(Color.red).frame(width: 8, height: 8)
                                            }
                                        }
                                        Text(m.body).font(.caption).foregroundStyle(.secondary)
                                        Text(m.createdAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
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
        case "rescue": return "hare.fill"
        default: return "bell.badge"
        }
    }
}

// MARK: - 领养意向 / 爱兔社区发帖 / 订单

struct AdoptionIntentSheet: View {
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
                        let n = AdminNotificationRecord(
                            id: "ADM\(Int(Date().timeIntervalSince1970 * 1000))",
                            type: "adopt",
                            title: "新领养意向",
                            content: "救援帖 \(post.id)（\(rabbitName)）收到领养申请。",
                            createdAt: Date(),
                            read: false
                        )
                        AdminNotificationsStore.append(n)
                        UserInboxStore.append(
                            title: "领养申请已提交",
                            body: "您已提交对 \(rabbitName)（\(post.id)）的领养意向，请等待管理员审核。"
                        )
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

struct CreateRabbitCommunityPostSheet: View {
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

struct OrdersListSheet: View {
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
