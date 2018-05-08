//
//  ViewController.swift
//  LQPlayer
//
//  Created by Lee on 2018/3/8.
//  Copyright © 2018年 ATM. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController {


    override func viewDidLoad() {
        super.viewDidLoad()
      
    }
    
    
    
    @IBAction func buttonClicked(_ sender: UIButton) {
        
        let albumCollectionVC = AlbumCollectionViewController()
        let navVC = UINavigationController.init(rootViewController: albumCollectionVC)
        self.present(navVC, animated: true, completion: nil)
        
        
        
        
        
        
    }
    
 
}













