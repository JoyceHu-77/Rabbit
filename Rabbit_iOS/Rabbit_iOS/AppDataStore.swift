//
//  AppDataStore.swift
//  Rabbit_iOS — 用户偏好仍用 Core Data；救援 / 捐换列表通过 Alamofire 请求接口（见 RabbitAPIService）。
//

import CoreData
import Foundation
import Observation

@Observable
@MainActor
final class AppDataStore {
    @ObservationIgnored
    let container: NSPersistentContainer

    private(set) var settings: AppSettingsEntity!

    /// 改变底部 Tab 顺序后递增，用于强制 `TabView` 重建。
    var tabBarConfigurationEpoch: UInt = 0

    /// 内存中的列表，由 `refreshRescues()` / `refreshDonations()` 从网络填充。
    private(set) var rescuePostsCache: [RescueDisplayPost] = []
    private(set) var donationPostsCache: [DonationDisplayPost] = []

    /// 最近一次列表请求的 `meta`（若接口未返回则为 nil；供后续分页 UI 使用）。
    private(set) var lastRescueListMeta: PaginationMeta?
    private(set) var lastDonationListMeta: PaginationMeta?

    /// 个人页角标（来自服务端站内信 / 管理通知）。
    private(set) var profileInboxUnread: Int = 0
    private(set) var profileAdminUnread: Int = 0

    /// 子页面请求跳转（如管理通知详情里「前往订单」）。
    var pendingProfileRoute: ProfileRoute?

    @ObservationIgnored
    private var suppressProfilePush = false

    /// 必须使用存储属性，`@Observable` 才能感应管理员开关；底层同步 `AppSettingsEntity.isAdmin`。
    var isAdmin = false {
        didSet {
            settings.isAdmin = isAdmin
            save()
        }
    }

    /// 必须使用存储属性，`@Observable` 才能感应登录态并驱动 `AppRootView` 切换。
    var isLoggedIn = false {
        didSet {
            settings.isLoggedIn = isLoggedIn
            save()
        }
    }

    var hasSeenWelcome: Bool {
        get { settings.hasSeenWelcome }
        set { settings.hasSeenWelcome = newValue; save() }
    }

    var lastWelcomeTime: Date? {
        get { settings.lastWelcomeTime }
        set { settings.lastWelcomeTime = newValue; save() }
    }

    var userName: String {
        get { settings.userName ?? "爱心用户" }
        set {
            settings.userName = newValue
            APIAuthHeaders.setViewerName(newValue)
            save()
        }
    }

    var userBio: String {
        get { settings.userBio ?? "热爱兔兔，致力于救助流浪动物" }
        set { settings.userBio = newValue; save() }
    }

    var badges: Int {
        get { Int(settings.badges) }
        set { settings.badges = Int32(newValue); save() }
    }

    var cloudCoins: Int {
        get { Int(settings.cloudCoins) }
        set { settings.cloudCoins = Int32(newValue); save() }
    }

    var shippingAddress: String {
        get { UserDefaults.standard.string(forKey: "userShippingAddress") ?? "" }
        set {
            UserDefaults.standard.set(newValue, forKey: "userShippingAddress")
        }
    }

    /// 端内演示登录的用户 ID（`1` 管理员，`2` 普通用户）；非空时角色以本地账号为准。
    var localUserId: String? {
        get {
            let raw = UserDefaults.standard.string(forKey: Self.localUserIdKey)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return raw.isEmpty ? nil : raw
        }
        set {
            if let newValue, !newValue.isEmpty {
                UserDefaults.standard.set(newValue, forKey: Self.localUserIdKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.localUserIdKey)
            }
        }
    }

    private static let localUserIdKey = "rabbit_local_user_id"

    var usesLocalAuth: Bool { localUserId != nil }

