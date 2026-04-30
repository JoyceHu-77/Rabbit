//
//  RabbitLoadingView.swift
//  Rabbit_iOS — 对应 RabbitLoading.tsx 氛围
//

import SwiftUI

struct RabbitLoadingView: View {
    @State private var bounce = false

    var body: some View {
        VStack(spacing: 16) {
            Text("🐰")
                .font(.system(size: 72))
                .offset(y: bounce ? -8 : 8)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: bounce)
            Text("兔兔加载中…")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .onAppear { bounce = true }
    }
}
