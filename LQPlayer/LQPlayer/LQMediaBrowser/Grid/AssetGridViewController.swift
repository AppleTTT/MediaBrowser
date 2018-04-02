//
//  AssetGridViewController.swift
//  LQPlayer
//
//  Created by 李树 on 2018/3/22.
//  Copyright © 2018年 laiqu. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class AssetGridViewController: UIViewController {

    //MARK:- Properties
    var collectionView: UICollectionView!
    /// 所有图片
    var fetchResult: PHFetchResult<PHAsset>!
    var sectionDic = [String: Array<AssetModel>]()
    var allKeys = [String]()
    var data = Array<PHAsset>()
    
    var addButtonItem: UIBarButtonItem!
    
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var thumbnailSize: CGSize!
    fileprivate var previousPreheatRect = CGRect.zero
    
    //MARK:- Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareData()
        initUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateItemSize()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    // MARK:- Layout
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateItemSize()
    }
    
    
    
    // MARK:- Actions
   
    
    //MARK:- Private funcs
    private func initUI() {
        let layout = UICollectionViewFlowLayout.init()
        collectionView = UICollectionView.init(frame: view.bounds, collectionViewLayout: layout)
        collectionView.delegate  = self
        collectionView.dataSource = self
        collectionView.backgroundColor =  UIColor.white
        collectionView.register(GridViewCell.self, forCellWithReuseIdentifier: String(describing: GridViewCell.self))
        collectionView.register(GirdReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier:String(describing: GirdReusableView.self))
        view.addSubview(collectionView)
    }
    
    private func prepareData() {
        resetCachedAssets()
        fetchResult = LQMdiaBrowserManager.allPhotos
        //准备数据源，将照片按照每天分组
        fetchResult.enumerateObjects { (asset, _, _) in
            let dateString = asset.creationDate?.dateToString()
            if self.sectionDic.keys.contains(dateString!) {
                var array = self.sectionDic[dateString!]
                let model = AssetModel.init(asset: asset)
                array?.append(model)
                self.sectionDic[dateString!] = array
            } else {
                let model = AssetModel.init(asset: asset)
                let array = [model]
                self.sectionDic[dateString!] = array
            }
        }
        allKeys = Array(sectionDic.keys)
        allKeys = allKeys.sorted(by: >)
        // 获取 mediaBrowser 里面的数据
        //        for string in allKeys {
        //            if sectionDic[string] != nil {
        //                data += Array(sectionDic[string]!)
        //            }
        //        }
    }
    
    private func updateItemSize() {
        let viewWidth = view.bounds.size.width
        
        let sectionInset = LQMdiaBrowserManager.shared.sectionInsets
        let columns = LQMdiaBrowserManager.shared.columns
        let minimumLineSpacing = LQMdiaBrowserManager.shared.minimumLineSpacing
        let minimumInteritemSpacing = LQMdiaBrowserManager.shared.minimumInteritemSpacing
        let itemWidth = (viewWidth - sectionInset.left - sectionInset.right - minimumInteritemSpacing * (columns - 1)) / columns
        let itemSize = CGSize(width: itemWidth, height: LQMdiaBrowserManager.shared.itemHeight == 0 ? itemWidth : LQMdiaBrowserManager.shared.itemHeight)
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = itemSize
            layout.minimumInteritemSpacing = minimumInteritemSpacing
            layout.minimumLineSpacing = minimumLineSpacing
            layout.sectionInset = sectionInset
            //TODO: 替换成 Manager 里面的参数
            layout.headerReferenceSize = CGSize.init(width: 100, height: 20)
        }
        // Determine the size of the thumbnails to request from the PHCachingImageManager
        let scale = UIScreen.main.scale
        thumbnailSize = CGSize(width: itemSize.width * scale, height: itemSize.height * scale)
    }
    
    private func updateCachedAssets() {
        // 当视图可见的时候才更新
        guard isViewLoaded && view.window != nil else { return }
        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        
        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        
        // Store the preheat rect to compare against in the future.
        previousPreheatRect = preheatRect
    }
    
    private func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
    private func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
}

extension AssetGridViewController: UICollectionViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if sectionDic.count > 0, allKeys.count > 0 {
            let browserVC = MediaBrowserViewController.init(showByViewController: self, delegate: self, data: sectionDic, keysSequence: allKeys)
            browserVC.show(indexPath: indexPath)
        }
    }
}

extension AssetGridViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sectionDic.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (sectionDic[allKeys[section]]?.count)!
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let reuseableView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: String(describing: GirdReusableView.self), for: indexPath)
        
        guard reuseableView is GirdReusableView else {
            fatalError("unexpected UICollectionReusableView")
        }
        let reuseableHeader = reuseableView as! GirdReusableView
        reuseableHeader.label.text = allKeys[indexPath.section]
        
        return reuseableHeader
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let model = sectionDic[allKeys[indexPath.section]]![indexPath.row]
        let asset = model.asset!
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: GridViewCell.self), for: indexPath) as? GridViewCell else {
            fatalError("unexpected cell in collection view")
        }
        
        if asset.mediaSubtypes.contains(.photoLive) {
            cell.livePhotoBadgeImage = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
        }
        cell.representedAssetIdentifier = asset.localIdentifier
        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
            // The cell may have been recycled by the time this handler gets called;
            // set the cell's thumbnail image only if it's still showing the same asset.
            if cell.representedAssetIdentifier == asset.localIdentifier && image != nil {
                cell.thumbnailImage = image
            }
        })
        cell.refreshCell(with: model)
        return cell
    }
}


extension AssetGridViewController: MediaBrowserViewControllerDelegate {
    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, didScrollAt indexPath: IndexPath) {
        collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.centeredVertically, animated: false)
    }
    
    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController?, thumbnailViewForIndexPath indexPath: IndexPath) -> UIView? {
        let cell = collectionView.cellForItem(at: indexPath) as? GridViewCell
        return cell
    }
    
    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController?, thumbnailImageForIndexPath indexPath: IndexPath) -> UIImage? {
        let cell = collectionView.cellForItem(at: indexPath) as? GridViewCell
        return cell?.imageView.image
    }
}

fileprivate extension Selector {
    
}

fileprivate extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

fileprivate extension Date {
    func dateToString() -> String {
        let dataFormater = DateFormatter.init()
        dataFormater.dateFormat = "yyyy-MM-dd"
        return dataFormater.string(from: self)
    }
}





