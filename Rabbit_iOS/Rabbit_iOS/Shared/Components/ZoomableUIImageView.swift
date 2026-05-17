//
//  ZoomableUIImageView.swift
//  Rabbit_iOS — 双指缩放查看 UIImage（UIScrollView，PhotoScroller 模式）
//

import SwiftUI
import UIKit

struct ZoomableUIImageView: UIViewRepresentable {
    let image: UIImage
    var maximumZoomMultiplier: CGFloat = 4

    func makeUIView(context: Context) -> ZoomableImageScrollView {
        let view = ZoomableImageScrollView()
        view.maximumZoomMultiplier = maximumZoomMultiplier
        view.setImageIfNeeded(image)
        return view
    }

    func updateUIView(_ uiView: ZoomableImageScrollView, context: Context) {
        uiView.maximumZoomMultiplier = maximumZoomMultiplier
        uiView.setImageIfNeeded(image)
    }
}

/// 支持双指放大/缩小；初始为整图适配屏幕，可继续放大至 `maximumZoomMultiplier` 倍。
final class ZoomableImageScrollView: UIScrollView, UIScrollViewDelegate {
    private let imageView = UIImageView()
    private var currentImage: UIImage?
    private var lastLayoutBoundsSize: CGSize = .zero
    var maximumZoomMultiplier: CGFloat = 4

    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        bouncesZoom = true
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        backgroundColor = .clear
        contentInsetAdjustmentBehavior = .never
        decelerationRate = .fast

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImageIfNeeded(_ image: UIImage) {
        guard currentImage !== image else { return }
        currentImage = image
        imageView.image = image
        lastLayoutBoundsSize = .zero
        setNeedsLayout()
        layoutIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let boundsSize = bounds.size
        guard boundsSize.width > 0, boundsSize.height > 0 else { return }

        guard boundsSize != lastLayoutBoundsSize else { return }
        lastLayoutBoundsSize = boundsSize
        configureZoomScalesForBoundsSize(boundsSize)
        centerImageInScrollView()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageInScrollView()
    }

    /// 以原图像素尺寸作为 content，用 `minimumZoomScale` 适配屏幕。
    private func configureZoomScalesForBoundsSize(_ boundsSize: CGSize) {
        guard let image = imageView.image, image.size.width > 0, image.size.height > 0 else { return }

        imageView.frame = CGRect(origin: .zero, size: image.size)
        contentSize = image.size

        let widthScale = boundsSize.width / image.size.width
        let heightScale = boundsSize.height / image.size.height
        let fitScale = min(widthScale, heightScale)

        minimumZoomScale = fitScale
        maximumZoomScale = max(fitScale * maximumZoomMultiplier, fitScale + 0.01)
        zoomScale = fitScale
    }

    /// 缩放后不足一屏时居中（Apple PhotoScroller 算法）
    private func centerImageInScrollView() {
        let boundsSize = bounds.size
        var frameToCenter = imageView.frame

        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }

        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }

        imageView.frame = frameToCenter
    }
}
