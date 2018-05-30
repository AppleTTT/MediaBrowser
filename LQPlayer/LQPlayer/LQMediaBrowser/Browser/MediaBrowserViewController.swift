//
//  MediaBrowserViewController.swift
//  LQPlayer
//
//  Created by Lee on 2018/3/26.
//  Copyright © 2018年 ATM. All rights reserved.
//

import UIKit
import Photos
import SnapKit

let photoCellReuseId = "photoCell"
let videoCellResueId = "videoCell"
let headerResueId    = "headerResueId"

class MediaBrowserViewController: UIViewController {

    //MARK:- Properties
    /// 左右两张图之间的距离
    var mediaSpace: CGFloat = 30.0
    /// 图片缩放模式
    var imageScaleMode = UIViewContentMode.scaleAspectFill
    /// 捏合手势放大图片时的最大允许比例
    var imageMaximumZoomScale: CGFloat = 2.0
    /// 双击放大图片时的目标比例
    var imageZoomScaleForDoubleTap: CGFloat = 2.0
    /// 当前显示的图片的序号
    var currentIndexPath = IndexPath(item: 0, section: 0) {
        didSet { animatorCoordinator?.updateCurrentHiddenView(relatedView) }
    }
    /// 当前正在显示视图的前一个页面关联视图
    var relatedView: UIView? {
        return mediaBrowserDelegate?.mediaBrowser(self, thumbnailViewForIndexPath: currentIndexPath)
    }
    /// 转场协调器
    private weak var animatorCoordinator: ScaleAnimatorCoordinator?
    /// presentation转场动画
    private weak var presentationAnimator: ScaleAnimator?
    /// 保存原windowLevel
    private var originWindowLevel: UIWindowLevel!
    /// 容器layout
    /// 容器layout
    private lazy var flowLayout: MediaBrowserLayout = {
        return MediaBrowserLayout()
    }()
    weak var mediaBrowserDelegate: MediaBrowserViewControllerDelegate?
    /// 本VC的presentingViewController
    private let presentingVC: UIViewController
    
    var dataSource = MediaBrowserCollectionViewDataSource.init(data: [:], keysSequence: [], owner: nil)
    
    /// 数据源,和取数据的数组一定不为空，为空则说明有问题
    var dataDictionary: [String: Array<AlbumItem>]!
    var keysSequence:  [String]!
    /// 上一个 cell，用于将滑出屏幕的视频 reset
    var lastCell: UICollectionViewCell?
    
    /// 预览界面是不会显示 statusBar 的，但是在拨打电话或者是开启热点的时候 statusBar 的高度会由 20 变为 40，因此这里要做下 UI 适配的处理
    var statusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.height - 20
    
    lazy var collectionView: BrowserCollectionView = { [unowned self] in
        let collectionView = BrowserCollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = dataSource
        collectionView.delegate = self
        collectionView.register(PhotoBrowserCell.self, forCellWithReuseIdentifier: photoCellReuseId)
        collectionView.register(VideoBrowserCell.self, forCellWithReuseIdentifier: videoCellResueId)
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerResueId)
        return collectionView
        }()

    
    //MARK:- Life cycle
    /// 初始化，传入用于present出本VC的VC，以及实现了PhotoBrowserDelegate协议的对象
    public init(showByViewController presentingVC: UIViewController, delegate: MediaBrowserViewControllerDelegate, data: [String: Array<AlbumItem>]!, keysSequence: [String]!) {
        self.presentingVC = presentingVC
        self.mediaBrowserDelegate = delegate
        self.dataDictionary = data
        self.keysSequence = keysSequence
        super.init(nibName: nil, bundle: nil)
        dataSource = MediaBrowserCollectionViewDataSource.init(data: data, keysSequence: keysSequence, owner: self)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        NotificationCenter.default.addObserver(self, selector: Selector.statusBarHeightChangedAction, name: .UIApplicationWillChangeStatusBarFrame, object: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 遮盖状态栏
        coverStatusBar(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // 显示状态栏
        coverStatusBar(false)
    }
    
    //MARK:- Layout
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        layoutViews()
    }
    //MARK:- APIs 展示，传入图片序号，从0开始
    public func show(indexPath: IndexPath) {
        currentIndexPath = indexPath
        self.transitioningDelegate = self
        self.modalPresentationStyle = .custom
        self.modalPresentationCapturesStatusBarAppearance = true
        presentingVC.present(self, animated: true, completion: nil)
    }
    
    // MARK:- Actions
    @objc func statusBarHeightChangedAction(notification: Notification) {
        statusBarHeight = UIApplication.shared.statusBarFrame.height - 20
        view.layoutSubviews()
    }
    
    /// 添加视图
    private func setupViews() {
        view.addSubview(collectionView)
    }
    /// 视图布局
    private func layoutViews() {
        // flowLayout
        flowLayout.minimumLineSpacing = mediaSpace
        flowLayout.itemSize = view.bounds.size
        // 之前是 view.bounds，后面由于开启 Hotspot 之后，这个值会变，因此改为如下
        collectionView.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: view.bounds.size.height - statusBarHeight)
    }
    
    private func coverStatusBar(_ cover: Bool) {
        let win = view.window ?? UIApplication.shared.keyWindow
        guard let window = win else { return }

        if originWindowLevel == nil { originWindowLevel = window.windowLevel }
        if cover {
            window.windowLevel = UIWindowLevelStatusBar + 1
        } else {
            window.windowLevel = originWindowLevel
        }
    }
}

