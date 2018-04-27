//
//  VideoBrowser1Cell.swift
//  LQPlayer
//
//  Created by 李树 on 2018/4/26.
//  Copyright © 2018年 laiqu. All rights reserved.
//

import UIKit
import AVKit
import Photos

private var playerViewCellKVOContext = 0

class VideoBrowser1Cell: PhotoBrowserCell {
    
    // MARK:- Properties
    /// 观察 \AVPlayerItem.status
    private var playerItemStatusObserver: NSKeyValueObservation?
    
    /// 观察 \AVPlayerItem.duration
    private var playerItemDurationObserver: NSKeyValueObservation?
    
    /// 观察 \AVPlayer.rate
    private var playerRateObserver: NSKeyValueObservation?
    
    @objc lazy var player = AVPlayer()
    
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
                        for key in VideoBrowser1Cell.assetKeysRequiredToPlay {
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
    
    /// 判断是否在手势返回的过程中
    var isDismissing = false
    
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
    
    // MARK:- IBOutlets
    
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var backMaskView: UIView!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var mediaDateLabel: UILabel!
    @IBOutlet weak var mediaTimeLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var timeSlider: UISlider!
    
    //MARK:- IBActions
    
    @IBAction func playPauseButtonClicked(_ sender: UIButton) {
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
    
    @IBAction func timeSliderChanged(_ sender: UISlider) {
        currentTime = Double(sender.value)
    }
    
    @IBAction func backButtonClicked(_ sender: UIButton) {
        //TODO: dismiss 操作
        
    }
    
    // MARK:- Life cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        scrollView.isHidden = true
        playerRateObserver = player.observe(\AVPlayer.rate, options: [.new, .initial]) { [weak self] (player, _) in
            guard let strongSelf = self else { return }
            // Update playPauseButton type
            let newRate = player.rate
            strongSelf.playPauseButton.isSelected = newRate != 0.0
        }
    }
    
    // MARK:- APIs
    override func refreshCell(asset: PHAsset?, placeholder: UIImage?) {
        guard let asset = asset else { return }
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
        
        
//        removeObserver(self, forKeyPath: #keyPath(VideoBrowser1Cell.player.currentItem.status), context: nil)
//        removeObserver(self, forKeyPath: #keyPath(VideoBrowser1Cell.player.rate), context: nil)
//        removeObserver(self, forKeyPath: #keyPath(VideoBrowser1Cell.player.currentItem.duration), context: nil)
    }
    
    
    // MARK: - Private funcs
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
            "duration": [#keyPath(VideoBrowser1Cell.player.currentItem.duration)],
            "rate": [#keyPath(VideoBrowser1Cell.player.rate)]
        ]
        
        return affectedKeyPathsMappingByKey[key] ?? super.keyPathsForValuesAffectingValue(forKey: key)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !isDismissing {
            playerView?.frame = fitFrame
        }
    }
    
    override func resizeCustomView(scale: CGFloat, rect: CGRect) {
        super.resizeCustomView(scale: scale, rect: rect)
        if rect != CGRect.zero {
            isDismissing = true
            playerView?.frame = rect
        }
        // 用于在拉动图片的时候，其他视图的变化，比如这里就是拉动的时候，删除，分享，返回等按钮的 alpha 就要变化
        if scale < 0.98 {
            UIView.animate(withDuration: 0.3, animations: {
                self.backMaskView?.alpha = 0.0
            }, completion: nil)
        } else if scale >= 1.0 {
            UIView.animate(withDuration: 0.3, animations: {
                self.backMaskView?.alpha = 1.0
            }, completion: nil)
        }
    }
    
    override func customViewEndPan(needResetSize: Bool, size: CGSize) {
        super .customViewEndPan(needResetSize: needResetSize, size: size)
        self.playerView?.center = self.centerOfContentSize
        if needResetSize { self.playerView?.bounds.size = size }
    }
    

}

extension VideoBrowser1Cell {
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






