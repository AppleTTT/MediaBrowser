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
            guard let playerItemStatusObserver = playerItemStatusObserver else { return }
            playerItemStatusObserver.invalidate()
        }
        
        didSet {
            player.replaceCurrentItem(with: playerItem)
            if playerItem == nil {
                cleanUpPlayerPeriodicTimeObserver()
            } else {
                setupPlayerPeriodicTimeObserver()
            }
            
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
                
                strongSelf.currentTimeLabel.text = Util.formatVideoTime(currentTime)
                strongSelf.totalTimeLabel.text = Util.formatVideoTime(newDurationSeconds)
            }
            
            playerItemStatusObserver = playerItem?.observe(\AVPlayerItem.status, options: [.new, .initial]) { [weak self] (item, _) in
                guard let strongSelf = self else { return }
                
                if item.status == .failed {
                    strongSelf.handle(error: strongSelf.player.currentItem?.error as NSError?)
                } else if item.status == .readyToPlay {
                    
                    if let asset = strongSelf.player.currentItem?.asset {
                        for key in VideoBrowserCell.assetKeysRequiredToPlay {
                            var  error: NSError?
                            if asset.statusOfValue(forKey: key, error: &error) == .failed {
                                strongSelf.handle(error: error)
                                return
                            }
                        }
                        
                        if !asset.isPlayable || asset.hasProtectedContent {
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
            currentTimeLabel.text = Util.formatVideoTime(newValue)
            let newValue = CMTimeMakeWithSeconds(newValue, 1)
            player.seek(to: newValue, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        }
    }
    
    var duration: Double {
        guard let currentItem = player.currentItem else { return 0.0 }
        return CMTimeGetSeconds(currentItem.duration)
    }
    
    var rate: Float {
        get {
            return player.rate
        }
        
        set {
            player.rate = newValue
        }
    }
    
    var timeObserverToken: AnyObject?
    
    //MARK:- Life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addUI()
        
        playerRateObserver = player.observe(\AVPlayer.rate, options: [.new]) { [weak self] (player, _) in
            guard let strongSelf = self else { return }
            strongSelf.playPauseButton.isSelected = !(player.rate == 0.0)
            
            if player.rate == 0.0, strongSelf.duration == strongSelf.currentTime {
                strongSelf.cancelAutoFadeOutMaskView()
                strongSelf.mainMaskView.alpha = 1.0
            }
            
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK:- APIs
    override func refreshCell(asset: PHAsset!, placeholder: UIImage?) {
        if asset.mediaType != .video { return }
        self.asset = asset
        imageView.image = placeholder
        
        mediaDateLabel.text = asset.creationDate?.string(custom: "yyyy年MM月dd日")
        mediaTimeLabel.text = asset.creationDate?.string(custom: "HH:mm")
        
        preparePlayer()
    }
    
    func cellDidDisappear() {
        player.pause()
        currentTime = 0.0
    }
    
    //MARK:- Actions
    @objc func playButtonClicked(button: UIButton) {
        
        guard self.asset != nil else {
            showMediaIsImportingToast()
            return
        }
        if player.rate != 1.0 {
            if currentTime == duration { currentTime = 0.0 }
            player.play()
            // 播放，就立马消失，暂停就等 2s 后消失
            switchMaskView(hide: true)
        } else {
            player.pause()
            autoDelayFadeOutMaskView()
        }
    }
    
    /// 单击手势，显示或者隐藏 maskView
    @objc func singleTapAction(_ tap: UITapGestureRecognizer) {
        // 动画显示或者隐藏 maskView
        // 自动消失
        mainMaskView.alpha = mainMaskView.alpha == 0 ? 1 : 0
        autoDelayFadeOutMaskView()
    }
    /// 双击手势，在显示图片的时候是放大或者缩小，在显示视频的时候，是暂停或者播放
    @objc override func doubleTapAction(_ tap: UITapGestureRecognizer) {
        self.playButtonClicked(button: playPauseButton)
    }
    
    @objc func sliderTouchBegan(_ sender: UISlider)  {
        cleanUpPlayerPeriodicTimeObserver()
        cancelAutoFadeOutMaskView()
    }
    
    @objc func sliderValueChanged(_ sender: UISlider)  {
        guard self.asset != nil else {
            showMediaIsImportingToast()
            return
        }
        
        currentTime = Double(sender.value)
    }
    
    @objc func sliderTouchEnded(_ sender: UISlider)  {
        setupPlayerPeriodicTimeObserver()
        autoDelayFadeOutMaskView()
    }
    
    override func sharePhoto() {
        super.sharePhoto()
        player.pause()
    }
    
    override func deletePhoto(_ deleteButton: UIButton) {
        super.deletePhoto(deleteButton)
        player.pause()
    }
    
    // MARK:- Override
    override func resizeCustomView(scale: CGFloat, rect: CGRect) {
        super.resizeCustomView(scale: scale, rect: rect)
        if rect != CGRect.zero {
            isDismissing = true
            playerView?.frame = rect
        }
    }
    
    override func customViewEndPan(needResetSize: Bool, size: CGSize) {
        super .customViewEndPan(needResetSize: needResetSize, size: size)
        self.playerView?.center = self.centerOfContentSize
        if needResetSize { self.playerView?.bounds.size = size }
    }
    
    private func autoDelayFadeOutMaskView() {
        cancelAutoFadeOutMaskView()
        delayItem = DispatchWorkItem { [weak self] in
            self?.switchMaskView(hide: true)
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2,
                                      execute: delayItem!)
    }
    
    private func cancelAutoFadeOutMaskView() {
        delayItem?.cancel()
    }
    
    private func switchMaskView(hide: Bool) {
        let alpha: CGFloat = hide ? 0 : 1
        UIView.animate(withDuration: 0.3, animations: {
            self.mainMaskView.alpha = alpha
        }) { (_) in
        }
    }
    
    private func cleanUpPlayerPeriodicTimeObserver() {
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
    
    private func setupPlayerPeriodicTimeObserver() {
        
        cleanUpPlayerPeriodicTimeObserver()
        
        let interval = CMTimeMake(1, 1)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { [weak self] time in
            let timeElapsed = Float(CMTimeGetSeconds(time))
            self?.timeSlider.value = timeElapsed
            self?.currentTimeLabel.text = Util.formatVideoTime(TimeInterval(timeElapsed))
        }) as AnyObject?
    }
    
    // MARK:- KVO
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
                self.playerItem = playerItem
            }
        })
    }
    
    private func addUI() {
        scrollView.isHidden = true
        
        playerView = PlayerView(frame: contentView.bounds)
        playerView.clipsToBounds = true
        playerView.playerLayer.player = player
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
        timeSlider.translatesAutoresizingMaskIntoConstraints = true
        timeSlider.autoresizingMask = .flexibleWidth
        timeSlider.addTarget(self, action: Selector.sliderTouchBegan, for: .touchDown)
        timeSlider.addTarget(self, action: Selector.sliderValueChanged, for: .valueChanged)
        timeSlider.addTarget(self, action: Selector.sliderTouchEnded, for: [.touchUpInside, .touchCancel, .touchUpOutside])
        
        currentTimeLabel = UILabel.init()
        currentTimeLabel.textColor = UIColor.white
        currentTimeLabel.text = "00:00"
        currentTimeLabel.font = UIFont.systemFont(ofSize: 13)
        
        totalTimeLabel = UILabel.init()
        totalTimeLabel.textColor = UIColor.white
        totalTimeLabel.font = UIFont.systemFont(ofSize: 13)
        totalTimeLabel.text = "00:00"
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
        
        mainMaskView.frame = contentView.bounds
        
        if !isDismissing {
            //            imageView.frame = fitFrame
            playerView?.frame = contentView.bounds
        }
        
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
}

fileprivate extension Selector {
    
    static let playButtonAction = #selector(VideoBrowserCell.playButtonClicked)
    static let singleTapAction = #selector(VideoBrowserCell.singleTapAction(_:))
    static let doubleTapAction = #selector(VideoBrowserCell.doubleTapAction(_:))
    static let sliderTouchBegan = #selector(VideoBrowserCell.sliderTouchBegan(_:))
    static let sliderValueChanged = #selector(VideoBrowserCell.sliderValueChanged(_:))
    static let sliderTouchEnded = #selector(VideoBrowserCell.sliderTouchEnded(_:))
}








