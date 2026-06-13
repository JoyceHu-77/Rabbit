//
//  ProfileTabView.swift
//  Rabbit_iOS — 个人页 Feature
//

import SwiftUI


struct ProfileTabView: View {
    @Environment(AppDataStore.self) private var store
    @State private var profilePath = NavigationPath()
    @State private var toast: String?

    var body: some View {
        NavigationStack(path: $profilePath) {
            loggedInContent
            .navigationDestination(for: ProfileRoute.self) { route in
                switch route {
                case .messages:
                    MessagesFlowView()
                case .orders:
                    OrdersFlowView { earned in
                        if earned > 0 {
                            store.cloudCoins += earned
                            toast = "\(earned) 云养币已到账！"
                        }
                    }
                case .myPosts:
                    MyPostsFlowView()
                case .address:
                    AddressFlowView()
                case .chat:
                    ChatFlowView(userName: store.userName)
                case .profileEdit:
                    ProfileEditFlowView()
                }
            }
        }
        .overlay(alignment: .top) {
            if let t = toast {
                Text(t).padding().background(.thinMaterial, in: Capsule()).padding(.top, 8)
                    .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toast = nil } }
            }
        }
        .task {
            UserInboxStore.ensureDemoSeedIfNeeded()
            await store.syncProfileFromServer()
        }
        .onChange(of: store.pendingProfileRoute) { _, route in
            guard let route else { return }
            profilePath.append(route)
            store.pendingProfileRoute = nil
        }
    }

    private var loggedInContent: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    Button {
                        profilePath.append(ProfileRoute.profileEdit)
                    } label: {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(.white.opacity(0.25))
                                .frame(width: 72, height: 72)
                                .overlay(Text(String(store.userName.prefix(1))).font(.title).foregroundStyle(.white))
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(store.userName).font(.title2.bold())
                                    if store.isAdmin {
                                        Label("管理员", systemImage: "shield.fill")
                                            .font(.caption2.weight(.bold))
                                            .padding(.horizontal, 8).padding(.vertical, 4)
                                            .background(Color.orange, in: Capsule())
                                    }
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.75))
                                }
                                Text(store.userBio).font(.caption).foregroundStyle(.white.opacity(0.85))
                                if let account = currentLocalAccount {
                                    Text("用户 ID \(account.id) · \(account.capabilitySummary)")
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.72))
                                        .lineLimit(2)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain)
                    HStack {
                        statBox(icon: "rosette", value: "\(store.badges)", label: "爱兔奖章")
                        statBox(icon: "bitcoinsign.circle", value: "\(store.cloudCoins)", label: "云养币")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient(colors: [Color.pink, Color.purple.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18))

                VStack(spacing: 0) {
                    profileRow("bell", "我的消息", badge: messageBadgeCount) {
                        profilePath.append(ProfileRoute.messages)
                    }
                    profileRow("bag", "我的订单", badge: nil) {
                        profilePath.append(ProfileRoute.orders)
                    }
                    profileRow("heart", "我的发布", badge: myPostsBadgeCount) {
                        profilePath.append(ProfileRoute.myPosts)
                    }
                    profileRow("message.fill", "好友聊天", badge: nil) {
                        profilePath.append(ProfileRoute.chat)
                    }
                    profileRow("mappin.and.ellipse", "收货地址", badge: nil) {
                        profilePath.append(ProfileRoute.address)
                    }
                }
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 4)

                roleCapabilityCard

                Button("退出登录", role: .destructive) {
                    store.logout()
                    toast = nil
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            await store.syncProfileFromServer()
        }
        .background(LinearGradient(colors: [Color.pink.opacity(0.12), Color.purple.opacity(0.1), Color.orange.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private var currentLocalAccount: LocalAuthAccount? {
        guard let id = store.localUserId else { return nil }
        return LocalAuthCatalog.account(for: id)
    }

    @ViewBuilder
    private var roleCapabilityCard: some View {
        if let account = currentLocalAccount {
            VStack(alignment: .leading, spacing: 10) {
                Label(account.isAdmin ? "管理员能力" : "普通用户能力", systemImage: account.isAdmin ? "shield.fill" : "person.fill")
                    .font(.headline)
                    .foregroundStyle(account.isAdmin ? .orange : Theme.red600)
                Text(account.capabilitySummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !account.isAdmin {
                    Text("如需审核、管理通知等能力，请退出后使用用户 ID 1 登录。")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    /// 我的发布数量角标（含待审/驳回，仅展示数字提示）
    private var myPostsBadgeCount: Int? {
        let n = store.myPublishedRescuePosts().count
        return n > 0 ? n : nil
    }

    /// 未读角标：站内信 + 管理员未读通知（仅管理员模式）
    private var messageBadgeCount: Int? {
        guard store.isLoggedIn else { return nil }
        let useAPI = RabbitAPIConfiguration.normalizedBaseURL() != nil
        let userUnread = useAPI ? store.profileInboxUnread : UserInboxStore.unreadCount()
        let adminUnread = store.isAdmin
            ? (useAPI ? store.profileAdminUnread : AdminNotificationsStore.load().filter { !$0.read }.count)
            : 0
        let total = userUnread + adminUnread
        return total > 0 ? total : nil
    }

    private func statBox(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3)
            Text(value).font(.title.bold())
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }

    private func profileRow(_ icon: String, _ title: String, badge: Int?, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: icon).foregroundStyle(.secondary)
                Text(title)
                Spacer()
                if let b = badge {
                    Text("\(b)")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red, in: Capsule())
                        .foregroundStyle(.white)
                }
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
            .padding()
            .profileFullWidthCellTap(action: action)
            Divider()
                .padding(.leading)
        }
    }
}