    init(container: NSPersistentContainer? = nil) {
        let resolved = container ?? PersistenceController.shared.container
        self.container = resolved
        let ctx = resolved.viewContext
        let req = NSFetchRequest<AppSettingsEntity>(entityName: "AppSettingsEntity")
        req.predicate = NSPredicate(format: "settingsID == %@", "app")
        req.fetchLimit = 1
        if let existing = try? ctx.fetch(req), let first = existing.first {
            settings = first
        } else {
            let s = AppSettingsEntity(context: ctx)
            s.settingsID = "app"
            s.hasSeenWelcome = false
            s.isAdmin = false
            s.isLoggedIn = false
            s.userName = "爱心用户"
            s.userBio = "热爱兔兔，致力于救助流浪动物"
            s.badges = 3
            s.cloudCoins = 15
            s.didSeedRescues = false
            s.didSeedDonations = false
            settings = s
            try? ctx.save()
        }
        // 与 Core Data 对齐；在 init 中赋值不触发 `didSet`。
        isAdmin = settings.isAdmin
        isLoggedIn = settings.isLoggedIn
        APIAuthHeaders.setViewerName(settings.userName ?? "爱心用户")
        migrateLegacySessionIfNeeded()
    }

    /// 旧版默认已登录但未记录本地用户 ID 时，按管理员开关回填演示 ID。
    private func migrateLegacySessionIfNeeded() {
        guard isLoggedIn, localUserId == nil else { return }
        localUserId = isAdmin ? LocalAuthCatalog.admin.id : LocalAuthCatalog.member.id
    }

    /// 端内用户 ID 登录；成功返回 `nil`，失败返回错误文案。
    @discardableResult
    func login(withUserId rawId: String) -> String? {
        let trimmed = rawId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let account = LocalAuthCatalog.account(for: trimmed) else {
            return "无效的用户 ID，请使用 1（管理员）或 2（普通用户）"
        }
        applyLocalAccount(account)
        isLoggedIn = true
        return nil
    }

    func logout() {
        localUserId = nil
        isLoggedIn = false
        isAdmin = false
    }

    private func applyLocalAccount(_ account: LocalAuthAccount) {
        localUserId = account.id
        userName = account.displayName
        userBio = account.bio
        badges = account.badges
        cloudCoins = account.cloudCoins
        isAdmin = account.isAdmin
    }

    func save() {
        let ctx = container.viewContext
        guard ctx.hasChanges else { return }
        try? ctx.save()
    }

    func bumpTabBarConfiguration() {
        tabBarConfigurationEpoch += 1
    }

    func currentProfileSnapshot() -> ProfileSnapshot {
        return ProfileSnapshot(
            viewerKey: "",
            userName: userName,
            userBio: userBio,
            badges: badges,
            cloudCoins: cloudCoins,
            isAdmin: isAdmin,
            isLoggedIn: isLoggedIn,
            shippingAddress: shippingAddress
        )
    }

    func applyProfileFromServer(_ profile: ProfileSnapshot) {
        suppressProfilePush = true
        defer { suppressProfilePush = false }
        if usesLocalAuth {
            if !profile.shippingAddress.isEmpty {
                shippingAddress = profile.shippingAddress
            }
            return
        }
        userName = profile.userName
        userBio = profile.userBio
        badges = profile.badges
        cloudCoins = profile.cloudCoins
        isAdmin = profile.isAdmin
        isLoggedIn = profile.isLoggedIn
        if !profile.shippingAddress.isEmpty {
            shippingAddress = profile.shippingAddress
        }
    }

    func syncProfileFromServer() async {
        guard RabbitAPIConfiguration.normalizedBaseURL() != nil else { return }
        guard !usesLocalAuth else { return }
        do {
            let profile = try await RabbitAPIService.fetchProfile()
            applyProfileFromServer(profile)
        } catch {
            return
        }
        if let inbox = try? await RabbitAPIService.fetchProfileInbox() {
            profileInboxUnread = inbox.filter { !$0.read }.count
        }
        if isAdmin, let admin = try? await RabbitAPIService.fetchAdminNotifications() {
            profileAdminUnread = admin.filter { !$0.read }.count
        } else {
            profileAdminUnread = 0
        }
    }

