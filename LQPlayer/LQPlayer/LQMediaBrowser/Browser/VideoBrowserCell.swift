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
    
    // MARK:- Properties
    var playPauseButton: UIButton!
    var timeSlider: UISlider!
    var currentTimeLabel: UILabel!
    var totalTimeLabel: UILabel!
    var totalDuration: TimeInterval?

    var delayItem: DispatchWorkItem?
    
    var isDismissing = false
    /// 观察 \AVPlayerItem.status
    private var playerItemStatusObserver: NSKeyValueObservation?
    
    /// 观察 \AVPlayerItem.duration
    private var playerItemDurationObserver: NSKeyValueObservation?
    
    /// 观察 \AVPlayer.rate
    private var playerRateObserver: NSKeyValueObservation?
    
    @objc lazy var player = AVPlayer()
    var playerView: PlayerView!
    var playerLayer: AVPlayerLayer? {
        return playerView.playerLayer
    }
    
    var playerItem: AVPlayerItem? = nil {
        willSet {
            /// remove any previous KVO observer
            guard let playerItemStatusObserver = playerItemStatusObserver else { return }
            playerItemStatusObserver.invalidate()
        }
        
        didSet {
            /*
             If needed, configure player item here before associating it with a player
             (example: adding outputs, setting text style rules, selecting media options)
             */
            player.replaceCurrentItem(with: playerItem)
            if playerItem == nil {
                cleanUpPlayerPeriodicTimeObserver()
            } else {
                setupPlayerPeriodicTimeObserver()
            }
            
            // Use KVO to get notified of changes in the AVPlayerItem duration property
            playerItemDurationObserver = playerItem?.observe(\AVPlayerItem.duration, options: [.new, .initial]) { [weak self](item, _) in
                guard let strongSelf = self else { return }
                
                // Update `timeSlider` and enable/disable controls when `duration` > 0.0
                let newDuration = item.duration
                let hasValidDuration = newDuration.isNumeric && newDuration.value != 0
                let newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0
                
                strongSelf.timeSlider.maximumValue = Float(newDurationSeconds)
                
                let currentTime = CMTimeGetSeconds(strongSelf.player.currentTime())
                strongSelf.timeSlider.value = hasValidDuration ? Float(currentTime) : 0.0
                
                strongSelf.playPauseButton.isEnabled = hasValidDuration
                strongSelf.timeSlider.isEnabled = hasValidDuration
                
                strongSelf.currentTimeLabel.text = strongSelf.createTimeString(time: Float(currentTime))
                strongSelf.totalTimeLabel.text = strongSelf.createTimeString(time: Float(newDurationSeconds))
            }
            
            playerItemStatusObserver = playerItem?.observe(\AVPlayerItem.status, options: [.new, .initial]) { [weak self] (item, _) in
                guard let strongSelf = self else { return }
                
                // display an error if status becomes Failed
                if item.status == .failed {
                    strongSelf.handle(error: strongSelf.player.currentItem?.error as NSError?)
                } else if item.status == .readyToPlay {
                    
                    if let asset = strongSelf.player.currentItem?.asset {
                        /*
                         First test whether the values of `assetKeysRequiredToPlay` we need
                         have been successfully loaded.
                         */
                        for key in VideoBrowserCell.assetKeysRequiredToPlay {
                            var  error: NSError?
                            if asset.statusOfValue(forKey: key, error: &error) == .failed {
                                strongSelf.handle(error: error)
                                return
                            }
                        }
                        
                        if !asset.isPlayable || asset.hasProtectedContent {
                            // we can't paly this asset
                            strongSelf.handle(error: nil)
                            return
                        }
                    }
                }
            }
        }
    }
    
    static let assetKeysRequiredToPlay = [
        "playable",
        "hasProtectedContent"
    ]
    
    var currentTime: Double {
        get {
            return CMTimeGetSeconds(player.currentTime())
        }
        
        set {
            let newValue = CMTimeMakeWithSeconds(newValue, 1)
            player.seek(to: newValue, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        }
    }
    
    var duration: Double {
        guard let currentItem = player.currentItem else { return 0.0 }
        return CMTimeGetSeconds(currentItem.duration)
    }
    
    var timeObserverToken: AnyObject?
    /*
     A formatter for individual date components used to provide an appropriate
     value for the `startTimeLabel` and `durationLabel`.
     */
    let timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        
        return formatter
    }()
    
    
    //MARK:- Life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        addUI()
        scrollView.isHidden = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK:- APIs
    override func refreshCell(asset: PHAsset!, placeholder: UIImage?) {
        if asset.mediaType != .video { return }
        self.asset = asset
        imageView.image = placeholder

    }
    
    func cellWillAppear() {
        playerView.playerLayer.player = player
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        
        PHImageManager.default().requestPlayerItem(forVideo: asset!, options: options, resultHandler: { playerItem, _ in
            DispatchQueue.main.sync {
                guard playerItem != nil else { return }
                self.playerItem = playerItem
            }
        })
        timeSlider.translatesAutoresizingMaskIntoConstraints = true
        timeSlider.autoresizingMask = .flexibleWidth
    }
    
    func cellDidDisappear() {
        player.pause()
        cleanUpPlayerPeriodicTimeObserver()
    }

    //MARK:- Actions
    @objc func playButtonClicked(button: UIButton) {
        if player.rate != 1.0 {
            // Not playing foward, so play
            if currentTime == duration {
                // At end, so got back to begining
                currentTime = 0.0
            }
            player.play()
        } else {
            player.pause()
        }
    }

    /// 单击手势，显示或者隐藏 maskView
    @objc func singleTapAction(_ tap: UITapGestureRecognizer) {
        // 动画显示或者隐藏 maskView
        // 自动消失
        mainMaskView.alpha = mainMaskView.alpha == 0 ? 1 : 0
        
    }
    /// 双击手势，在显示图片的时候是放大或者缩小，在显示视频的时候，是暂停或者播放
    @objc override func doubleTapAction(_ tap: UITapGestureRecognizer) {
        self.playButtonClicked(button: playPauseButton)
    }
    
    @objc func sliderValueChanged(_ sender: UISlider)  {
        cancelAutoFadeOutAnimation()
        currentTime = Double(sender.value)
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
                self.mainMaskView.alpha = 0.0
            }, completion: nil)
        } else if scale >= 1.0 {
            UIView.animate(withDuration: 0.3, animations: {
                self.mainMaskView.alpha = 1.0
            }, completion: nil)
        }
    }
    
    override func customViewEndPan(needResetSize: Bool, size: CGSize) {
        super .customViewEndPan(needResetSize: needResetSize, size: size)
        self.playerView?.center = self.centerOfContentSize
        if needResetSize { self.playerView?.bounds.size = size }
    }

    private func autoFadeOutControlViewWithAnimation() {
        cancelAutoFadeOutAnimation()
        delayItem = DispatchWorkItem { [weak self] in
//            if self?.isPlayToEnd == false{
//                self?.switchMaskView(hide: true)
//            }
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
            self.mainMaskView.alpha = CGFloat(alpha)
        }) { (_) in
            if hide {
                self.autoFadeOutControlViewWithAnimation()
            }
        }
    }
    
    private func cleanUpPlayerPeriodicTimeObserver() {
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
    
    private func setupPlayerPeriodicTimeObserver() {
        guard timeObserverToken == nil else { return }
        let time = CMTimeMake(1, 1)
        // Use a weak self variable to avoid a retain cycle in the block
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: time, queue: DispatchQueue.main, using: { [weak self] time in
            let timeElapsed = Float(CMTimeGetSeconds(time))
            self?.timeSlider.setValue(timeElapsed, animated: false)
            self?.currentTimeLabel.text = self?.createTimeString(time: timeElapsed)
        }) as AnyObject?
    }
    
    // MARK:- KVO
    // Trigger KVO for anyone observing our properties affected by player and player.currentItem
    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        let affectedKeyPathsMappingByKey: [String: Set<String>] = [
            "duration": [#keyPath(VideoBrowserCell.player.currentItem.duration)],
            "rate": [#keyPath(VideoBrowserCell.player.rate)]
        ]
        
        return affectedKeyPathsMappingByKey[key] ?? super.keyPathsForValuesAffectingValue(forKey: key)
    }
    
    private func preparePlayer() {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: options, resultHandler: { playerItem, _ in
            DispatchQueue.main.sync {
                guard playerItem != nil else { return }
            }
        })
    }
    
    
    private func addUI() {
        playerView = PlayerView(frame: fitFrame)
        playerView.clipsToBounds = true
        contentView.insertSubview(playerView, belowSubview: mainMaskView)
        
        playPauseButton = UIButton.init(type: .custom)
        playPauseButton.setImage(UIImage.init(named: "播放大"), for: .normal)
        playPauseButton.setImage(UIImage.init(named: "暂停大"), for: .selected)
        playPauseButton.addTarget(self, action: Selector.playButtonAction, for: .touchUpInside)
        
        timeSlider = UISlider.init()
        timeSlider.minimumTrackTintColor = UIColor.purple
        timeSlider.maximumTrackTintColor = UIColor.white
        timeSlider.value = 0.0
        timeSlider.maximumValue = 1.0
        timeSlider.minimumValue = 0.0
        timeSlider.addTarget(self, action: Selector.sliderValueChanged, for: UIControlEvents.valueChanged)
        timeSlider.addTarget(self, action: Selector.sliderTouchEnded, for: [UIControlEvents.touchUpInside,UIControlEvents.touchCancel, UIControlEvents.touchUpOutside])
        
        currentTimeLabel = UILabel.init()
        currentTimeLabel.textColor = UIColor.white
        currentTimeLabel.font = UIFont.systemFont(ofSize: 13)
        
        totalTimeLabel = UILabel.init()
        totalTimeLabel.textColor = UIColor.white
        totalTimeLabel.font = UIFont.systemFont(ofSize: 13)
        totalTimeLabel.textAlignment = .right
        
        mainMaskView.addSubview(playPauseButton)
        mainMaskView.addSubview(currentTimeLabel)
        mainMaskView.addSubview(totalTimeLabel)
        mainMaskView.addSubview(timeSlider)
        
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
        mainMaskView.frame = contentView.bounds
        
        var bottomPadding: CGFloat = 10
        if #available(iOS 11.0, *),  UIScreen.main.bounds.height == 812 {
            bottomPadding = self.safeAreaInsets.bottom + 50
        }
        
        playPauseButton.snp.updateConstraints { (make) in
            make.centerX.centerY.equalTo(contentView)
            make.width.height.equalTo(50)
        }
        
        currentTimeLabel.snp.updateConstraints { (make) in
            make.left.equalTo(contentView.snp.left).offset(10)
            make.bottom.equalTo(contentView.snp.bottom).offset(-bottomPadding)
        }
        
        totalTimeLabel.snp.updateConstraints { (make) in
            make.right.equalTo(contentView.snp.right).offset(-10)
            make.centerY.equalTo(currentTimeLabel)
        }
        
        timeSlider.snp.updateConstraints { (make) in
            make.left.equalTo(currentTimeLabel.snp.right).offset(3)
            make.right.equalTo(totalTimeLabel.snp.left).offset(-3)
            make.centerY.equalTo(currentTimeLabel).offset(0)
        }
    }
}

extension VideoBrowserCell {
    func handle(error: NSError?) {
        print("👻Error: \(String(describing: error?.localizedDescription))")
    }
    
    // MARK: Convenience
    func createTimeString(time: Float) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))
        
        return timeRemainingFormatter.string(from: components as DateComponents)!
    }
}






fileprivate extension Selector {

    static let playButtonAction = #selector(VideoBrowserCell.playButtonClicked)
    static let singleTapAction = #selector(VideoBrowserCell.singleTapAction(_:))
    static let doubleTapAction = #selector(VideoBrowserCell.doubleTapAction(_:))
    static let sliderValueChanged = #selector(VideoBrowserCell.sliderValueChanged(_:))
    static let sliderTouchEnded = #selector(VideoBrowserCell.sliderTouchEnded(_:))
}








