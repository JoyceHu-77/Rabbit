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

    /// 内存中的列表，由 `refreshRescues()` / `refreshDonations()` 从网络填充。
    private(set) var rescuePostsCache: [RescueDisplayPost] = []
    private(set) var donationPostsCache: [DonationDisplayPost] = []

    var isAdmin: Bool {
        get { settings.isAdmin }
        set { settings.isAdmin = newValue; save() }
    }

    var isLoggedIn: Bool {
        get { settings.isLoggedIn }
        set { settings.isLoggedIn = newValue; save() }
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
        set { settings.userName = newValue; save() }
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
            s.isAdmin = true
            s.isLoggedIn = true
            s.userName = "爱心用户"
            s.userBio = "热爱兔兔，致力于救助流浪动物"
            s.badges = 3
            s.cloudCoins = 15
            s.didSeedRescues = false
            s.didSeedDonations = false
            settings = s
            try? ctx.save()
        }
    }

    func save() {
        let ctx = container.viewContext
        guard ctx.hasChanges else { return }
        try? ctx.save()
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

    /// 从接口拉取救援列表并更新内存缓存。
    func refreshRescues() async {
        rescuePostsCache = await RabbitAPIService.fetchRescues()
    }

    /// 从接口拉取捐换列表并更新内存缓存。
    func refreshDonations() async {
        donationPostsCache = await RabbitAPIService.fetchDonations()
    }

    func fetchRescuePosts() -> [RescueDisplayPost] {
        rescuePostsCache
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
            return nil
        }
        do {
            let saved = try await RabbitAPIService.createRescue(post)
            upsertRescue(saved)
            return nil
        } catch {
            return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
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
