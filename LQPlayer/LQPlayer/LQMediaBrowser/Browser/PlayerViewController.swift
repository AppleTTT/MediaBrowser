//
//  PlayerViewController.swift
//  LQPlayer
//
//  Created by Lee on 2018/4/23.
//  Copyright © 2018年 ATM. All rights reserved.
//

import UIKit
import AVKit
import Photos

private var playerViewControllerKVOContext = 0

class PlayerViewController: UIViewController {

    // MARK:- Properties
    
    /// 观察 \AVPlayerItem.status
    private var playerItemStatusObserver: NSKeyValueObservation?
    
    /// 观察 \AVPlayerItem.duration
    private var playerItemDurationObserver: NSKeyValueObservation?
    
    /// 观察 \AVPlayer.rate
    private var playerRateObserver: NSKeyValueObservation?
    
    @objc lazy var player = AVPlayer()
    
    var playerView: PlayerView {
        return self.view as! PlayerView
    }
    
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
                
                strongSelf.playTimeLabel.text = "\(strongSelf.timeSlider.value)"
                strongSelf.totalTimeLabel.text = "\(newDurationSeconds)"
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
                        for key in PlayerViewController.assetKeysRequiredToPlay {
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
    
    var asset:PHAsset?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        
    }
    
    // MARK:- IBOutlets
    
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var playTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    
    // MARK:- IBActions
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
    
    @IBAction func timeSliderDidChanged(_ sender: UISlider) {
        currentTime = Double(sender.value)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        playerRateObserver = player.observe(\AVPlayer.rate, options: [.new, .initial]) { [weak self] (player, _) in
            guard let strongSelf = self else { return }
            // Update playPauseButton type
            let newRate = player.rate
            strongSelf.playPauseButton.isSelected = newRate != 0.0
        }
    }
    
    // MARK:- View Handling
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        player.pause()
        cleanUpPlayerPeriodicTimeObserver()
        
        removeObserver(self, forKeyPath: #keyPath(PlayerViewController.player.currentItem.duration), context: &playerViewControllerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(PlayerViewController.player.currentItem.status), context: &playerViewControllerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(PlayerViewController.player.rate), context: &playerViewControllerKVOContext)
    }
    
    // MARK:- APIs
    func setupPlayback(asset: PHAsset?) {
        guard let asset = asset else { return }
        self.asset = asset
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
        let time = CMTimeMake(1, 30)
        // Use a weak self variable to avoid a retain cycle in the block
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: time, queue: DispatchQueue.main, using: { [weak self] time in
            self?.timeSlider.value = Float(CMTimeGetSeconds(time))
        }) as AnyObject?
    }
    
    // MARK:- KVO
    // Trigger KVO for anyone observing our properties affected by player and player.currentItem
    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        let affectedKeyPathsMappingByKey: [String: Set<String>] = [
            "duration": [#keyPath(PlayerViewController.player.currentItem.duration)],
            "rate": [#keyPath(PlayerViewController.player.rate)]
        ]
        
        return affectedKeyPathsMappingByKey[key] ?? super.keyPathsForValuesAffectingValue(forKey: key)
    }
}

extension PlayerViewController {
    func handle(error: NSError?) {
        let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
        
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alertController.addAction(alertAction)
        
        present(alertController, animated: true, completion: nil)
    }
}







