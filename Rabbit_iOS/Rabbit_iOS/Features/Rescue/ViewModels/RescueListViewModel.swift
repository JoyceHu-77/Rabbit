//
//  RescueListViewModel.swift
//  Rabbit_iOS — 救援列表状态与筛选逻辑（MVVM：视图仅绑定与触发）
//

import Foundation
import Observation

@MainActor
@Observable
final class RescueListViewModel {
    var allPosts: [RescueDisplayPost] = []
    /// 筛选后的全量（分页前）
    var filteredAll: [RescueDisplayPost] = []
    var posts: [RescueDisplayPost] = []
    var showFilters = false
    var filterState = RescueFilterState()
    var appliedFilters = RescueFilterState()
    var sortLatest = true
    var searchQuery = ""
    var isLoading = true
    var pageSize = 12
    var loadedCount = 12

    init() {
        appliedFilters.statuses = ["待救援"]
        filterState = appliedFilters
    }

    var appliedFiltersStatusKey: String {
        let s = appliedFilters.statuses.sorted().joined(separator: ",")
        let d = appliedFilters.districts.sorted().joined(separator: ",")
        let f = appliedFilters.dateFrom.map { "\($0.timeIntervalSince1970)" } ?? ""
        let t = appliedFilters.dateTo.map { "\($0.timeIntervalSince1970)" } ?? ""
        return "\(s)|\(d)|\(f)|\(t)|\(appliedFilters.myPosts)"
    }

    func reloadFromStore(_ store: AppDataStore) {
        allPosts = store.visibleRescuePosts(isAdmin: store.isAdmin, viewerUserName: store.userName)
    }

    func applyFilters(viewerUserName: String) {
        var filtered = allPosts
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            filtered = filtered.filter {
                $0.title.lowercased().contains(q) || $0.id.lowercased().contains(q) || $0.description.lowercased().contains(q)
            }
        }
        if !appliedFilters.statuses.isEmpty {
            filtered = filtered.filter { appliedFilters.statuses.contains($0.status) }
        }
        if !appliedFilters.districts.isEmpty {
            filtered = filtered.filter { p in
                appliedFilters.districts.contains { p.location.contains($0) }
            }
        }
        if let from = appliedFilters.dateFrom {
            filtered = filtered.filter { p in
                if p.date == "未知" { return false }
                let pd = RescuePostLogic.parseChineseDate(p.date)
                if let to = appliedFilters.dateTo {
                    return pd >= stripTime(from) && pd <= endOfDay(to)
                }
                return pd >= stripTime(from)
            }
        }
        if appliedFilters.myPosts {
            let me = viewerUserName.trimmingCharacters(in: .whitespacesAndNewlines)
            filtered = filtered.filter { ($0.publisherName ?? "").trimmingCharacters(in: .whitespacesAndNewlines) == me && !me.isEmpty }
        }

        filtered.sort { a, b in
            let da = RescuePostLogic.parseChineseDate(a.date)
            let db = RescuePostLogic.parseChineseDate(b.date)
            let ka = a.date != "未知"
            let kb = b.date != "未知"
            if !ka && !kb { return false }
            if !ka { return false }
            if !kb { return true }
            return sortLatest ? (da > db) : (da < db)
        }
        filteredAll = filtered
        loadedCount = pageSize
        posts = Array(filtered.prefix(loadedCount))
    }

    func loadMoreIfNeeded(currentItemId: String?) {
        guard let id = currentItemId,
              let idx = filteredAll.firstIndex(where: { $0.id == id }),
              idx >= filteredAll.count - 3,
              loadedCount < filteredAll.count
        else { return }
        loadedCount = min(loadedCount + pageSize, filteredAll.count)
        posts = Array(filteredAll.prefix(loadedCount))
    }

    func refreshWithLoadingDelay(store: AppDataStore) async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        await store.refreshRescues()
        reloadFromStore(store)
        applyFilters(viewerUserName: store.userName)
        isLoading = false
    }

    private func stripTime(_ d: Date) -> Date {
        Calendar.current.startOfDay(for: d)
    }

    private func endOfDay(_ d: Date) -> Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: d)
        c.hour = 23
        c.minute = 59
        c.second = 59
        return Calendar.current.date(from: c) ?? d
    }
}
