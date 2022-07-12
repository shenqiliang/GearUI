//
//  ControlsViewController.swift
//  GearUIExample
//
//  Created by 谌启亮 on 2021/12/23.
//Copyright © 2021 Tencent. All rights reserved.
//

import UIKit
import GearUI

@objcMembers
class TabControlViewController: GUViewController {
    
    @objc var tabControl: GUTabControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabControl.setAttribute("round(corner:2,fillColor:#5b32f0)", forKeyPath: "indicatorImage")
        
    }
    
    @objc func change() {
        tabControl.setAttribute("round(corner:2,fillColor:red)", forKeyPath: "indicatorImage")

    }

}
