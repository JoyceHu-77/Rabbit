//
//  RescueTabView.swift
//  Rabbit_iOS — 对应 RescueTab.tsx
//

import SwiftUI

struct RescueTabView: View {
    @Environment(AppDataStore.self) private var store

    @State private var allPosts: [RescueDisplayPost] = []
    @State private var posts: [RescueDisplayPost] = []
    @State private var showFilters = false
    @State private var filterState = RescueFilterState()
    @State private var appliedFilters = RescueFilterState()
    @State private var showCreate = false
    @State private var selectedPost: RescueDisplayPost?
    @State private var sortLatest = true
    @State private var searchQuery = ""
    @State private var isLoading = true

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                header

                if showFilters {
                    RescueFiltersView(filters: $filterState, onApply: {
                        appliedFilters = filterState
                        applyFilters()
                    }, onClose: { showFilters = false })
                }

                filterChips

                ScrollView {
                    if isLoading {
                        RabbitLoadingView()
                    } else if posts.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            ForEach(posts) { p in
                                Button {
                                    selectedPost = p
                                } label: {
                                    RescueCardView(post: p)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                }
            }

            Button {
                showCreate = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(colors: [Color(red: 0.86, green: 0.15, blue: 0.15), Theme.rose], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: Circle()
                    )
                    .shadow(radius: 6)
            }
            .padding(.trailing, LayoutMetrics.horizontalInset)
            .padding(.bottom, LayoutMetrics.fabBottomMargin)
        }
        .task {
            await refreshWithLoadingDelay()
        }
        .onChange(of: sortLatest) { _, _ in
            Task { await refreshWithLoadingDelay() }
        }
        .onChange(of: appliedFiltersStatusKey) { _, _ in
            Task { await refreshWithLoadingDelay() }
        }
        .onChange(of: searchQuery) { _, _ in
            applyFilters()
        }
        .sheet(isPresented: $showCreate) {
            CreateRescuePostView { draft in
                var p = draft
                p.id = store.nextRescuePostID()
                let err = await store.createRescuePost(p)
                if err == nil {
                    reloadFromStore()
                    applyFilters()
                }
                return err
            }
        }
        .sheet(item: $selectedPost) { p in
            RescueDetailView(post: p, isAdmin: store.isAdmin) {
                reloadFromStore()
                applyFilters()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("🐰 爱兔救援")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.gray)
                TextField("搜索兔兔姓名、编号…", text: $searchQuery)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 10) {
                Button {
                    sortLatest.toggle()
                } label: {
                    Label(sortLatest ? "最新发布" : "最早发布", systemImage: "arrow.up.arrow.down")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(.white)

                Button {
                    filterState = appliedFilters
                    showFilters.toggle()
                } label: {
                    Label("筛选", systemImage: "line.3.horizontal.decrease.circle")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.redHeader)
    }

    @ViewBuilder
    private var filterChips: some View {
        let n = appliedFilters.statuses.count + appliedFilters.districts.count
            + (appliedFilters.dateFrom != nil ? 1 : 0) + (appliedFilters.myPosts ? 1 : 0)
        if n > 0 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Text("已选:").font(.caption).foregroundStyle(.secondary)
                    ForEach(Array(appliedFilters.statuses), id: \.self) { s in
                        chip(s) { appliedFilters.statuses.remove(s); filterState = appliedFilters; applyFilters() }
                    }
                    ForEach(Array(appliedFilters.districts), id: \.self) { d in
                        chip(d) { appliedFilters.districts.remove(d); filterState = appliedFilters; applyFilters() }
                    }
                    if appliedFilters.dateFrom != nil {
                        chip(dateChipText) {
                            appliedFilters.dateFrom = nil
                            appliedFilters.dateTo = nil
                            filterState = appliedFilters
                            applyFilters()
                        }
                    }
                    if appliedFilters.myPosts {
                        chip("我的发布") {
                            appliedFilters.myPosts = false
                            filterState = appliedFilters
                            applyFilters()
                        }
                    }
                    if n > 1 {
                        Button("清除全部") {
                            appliedFilters = RescueFilterState()
                            filterState = appliedFilters
                            applyFilters()
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color.white)
            .overlay(alignment: .bottom) { Divider() }
        }
    }

    private var dateChipText: String {
        let f = DateFormatter()
        f.dateStyle = .short
        guard let from = appliedFilters.dateFrom else { return "" }
        let to = appliedFilters.dateTo.map { f.string(from: $0) } ?? ""
        return "\(f.string(from: from))-\(to)"
    }

    private func chip(_ title: String, onRemove: @escaping () -> Void) -> some View {
        Button(action: onRemove) {
            HStack(spacing: 4) {
                Text(title).font(.caption)
                Image(systemName: "xmark").font(.caption2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.red.opacity(0.12), in: Capsule())
            .foregroundStyle(Color.red)
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("🐰").font(.system(size: 72))
            Text("没有找到兔兔").font(.title3.weight(.medium))
            Text("试试调整筛选条件或发布新的救援信息").font(.footnote).foregroundStyle(.secondary)
            Button("发布救援信息") { showCreate = true }
                .buttonStyle(.borderedProminent)
                .tint(.red)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func reloadFromStore() {
        allPosts = store.fetchRescuePosts()
    }

    private func applyFilters() {
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
            filtered = filtered.filter { $0.finderName == "张女士" }
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
        posts = filtered
    }

    private var appliedFiltersStatusKey: String {
        let s = appliedFilters.statuses.sorted().joined(separator: ",")
        let d = appliedFilters.districts.sorted().joined(separator: ",")
        let f = appliedFilters.dateFrom.map { "\($0.timeIntervalSince1970)" } ?? ""
        let t = appliedFilters.dateTo.map { "\($0.timeIntervalSince1970)" } ?? ""
        return "\(s)|\(d)|\(f)|\(t)|\(appliedFilters.myPosts)"
    }

    private func refreshWithLoadingDelay() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        await store.refreshRescues()
        reloadFromStore()
        applyFilters()
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

