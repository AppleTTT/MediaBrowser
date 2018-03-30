//
//  VideoBrowserCell.swift
//  LQPlayer
//
//  Created by 李树 on 2018/3/27.
//  Copyright © 2018年 laiqu. All rights reserved.
//

import UIKit
import Photos

class VideoBrowserCell: PhotoBrowserCell {
    
    var playerLayer: AVPlayerLayer?
    var playerView: UIView?
    
    var mainMaskView: UIView?
    var playButton: UIButton!
    var timeSlider: UISlider!
    var currentTimeLabel: UILabel!
    var totalTimeLabel: UILabel!
    var totalDuration: TimeInterval?
    
    var delayItem: DispatchWorkItem?
    var timer: Timer?
    
    var isDismissing = false
    
    var isPlayToEnd: Bool {
        if playerLayer?.player?.currentItem != nil {
            if playerLayer?.player?.rate == 0.0, playerLayer?.player?.currentItem?.duration == playerLayer?.player?.currentTime() { return true }
        }
        return false
    }
    
    //MARK:- Life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
        scrollView.isHidden = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- APIs
    override func refreshCell(asset: PHAsset!, placeholder: UIImage?) {
        if asset.mediaType != .video { return }
        self.asset = asset
        imageView.image = placeholder
        resetUI()
        preparePlayer()
    }
    
    func stopPlayer() {
        timeSlider.setValue(0, animated: false)
        playButton.isSelected = false
        delayItem?.cancel()
        if playerLayer?.player?.currentItem != nil {
            pauseVideo()
            if playerLayer?.player?.currentItem?.status == .readyToPlay {
                playerLayer?.player!.seek(to: CMTimeMake(Int64(0), 1), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: { (finished) in
                })
                currentTimeLabel.text = Util.formatVideoTime(0)
            }
        }
    }

    //MARK:- Actions
    @objc func dismiss() {
        
    }
    
    @objc func playButtonClicked(button: UIButton) {
        button.isSelected = !button.isSelected
        if button.isSelected {
            playVideo()
            // maskView  立即消失
            switchMaskView(hide: true)
        }else {
            pauseVideo()
            autoFadeOutControlViewWithAnimation()
        }
        
    }
    /// Timer 事件
    @objc func playerTimerAction() {
        let currentTime = CMTimeGetSeconds(self.playerLayer!.player!.currentTime())
        timeSlider.setValue(Float(currentTime / totalDuration!), animated: true)
        currentTimeLabel.text = Util.formatVideoTime(TimeInterval(currentTime))
        if isPlayToEnd {
            videoDidEndPlay()
        }
    }
    /// 单击手势，显示或者隐藏 maskView
    @objc func singleTapAction(_ tap: UITapGestureRecognizer) {
        // 动画显示或者隐藏 maskView
        // 自动消失
        mainMaskView?.alpha = mainMaskView?.alpha == 0 ? 1 : 0
        
    }
    /// 双击手势，在显示图片的时候是放大或者缩小，在显示视频的时候，是暂停或者播放
    @objc override func doubleTapAction(_ tap: UITapGestureRecognizer) {
        self.playButtonClicked(button: playButton)
    }

    /// slider actions
    @objc func sliderTouchBegan(_ sender: UISlider)  {
        
    }
    
    @objc func sliderValueChanged(_ sender: UISlider)  {
        cancelAutoFadeOutAnimation()
        let currentValue = TimeInterval(sender.value) * totalDuration!
        currentTimeLabel.text = Util.formatVideoTime(currentValue)
        playerLayer?.player!.seek(to: CMTimeMake(Int64(currentValue), 1), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: { (finished) in
        })
    }
    
    @objc func sliderTouchEnded(_ sender: UISlider)  {
        autoFadeOutControlViewWithAnimation()
    }
    
