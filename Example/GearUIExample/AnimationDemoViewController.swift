//
//  AnimationDemoViewController.swift
//  GearUI
//
//  Created by 谌启亮 on 17/10/2017.
//Copyright © 2017 谌启亮. All rights reserved.
//

import UIKit
import GearUI

class AnimationDemoViewController: GUViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @objc func runAnimation() {
        self.view.runAnimation(withNodeId: "disappear_animation")
    }

}
