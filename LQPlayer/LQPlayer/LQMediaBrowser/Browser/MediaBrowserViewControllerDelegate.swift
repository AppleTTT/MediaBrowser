//
//  MediaBrowserViewControllerDelegate.swift
//  LQPlayer
//
//  Created by Lee on 2018/3/26.
//  Copyright © 2018年 ATM. All rights reserved.
//

import Foundation
import UIKit


protocol MediaBrowserViewControllerDelegate: class {
    /// 实现本方法以返回图片数量
//    func numberOfMedia(in mediaBrowser: MediaBrowserViewController) -> Int
    
    /// 实现本方法以返回默认显示图片，缩略图或占位图
    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController?, thumbnailImageForIndexPath indexPaht: IndexPath) -> UIImage?
    
    /// 实现本方法以返回默认图所在view，在转场动画完成后将会修改这个view的alpha属性
    /// 比如你可返回ImageView，或整个Cell
    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController?, thumbnailViewForIndexPath indexPath: IndexPath) -> UIView?
    
//    /// 实现本方法以返回高质量图片的url。可选
//    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, highQualityUrlForIndex index: Int) -> URL?
//
//    /// 实现本方法以返回原图级质量的url。当本代理方法有返回值时，自动显示查看原图按钮。可选
//    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, rawUrlForIndex index: Int) -> URL?
//
//    /// 长按时回调。可选
//    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, didLongPressForIndex index: Int, image: UIImage)
//
//    ///删除图片的回调
//    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, didDeleteItemAtIndex index: Int)
//
//    ///滑动图片的回调
    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, didScrollAt indexPath: IndexPath)
}


//MARK:- 给出默认实现
extension MediaBrowserViewControllerDelegate {
//    func numberOfMedia(in mediaBrowser: MediaBrowserViewController) -> Int { return 0 }
//    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController?, thumbnailImageForIndexPath indexPath: IndexPath) -> UIImage? { return nil }
//    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController?, thumbnailViewForIndexPath indexPath: IndexPath) -> UIView? { return nil }
//    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, highQualityUrlForIndex index: Int) -> URL? { return nil }
//    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, rawUrlForIndex index: Int) -> URL? { return nil }
//    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, didLongPressForIndex index: Int, image: UIImage) { }
//    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, didDeleteItemAtIndex index: Int) { }
//    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, didScrollAtIndex index: Int) { }
}





