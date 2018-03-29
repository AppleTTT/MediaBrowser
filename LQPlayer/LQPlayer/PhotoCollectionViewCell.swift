//
//  PhotoCollectionViewCell.swift
//  LQPlayer
//
//  Created by 李树 on 2018/3/8.
//  Copyright © 2018年 laiqu. All rights reserved.
//

import UIKit
import Photos

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbImageView: UIImageView!
    
    @IBOutlet weak var typeLabel: UILabel!
    
    
    
    func updateCell(with asset: PHAsset) {
        
        switch asset.mediaType {
        case .image:
            typeLabel.text = "Image"
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize.init(width: 50, height: 40), contentMode: .aspectFit, options: nil, resultHandler: { (image, _) in
                self.thumbImageView.image = image
            })
        case .video:
            typeLabel.text = "Video"
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize.init(width: 50, height: 40), contentMode: .aspectFit, options: nil, resultHandler: { (image, _) in
                self.thumbImageView.image = image
            })
        case .unknown:
            typeLabel.text = "unknown"
            self.thumbImageView.image = UIImage(named: "unknow")
        case .audio:
            typeLabel.text = "audio"
            self.thumbImageView.image = UIImage(named: "unknow")
        }
    }
    
    
    
    
}
