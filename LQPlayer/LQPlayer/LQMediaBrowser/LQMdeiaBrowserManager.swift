//
//  LQMdeiaBrowserManager.swift
//  LQPlayer
//
//  Created by 李树 on 2018/3/22.
//  Copyright © 2018年 laiqu. All rights reserved.
//

import Foundation
import UIKit


struct LQMdiaBrowserManager {
    
    
    static let shared = LQMdiaBrowserManager()
    
    // gridVC 里面的列数与每张图片的间距
    var columns: CGFloat = 3
    var minimumLineSpacing: CGFloat = 6
    var minimumInteritemSpacing:CGFloat = 6
    var itemHeight:CGFloat = 0
    
    var sectionInsets = UIEdgeInsets(top: 5.0, left: 15.0, bottom: 5.0, right: 15.0)
    
}


