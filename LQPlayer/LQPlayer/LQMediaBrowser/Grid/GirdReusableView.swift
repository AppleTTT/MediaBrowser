//
//  GirdReusableView.swift
//  LQPlayer
//
//  Created by Lee on 2018/3/24.
//  Copyright © 2018年 ATM. All rights reserved.
//

import UIKit

class GirdReusableView: UICollectionReusableView {
    
    
    var label: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        label = UILabel.init(frame: self.bounds)
        label.backgroundColor = UIColor.yellow
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = UIColor.black
        self.addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        label.frame = CGRect.init(x: 15, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)
    }
    
    
}
