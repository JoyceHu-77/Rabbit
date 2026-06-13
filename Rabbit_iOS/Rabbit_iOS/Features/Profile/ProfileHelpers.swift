//
//  ProfileHelpers.swift
//  Rabbit_iOS — 地址编辑、好友 chat / 二维码演示
//

import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

// MARK: - Push 流程页（由 ProfileTabView NavigationStack 承载，勿再套 Sheet）

struct ProfileEditFlowView: View {
    @Environment(AppDataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var bio = ""
    @State private var isSaving = false

    var body: some View {
        Form {
            Section("昵称") {
                TextField("显示名称", text: $name)
            }
            Section("个人简介") {
                TextField("一句话介绍自己", text: $bio, axis: .vertical)
                    .lineLimit(2 ... 5)
            }
        }
        .navigationTitle("编辑资料")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    Task { await save() }
                }
                .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            name = store.userName
            bio = store.userBio
        }
    }

    @MainActor
    private func save() async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        isSaving = true
        defer { isSaving = false }
        store.userName = trimmedName
        store.userBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        await store.pushProfileToServer()
        await store.syncProfileFromServer()
        dismiss()
    }
}

struct AddressFlowView: View {
    @Environment(AppDataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var addressText = ""

    var body: some View {
        Form {
            Section {
                Text("仅用于徽章寄送、爱心橱窗等实物发货（与 PRD 一致）")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("详细地址") {
                TextField("省市区与街道门牌", text: $addressText, axis: .vertical)
                    .lineLimit(3 ... 8)
            }
        }
        .navigationTitle("收货地址")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") {
                    store.shippingAddress = addressText.trimmingCharacters(in: .whitespacesAndNewlines)
                    Task {
                        await store.pushProfileToServer()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            let addr = store.shippingAddress
            addressText = addr.isEmpty ? "上海市浦东新区××路××号" : addr
        }
    }
}

struct ChatFlowView: View {
    let userName: String

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("我的好友码（演示）").font(.headline)
                    Text("其他用户在「添加好友」中扫描即可发起会话（一期占位）。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let img = QRImageGenerator.uiImage(from: "rabbit://friend/\(userName)") {
                        Image(uiImage: img)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160, height: 160)
                    }
                }
                .padding(.vertical, 8)
            }
            Section("会话（演示）") {
                NavigationLink {
                    ChatThreadView(peerName: "爱兔会小助手")
                } label: {
                    HStack {
                        Label("爱兔会小助手", systemImage: "bubble.left.and.bubble.right.fill")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .profileCellHitArea()
                }
            }
        }
        .navigationTitle("好友与聊天")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChatThreadView: View {
    let peerName: String
    @State private var draft = ""
    @State private var messages: [String] = [
        "感谢您参与爱心救助！有任何领养问题可以随时留言。",
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { _, m in
                        Text(m)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            HStack {
                TextField("发送文字…", text: $draft)
                    .textFieldStyle(.roundedBorder)
                Button("发送") {
                    let t = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !t.isEmpty else { return }
                    messages.append(t)
                    draft = ""
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .navigationTitle(peerName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum QRImageGenerator {
    static func uiImage(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
