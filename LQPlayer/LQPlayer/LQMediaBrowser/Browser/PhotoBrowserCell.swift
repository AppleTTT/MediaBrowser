//
//  PhotoBrowserCell.swift
//  LQPlayer
//
//  Created by 李树 on 2018/3/27.
//  Copyright © 2018年 laiqu. All rights reserved.
//

import UIKit
import Photos

@objc protocol PhotoBrowserCellDelegate: NSObjectProtocol {
    /// 拖动时回调。scale:缩放比率
    func photoBrowserCell(_ cell: PhotoBrowserCell, didPanScale scale: CGFloat)
    /// dismiss 操作
    func photoBrowserDismiss(_ cell: PhotoBrowserCell)
    
    /// 自定义 分享操作
    @objc optional func shareMedia(_ cell: PhotoBrowserCell)
    /// 自定义 删除操作
    @objc optional func deleteMedia(_ cell: PhotoBrowserCell)
}

class PhotoBrowserCell: UICollectionViewCell {
    
    weak var photoBrowserCellDelegate: PhotoBrowserCellDelegate?
    let imageView = UIImageView()
    /// 捏合手势放大图片时的最大允许比例
    var imageMaximumZoomScale: CGFloat = 2.0 {
        didSet { self.scrollView.maximumZoomScale = imageMaximumZoomScale }
    }
    /// 双击放大图片时的目标比例
    var imageZoomScaleForDoubleTap: CGFloat = 2.0
    /// 放大图片用
    let scrollView = UIScrollView()
    /// 计算contentSize应处于的中心位置
    var centerOfContentSize: CGPoint {
        let deltaWidth = bounds.width - scrollView.contentSize.width
        let offsetX = deltaWidth > 0 ? deltaWidth * 0.5 : 0
        let deltaHeight = bounds.height - scrollView.contentSize.height
        let offsetY = deltaHeight > 0 ? deltaHeight * 0.5 : 0
        return CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX,
                       y: scrollView.contentSize.height * 0.5 + offsetY)
    }
    
    /// 取图片适屏size
    var fitSize: CGSize {
        guard let image = imageView.image else { return CGSize.zero }
        let width = scrollView.bounds.width
        let scale = image.size.height / image.size.width
        return CGSize(width: width, height: scale * width)
    }
    /// 取图片适屏frame
    var fitFrame: CGRect {
        let size = fitSize
        let y = (scrollView.bounds.height - size.height) > 0 ? (scrollView.bounds.height - size.height) * 0.5 : 0
        return CGRect(x: 0, y: y, width: size.width, height: size.height)
    }
    /// 记录pan手势开始时imageView的位置
    var beganFrame = CGRect.zero
    /// 记录pan手势开始时，手势位置
    var beganTouch = CGPoint.zero
    var shouldLayout = true
    var asset: PHAsset!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    //MARK:- APIs
    func refreshCell(asset: PHAsset?, placeholder: UIImage?) {
         guard let asset = asset else { return }
        imageView.contentMode = UIViewContentMode.scaleAspectFill
        imageView.image = placeholder
        self.asset = asset
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize.init(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .aspectFill, options: nil) { (image, info) in
            if self.asset.localIdentifier == asset.localIdentifier && image != nil {
                self.imageView.image = image
                self.doLayout()
            }
        }
        self.doLayout()
    }

    //MARK:- Actions
    /// 响应双击
    @objc func doubleTapAction(_ dbTap: UITapGestureRecognizer) {
        // 如果当前没有任何缩放，则放大到目标比例
        // 否则重置到原比例
        if scrollView.zoomScale == 1.0 {
            // 以点击的位置为中心，放大
            let pointInView = dbTap.location(in: imageView)
            let w = scrollView.bounds.size.width / imageZoomScaleForDoubleTap
            let h = scrollView.bounds.size.height / imageZoomScaleForDoubleTap
            let x = pointInView.x - (w / 2.0)
            let y = pointInView.y - (h / 2.0)
            scrollView.zoom(to: CGRect(x: x, y: y, width: w, height: h), animated: true)
        } else {
            scrollView.setZoomScale(1.0, animated: true)
        }
    }
    
    /// 响应拖动
    @objc func panAction(_ pan: UIPanGestureRecognizer) {
        guard imageView.image != nil else { return }
        var results: (CGRect, CGFloat) {
            // 拖动偏移量
            let translation = pan.translation(in: scrollView)
            let currentTouch = pan.location(in: scrollView)
            // 由下拉的偏移值决定缩放比例，越往下偏移，缩得越小。scale值区间[0.3, 1.0]
            let scale = min(1.0, max(0.3, 1 - translation.y / bounds.height))
            let width = beganFrame.size.width * scale
            let height = beganFrame.size.height * scale
            // 计算x和y。保持手指在图片上的相对位置不变。
            // 即如果手势开始时，手指在图片X轴三分之一处，那么在移动图片时，保持手指始终位于图片X轴的三分之一处
            let xRate = (beganTouch.x - beganFrame.origin.x) / beganFrame.size.width
            let currentTouchDeltaX = xRate * width
            let x = currentTouch.x - currentTouchDeltaX
            
            let yRate = (beganTouch.y - beganFrame.origin.y) / beganFrame.size.height
            let currentTouchDeltaY = yRate * height
            let y = currentTouch.y - currentTouchDeltaY
            return (CGRect(x: x, y: y, width: width, height: height), scale)
        }
        
        switch pan.state {
        case .began:
            beganFrame = imageView.frame
            beganTouch = pan.location(in: scrollView)
        case .changed:
            let r = results
            imageView.frame = r.0
            // 通知代理，发生了缩放。代理可依scale值改变背景蒙板alpha值
            photoBrowserCellDelegate?.photoBrowserCell(self, didPanScale: r.1)
            resizeCustomView(scale: r.1, rect: r.0)
        case .ended, .cancelled:
            if pan.velocity(in: self).y > 0 {
                // dismiss
                shouldLayout = false
                imageView.frame = results.0
                photoBrowserCellDelegate?.photoBrowserDismiss(self)
                resizeCustomView(scale: 0.0, rect: results.0)
            } else {
                endPan()
                resizeCustomView(scale: 1.0, rect: CGRect.zero)
            }
        default: endPan()
            resizeCustomView(scale: 1.0, rect: CGRect.zero)
        }
    }
    
    //MARK:- Funs for override 交由子类重写，主要是方便 VideoCell
    func resizeCustomView(scale: CGFloat, rect: CGRect) { }
    func customViewEndPan(needResetSize: Bool, size: CGSize) { }
    
    //MARK:- Private funcs
    private func endPan() {
        photoBrowserCellDelegate?.photoBrowserCell(self, didPanScale: 1.0)
        // 如果图片当前显示的size小于原size，则重置为原size
        let size = fitSize
        let needResetSize = imageView.bounds.size.width < size.width
            || imageView.bounds.size.height < size.height
        UIView.animate(withDuration: 0.25) {
            self.imageView.center = self.centerOfContentSize
            self.customViewEndPan(needResetSize: needResetSize, size: size)
            if needResetSize {
                self.imageView.bounds.size = size
            }
        }
    }
    
    private func doLayout() {
        guard shouldLayout else { return }
        scrollView.frame = contentView.bounds
        scrollView.setZoomScale(1.0, animated: false)
        imageView.frame = fitFrame
    }
    
    private func initUI() {
        contentView.addSubview(scrollView)
        scrollView.delegate = self
        scrollView.maximumZoomScale = imageMaximumZoomScale
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        scrollView.addSubview(imageView)
        imageView.clipsToBounds = true
        // 双击手势
        let doubleTap = UITapGestureRecognizer(target: self, action: Selector.doubleTapAction)
        doubleTap.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(doubleTap)
        // 拖动手势
        let pan = UIPanGestureRecognizer(target: self, action: Selector.panAction)
        pan.delegate = self
        contentView.addGestureRecognizer(pan)
    }
    
    //MARK:- Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        doLayout()
    }
}

extension PhotoBrowserCell: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        imageView.center = centerOfContentSize
    }
}

extension PhotoBrowserCell: UIGestureRecognizerDelegate {
    override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // 只响应pan手势
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: self)
        // 向上滑动时，不响应手势
        if velocity.y < 0 { return false }
        // 横向滑动时，不响应pan手势
        if abs(Int(velocity.x)) > Int(velocity.y) { return false }
        // 向下滑动，如果图片顶部超出可视区域，不响应手势
        if scrollView.contentOffset.y > 0 { return false }
        return true
    }
}

private extension Selector {
    static let doubleTapAction = #selector(PhotoBrowserCell.doubleTapAction(_:))
    static let panAction = #selector(PhotoBrowserCell.panAction(_:))
}