    func pushProfileToServer() async {
        guard !suppressProfilePush, !usesLocalAuth, RabbitAPIConfiguration.normalizedBaseURL() != nil else { return }
        _ = try? await RabbitAPIService.patchProfile(currentProfileSnapshot())
    }

    func adjustWalletOnServer(badgesDelta: Int, cloudCoinsDelta: Int) async {
        guard RabbitAPIConfiguration.normalizedBaseURL() != nil else { return }
        do {
            let profile = try await RabbitAPIService.adjustWallet(
                badgesDelta: badgesDelta,
                cloudCoinsDelta: cloudCoinsDelta
            )
            applyProfileFromServer(profile)
        } catch {
            return
        }
    }

    func refreshProfileBadgeCounts() async {
        guard RabbitAPIConfiguration.normalizedBaseURL() != nil, !usesLocalAuth else { return }
        if let inbox = try? await RabbitAPIService.fetchProfileInbox() {
            profileInboxUnread = inbox.filter { !$0.read }.count
        }
        if isAdmin, let admin = try? await RabbitAPIService.fetchAdminNotifications() {
            profileAdminUnread = admin.filter { !$0.read }.count
        } else {
            profileAdminUnread = 0
        }
    }

    func shouldShowWelcomeModal() -> Bool {
        if !hasSeenWelcome { return true }
        guard let last = lastWelcomeTime else { return true }
        let day: TimeInterval = 24 * 60 * 60
        return Date().timeIntervalSince(last) > day
    }

    func markWelcomeSeen() {
        hasSeenWelcome = true
        lastWelcomeTime = Date()
    }

    /// 从接口拉取救援列表并更新内存缓存；`query` 为 nil 时与无参旧版行为一致。
    func refreshRescues(query: RescueListQuery? = nil) async {
        let r = await RabbitAPIService.fetchRescues(query: query)
        rescuePostsCache = r.posts
        lastRescueListMeta = r.meta
    }

    /// 从接口拉取捐换列表并更新内存缓存。
    func refreshDonations(query: DonationListQuery? = nil) async {
        let r = await RabbitAPIService.fetchDonations(query: query)
        donationPostsCache = r.posts
        lastDonationListMeta = r.meta
    }

    /// 全量缓存（含待审核，仅供管理员或同步逻辑使用）。
    func fetchRescuePosts() -> [RescueDisplayPost] {
        rescuePostsCache
    }

    /// 列表与领养等场景：审核通过公开展示；发帖人可见本人待审/驳回帖。
    func visibleRescuePosts(isAdmin: Bool, viewerUserName: String) -> [RescueDisplayPost] {
        rescuePostsCache.filter { $0.isListedForViewer(isAdmin: isAdmin, viewerUserName: viewerUserName) }
    }

    /// 当前用户发布的全部救援帖（含待审核、已驳回），按日期倒序。
    func myPublishedRescuePosts() -> [RescueDisplayPost] {
        let me = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !me.isEmpty else { return [] }
        return rescuePostsCache
            .filter {
                ($0.publisherName ?? "").trimmingCharacters(in: .whitespacesAndNewlines) == me
            }
            .sorted {
                RescuePostLogic.parseChineseDate($0.date) > RescuePostLogic.parseChineseDate($1.date)
            }
    }

    /// 拉取「我的发布」列表（优先 `mine=1`，并带发帖人昵称）。
    func refreshMyPublishedRescues() async {
        let me = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        var query = RescueListQuery(mine: 1)
        if !me.isEmpty {
            query.publisherName = me
        }
        let r = await RabbitAPIService.fetchRescues(query: query)
        if !r.posts.isEmpty {
            mergeRescuesIntoCache(r.posts)
        } else if rescuePostsCache.isEmpty {
            await refreshRescues()
        }
    }

    /// 将接口返回的帖子合并进缓存（按 id 覆盖/追加），不整表替换以免丢失其他筛选结果。
    private func mergeRescuesIntoCache(_ incoming: [RescueDisplayPost]) {
        for post in incoming {
            if let i = rescuePostsCache.firstIndex(where: { $0.id == post.id }) {
                rescuePostsCache[i] = post
            } else {
                rescuePostsCache.append(post)
            }
        }
    }

