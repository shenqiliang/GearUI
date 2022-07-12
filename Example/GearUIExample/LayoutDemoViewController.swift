//
//  LayoutDemoViewController.swift
//  GearUI
//
//  Created by 谌启亮 on 13/10/2017.
//Copyright © 2017 谌启亮. All rights reserved.
//

import UIKit
import GearUI

@objcMembers
class LayoutDemoViewController: GUViewController {
    
    @objc var coverView: GULayoutView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @objc func closeCover() {
        coverView.disableLayout = true
    }

}