extension MediaBrowserViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // 已经消失的 cell
        if lastCell is VideoBrowserCell {
            let videoBrowserCell = lastCell as! VideoBrowserCell
            videoBrowserCell.cellDidDisappear()
        }
        
        lastCell = cell
    }
    
    //MARK:- UIScrollViewDelegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if collectionView.visibleCells.count == 1 {
            let cell = collectionView.visibleCells.first
            let scrollIndexPath = collectionView.indexPath(for: cell!)!
            mediaBrowserDelegate?.mediaBrowser(self, didScrollAt: scrollIndexPath)
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if collectionView.visibleCells.count == 1 {
            let cell = collectionView.visibleCells.first
            currentIndexPath = collectionView.indexPath(for: cell!)!
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard lastCell != nil else { return }
        if lastCell is VideoBrowserCell, !collectionView.visibleCells.contains(lastCell!) {
            let videoBrowserCell = lastCell as! VideoBrowserCell
            videoBrowserCell.cellDidDisappear()
        }
    }
}

extension MediaBrowserViewController: PhotoBrowserCellDelegate {
    func shareMedia(_ cell: PhotoBrowserCell) {
        
    }
    
    func deleteMedia(_ cell: PhotoBrowserCell, _ deleteButton: UIButton) {
        
    }
    
    func photoBrowserDismiss(_ cell: PhotoBrowserCell) {
        coverStatusBar(false)
        dismiss(animated: true, completion: nil)
    }
    
    func photoBrowserCell(_ cell: PhotoBrowserCell, didPanScale scale: CGFloat) {
        // 实测用scale的平方，效果比线性好些
        let alpha = scale * scale
        animatorCoordinator?.maskView.alpha = alpha
        // 半透明时重现状态栏，否则遮盖状态栏
        coverStatusBar(alpha >= 1.0)
    }
    
}


// MARK: - 转场动画
extension MediaBrowserViewController: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        // 立即布局
        setupViews()
        layoutViews()
        // 立即加载collectionView
        let indexPath = currentIndexPath
        collectionView.reloadData()
        collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
        collectionView.layoutIfNeeded()
        let cell = collectionView.cellForItem(at: indexPath) as? PhotoBrowserCell
        let imageView = UIImageView(image: cell?.imageView.image)
        imageView.contentMode = imageScaleMode
        imageView.clipsToBounds = true
        // 创建animator
        let animator = ScaleAnimator(startView: relatedView, endView: cell?.imageView, scaleView: imageView)
        presentationAnimator = animator
        return animator
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let cell = collectionView.visibleCells.first as? PhotoBrowserCell else {
            return nil
        }
        let imageView = UIImageView(image: cell.imageView.image)
        imageView.contentMode = imageScaleMode
        imageView.clipsToBounds = true
        return ScaleAnimator(startView: cell.imageView, endView: relatedView, scaleView: imageView)
    }
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let coordinator = ScaleAnimatorCoordinator(presentedViewController: presented, presenting: presenting)
        coordinator.currentHiddenView = relatedView
        animatorCoordinator = coordinator
        return coordinator
    }
}

extension MediaBrowserViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return CGSize.zero
        }
        return CGSize.init(width: 30, height: view.bounds.size.height)
    }
}

fileprivate extension Selector {
    static let statusBarHeightChangedAction = #selector(MediaBrowserViewController.statusBarHeightChangedAction(notification:))
}




