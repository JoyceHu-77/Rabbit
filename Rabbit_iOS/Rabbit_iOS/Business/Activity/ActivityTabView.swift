//
//  ActivityTabView.swift
//  Rabbit_iOS — 爱兔活动 Feature
//

import SwiftUI


struct ActivityTabView: View {
    @Environment(AppDataStore.self) private var store
    @State private var topTab = 0
    @State private var bannerIndex = 0
    @State private var banners: [ActivityBannerItem] = ActivityBannerItem.fallbackDefaults

    var body: some View {
        VStack(spacing: 0) {
            headerActivity
            Picker("", selection: $topTab) {
                Text("活动").tag(0)
                Text("线下活动").tag(1)
                Text("爱心橱窗").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color.white)

            ScrollView {
                switch topTab {
                case 0:
                    VStack(alignment: .leading, spacing: 18) {
                        activityBanners
                        if banners.indices.contains(bannerIndex), banners[bannerIndex].targetKey == "cloud" {
                            CloudAdoptActivityContent()
                        } else {
                            CheckinActivityContent()
                        }
                    }
                    .padding(.bottom, 20)
                case 1:
                    OfflineEventsContent()
                        .padding(.vertical, 12)
                default:
                    CharityShopContent()
                        .padding(.vertical, 12)
                }
            }
        }
        .task { await loadBanners() }
    }

    private func loadBanners() async {
        let loaded = await RabbitAPIService.fetchActivityBanners()
        banners = loaded
        if bannerIndex >= banners.count {
            bannerIndex = 0
        }
    }

    private var headerActivity: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("爱兔活动").font(.largeTitle.bold()).foregroundStyle(.white)
            Text("参与活动，传递爱心").font(.subheadline).foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.vertical, 26)
        .background(LinearGradient(colors: [Color.red, Theme.rose, Color.pink.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private var activityBanners: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Array(banners.enumerated()), id: \.element.id) { i, b in
                        Button {
                            bannerIndex = i
                        } label: {
                            ZStack(alignment: .bottomLeading) {
                                PostImageView(urlString: b.imageURL)
                                    .frame(width: 240, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                LinearGradient(colors: [.clear, Color.red.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(b.title).font(.headline).foregroundStyle(.white)
                                    Text(b.subtitle).font(.caption).foregroundStyle(.white.opacity(0.95))
                                }
                                .padding(12)
                            }
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(bannerIndex == i ? Color.red : .clear, lineWidth: 4))
                        }
                    }
                }
                .padding(.horizontal)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("「\(banners.indices.contains(bannerIndex) ? banners[bannerIndex].title : "")」").font(.headline)
                Text("在下方完成打卡或云养流程，奖章与云养币将写入「个人页」。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}
