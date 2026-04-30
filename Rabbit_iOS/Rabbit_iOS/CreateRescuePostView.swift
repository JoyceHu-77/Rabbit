//
//  CreateRescuePostView.swift
//  Rabbit_iOS — 对应 CreateRescuePost.tsx 核心字段与校验
//

import SwiftUI

struct CreateRescuePostView: View {
    @Environment(\.dismiss) private var dismiss
    /// 返回 `nil` 表示成功；非 `nil` 为错误文案（不关闭表单）。
    var onSubmit: (RescueDisplayPost) async -> String?

    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var dateText = ""
    @State private var finderName = ""
    @State private var finderContact = ""
    @State private var isPublic = false
    @State private var imageURL = ""
    @State private var healthStatus = "未知"
    @State private var sterilizedStatus = "未知"
    @State private var alertMessage: String?

    private let healthOptions = ["健康", "仍有伤痛", "未知"]
    private let sterilOptions = ["已绝育", "未绝育", "未知"]

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("标题", text: $title)
                    TextField("地点", text: $location)
                    TextField("登记日期（如 2025年6月 或 未知）", text: $dateText)
                    TextField("首图 URL（https…）", text: $imageURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }
                Section("描述") {
                    TextField("详细描述（中文）", text: $description, axis: .vertical)
                        .lineLimit(4 ... 12)
                }
                Section("发现人") {
                    TextField("称呼", text: $finderName)
                    TextField("联系方式", text: $finderContact)
                    Toggle("公开联系方式", isOn: $isPublic)
                }
                Section("状态标签") {
                    Picker("健康状况", selection: $healthStatus) {
                        ForEach(healthOptions, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("绝育状况", selection: $sterilizedStatus) {
                        ForEach(sterilOptions, id: \.self) { Text($0).tag($0) }
                    }
                }
            }
            .navigationTitle("发布救援信息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("发布") {
                        Task { await submit() }
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if dateText.isEmpty {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy年M月"
                    dateText = f.string(from: Date())
                }
            }
            .alert("提示", isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private func submit() async {
        if let e = validateChineseText(description), !description.isEmpty {
            alertMessage = e
            return
        }
        if !finderName.isEmpty, !validateFinderName(finderName) {
            alertMessage = "发现人称呼格式不正确"
            return
        }
        if !finderContact.isEmpty, !validateContact(finderContact) {
            alertMessage = "联系方式格式不正确"
            return
        }
        let locParts = location.split(separator: "-").map(String.init)
        let city = locParts.first ?? location
        let district = locParts.count > 1 ? locParts[1] : ""
        let imgs = imageURL.trimmingCharacters(in: .whitespaces).isEmpty
            ? ["https://images.unsplash.com/photo-1585110396000-c9ffd4e4b308?w=400"]
            : [imageURL.trimmingCharacters(in: .whitespaces)]

        let descPrefix = "健康状况：\(healthStatus)；绝育状态：\(sterilizedStatus == "已绝育" ? "绝育了" : (sterilizedStatus == "未绝育" ? "未绝育" : "不清楚"))；"
        let fullDesc = descPrefix + description

        let post = RescueDisplayPost(
            id: "",
            title: title.isEmpty ? "新救援帖" : title,
            description: fullDesc,
            images: imgs,
            location: location.isEmpty ? "上海" : location,
            city: city,
            district: district,
            date: dateText,
            status: "待救援",
            finderName: finderName.isEmpty ? nil : finderName,
            finderContact: finderContact.isEmpty ? nil : finderContact,
            finderIsPublic: isPublic,
            organizerName: nil,
            organizerContact: nil,
            organizerIsPublic: false,
            wechatQR: nil,
            healthStatus: healthStatus == "未知" ? nil : healthStatus,
            sterilizedStatus: sterilizedStatus == "未知" ? nil : (sterilizedStatus == "已绝育" ? "绝育了" : "未绝育"),
            sourceRabbitId: 0
        )
        if let err = await onSubmit(post) {
            alertMessage = err
            return
        }
        dismiss()
    }

    private func validateChineseText(_ text: String) -> String? {
        let inappropriate = ["傻逼", "智障", "脑残", "废物", "垃圾", "操", "艹", "他妈", "你妈", "死全家"]
        for w in inappropriate where text.contains(w) { return "请输入文明用语" }
        return nil
    }

    private func validateFinderName(_ name: String) -> Bool {
        name.range(of: #"^[\u4e00-\u9fa5a-zA-Z\s]+$"#, options: .regularExpression) != nil
    }

    private func validateContact(_ contact: String) -> Bool {
        contact.range(of: #"^[\u4e00-\u9fa5a-zA-Z0-9\s\-_]+$"#, options: .regularExpression) != nil
    }
}
