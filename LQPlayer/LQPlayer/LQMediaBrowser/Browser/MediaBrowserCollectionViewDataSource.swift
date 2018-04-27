//
//  MediaBrowserCollectionViewDataSource.swift
//  LQPlayer
//
//  Created by 李树 on 2018/3/26.
//  Copyright © 2018年 laiqu. All rights reserved.
//

import UIKit
import Photos

class MediaBrowserCollectionViewDataSource: NSObject, UICollectionViewDataSource {
    
    
    var dataDictionary: [String: Array<AssetModel>]!
    var keysSequence:  [String]!
    weak var owner: MediaBrowserViewController?
    
    init(data: [String: Array<AssetModel>], keysSequence: [String], owner: MediaBrowserViewController?) {
        self.dataDictionary = data
        self.keysSequence = keysSequence
        self.owner = owner
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataDictionary[keysSequence[section]]!.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return keysSequence.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.section != keysSequence.count else { fatalError() }
        let asset = dataDictionary[keysSequence[indexPath.section]]![indexPath.item].asset
        
        if asset?.mediaType == .image {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCellReuseId, for: indexPath) as! PhotoBrowserCell
            let image = owner?.mediaBrowserDelegate?.mediaBrowser(owner, thumbnailImageForIndexPath: indexPath)
            cell.refreshCell(asset: asset, placeholder: image)
            cell.photoBrowserCellDelegate = owner
            return cell
        }
        
        if asset?.mediaType == .video {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: video1CellResueId, for: indexPath) as! VideoBrowser1Cell
            let image = owner?.mediaBrowserDelegate?.mediaBrowser(owner, thumbnailImageForIndexPath: indexPath)
//            cell.refreshCell(asset: asset, placeholder: image)
//            cell.photoBrowserCellDelegate = owner
            cell.refreshCell(asset: asset, placeholder: image)
            return cell
        }
        return UICollectionViewCell.init()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let reuseableView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerResueId, for: indexPath)

        reuseableView.backgroundColor = UIColor.black
        return reuseableView
    } 
}






