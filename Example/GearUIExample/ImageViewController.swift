//
//  ImageViewController.swift
//  GearUIExample
//
//  Created by 谌启亮 on 2021/8/19.
//Copyright © 2021 Tencent. All rights reserved.
//

import UIKit
import GearUI

@objcMembers
class ImageViewController: GUViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @objc func gifImageAction() {
        (self.view.view(nodeId: "gifImageView") as! GUImageView).image = nil
        self.setKeyPathAttributes(["gifImageView.content": "https://upload.wikimedia.org/wikipedia/commons/2/2c/Rotating_earth_%28large%29.gif"])
    }
    
    deinit {
        print("imageview deinit")
    }

}
