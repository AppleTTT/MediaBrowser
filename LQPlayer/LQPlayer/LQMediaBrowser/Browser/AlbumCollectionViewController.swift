//
//  AlbumCollectionViewController.swift
//  LQPlayer
//
//  Created by 李树 on 2018/3/21.
//  Copyright © 2018年 laiqu. All rights reserved.
//

import UIKit
import Photos

class AlbumCollectionViewController: UIViewController {

    enum Section: Int {
        case allPhotos = 0
        case smartAlbums
        case userCollections
        
        static let count = 3
    }
    
    enum CellIdentifier: String {
        case allPhotos, collection
    }
    
    // MARK:- Properties
    var allPhotos: PHFetchResult<PHAsset>!
    var smartAlbums: PHFetchResult<PHAssetCollection>!
    var userCollections: PHFetchResult<PHCollection>!
    
    var tableView: UITableView!
    
    var sectionTitles = ["", "smart Albums", "Albums"]
    
    // MARK:- Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: Selector.addAlbumAction)
        self.navigationItem.rightBarButtonItem = addButton
        
        // 获取 PHFetchResult 的过程是同步的
        let allPhotoOption = PHFetchOptions()
        allPhotoOption.sortDescriptors = [NSSortDescriptor(key: "creationDate",  ascending: true)]
        allPhotos = PHAsset.fetchAssets(with: allPhotoOption)
        smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        userCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        
        tableView = UITableView.init(frame: view.bounds, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier.allPhotos.rawValue)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier.collection.rawValue)
        view.addSubview(tableView)
        tableView.reloadData()
        
        title = "Photos"
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    // MARK:- Actions
    @objc func addAlbumAction(_ barButton: UIBarButtonItem) {
        // 新增相册
        let alertController = UIAlertController(title: "New Album", message: nil, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "Album name"
        }
        // 可以使用尾闭包格式
        alertController.addAction(UIAlertAction(title: "Create", style: .default, handler: { (_) in
            let textField = alertController.textFields?.first
            if let text = textField?.text, !text.isEmpty {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: text)
                }, completionHandler: { (success, error) in
                    if !success {  print("creat album error: \(String(describing: error))") }
                })
            }
        }))
        self.present(alertController, animated: true, completion: nil)
    }

}


extension AlbumCollectionViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let assetGirdVC = AssetGridViewController()
        
        switch Section(rawValue: indexPath.section)! {
        case .allPhotos:
            assetGirdVC.fetchResult = allPhotos
        case .smartAlbums:
            let collection = smartAlbums.object(at: indexPath.row)
            assetGirdVC.fetchResult = PHAsset.fetchAssets(in: collection, options: nil)
            assetGirdVC.assetCollection = collection
            
        case .userCollections:
            guard let collection = userCollections.object(at: indexPath.row) as? PHAssetCollection else { fatalError("expected asset collection") }
            assetGirdVC.fetchResult = PHAsset.fetchAssets(in: collection, options: nil)
            assetGirdVC.assetCollection = collection
        }
        self.navigationController?.pushViewController(assetGirdVC, animated: true)
    }
    
}


extension AlbumCollectionViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        switch Section(rawValue: section)! {
            case .allPhotos: return 1
            case .smartAlbums: return smartAlbums.count
            case .userCollections: return userCollections.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch Section(rawValue: indexPath.section)! {
        case .allPhotos:
            let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.allPhotos.rawValue, for: indexPath)
            cell.textLabel?.text = "All photos"
            return cell
            
        case .smartAlbums:
            let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.collection.rawValue, for: indexPath)
            cell.textLabel?.text = smartAlbums.object(at: indexPath.row).localizedTitle
            return cell
        case .userCollections:
            let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.collection.rawValue, for: indexPath)
            cell.textLabel?.text = userCollections.object(at: indexPath.row).localizedTitle
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
}


fileprivate extension Selector {
    
    static let addAlbumAction = #selector(AlbumCollectionViewController.addAlbumAction(_:))
    
    
}


















