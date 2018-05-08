//
//  LQMdeiaBrowserManager.swift
//  LQPlayer
//
//  Created by Lee on 2018/3/22.
//  Copyright © 2018年 ATM. All rights reserved.
//

import Foundation
import UIKit
import Photos


struct LQMdiaBrowserManager {
    
    
    static let shared = LQMdiaBrowserManager()
    
    // gridVC 里面的列数与每张图片的间距
    var columns: CGFloat = 3
    var minimumLineSpacing: CGFloat = 6
    var minimumInteritemSpacing:CGFloat = 6
    var itemHeight:CGFloat = 0
    
    var sectionInsets = UIEdgeInsets(top: 5.0, left: 15.0, bottom: 5.0, right: 15.0)
    
    
    static let allPhotos: PHFetchResult<PHAsset> = {
        let allPhotoOption = PHFetchOptions()
        allPhotoOption.sortDescriptors = [NSSortDescriptor(key: "creationDate",  ascending: true)]
        let assets = PHAsset.fetchAssets(with: allPhotoOption)
        return assets
    }()
    static let smartAlbums: PHFetchResult<PHAssetCollection> = {
        return PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
    }()
    static let userCollections: PHFetchResult<PHCollection> = {
        return PHCollectionList.fetchTopLevelUserCollections(with: nil)
    }()
    

    
    
    
    
    
    
    
}


