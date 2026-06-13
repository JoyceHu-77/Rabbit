//
//  LoginView.swift
//  Rabbit_iOS — 端内用户 ID 登录（演示）
//

import SwiftUI

struct LoginView: View {
    @Environment(AppDataStore.self) private var store
    @State private var userIdInput = ""
    @State private var errorMessage: String?
    @FocusState private var idFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                header
                inputCard
                quickPickSection
                loginButton
                hintCard
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.screenBg.ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.pink.opacity(0.35), Color.purple.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                Image(systemName: "hare.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.red600)
            }
            Text("爱兔会")
                .font(.largeTitle.bold())
            Text("请输入演示用户 ID 登录")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("用户 ID")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("例如 1 或 2", text: $userIdInput)
                .keyboardType(.numberPad)
                .textContentType(.username)
                .focused($idFieldFocused)
                .padding(14)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onChange(of: userIdInput) { _, _ in
                    errorMessage = nil
                }
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    private var quickPickSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速选择")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(LocalAuthCatalog.all, id: \.id) { account in
                Button {
                    userIdInput = account.id
                    errorMessage = nil
                    idFieldFocused = false
                } label: {
                    HStack(spacing: 14) {
                        roleIcon(for: account)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text("ID \(account.id)")
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(account.isAdmin ? Color.orange.opacity(0.2) : Color.pink.opacity(0.15), in: Capsule())
                                Text(account.roleTitle)
                                    .font(.headline)
                            }
                            Text(account.displayName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: userIdInput == account.id ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(userIdInput == account.id ? Theme.red600 : Color(.systemGray3))
                    }
                    .padding(16)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func roleIcon(for account: LocalAuthAccount) -> some View {
        ZStack {
            Circle()
                .fill(account.isAdmin ? Color.orange.opacity(0.18) : Color.pink.opacity(0.18))
                .frame(width: 48, height: 48)
            Image(systemName: account.isAdmin ? "shield.fill" : "person.fill")
                .font(.title3)
                .foregroundStyle(account.isAdmin ? .orange : Theme.red600)
        }
    }

    private var loginButton: some View {
        Button {
            idFieldFocused = false
            let id = userIdInput.trimmingCharacters(in: .whitespacesAndNewlines)
            if let message = store.login(withUserId: id) {
                errorMessage = message
            } else {
                errorMessage = nil
            }
        } label: {
            Text("进入爱兔会")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.red600)
        .disabled(userIdInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private var hintCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("演示说明", systemImage: "info.circle")
                .font(.subheadline.weight(.semibold))
            Text("ID 1 为管理员，可使用审核、管理通知等能力；ID 2 为普通用户，仅可使用常规功能。当前未连接登录接口，账号信息写在 App 内。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    LoginView()
        .environment(AppDataStore())
}
