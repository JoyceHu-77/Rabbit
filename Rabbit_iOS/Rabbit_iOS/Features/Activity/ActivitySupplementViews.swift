//
//  ActivitySupplementViews.swift
//  Rabbit_iOS — 与 rabbit_web_new ActivityTab（只取心滴 / 云养 / 线下 / 橱窗）逻辑对齐的本地实现。
//

import SwiftUI

// MARK: - 只取心滴

struct CheckinActivityContent: View {
    @Environment(AppDataStore.self) private var store

    private enum Phase: String {
        case idle, joined, upload
    }

    @State private var phase: Phase = .idle
    @State private var daysLeft = 7

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("只取心滴").font(.title2.bold()).foregroundStyle(Color.pink.opacity(0.85))
                Spacer()
                Image(systemName: "rosette").font(.title).foregroundStyle(.pink)
            }

            Text("点击参与活动后，7 天内可记录每日善事（如喂流浪猫、给环卫工人送水并拍照）。期满上传记录可获得爱兔奖章，用于兑换橱窗奖品。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("活动规则").font(.headline)
                ruleRow("每天记录一件善事，可拍照留存")
                ruleRow("7 天完成后上传所有善事记录")
                ruleRow("邀请好友一起参与，双方各获赠一枚奖章")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 14))

            switch phase {
            case .idle:
                Button("点击参与") {
                    phase = .joined
                    daysLeft = 7
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
                .frame(maxWidth: .infinity)

            case .joined:
                VStack(spacing: 12) {
                    Label("还剩 \(daysLeft) 天", systemImage: "calendar")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white, in: Capsule())
                    Text("继续加油！记录您的善举").font(.footnote).foregroundStyle(.secondary)
                    if daysLeft > 0 {
                        Button("演示：快进一天") {
                            daysLeft = max(0, daysLeft - 1)
                        }
                        .buttonStyle(.bordered)
                    }
                    if daysLeft == 0 {
                        Text("恭喜完成 7 天善事记录！").font(.subheadline.weight(.semibold)).foregroundStyle(.green)
                        Button("上传物料领取奖章") {
                            phase = .upload
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.pink)
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)

            case .upload:
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                        .foregroundStyle(.pink.opacity(0.5))
                        .frame(height: 120)
                        .overlay(
                            VStack(spacing: 6) {
                                Image(systemName: "arrow.up.doc")
                                    .font(.title)
                                    .foregroundStyle(.pink)
                                Text("在此上传 7 日记录（演示）")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        )
                    Button("确认上传") {
                        store.badges += 1
                        phase = .idle
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(colors: [Color.pink.opacity(0.2), Color.red.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    private func ruleRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").foregroundStyle(.pink)
            Text(text).font(.caption)
        }
    }
}

// MARK: - 云养

struct CloudAdoptActivityContent: View {
    @Environment(AppDataStore.self) private var store
    @State private var rabbits: [RescueDisplayPost] = []
    @State private var showSheet = false
    @State private var selected: RescueDisplayPost?
    @State private var amount = 100
    @State private var toast: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("爱心云养计划").font(.title2.bold()).foregroundStyle(Color.purple.opacity(0.85))
                Spacer()
                Image(systemName: "cloud.fill").font(.title).foregroundStyle(.purple)
            }
            Text("自主选择云养小兔与每月金额；每月金额的 10% 转为云养币，可兑换礼品。参与可获赠爱兔会志愿者徽章（线下活动发放）。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("云养规则").font(.headline)
                ruleRow("自主选择云养小兔和月度金额", color: .purple)
                ruleRow("每月金额的 10% 转为云养币", color: .purple)
                ruleRow("完成云养可记录在历史，便于回顾", color: .purple)
            }
            .padding()
            .background(Color.white, in: RoundedRectangle(cornerRadius: 14))

            if rabbits.isEmpty {
                Text("暂无适合云养的兔兔数据").foregroundStyle(.secondary)
            } else {
                ForEach(rabbits) { r in
                    cloudRow(r)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(colors: [Color.purple.opacity(0.15), Color.pink.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .task {
            await store.refreshRescues()
            let all = store.visibleRescuePosts(isAdmin: store.isAdmin, viewerUserName: store.userName)
            rabbits = all.filter { $0.status != "已去世" && $0.status != "已领养" && $0.moderationStatus == "approved" }
                .prefix(4)
                .map { $0 }
        }
        .sheet(isPresented: $showSheet) {
            NavigationStack {
                Form {
                    if let r = selected {
                        Section {
                            Text(rabbitDisplayName(r)).font(.headline)
                            Text(r.description).font(.caption).foregroundStyle(.secondary)
                        }
                        Section("每月金额") {
                            Picker("金额", selection: $amount) {
                                Text("¥50").tag(50)
                                Text("¥100").tag(100)
                                Text("¥200").tag(200)
                            }
                            .pickerStyle(.segmented)
                        }
                        Section {
                            let coins = max(1, amount / 10)
                            Text("预计获得 \(coins) 云养币（10%）")
                                .font(.subheadline)
                        }
                    }
                }
                .navigationTitle("确认云养")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            showSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("确认") {
                            guard let r = selected else { return }
                            Task {
                                await confirmCloudAdopt(rescue: r, amount: amount)
                            }
                        }
                    }
                }
            }
        }
        .overlay(alignment: .top) {
            if let t = toast {
                Text(t)
                    .padding()
                    .background(.thinMaterial, in: Capsule())
                    .padding(.top, 8)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { toast = nil }
                    }
            }
        }
    }

    private func cloudRow(_ r: RescueDisplayPost) -> some View {
        HStack(alignment: .top, spacing: 12) {
            PostImageView(urlString: r.images.first)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 6) {
                Text(rabbitDisplayName(r)).font(.subheadline.weight(.semibold))
                Text(r.description).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                Button("云养 TA") {
                    selected = r
                    showSheet = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.purple)
            }
        }
        .padding()
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
    }

    private func ruleRow(_ text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").foregroundStyle(color)
            Text(text).font(.caption)
        }
    }

    private func rabbitDisplayName(_ post: RescueDisplayPost) -> String {
        if let range = post.title.range(of: " - ") {
            return String(post.title[..<range.lowerBound])
        }
        return post.title
    }

    @MainActor
    private func confirmCloudAdopt(rescue: RescueDisplayPost, amount: Int) async {
        if RabbitAPIConfiguration.normalizedBaseURL() != nil {
            do {
                let result = try await RabbitAPIService.confirmCloudAdopt(
                    rescueId: rescue.id,
                    amountYuan: amount
                )
                if let profile = result.profile {
                    store.applyProfileFromServer(profile)
                } else {
                    store.cloudCoins += result.cloudCoinsGranted
                }
                await store.refreshProfileBadgeCounts()
                toast = "云养成功，\(result.cloudCoinsGranted) 云养币已到账"
                showSheet = false
                return
            } catch {
                toast = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                return
            }
        }
        let coins = max(1, amount / 10)
        store.cloudCoins += coins
        toast = "云养成功，\(coins) 云养币已到账（本地）"
        showSheet = false
    }
}

