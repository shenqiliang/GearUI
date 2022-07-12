//
//  TableViewDemoViewController.swift
//  GearUI
//
//  Created by 谌启亮 on 13/10/2017.
//Copyright © 2017 谌启亮. All rights reserved.
//

import UIKit
import GearUI

class TableViewDemoViewController: GUViewController {
    
    @objc var tableView: GUTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "test", style: .plain, target: self, action: #selector(scroll))
    }
    
    @objc func scroll() {
        tableView.phyicalAnimatedScroll(toContentOffset: CGPoint(x: 0, y: 300), velocity: 1500)
    }

}
