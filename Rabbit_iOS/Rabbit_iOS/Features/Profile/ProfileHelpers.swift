//
//  ProfileHelpers.swift
//  Rabbit_iOS — 底部 Tab 配置、地址编辑、好友 chat / 二维码演示
//

import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

struct TabBarSettingsSheet: View {
    var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("个人页位置（快捷）") {
                    Button("个人页移到末尾（PRD 默认）") {
                        TabOrderSettings.applyProfilePositionTrailing()
                        store.bumpTabBarConfiguration()
                    }
                    Button("个人页移到中间") {
                        TabOrderSettings.applyProfilePositionMiddle()
                        store.bumpTabBarConfiguration()
                    }
                }
                Section("预设") {
                    Button("恢复 PRD 五 Tab 默认顺序") {
                        TabOrderSettings.resetToPRDDefault()
                        store.bumpTabBarConfiguration()
                    }
                }
                Section("当前顺序") {
                    Text(TabOrderSettings.orderedTabs().map(\.title).joined(separator: " → "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("底部导航")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

struct AddressEditorSheet: View {
    @Environment(AppDataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userShippingAddress") private var addressText: String = "上海市浦东新区××路××号"

    var body: some View {
        NavigationStack {
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        Task {
                            await store.pushProfileToServer()
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                if addressText.isEmpty {
                    addressText = UserDefaults.standard.string(forKey: "userShippingAddress")
                        ?? "上海市浦东新区××路××号"
                }
            }
        }
    }
}

struct SimpleChatView: View {
    let userName: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
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
                        Label("爱兔会小助手", systemImage: "bubble.left.and.bubble.right.fill")
                    }
                }
            }
            .navigationTitle("好友与聊天")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
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
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(messages.enumerated()), id: \.offset) { _, m in
                            Text(m)
                                .padding(12)
                                .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                }
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
