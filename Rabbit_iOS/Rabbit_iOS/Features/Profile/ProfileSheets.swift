//
//  ProfileSheets.swift
//  Rabbit_iOS — 消息 / 订单 / 领养意向 / 社区发帖 Sheet
//

import SwiftUI


struct MessagesSheet: View {
    @Environment(AppDataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private enum MsgTab: Hashable {
        case user, admin
    }

    @State private var tab: MsgTab = .user
    @State private var inbox: [ProfileInboxItem] = []
    @State private var adminList: [ProfileAdminNoticeItem] = []
    @State private var useLocalFallback = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if store.isAdmin {
                    Picker("", selection: $tab) {
                        Text("用户消息").tag(MsgTab.user)
                        Text("管理通知").tag(MsgTab.admin)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }

                if tab == .user || !store.isAdmin {
                    List {
                        if useLocalFallback {
                            let local = localInboxRecords()
                            if local.isEmpty {
                                Text("暂无站内信").foregroundStyle(.secondary)
                            } else {
                                ForEach(local) { m in
                                    localInboxRow(m)
                                }
                            }
                        } else if inbox.isEmpty {
                            Text("暂无站内信").foregroundStyle(.secondary)
                        } else {
                            ForEach(inbox) { m in
                                inboxRow(m)
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
                                adminRow(n)
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
            .task { await reloadMessages() }
            .onChange(of: store.isAdmin) { _, isAdmin in
                if !isAdmin { tab = .user }
            }
        }
    }

    @ViewBuilder
    private func inboxRow(_ m: ProfileInboxItem) -> some View {
        Button {
            Task { await markInboxRead(m) }
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

    @ViewBuilder
    private func localInboxRow(_ m: UserInboxRecord) -> some View {
        Button {
            UserInboxStore.markRead(id: m.id)
            Task { await store.refreshProfileBadgeCounts() }
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

    @ViewBuilder
    private func adminRow(_ n: ProfileAdminNoticeItem) -> some View {
        Button {
            Task { await markAdminRead(n) }
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

    private func localInboxRecords() -> [UserInboxRecord] {
        UserInboxStore.load()
    }

    @MainActor
    private func reloadMessages() async {
        guard RabbitAPIConfiguration.normalizedBaseURL() != nil else {
            useLocalFallback = true
            adminList = []
            return
        }
        useLocalFallback = false
        do {
            inbox = try await RabbitAPIService.fetchProfileInbox()
        } catch {
            useLocalFallback = true
        }
        if store.isAdmin {
            adminList = (try? await RabbitAPIService.fetchAdminNotifications()) ?? []
        }
        await store.refreshProfileBadgeCounts()
    }

    @MainActor
    private func markInboxRead(_ m: ProfileInboxItem) async {
        guard !m.read else { return }
        if let i = inbox.firstIndex(where: { $0.id == m.id }) {
            inbox[i].read = true
        }
        try? await RabbitAPIService.markProfileInboxRead(messageId: m.id)
        await store.refreshProfileBadgeCounts()
    }

    @MainActor
    private func markAdminRead(_ n: ProfileAdminNoticeItem) async {
        guard !n.read else { return }
        if let i = adminList.firstIndex(where: { $0.id == n.id }) {
            adminList[i].read = true
        }
        try? await RabbitAPIService.markAdminNotificationRead(id: n.id)
        await store.refreshProfileBadgeCounts()
    }

    private var titleText: String {
        if !store.isAdmin || tab == .user {
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
    let onSubmitted: (String) -> Void

    @Environment(AppDataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var isSubmitting = false

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
                        Task { await submitIntent() }
                    }
                    .disabled(isSubmitting || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || phone.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
                }
            }
        }
    }

    @MainActor
    private func submitIntent() async {
        let applicant = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let phoneTrim = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        isSubmitting = true
        defer { isSubmitting = false }

        if RabbitAPIConfiguration.normalizedBaseURL() != nil {
            do {
                try await RabbitAPIService.createAdoptionIntent(
                    AdoptionIntentDraft(
                        rescueId: post.id,
                        applicantName: applicant,
                        applicantPhone: phoneTrim,
                        note: nil
                    )
                )
                onSubmitted("领养意向已提交，请等待管理员审核")
                await store.refreshProfileBadgeCounts()
                dismiss()
                return
            } catch {
                onSubmitted((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
                return
            }
        }

        notifyLocalAfterSubmit()
        onSubmitted("领养意向已提交（本地）")
        dismiss()
    }

    private func notifyLocalAfterSubmit() {
        AdminNotificationsStore.append(
            AdminNotificationRecord(
                id: "ADM\(Int(Date().timeIntervalSince1970 * 1000))",
                type: "adopt",
                title: "新领养意向",
                content: "救援帖 \(post.id)（\(rabbitName)）收到领养申请。",
                createdAt: Date(),
                read: false
            )
        )
        UserInboxStore.append(
            title: "领养申请已提交",
            body: "您已提交对 \(rabbitName)（\(post.id)）的领养意向，请等待管理员审核。"
        )
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
    @State private var isPublishing = false

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
                        Task { await publishPost() }
                    }
                }
            }
        }
    }

    @MainActor
    private func publishPost() async {
        let draft = CommunityPostDraft(
            authorName: author.isEmpty ? "爱心网友" : author,
            title: title.isEmpty ? "分享" : title,
            content: content,
            images: imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [] : [imageURL]
        )
        isPublishing = true
        defer { isPublishing = false }

        if RabbitAPIConfiguration.normalizedBaseURL() != nil {
            do {
                let saved = try await RabbitAPIService.createCommunityPost(draft)
                var all = await RabbitAPIService.fetchCommunityPosts()
                if all.isEmpty {
                    RabbitCommunityStore.append(saved)
                    all = RabbitCommunityStore.load()
                } else {
                    RabbitCommunityStore.replaceAll(all)
                }
                onSaved()
                dismiss()
                return
            } catch {
                return
            }
        }

        let p = RabbitCommunityPost(
            id: "RC\(Int(Date().timeIntervalSince1970 * 1000))",
            authorName: draft.authorName,
            title: draft.title,
            content: draft.content,
            images: draft.images,
            createdAt: Date(),
            likes: 0,
            likedByUser: false
        )
        RabbitCommunityStore.append(p)
        onSaved()
        dismiss()
    }
}

struct OrdersListSheet: View {
    @Environment(AppDataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let onCloudCoinsEarned: (Int) -> Void

    @State private var orders: [ProfileOrderItem] = []
    @State private var payingOrderId: String?
    @State private var useLocalDemo = false

    var body: some View {
        NavigationStack {
            List {
                Section("待支付") {
                    if useLocalDemo {
                        localPendingRow
                    } else {
                        let pending = orders.filter(\.isPending)
                        if pending.isEmpty {
                            Text("暂无待支付订单").foregroundStyle(.secondary)
                        } else {
                            ForEach(pending) { order in
                                orderPendingRow(order)
                            }
                        }
                    }
                }
                Section("已完成") {
                    let paid = orders.filter { !$0.isPending }
                    if useLocalDemo {
                        Text("暂无").foregroundStyle(.secondary)
                    } else if paid.isEmpty {
                        Text("暂无").foregroundStyle(.secondary)
                    } else {
                        ForEach(paid) { order in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(order.title)
                                Text(order.subtitle).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("我的订单")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .task { await loadOrders() }
        }
    }

    private var localPendingRow: some View {
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

    @ViewBuilder
    private func orderPendingRow(_ order: ProfileOrderItem) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(order.title)
                Text(order.subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(payingOrderId == order.id ? "处理中…" : "模拟支付完成") {
                Task { await payOrder(order) }
            }
            .disabled(payingOrderId != nil)
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }

    @MainActor
    private func loadOrders() async {
        guard RabbitAPIConfiguration.normalizedBaseURL() != nil else {
            useLocalDemo = true
            return
        }
        useLocalDemo = false
        orders = (try? await RabbitAPIService.fetchProfileOrders()) ?? []
        if orders.isEmpty {
            useLocalDemo = true
        }
    }

    @MainActor
    private func payOrder(_ order: ProfileOrderItem) async {
        payingOrderId = order.id
        defer { payingOrderId = nil }
        guard RabbitAPIConfiguration.normalizedBaseURL() != nil else { return }
        do {
            let result = try await RabbitAPIService.payProfileOrder(orderId: order.id)
            store.applyProfileFromServer(result.profile)
            onCloudCoinsEarned(result.cloudCoinsGranted)
            await loadOrders()
            await store.refreshProfileBadgeCounts()
            dismiss()
        } catch {
            onCloudCoinsEarned(0)
        }
    }
}
