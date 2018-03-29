//
//  GridViewCell.swift
//  LQPlayer
//
//  Created by 李树 on 2018/3/24.
//  Copyright © 2018年 laiqu. All rights reserved.
//

import UIKit

class GridViewCell: UICollectionViewCell {
    
    
    var imageView: UIImageView!
    var livePhotoBadgeImageView: UIImageView!
    
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = UIImageView.init(frame: contentView.bounds)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        contentView.addSubview(imageView)
        
        livePhotoBadgeImageView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: 28, height: 28))
        livePhotoBadgeImageView.contentMode = .scaleToFill
        contentView.addSubview(livePhotoBadgeImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
