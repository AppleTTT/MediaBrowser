//
//  BrowserCollectionView.swift
//  LQPlayer
//
//  Created by 李树 on 2018/3/26.
//  Copyright © 2018年 laiqu. All rights reserved.
//

import UIKit

class BrowserCollectionView: UICollectionView {

    // 当 Cell 上面有 slide 的时候，滑动的手势会影响到 slide 的手势，因此需要使用自定义的 UICollectionView 来重写此方法
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        let view = super.hitTest(point, with: event)
        if view is UISlider {
            self.isScrollEnabled = false
        }else {
            self.isScrollEnabled = true
        }
        return view
    }

}