    func upsertRescue(_ post: RescueDisplayPost) {
        if let i = rescuePostsCache.firstIndex(where: { $0.id == post.id }) {
            rescuePostsCache[i] = post
        } else {
            rescuePostsCache.append(post)
        }
    }

    /// 发布新救援：已配置 `RABBIT_API_BASE_URL` 时走 `POST /v1/rescues`，否则仅写入本地缓存。
    func createRescuePost(_ post: RescueDisplayPost) async -> String? {
        if RabbitAPIConfiguration.normalizedBaseURL() == nil {
            upsertRescue(post)
            notifyRescueSubmitted(post)
            return nil
        }
        do {
            let saved = try await RabbitAPIService.createRescue(post)
            upsertRescue(saved)
            notifyRescueSubmitted(saved)
            await refreshProfileBadgeCounts()
            return nil
        } catch {
            return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func notifyRescueSubmitted(_ post: RescueDisplayPost) {
        guard RabbitAPIConfiguration.normalizedBaseURL() == nil else { return }
        UserInboxStore.append(
            title: "救援帖审核中",
            body: "您提交的「\(post.title)」（编号 \(post.id)）已进入审核，通过后将对所有人展示。"
        )
        AdminNotificationsStore.append(
            AdminNotificationRecord(
                id: "ADM\(Int(Date().timeIntervalSince1970 * 1000))",
                type: "rescue",
                title: "新救援帖待审核",
                content: "[\(post.id)] \(post.title)",
                createdAt: Date(),
                read: false
            )
        )
    }

    func nextRescuePostID() -> String {
        let pattern = #"R(\d+)"#
        let nums = rescuePostsCache.compactMap { post -> Int? in
            guard let re = try? NSRegularExpression(pattern: pattern),
                  let m = re.firstMatch(in: post.id, range: NSRange(post.id.startIndex..., in: post.id)),
                  let r = Range(m.range(at: 1), in: post.id)
            else { return nil }
            return Int(post.id[r])
        }
        let next = (nums.max() ?? 0) + 1
        return String(format: "R%03d", next)
    }

    func fetchDonationPosts() -> [DonationDisplayPost] {
        donationPostsCache.sorted { $0.id > $1.id }
    }

    /// 发布捐换：已配置 API 时走 `POST /v1/donations`，否则仅追加本地缓存。
    func addDonation(_ draft: DonationDraft) async -> String? {
        if RabbitAPIConfiguration.normalizedBaseURL() == nil {
            appendDonationLocally(draft)
            return nil
        }
        do {
            let row = try await RabbitAPIService.createDonation(draft)
            donationPostsCache.append(row)
            return nil
        } catch {
            return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func appendDonationLocally(_ draft: DonationDraft) {
        let pattern = #"D(\d+)"#
        let nums = donationPostsCache.compactMap { post -> Int? in
            guard let re = try? NSRegularExpression(pattern: pattern),
                  let m = re.firstMatch(in: post.id, range: NSRange(post.id.startIndex..., in: post.id)),
                  let r = Range(m.range(at: 1), in: post.id)
            else { return nil }
            return Int(post.id[r])
        }
        let next = (nums.max() ?? 0) + 1
        let id = String(format: "D%03d", next)
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let row = DonationDisplayPost(
            id: id,
            title: draft.title,
            description: draft.description,
            image: draft.imageURL,
            type: draft.type,
            target: draft.target,
            status: "待领取",
            contactName: draft.contactName,
            contactPhone: draft.contactPhone,
            date: f.string(from: Date())
        )
        donationPostsCache.append(row)
    }
}

struct DonationDisplayPost: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var description: String
    var image: String
    var type: String
    var target: String
    var status: String
    var contactName: String
    var contactPhone: String
    var date: String
}

struct DonationDraft: Sendable {
    var title: String
    var description: String
    var imageURL: String
    var type: String
    var target: String
    var contactName: String
    var contactPhone: String
}
