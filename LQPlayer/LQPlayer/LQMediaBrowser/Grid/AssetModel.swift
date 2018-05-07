//
//  GridCellModel.swift
//  LQPlayer
//
//  Created by 李树 on 2018/3/27.
//  Copyright © 2018年 laiqu. All rights reserved.
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






