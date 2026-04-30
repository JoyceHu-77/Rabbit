//
//  CreateRescuePostView.swift
//  Rabbit_iOS — 发布救援：相册多图、日历、地图选点、审核态与发帖人关联
//

import PhotosUI
import SwiftUI

struct CreateRescuePostView: View {
    @Environment(AppDataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    /// 返回 `nil` 表示成功；非 `nil` 为错误文案（不关闭表单）。
    var onSubmit: (RescueDisplayPost) async -> String?

    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var pickedDate = Date()
    @State private var finderName = ""
    @State private var finderContact = ""
    @State private var isPublic = false
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var fallbackImageURL = ""
    @State private var healthStatus = "未知"
    @State private var sterilizedStatus = "未知"
    @State private var alertMessage: String?
    @State private var showMapPicker = false
    @State private var isSubmitting = false

    private let healthOptions = ["健康", "仍有伤痛", "未知"]
    private let sterilOptions = ["已绝育", "未绝育", "未知"]

    var body: some View {
        NavigationStack {
            Form {
                Section("照片（最多 10 张）") {
                    PhotosPicker(selection: $photoItems, maxSelectionCount: 10, matching: .images) {
                        Label(photoItems.isEmpty ? "从相册选择" : "已选 \(photoItems.count) 张，点击重选", systemImage: "photo.on.rectangle.angled")
                    }
                    Text("也可填写一张网络图片 URL 作为补充（可选）")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("首图 URL（可选 https…）", text: $fallbackImageURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }
                Section("基本信息") {
                    TextField("标题", text: $title)
                    HStack {
                        TextField("地点（城市-区县）", text: $location)
                        Button {
                            showMapPicker = true
                        } label: {
                            Image(systemName: "map.fill")
                        }
                        .accessibilityLabel("地图选点")
                    }
                    DatePicker("登记日期", selection: $pickedDate, displayedComponents: .date)
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
                Section {
                    Button("保存草稿") {
                        saveDraft()
                        alertMessage = "草稿已保存"
                    }
                    if RescueDraftStore.load() != nil {
                        Button("载入草稿") {
                            loadDraft()
                        }
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
                    .disabled(isSubmitting)
                }
            }
            .onAppear {
                if let d = RescueDraftStore.load() {
                    title = d.title
                    description = d.description
                    location = d.location
                    finderName = d.finderName
                    finderContact = d.finderContact
                    isPublic = d.finderIsPublic
                    healthStatus = d.healthStatus
                    sterilizedStatus = d.sterilizedStatus
                    let f = DateFormatter()
                    f.dateFormat = "yyyy年M月"
                    if let dt = f.date(from: d.dateText) {
                        pickedDate = dt
                    }
                }
            }
            .sheet(isPresented: $showMapPicker) {
                LocationPickerSheet(locationText: $location)
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

    private func saveDraft() {
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月"
        let payload = RescueDraftPayload(
            title: title,
            description: description,
            location: location,
            dateText: f.string(from: pickedDate),
            finderName: finderName,
            finderContact: finderContact,
            finderIsPublic: isPublic,
            healthStatus: healthStatus,
            sterilizedStatus: sterilizedStatus
        )
        RescueDraftStore.save(payload)
    }

    private func loadDraft() {
        guard let d = RescueDraftStore.load() else { return }
        title = d.title
        description = d.description
        location = d.location
        finderName = d.finderName
        finderContact = d.finderContact
        isPublic = d.finderIsPublic
        healthStatus = d.healthStatus
        sterilizedStatus = d.sterilizedStatus
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月"
        if let dt = f.date(from: d.dateText) {
            pickedDate = dt
        }
    }

    private func submit() async {
        if let e = ChineseContentValidator.validateTitle(title), !title.isEmpty {
            alertMessage = e
            return
        }
        if let e = ChineseContentValidator.validateDescriptionOrComment(description), !description.isEmpty {
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

        isSubmitting = true
        defer { isSubmitting = false }

        var imgs = await savePickerImagesToDisk(photoItems, max: 10)
        let trimmedURL = fallbackImageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedURL.isEmpty, trimmedURL.hasPrefix("http") {
            imgs.append(trimmedURL)
        }
        if imgs.isEmpty {
            imgs = ["https://images.unsplash.com/photo-1585110396000-c9ffd4e4b308?w=400"]
        }

        let f = DateFormatter()
        f.dateFormat = "yyyy年M月"
        let dateText = f.string(from: pickedDate)

        let locParts = location.split(separator: "-").map(String.init)
        let city = locParts.first ?? (location.isEmpty ? "上海" : location)
        let district = locParts.count > 1 ? locParts[1] : ""

        let descPrefix = "健康状况：\(healthStatus)；绝育状态：\(sterilizedStatus == "已绝育" ? "绝育了" : (sterilizedStatus == "未绝育" ? "未绝育" : "不清楚"))；"
        let fullDesc = descPrefix + description

        let pubName = store.userName.trimmingCharacters(in: .whitespacesAndNewlines)

        let post = RescueDisplayPost(
            id: "",
            title: title.isEmpty ? "新救援帖" : title,
            description: fullDesc,
            images: imgs,
            location: location.isEmpty ? "上海" : location,
            city: String(city),
            district: String(district),
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
            sourceRabbitId: 0,
            publisherName: pubName.isEmpty ? "爱心用户" : pubName,
            moderationStatus: "pending",
            auditRejectionReason: nil
        )

        if let err = await onSubmit(post) {
            alertMessage = err
            saveDraft()
            return
        }
        RescueDraftStore.clear()
        dismiss()
    }

    private func validateFinderName(_ name: String) -> Bool {
        name.range(of: #"^[\u4e00-\u9fa5a-zA-Z\s]+$"#, options: .regularExpression) != nil
    }

    private func validateContact(_ contact: String) -> Bool {
        contact.range(of: #"^[\u4e00-\u9fa5a-zA-Z0-9\s\-_]+$"#, options: .regularExpression) != nil
    }

    private func savePickerImagesToDisk(_ items: [PhotosPickerItem], max: Int) async -> [String] {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("rescue_uploads", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var urls: [String] = []
        for item in items.prefix(max) {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            let file = dir.appendingPathComponent("\(UUID().uuidString).jpg")
            guard (try? data.write(to: file)) != nil else { continue }
            urls.append(file.absoluteString)
        }
        return urls
    }
}
