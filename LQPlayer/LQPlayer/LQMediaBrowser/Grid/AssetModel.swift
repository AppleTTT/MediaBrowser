//
//  GridCellModel.swift
//  LQPlayer
//
//  Created by Lee on 2018/3/27.
//  Copyright © 2018年 ATM. All rights reserved.
//

import UIKit
import Photos


class AlbumItem {
    
    var asset: PHAsset?
    var isSelected: Bool = false
    
    init(asset: PHAsset, isSelected: Bool = false) {
        self.asset = asset
        self.isSelected = isSelected
    }
    
}