    //MARK:- Override
    override func resizeCustomView(scale: CGFloat, rect: CGRect) {
        super.resizeCustomView(scale: scale, rect: rect)
        if rect != CGRect.zero {
            isDismissing = true
            playerView?.frame = rect
            imageView.frame = rect
        }
        // 用于在拉动图片的时候，其他视图的变化，比如这里就是拉动的时候，删除，分享，返回等按钮的 alpha 就要变化
        if scale < 0.98 {
            UIView.animate(withDuration: 0.3, animations: {
                self.mainMaskView?.alpha = 0.0
            }, completion: nil)
        } else if scale >= 1.0 {
            UIView.animate(withDuration: 0.3, animations: {
                self.mainMaskView?.alpha = 1.0
            }, completion: nil)
        }
    }
    
    override func customViewEndPan(needResetSize: Bool, size: CGSize) {
        super .customViewEndPan(needResetSize: needResetSize, size: size)
        self.playerView?.center = self.centerOfContentSize
        if needResetSize { self.playerView?.bounds.size = size }
    }

    
    //MARK:- Private funcs
    
    private func playVideo() {
        setupTimer()
        if isPlayToEnd {
            // relplay
            playerLayer?.player?.seek(to: CMTimeMake(Int64(0), 1), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: {[weak self] (finished) in
                self?.playerLayer?.player?.play()
                self?.timeSlider.setValue(0, animated: true)
                self?.setupTimer()
            })
        } else {
            playerLayer?.player!.play()
        }
    }
    
    private func pauseVideo() {
        if playerLayer?.player?.currentItem != nil {
            playerLayer?.player!.pause()
            timer?.fireDate = Date.distantFuture
        }
    }
    
    private func videoDidEndPlay() {
        // 此时说明已经播放完毕，再次播放则重头开始播放
        timer?.invalidate()
        // 显示 mask 并取消自动消失
        self.mainMaskView?.alpha = 1.0
        self.playButton.isSelected = false
        cancelAutoFadeOutAnimation()
    }
    
