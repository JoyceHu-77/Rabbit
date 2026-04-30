//
//  RescueTabView.swift
//  Rabbit_iOS — 爱兔救援（表现层 + RescueListViewModel）
//

import SwiftUI

struct RescueTabView: View {
    @Environment(AppDataStore.self) private var store
    @State private var viewModel = RescueListViewModel()
    @State private var showCreate = false
    @State private var selectedPost: RescueDisplayPost?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                header

                if viewModel.showFilters {
                    RescueFiltersView(filters: $viewModel.filterState, onApply: {
                        viewModel.appliedFilters = viewModel.filterState
                        viewModel.applyFilters()
                    }, onClose: { viewModel.showFilters = false })
                }

                filterChips

                ScrollView {
                    if viewModel.isLoading {
                        RabbitLoadingView()
                    } else if viewModel.posts.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            ForEach(viewModel.posts) { p in
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
            await viewModel.refreshWithLoadingDelay(store: store)
        }
        .onChange(of: viewModel.sortLatest) { _, _ in
            Task { await viewModel.refreshWithLoadingDelay(store: store) }
        }
        .onChange(of: viewModel.appliedFiltersStatusKey) { _, _ in
            Task { await viewModel.refreshWithLoadingDelay(store: store) }
        }
        .onChange(of: viewModel.searchQuery) { _, _ in
            viewModel.applyFilters()
        }
        .sheet(isPresented: $showCreate) {
            CreateRescuePostView { draft in
                var p = draft
                p.id = store.nextRescuePostID()
                let err = await store.createRescuePost(p)
                if err == nil {
                    viewModel.reloadFromStore(store)
                    viewModel.applyFilters()
                }
                return err
            }
        }
        .sheet(item: $selectedPost) { p in
            RescueDetailView(post: p, isAdmin: store.isAdmin) {
                viewModel.reloadFromStore(store)
                viewModel.applyFilters()
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
                TextField("搜索兔兔姓名、编号…", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 10) {
                Button {
                    viewModel.sortLatest.toggle()
                } label: {
                    Label(viewModel.sortLatest ? "最新发布" : "最早发布", systemImage: "arrow.up.arrow.down")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(.white)

                Button {
                    viewModel.filterState = viewModel.appliedFilters
                    viewModel.showFilters.toggle()
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
        let n = viewModel.appliedFilters.statuses.count + viewModel.appliedFilters.districts.count
            + (viewModel.appliedFilters.dateFrom != nil ? 1 : 0) + (viewModel.appliedFilters.myPosts ? 1 : 0)
        if n > 0 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Text("已选:").font(.caption).foregroundStyle(.secondary)
                    ForEach(Array(viewModel.appliedFilters.statuses), id: \.self) { s in
                        chip(s) {
                            viewModel.appliedFilters.statuses.remove(s)
                            viewModel.filterState = viewModel.appliedFilters
                            viewModel.applyFilters()
                        }
                    }
                    ForEach(Array(viewModel.appliedFilters.districts), id: \.self) { d in
                        chip(d) {
                            viewModel.appliedFilters.districts.remove(d)
                            viewModel.filterState = viewModel.appliedFilters
                            viewModel.applyFilters()
                        }
                    }
                    if viewModel.appliedFilters.dateFrom != nil {
                        chip(dateChipText) {
                            viewModel.appliedFilters.dateFrom = nil
                            viewModel.appliedFilters.dateTo = nil
                            viewModel.filterState = viewModel.appliedFilters
                            viewModel.applyFilters()
                        }
                    }
                    if viewModel.appliedFilters.myPosts {
                        chip("我的发布") {
                            viewModel.appliedFilters.myPosts = false
                            viewModel.filterState = viewModel.appliedFilters
                            viewModel.applyFilters()
                        }
                    }
                    if n > 1 {
                        Button("清除全部") {
                            viewModel.appliedFilters = RescueFilterState()
                            viewModel.filterState = viewModel.appliedFilters
                            viewModel.applyFilters()
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
        guard let from = viewModel.appliedFilters.dateFrom else { return "" }
        let to = viewModel.appliedFilters.dateTo.map { f.string(from: $0) } ?? ""
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
}
