//
//  MyPostsFlowView.swift
//  Rabbit_iOS — 个人页 · 我的发布（单列 Feed）
//

import SwiftUI

struct MyPostsFlowView: View {
    @Environment(AppDataStore.self) private var store
    @Environment(MainTabCoordinator.self) private var tabCoordinator
    @Environment(\.dismiss) private var dismiss

    @State private var posts: [RescueDisplayPost] = []
    @State private var isLoading = true
    @State private var selectedPost: RescueDisplayPost?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("加载中…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if posts.isEmpty {
                emptyState
            } else {
                feedList
            }
        }
        .navigationTitle("我的发布")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedPost) { post in
            RescueDetailView(post: post, viewerUserName: store.userName) {
                Task { await reload() }
            }
        }
        .refreshable { await reload() }
        .task { await reload() }
    }

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(posts) { post in
                    Button {
                        selectedPost = post
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            if let badge = moderationBadge(for: post) {
                                Text(badge.text)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(badge.foreground)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(badge.background, in: Capsule())
                            }
                            RescueCardView(post: post, layout: .feed)
                        }
                        .profileCellHitArea()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, LayoutMetrics.horizontalInset)
            .padding(.vertical, 12)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("还没有发布", systemImage: "heart.slash")
        } description: {
            Text("你发布的救援帖会显示在这里，包括审核中、已驳回与已展示的内容。")
        } actions: {
            Button("去发布救援帖") {
                tabCoordinator.select(.rescue)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
        }
    }

    @MainActor
    private func reload() async {
        isLoading = posts.isEmpty
        await store.refreshMyPublishedRescues()
        posts = store.myPublishedRescuePosts()
        isLoading = false
    }

    private func moderationBadge(for post: RescueDisplayPost) -> (text: String, foreground: Color, background: Color)? {
        switch post.moderationStatus {
        case "pending":
            return ("审核中", .orange, Color.orange.opacity(0.15))
        case "rejected":
            return ("已驳回", .red, Color.red.opacity(0.12))
        default:
            return nil
        }
    }
}
