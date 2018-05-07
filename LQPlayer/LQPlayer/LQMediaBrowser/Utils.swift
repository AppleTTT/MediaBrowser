//
//  Utils.swift
//  LQPlayer
//
//  Created by Lee on 2018/3/28.
//  Copyright © 2018年 ATM. All rights reserved.
//

import Foundation

class Util {
    static func formatVideoTime(_ duration: TimeInterval) -> String {
        let interval = Int(duration.rounded())
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}









