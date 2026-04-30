//
//  RescueFiltersView.swift
//  Rabbit_iOS — 对应 RescueFilters.tsx
//

import SwiftUI

struct RescueFilterState: Equatable {
    var statuses: Set<String> = []
    var districts: Set<String> = []
    var dateFrom: Date?
    var dateTo: Date?
    var myPosts: Bool = false
}

struct RescueFiltersView: View {
    @Binding var filters: RescueFilterState
    var onApply: () -> Void
    var onClose: () -> Void

    private let statuses = ["待救援", "救援中", "已救援", "寄养中", "已领养", "已去世"]
    private let districts = ["黄浦区", "徐汇区", "长宁区", "静安区", "普陀区", "虹口区", "杨浦区", "浦东新区"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("筛选条件")
                    .font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("日期范围").font(.subheadline.weight(.medium))
                DatePicker("从", selection: Binding(
                    get: { filters.dateFrom ?? Date() },
                    set: { filters.dateFrom = $0 }
                ), displayedComponents: .date)
                DatePicker("到", selection: Binding(
                    get: { filters.dateTo ?? Date() },
                    set: { filters.dateTo = $0 }
                ), displayedComponents: .date)
            }

            Text("状态").font(.subheadline.weight(.medium))
            FlowWrap(spacing: 8) {
                ForEach(statuses, id: \.self) { s in
                    chip(s, selected: filters.statuses.contains(s)) {
                        if filters.statuses.contains(s) { filters.statuses.remove(s) }
                        else { filters.statuses.insert(s) }
                    }
                }
            }

            Text("地区").font(.subheadline.weight(.medium))
            FlowWrap(spacing: 8) {
                ForEach(districts, id: \.self) { d in
                    chip(d, selected: filters.districts.contains(d)) {
                        if filters.districts.contains(d) { filters.districts.remove(d) }
                        else { filters.districts.insert(d) }
                    }
                }
            }

            Toggle("我的发布", isOn: $filters.myPosts)

            HStack {
                Button("重置") {
                    filters = RescueFilterState()
                    onApply()
                    onClose()
                }
                .buttonStyle(.bordered)
                Spacer()
                Button("应用") {
                    onApply()
                    onClose()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding()
        .background(Color.white)
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selected ? Color.red.opacity(0.2) : Color.gray.opacity(0.12), in: Capsule())
                .foregroundStyle(selected ? Color.red : .primary)
        }
        .buttonStyle(.plain)
    }
}

/// 简单流式布局
private struct FlowWrap: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let res = layout(proposal: proposal, subviews: subviews)
        for (i, p) in res.positions.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + p.x, y: bounds.minY + p.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0
        var maxW = proposal.width ?? 0
        if maxW == 0 { maxW = 320 }
        var positions: [CGPoint] = []
        for sub in subviews {
            let s = sub.sizeThatFits(.unspecified)
            if x + s.width > maxW, x > 0 {
                x = 0
                y += rowH + spacing
                rowH = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowH = max(rowH, s.height)
            x += s.width + spacing
        }
        return (CGSize(width: maxW, height: y + rowH), positions)
    }
}