    private func setupTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: Selector.playerTimerAction, userInfo: nil, repeats: true)
        // 不添加这句，那么当滑动 CollectionView 的时候，时间轴不会动
        RunLoop.current.add(timer!, forMode: .commonModes)
        timer?.fireDate = Date()
    }
    
    private func resetUI() {
        timeSlider.value = 0.0
        playButton.isSelected = false
        playButton.isHidden = false
        mainMaskView?.alpha = 1.0
        // 取消自动消失
        cancelAutoFadeOutAnimation()
    }
    
    private func autoFadeOutControlViewWithAnimation() {
        cancelAutoFadeOutAnimation()
        delayItem = DispatchWorkItem { [weak self] in
            if self?.isPlayToEnd == false{
                self?.switchMaskView(hide: true)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2,
                                      execute: delayItem!)
    }
    
    private func cancelAutoFadeOutAnimation() {
        delayItem?.cancel()
    }
    
    private func switchMaskView(hide: Bool) {
        let alpha: CGFloat = hide ? 0 : 1
        UIView.animate(withDuration: 0.3, animations: {
            self.mainMaskView?.alpha = CGFloat(alpha)
        }) { (_) in
            if hide {
                self.autoFadeOutControlViewWithAnimation()
            }
        }
        
    }
    
    private func preparePlayer() {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: options, resultHandler: { playerItem, _ in
            DispatchQueue.main.sync {
                guard playerItem != nil else { return }
                
                self.totalDuration = self.asset.duration
                self.totalTimeLabel.text = Util.formatVideoTime(self.totalDuration!)
                self.currentTimeLabel.text = Util.formatVideoTime(0)
                // 生成 AVPlayer 和 AVPlayerLayer
                let player: AVPlayer
                player = AVPlayer(playerItem: playerItem)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                playerLayer.frame = self.contentView.layer.bounds
                self.playerLayer?.removeFromSuperlayer()
                self.playerView?.layer.addSublayer(playerLayer)
                self.playerLayer = playerLayer
            }
        })
    }
    
    
    private func initUI() {
        playerView = UIView.init()
        playerView?.clipsToBounds = true
        contentView.addSubview(playerView!)
        
        playerLayer = AVPlayerLayer.init()
        playerView?.layer.addSublayer(playerLayer!)
        
        mainMaskView = UIView.init()
        contentView.addSubview(mainMaskView!)
        mainMaskView?.backgroundColor = .clear
        
        playButton = UIButton.init(type: .custom)
        playButton.setImage(UIImage.init(named: "播放大"), for: .normal)
        playButton.setImage(UIImage.init(named: "暂停大"), for: .selected)
        playButton.addTarget(self, action: Selector.playButtonAction, for: .touchUpInside)
        
        timeSlider = UISlider.init()
        timeSlider.minimumTrackTintColor = UIColor.purple
        timeSlider.maximumTrackTintColor = UIColor.white
        timeSlider.value = 0.0
        timeSlider.maximumValue = 1.0
        timeSlider.minimumValue = 0.0
        timeSlider.addTarget(self, action: Selector.sliderTouchBegan, for: UIControlEvents.touchDown)
        timeSlider.addTarget(self, action: Selector.sliderValueChanged, for: UIControlEvents.valueChanged)
        timeSlider.addTarget(self, action: Selector.sliderTouchEnded, for: [UIControlEvents.touchUpInside,UIControlEvents.touchCancel, UIControlEvents.touchUpOutside])
        
        currentTimeLabel = UILabel.init()
        currentTimeLabel.textColor = UIColor.white
        currentTimeLabel.font = UIFont.systemFont(ofSize: 13)
        
        totalTimeLabel = UILabel.init()
        totalTimeLabel.textColor = UIColor.white
        totalTimeLabel.font = UIFont.systemFont(ofSize: 13)
        totalTimeLabel.textAlignment = .right
        
        mainMaskView?.addSubview(playButton)
        mainMaskView?.addSubview(currentTimeLabel)
        mainMaskView?.addSubview(totalTimeLabel)
        mainMaskView?.addSubview(timeSlider)
        
        // 单击 显示/隐藏 maskView
        let singleTap = UITapGestureRecognizer(target: self, action: Selector.singleTapAction)
        contentView.addGestureRecognizer(singleTap)
        let doubleTap = UITapGestureRecognizer(target: self, action: Selector.doubleTapAction)
        doubleTap.numberOfTapsRequired = 2
        singleTap.require(toFail: doubleTap)
        contentView.addGestureRecognizer(doubleTap)
    }
    
    //MARK:- Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !isDismissing {
            imageView.frame = fitFrame
            playerView?.frame = fitFrame
        }
        playerLayer?.frame = (playerView?.bounds)!
        mainMaskView?.frame = contentView.bounds
        
        playButton.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        playButton.center = contentView.center
        
        currentTimeLabel.frame = CGRect(x: 10, y: contentView.bounds.maxY - 30, width: 50, height: 20)
        totalTimeLabel.frame = CGRect(x: contentView.bounds.maxX - 60, y: currentTimeLabel.frame.origin.y, width: 50, height: 20)
        timeSlider.frame = CGRect(x: currentTimeLabel.frame.maxX + 3, y: contentView.bounds.maxY - 30, width: contentView.bounds.size.width - 126, height: 20)
    }
}





fileprivate extension Selector {
//    static let sharePhoto = #selector(VideoBrowserViewCell.sharePhoto)
//    static let deletePhoto = #selector(VideoBrowserViewCell.deletePhoto(_:))
    static let dismiss = #selector(VideoBrowserCell.dismiss)
    
    static let playButtonAction = #selector(VideoBrowserCell.playButtonClicked)
    static let singleTapAction = #selector(VideoBrowserCell.singleTapAction(_:))
    static let doubleTapAction = #selector(VideoBrowserCell.doubleTapAction(_:))
    
    static let sliderTouchBegan = #selector(VideoBrowserCell.sliderTouchBegan(_:))
    static let sliderValueChanged = #selector(VideoBrowserCell.sliderValueChanged(_:))
    static let sliderTouchEnded = #selector(VideoBrowserCell.sliderTouchEnded(_:))
    
    static let playerTimerAction = #selector(VideoBrowserCell.playerTimerAction)
    
    
}








