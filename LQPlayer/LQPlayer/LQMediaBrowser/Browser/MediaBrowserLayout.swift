//
//  PhotoBrowserLayout.swift
//  LQPlayer
//
//  Created by Lee on 2018/3/24.
//  Copyright © 2018年 ATM. All rights reserved.
//

import UIKit

public class MediaBrowserLayout: UICollectionViewFlowLayout {
    
    /// 一页宽度，算上空隙
    private var pageWidth: CGFloat {
        return self.itemSize.width + self.minimumLineSpacing
    }
    
    /// 上次页码
    private lazy var lastPage: CGFloat = {
        guard let offsetX = self.collectionView?.contentOffset.x else {
            return 0
        }
        return round(offsetX / self.pageWidth)
    }()
    
    /// 最小页码
    private let minPage: CGFloat = 0
    
    /// 最大页码
    private lazy var maxPage: CGFloat = {
        guard var contentWidth = self.collectionView?.contentSize.width else {
            return 0
        }
        contentWidth += self.minimumLineSpacing
        return contentWidth / self.pageWidth - 1
    }()
    
    override init() {
        super.init()
        scrollDirection = .horizontal
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 调整scroll停下来的位置
    override public func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        // 页码
        var page = round(proposedContentOffset.x / pageWidth)
        // 处理轻微滑动
        if velocity.x > 0.2 {
            page += 1
        } else if velocity.x < -0.2 {
            page -= 1
        }
        
        // 一次滑动不允许超过一页
        if page > lastPage + 1 {
            page = lastPage + 1
        } else if page < lastPage - 1 {
            page = lastPage - 1
        }
        if page > maxPage {
            page = maxPage
        } else if page < minPage {
            page = minPage
        }
        lastPage = page
        return CGPoint(x: page * pageWidth, y: 0)
    }
}
