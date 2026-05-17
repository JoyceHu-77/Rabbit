//
//  WelcomeGuideVideoView.swift
//  Rabbit_iOS — 欢迎引导循环视频（默认静音，可切换）
//

import AVFoundation
import AVKit
import SwiftUI

struct WelcomeGuideVideoView: View {
    let url: URL
    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?
    @State private var isMuted = true

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                    .disabled(true)
            } else {
                ProgressView()
            }
        }
        .onAppear { startPlayback() }
        .onDisappear { tearDown() }
        .overlay(alignment: .bottomTrailing) {
            Button {
                isMuted.toggle()
                player?.isMuted = isMuted
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.black.opacity(0.55), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(10)
            .accessibilityLabel(isMuted ? "取消静音" : "静音")
        }
    }

    private func startPlayback() {
        guard player == nil else {
            player?.play()
            return
        }
        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer(playerItem: item)
        queue.isMuted = isMuted
        looper = AVPlayerLooper(player: queue, templateItem: item)
        player = queue
        queue.play()
    }

    private func tearDown() {
        player?.pause()
        looper?.disableLooping()
        looper = nil
        player = nil
    }
}
