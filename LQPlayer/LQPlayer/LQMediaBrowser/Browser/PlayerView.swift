//
//  PlayerView.swift
//  LQPlayer
//
//  Created by 李树 on 2018/4/23.
//  Copyright © 2018年 laiqu. All rights reserved.
//

import UIKit
import AVFoundation

class PlayerView: UIView {
    // MARK: Properties
    
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        
        set {
            playerLayer.player = newValue
        }
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
