//
//  ProfileSheets.swift
//  Rabbit_iOS — 消息 / 订单 / 领养意向 / 社区发帖 Sheet
//

import PhotosUI
import SwiftUI


private enum InboxMessageRoute: Hashable {
    case remote(ProfileInboxItem)
    case local(UserInboxRecord)
}

private enum AdminNoticeRoute: Hashable {
    case remote(ProfileAdminNoticeItem)
}

private enum MessageDetailSelection: Hashable {
    case inbox(InboxMessageRoute)
    case admin(AdminNoticeRoute)
}

/// 个人页 Push 进入的消息列表（内含二级详情导航）。
struct MessagesFlowView: View {
    @Environment(AppDataStore.self) private var store
    @Environment(MainTabCoordinator.self) private var tabCoordinator
    @Environment(\.dismiss) private var dismiss

    private enum MsgTab: Hashable {
        case user, admin
    }

    @State private var tab: MsgTab = .user
    @State private var inbox: [ProfileInboxItem] = []
    @State private var adminList: [ProfileAdminNoticeItem] = []
    @State private var useLocalFallback = false

    var body: some View {
        List {
            if store.isAdmin {
                Section {
                    Picker("", selection: $tab) {
                        Text("用户消息").tag(MsgTab.user)
                        Text("管理通知").tag(MsgTab.admin)
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                }
            }

            if tab == .user || !store.isAdmin {
                userMessagesSection
            } else {
                adminMessagesSection
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(titleText)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: MessageDetailSelection.self) { selection in
            switch selection {
            case .inbox(let route):
                inboxDetail(for: route)
            case .admin(let route):
                adminDetail(for: route)
            }
        }
        .task { await reloadMessages() }
        .onChange(of: store.isAdmin) { _, isAdmin in
            if !isAdmin { tab = .user }
        }
    }

    @ViewBuilder
    private func inboxDetail(for route: InboxMessageRoute) -> some View {
        switch route {
        case .remote(let m):
            InboxMessageDetailView(
                title: m.title,
                messageBody: m.body,
                createdAt: m.createdAt,
                read: m.read
            ) {
                Task { await markInboxRead(m) }
            }
        case .local(let m):
            InboxMessageDetailView(
                title: m.title,
                messageBody: m.body,
                createdAt: m.createdAt,
                read: m.read
            ) {
                UserInboxStore.markRead(id: m.id)
                Task { await store.refreshProfileBadgeCounts() }
            }
        }
    }

    @ViewBuilder
    private func adminDetail(for route: AdminNoticeRoute) -> some View {
        switch route {
        case .remote(let n):
            AdminNoticeDetailView(notice: n) {
                Task { await markAdminRead(n) }
            } onNavigate: { action in
                handleAdminAction(action)
            }
        }
    }

    @ViewBuilder
    private var userMessagesSection: some View {
        Section {
            if useLocalFallback {
                let local = localInboxRecords()
                if local.isEmpty {
                    ContentUnavailableView("暂无消息", systemImage: "tray")
                } else {
                    ForEach(local) { m in
                        NavigationLink(value: MessageDetailSelection.inbox(.local(m))) {
                            inboxRowLabel(title: m.title, body: m.body, createdAt: m.createdAt, read: m.read)
                        }
                        .listRowBackground(m.read ? nil : Color.red.opacity(0.06))
                    }
                }
            } else if inbox.isEmpty {
                ContentUnavailableView("暂无消息", systemImage: "tray")
            } else {
                ForEach(inbox) { m in
                    NavigationLink(value: MessageDetailSelection.inbox(.remote(m))) {
                        inboxRowLabel(title: m.title, body: m.body, createdAt: m.createdAt, read: m.read)
                    }
                    .listRowBackground(m.read ? nil : Color.red.opacity(0.06))
                }
            }
        } header: {
            Text("消息中心")
        } footer: {
            Text("点击任意消息查看详情；未读消息打开后自动标记已读。")
        }
    }

    @ViewBuilder
    private var adminMessagesSection: some View {
        Section {
            if adminList.isEmpty {
                ContentUnavailableView(
                    "暂无待处理",
                    systemImage: "bell.slash",
                    description: Text("用户支付或提交救援帖后会在此出现通知。")
                )
            } else {
                ForEach(adminList) { n in
                    NavigationLink(value: MessageDetailSelection.admin(.remote(n))) {
                        adminRowLabel(n)
                    }
                    .listRowBackground(n.read ? nil : Color.orange.opacity(0.06))
                }
            }
        } header: {
            Text("管理通知")
        }
    }

    private func inboxRowLabel(title: String, body: String, createdAt: Date, read: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                if !read {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                }
            }
            Text(body)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Text(createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .profileCellHitArea()
    }

    private func adminRowLabel(_ n: ProfileAdminNoticeItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName(for: n.type))
                .foregroundStyle(.orange)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(n.title).font(.subheadline.weight(.semibold))
                    Spacer()
                    if !n.read {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                    }
                }
                Text(n.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(n.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .profileCellHitArea()
    }

    private func handleAdminAction(_ action: ProfileAdminNavigateAction) {
        dismiss()
        switch action {
        case .openRescueModeration:
            tabCoordinator.select(.rescue)
        case .openOrders:
            store.pendingProfileRoute = .orders
        }
    }

    private func localInboxRecords() -> [UserInboxRecord] {
        UserInboxStore.load()
    }

    @MainActor
    private func reloadMessages() async {
        UserInboxStore.ensureDemoSeedIfNeeded()
        guard RabbitAPIConfiguration.normalizedBaseURL() != nil else {
            useLocalFallback = true
            adminList = store.isAdmin ? localAdminNoticeItems() : []
            return
        }
        useLocalFallback = false
        do {
            inbox = try await RabbitAPIService.fetchProfileInbox()
            if inbox.isEmpty {
                useLocalFallback = true
            }
        } catch {
            useLocalFallback = true
        }
        if store.isAdmin {
            let remoteAdmin = (try? await RabbitAPIService.fetchAdminNotifications()) ?? []
            adminList = remoteAdmin.isEmpty ? localAdminNoticeItems() : remoteAdmin
        }
        await store.refreshProfileBadgeCounts()
    }

    @MainActor
    private func markInboxRead(_ m: ProfileInboxItem) async {
        if let i = inbox.firstIndex(where: { $0.id == m.id }), !inbox[i].read {
            inbox[i].read = true
            try? await RabbitAPIService.markProfileInboxRead(messageId: m.id)
            await store.refreshProfileBadgeCounts()
        } else if !m.read {
            try? await RabbitAPIService.markProfileInboxRead(messageId: m.id)
            await store.refreshProfileBadgeCounts()
        }
    }

    @MainActor
    private func markAdminRead(_ n: ProfileAdminNoticeItem) async {
        if useLocalFallback || RabbitAPIConfiguration.normalizedBaseURL() == nil {
            AdminNotificationsStore.markRead(id: n.id)
            if let i = adminList.firstIndex(where: { $0.id == n.id }) {
                adminList[i].read = true
            }
            await store.refreshProfileBadgeCounts()
            return
        }
        if let i = adminList.firstIndex(where: { $0.id == n.id }), !adminList[i].read {
            adminList[i].read = true
            try? await RabbitAPIService.markAdminNotificationRead(id: n.id)
            await store.refreshProfileBadgeCounts()
        } else if !n.read {
            try? await RabbitAPIService.markAdminNotificationRead(id: n.id)
            await store.refreshProfileBadgeCounts()
        }
    }

    private func localAdminNoticeItems() -> [ProfileAdminNoticeItem] {
        AdminNotificationsStore.load().map {
            ProfileAdminNoticeItem(
                id: $0.id,
                type: $0.type,
                title: $0.title,
                content: $0.content,
                createdAt: $0.createdAt,
                read: $0.read
            )
        }
    }

    private var titleText: String {
        if !store.isAdmin || tab == .user {
            return "消息中心"
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
        case "donation": return "gift.fill"
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
                notifyLocalAfterSubmit()
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
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var isPublishing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("发布信息（均为必填）") {
                    TextField("标题", text: $title)
                    TextField("昵称", text: $author)
                    TextField("正文", text: $content, axis: .vertical)
                        .lineLimit(3 ... 8)
                }
                Section("图片（最多 10 张，必填）") {
                    PhotosPicker(selection: $photoItems, maxSelectionCount: 10, matching: .images) {
                        Label(photoItems.isEmpty ? "从相册选择图片" : "已选 \(photoItems.count) 张，点击重选", systemImage: "photo.on.rectangle.angled")
                    }
                    TextField("或填写图片 URL", text: $imageURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("发布动态")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isPublishing ? "发布中..." : "发布") {
                        Task { await publishPost() }
                    }
                    .disabled(isPublishing)
                }
            }
        }
    }

    @MainActor
    private func publishPost() async {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let a = author.trimmingCharacters(in: .whitespacesAndNewlines)
        let c = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = imageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { errorMessage = "请输入标题"; return }
        guard !a.isEmpty else { errorMessage = "请输入昵称"; return }
        guard !c.isEmpty else { errorMessage = "请输入正文"; return }
        if let err = ChineseContentValidator.validateTitle(t) ?? ChineseContentValidator.validateDescriptionOrComment(c) {
            errorMessage = err
            return
        }
        isPublishing = true
        errorMessage = nil
        defer { isPublishing = false }

        var images = await savePickerImagesToDisk(photoItems, max: 10)
        if !url.isEmpty {
            guard url.hasPrefix("http://") || url.hasPrefix("https://") || url.hasPrefix("file:") else {
                errorMessage = "图片 URL 格式不正确"
                return
            }
            images.append(url)
        }
        guard !images.isEmpty else {
            errorMessage = "请至少上传一张图片"
            return
        }
        let draft = CommunityPostDraft(authorName: a, title: t, content: c, images: Array(images.prefix(10)))

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
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
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
        UserInboxStore.append(title: "动态发布成功", body: "您发布的「\(draft.title)」已展示在爱兔社区。")
        onSaved()
        dismiss()
    }

    private func savePickerImagesToDisk(_ items: [PhotosPickerItem], max: Int) async -> [String] {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("rabbit_community_uploads", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var urls: [String] = []
        for item in items.prefix(max) {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            let file = dir.appendingPathComponent("\(UUID().uuidString).jpg")
            guard (try? data.write(to: file)) != nil else { continue }
            urls.append(file.absoluteString)
        }
        return urls
    }
}

private enum OrderDetailRoute: Hashable {
    case remote(ProfileOrderItem)
    case localDemo
}

struct OrdersFlowView: View {
    @Environment(AppDataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let onCloudCoinsEarned: (Int) -> Void

    @State private var orders: [ProfileOrderItem] = []
    @State private var payingOrderId: String?
    @State private var useLocalDemo = false

    var body: some View {
        List {
            Section {
                if useLocalDemo {
                    NavigationLink(value: OrderDetailRoute.localDemo) {
                        orderRowLabel(
                            title: "爱心橱窗 · 电子照片",
                            subtitle: "¥5 · 演示订单",
                            reward: 5,
                            isPending: true
                        )
                    }
                } else {
                    let pending = orders.filter(\.isPending)
                    if pending.isEmpty {
                        ContentUnavailableView("暂无待支付订单", systemImage: "bag")
                    } else {
                        ForEach(pending) { order in
                            NavigationLink(value: OrderDetailRoute.remote(order)) {
                                orderRowLabel(
                                    title: order.title,
                                    subtitle: order.subtitle,
                                    reward: order.cloudCoinsReward,
                                    isPending: true
                                )
                            }
                        }
                    }
                }
            } header: {
                Text("待支付")
            }

            Section {
                let paid = orders.filter { !$0.isPending }
                if useLocalDemo {
                    Text("完成支付后显示在这里").font(.caption).foregroundStyle(.secondary)
                } else if paid.isEmpty {
                    Text("暂无已完成订单").foregroundStyle(.secondary)
                } else {
                    ForEach(paid) { order in
                        NavigationLink(value: OrderDetailRoute.remote(order)) {
                            orderRowLabel(
                                title: order.title,
                                subtitle: order.subtitle,
                                reward: order.cloudCoinsReward,
                                isPending: false
                            )
                        }
                    }
                }
            } header: {
                Text("已完成")
            } footer: {
                Text("点击订单进入详情；演示环境可使用「模拟支付完成」获得云养币。")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("我的订单")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: OrderDetailRoute.self) { route in
            switch route {
            case .localDemo:
                OrderDetailView(
                    title: "爱心橱窗 · 电子照片",
                    subtitle: "¥5 · 演示订单",
                    status: "pending",
                    cloudCoinsReward: 5,
                    createdAt: Date(),
                    isPaying: payingOrderId == "local-demo"
                ) {
                    payLocalDemo()
                }
            case .remote(let order):
                OrderDetailView(
                    title: order.title,
                    subtitle: order.subtitle,
                    status: order.status,
                    cloudCoinsReward: order.cloudCoinsReward,
                    createdAt: order.createdAt,
                    isPaying: payingOrderId == order.id
                ) {
                    Task { await payOrder(order) }
                }
            }
        }
        .task { await loadOrders() }
    }

    @MainActor
    private func payLocalDemo() {
        payingOrderId = "local-demo"
        defer { payingOrderId = nil }
        onCloudCoinsEarned(5)
        AdminNotificationsStore.appendOrderPaymentNotification(
            title: "爱心橱窗订单待核对",
            amountDescription: "¥5（用户端已发放 5 云养币）"
        )
        dismiss()
    }

    private func orderRowLabel(title: String, subtitle: String, reward: Int, isPending: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
                if isPending, reward > 0 {
                    Text("支付后可得 \(reward) 云养币")
                        .font(.caption2)
                        .foregroundStyle(.pink)
                }
            }
        }
        .profileCellHitArea()
    }

    @MainActor
    private func loadOrders() async {
        guard RabbitAPIConfiguration.normalizedBaseURL() != nil else {
            useLocalDemo = true
            orders = []
            return
        }
        useLocalDemo = false
        orders = (try? await RabbitAPIService.fetchProfileOrders()) ?? []
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
        } catch {
            onCloudCoinsEarned(0)
        }
    }
}

// MARK: - 消息 / 通知 / 订单详情（二级页）

enum ProfileAdminNavigateAction {
    case openRescueModeration
    case openOrders
}

private enum ProfileMessageParser {
    static func rescueId(in text: String) -> String? {
        let pattern = #"R\d{3,}"#
        guard let re = try? NSRegularExpression(pattern: pattern),
              let m = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let r = Range(m.range, in: text)
        else { return nil }
        return String(text[r])
    }
}

struct InboxMessageDetailView: View {
    let title: String
    let messageBody: String
    let createdAt: Date
    let read: Bool
    let onAppearMarkRead: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "envelope.open.fill")
                        .font(.title2)
                        .foregroundStyle(.pink)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.title3.weight(.semibold))
                        Text(createdAt.formatted(date: .complete, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !read {
                    Label("未读", systemImage: "circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                        .labelStyle(.titleAndIcon)
                }

                Text(messageBody)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .navigationTitle("消息详情")
        .navigationBarTitleDisplayMode(.inline)
        .task { onAppearMarkRead() }
    }
}

struct AdminNoticeDetailView: View {
    let notice: ProfileAdminNoticeItem
    let onAppearMarkRead: () -> Void
    let onNavigate: (ProfileAdminNavigateAction) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: adminIconName)
                        .font(.title2)
                        .foregroundStyle(.orange)
                        .frame(width: 36)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(notice.title)
                            .font(.title3.weight(.semibold))
                        Text(notice.createdAt.formatted(date: .complete, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !notice.read {
                    Label("待处理", systemImage: "circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }

                Text(notice.content)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let rescueId = ProfileMessageParser.rescueId(in: notice.content) {
                    Text("关联救援帖：\(rescueId)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let action = suggestedAction {
                    Button(actionTitle(for: action)) {
                        onNavigate(action)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .navigationTitle("通知详情")
        .navigationBarTitleDisplayMode(.inline)
        .task { onAppearMarkRead() }
    }

    private var adminIconName: String {
        switch notice.type {
        case "payment": return "creditcard"
        case "order": return "bag"
        case "cloudAdopt": return "cloud"
        case "adopt": return "heart.fill"
        case "rescue": return "hare.fill"
        case "donation": return "gift.fill"
        default: return "bell.badge"
        }
    }

    private var suggestedAction: ProfileAdminNavigateAction? {
        switch notice.type {
        case "rescue", "adopt":
            return .openRescueModeration
        case "payment", "order":
            return .openOrders
        default:
            if ProfileMessageParser.rescueId(in: notice.content) != nil {
                return .openRescueModeration
            }
            return nil
        }
    }

    private func actionTitle(for action: ProfileAdminNavigateAction) -> String {
        switch action {
        case .openRescueModeration: return "前往爱兔救援处理"
        case .openOrders: return "前往核对订单"
        }
    }
}

struct OrderDetailView: View {
    let title: String
    let subtitle: String
    let status: String
    let cloudCoinsReward: Int
    let createdAt: Date
    let isPaying: Bool
    let onPay: () -> Void

    private var isPending: Bool { status == "pending" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.title2.weight(.semibold))
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                LabeledContent("下单时间") {
                    Text(createdAt.formatted(date: .abbreviated, time: .shortened))
                }
                LabeledContent("订单状态") {
                    Text(isPending ? "待支付" : "已完成")
                        .foregroundStyle(isPending ? .orange : .green)
                }
                if cloudCoinsReward > 0 {
                    LabeledContent("云养币奖励") {
                        Text("\(cloudCoinsReward) 枚")
                    }
                }

                if isPending {
                    Button(isPaying ? "处理中…" : "模拟支付完成") {
                        onPay()
                    }
                    .disabled(isPaying)
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                    .frame(maxWidth: .infinity)
                } else {
                    Label("订单已完成", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .padding()
        }
        .navigationTitle("订单详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}
