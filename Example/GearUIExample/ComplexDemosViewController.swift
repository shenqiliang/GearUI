//
//  ComplexDemosViewController.swift
//  GearUI
//
//  Created by 谌启亮 on 13/10/2017.
//Copyright © 2017 谌启亮. All rights reserved.
//

import UIKit
import GearUI

class ComplexDemosViewController: GUViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @objc func gotoDemo1(_ sender: Any) {
        self.navigationController?.pushViewController(ComplexDemo1ViewController(), animated: true)
    }

}
