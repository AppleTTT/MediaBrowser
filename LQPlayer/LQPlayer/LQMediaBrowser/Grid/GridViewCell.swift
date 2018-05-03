//
//  GridViewCell.swift
//  LQPlayer
//
//  Created by 李树 on 2018/3/24.
//  Copyright © 2018年 laiqu. All rights reserved.
//

import UIKit
import SnapKit

class GridViewCell: UICollectionViewCell {
    
    //MARK:- Properties
    var imageView: UIImageView!
    var livePhotoBadgeImageView: UIImageView!
    var durationLable: UILabel!
    
    var representedAssetIdentifier: String!
    
    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }
    
    var livePhotoBadgeImage: UIImage! {
        didSet {
            livePhotoBadgeImageView.image = livePhotoBadgeImage
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImage = nil
        livePhotoBadgeImageView.image = nil
    }
    
    //MARK:- Life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        
        imageView = UIImageView.init()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        contentView.addSubview(imageView)
        
        livePhotoBadgeImageView = UIImageView.init()
        livePhotoBadgeImageView.contentMode = .scaleToFill
        contentView.addSubview(livePhotoBadgeImageView)
        
        durationLable = UILabel.init()
        durationLable.textColor = UIColor.white
        durationLable.font = UIFont.systemFont(ofSize: 11)
        durationLable.textAlignment = .right
        durationLable.backgroundColor = UIColor.clear
        contentView.addSubview(durationLable)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- Layout
    override func layoutSubviews() {
        imageView.frame = contentView.bounds
        livePhotoBadgeImageView.snp.remakeConstraints { (make) in
            make.left.top.equalTo(contentView).offset(0)
            make.width.height.equalTo(28)
        }
        
        durationLable.snp.remakeConstraints { (make) in
            make.bottom.right.equalTo(contentView).offset(-6)
            make.height.equalTo(14)
        }
    }
    
    //MARK:- APIs
    func refreshCell(with model: AssetModel?) {
        guard let model = model else { return }
        if model.asset != nil, model.asset!.duration > 0 {
            durationLable.text = Util.formatVideoTime(model.asset!.duration)
        } else {
             durationLable.text = ""
        }
    }
    
}