// MARK: - 线下活动

struct OfflineEventsContent: View {
    @Environment(AppDataStore.self) private var store
    @State private var past: [OfflineEventItem] = OfflineEventItem.fallbackPast
    @State private var upcoming: [OfflineEventItem] = OfflineEventItem.fallbackUpcoming
    @State private var selected: OfflineEventItem?
    @State private var showCreateEvent = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("往期活动").font(.title3.bold())
                Spacer()
                if store.isAdmin {
                    Button {
                        showCreateEvent = true
                    } label: {
                        Label("新增活动", systemImage: "plus")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .accessibilityHint("管理员发布即将开始的线下活动")
                }
            }

            ForEach(past) { e in
                eventCard(e)
            }

            Text("即将开始").font(.title3.bold())
            ForEach(upcoming) { e in
                eventCard(e)
            }
        }
        .padding(.horizontal)
        .sheet(item: $selected) { e in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        PostImageView(urlString: e.bannerURL ?? e.imageURL)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        Text(e.title).font(.title2.bold())
                        Label(e.date, systemImage: "calendar")
                        Label(e.location, systemImage: "mappin.and.ellipse")
                        Text(e.description).font(.body).foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("活动详情")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("关闭") { selected = nil }
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateEvent) {
            CreateOfflineEventSheet { newEvent in
                upcoming.insert(newEvent, at: 0)
            }
        }
        .task { await reloadOfflineEvents() }
        .refreshable { await reloadOfflineEvents() }
    }

    private func reloadOfflineEvents() async {
        async let pastRows = RabbitAPIService.fetchOfflineEvents(isPast: true)
        async let upcomingRows = RabbitAPIService.fetchOfflineEvents(isPast: false)
        past = await pastRows
        upcoming = await upcomingRows
    }

    private func eventCard(_ e: OfflineEventItem) -> some View {
        Button {
            selected = e
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                PostImageView(urlString: e.bannerURL ?? e.imageURL)
                    .frame(height: 160)
                    .clipped()
                VStack(alignment: .leading, spacing: 8) {
                    Text(e.title).font(.headline).foregroundStyle(.primary)
                    HStack {
                        Label(e.date, systemImage: "calendar")
                        Spacer()
                        Label(e.location, systemImage: "mappin.and.ellipse")
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding()
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 爱心橱窗

struct CharityShopContent: View {
    @Environment(AppDataStore.self) private var store
    @State private var products: [CharityShopProductItem] = []
    @State private var toast: String?
    @State private var showQRHint = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("爱兔会爱心橱窗").font(.title2.bold())
                    Text("收益用于兔兔粮草、医疗与生活物资").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if store.isAdmin {
                    Button {
                        showQRHint = true
                    } label: {
                        Image(systemName: "qrcode")
                            .padding(10)
                            .background(Color.pink.opacity(0.2), in: Circle())
                    }
                    .accessibilityLabel("收款二维码管理")
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(products) { p in
                    charityCard(p)
                }
            }
        }
        .padding(.horizontal)
        .task {
            products = await RabbitAPIService.fetchCharityProducts()
        }
        .refreshable {
            products = await RabbitAPIService.fetchCharityProducts()
        }
        .alert("管理员", isPresented: $showQRHint) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("收款二维码管理可与 Web QRCodesDialog 一致；演示版请在真实接入时配置。")
        }
        .overlay(alignment: .top) {
            if let t = toast {
                Text(t).padding().background(.thinMaterial, in: Capsule()).padding(.top, 8)
                    .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toast = nil } }
            }
        }
    }

    private func charityCard(_ p: CharityShopProductItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            PostImageView(urlString: p.image)
                .aspectRatio(1, contentMode: .fill)
                .clipped()
            VStack(alignment: .leading, spacing: 8) {
                Text(p.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                Text(p.description).font(.caption2).foregroundStyle(.secondary).lineLimit(3)
                HStack {
                    Text("¥\(p.price)").font(.subheadline.weight(.bold)).foregroundStyle(.pink)
                    Spacer()
                    Label("\(p.badges)", systemImage: "rosette").font(.caption2)
                    Label("\(p.cloudCoins)", systemImage: "bitcoinsign.circle").font(.caption2)
                }
                Button("购买") {
                    toast = "已创建演示订单：\(p.title)"
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.orange)
                .frame(maxWidth: .infinity)
                HStack(spacing: 8) {
                    Button("奖章兑换") {
                        Task { await redeemWithBadges(p) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    Button("云养币兑换") {
                        Task { await redeemWithCloudCoins(p) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }
            .padding(10)
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
        .shadow(radius: 3)
    }

    @MainActor
    private func redeemWithBadges(_ p: CharityShopProductItem) async {
        guard store.badges >= p.badges else {
            toast = "奖章不足"
            return
        }
        if RabbitAPIConfiguration.normalizedBaseURL() != nil {
            await store.adjustWalletOnServer(badgesDelta: -p.badges, cloudCoinsDelta: 0)
            toast = "已用 \(p.badges) 枚奖章兑换"
        } else {
            store.badges -= p.badges
            toast = "已用 \(p.badges) 枚奖章兑换"
        }
    }

    @MainActor
    private func redeemWithCloudCoins(_ p: CharityShopProductItem) async {
        guard store.cloudCoins >= p.cloudCoins else {
            toast = "云养币不足"
            return
        }
        if RabbitAPIConfiguration.normalizedBaseURL() != nil {
            await store.adjustWalletOnServer(badgesDelta: 0, cloudCoinsDelta: -p.cloudCoins)
            toast = "已用 \(p.cloudCoins) 云养币兑换"
        } else {
            store.cloudCoins -= p.cloudCoins
            toast = "已用 \(p.cloudCoins) 云养币兑换"
        }
    }
}

// MARK: - 管理员：新建线下活动（简版，对齐 Web CreateEventDialog 入口）

private struct CreateOfflineEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (OfflineEventItem) -> Void

    @State private var title = ""
    @State private var date = ""
    @State private var location = ""
    @State private var detail = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("活动信息") {
                    TextField("标题", text: $title)
                    TextField("日期（如 2026-06-01）", text: $date)
                    TextField("地点", text: $location)
                    TextField("活动简介", text: $detail, axis: .vertical)
                        .lineLimit(3 ... 8)
                }
                Section {
                    Text("提交后将出现在「即将开始」列表顶部；配图使用默认示意图。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("新增线下活动")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("发布") {
                        Task { await publishEvent() }
                    }
                    .disabled(isSaving)
                }
            }
            if let errorMessage {
                Text(errorMessage).font(.caption).foregroundStyle(.red)
            }
        }
    }

    @MainActor
    private func publishEvent() async {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let d = date.trimmingCharacters(in: .whitespacesAndNewlines)
        let loc = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let desc = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        if RabbitAPIConfiguration.normalizedBaseURL() != nil {
            do {
                let saved = try await RabbitAPIService.createOfflineEvent(
                    title: t.isEmpty ? "未命名活动" : t,
                    date: d.isEmpty ? "日期待定" : d,
                    location: loc.isEmpty ? "地点待定" : loc,
                    description: desc.isEmpty ? "活动内容待定，敬请关注。" : desc
                )
                onSave(saved)
                dismiss()
                return
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                return
            }
        }

        let local = OfflineEventItem(
            id: "OE\(Int(Date().timeIntervalSince1970 * 1000))",
            title: t.isEmpty ? "未命名活动" : t,
            date: d.isEmpty ? "日期待定" : d,
            location: loc.isEmpty ? "地点待定" : loc,
            imageURL: "https://images.unsplash.com/photo-1591797057589-eb91f36c0a6f?w=600",
            bannerURL: nil,
            description: desc.isEmpty ? "活动内容待定，敬请关注。" : desc,
            isPast: false
        )
        onSave(local)
        dismiss()
    }
}
