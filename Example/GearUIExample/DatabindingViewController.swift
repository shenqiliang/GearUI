//
//  DatabindingViewController.swift
//  GearUIExample
//
//  Created by 谌启亮 on 2022/4/6.
//Copyright © 2022 Tencent. All rights reserved.
//

import UIKit
import GearUI

class ImageObj: NSObject {
    @objc dynamic var color = ""
    
    deinit {
        print("ImageObj deinit")
    }
}


class DatabindingViewModel: NSObject {
    @objc dynamic var img: ImageObj = .init()
    
    override func removeObserver(_ observer: NSObject, forKeyPath keyPath: String, context: UnsafeMutableRawPointer?) {
        super.removeObserver(observer, forKeyPath: keyPath, context: context)
    }
}


@objcMembers
class DatabindingViewController: GUViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var databingViewModel = DatabindingViewModel()
        self.view.bind(databingViewModel, keyPath: "img.color", toKeyPath: "second.image")
        databingViewModel.img.color = "green"
        databingViewModel = DatabindingViewModel()
        self.view.bind(databingViewModel, keyPath: "img.color", toKeyPath: "second.image")
        databingViewModel.img.color = "green"
        databingViewModel = DatabindingViewModel()
        self.view.bind(databingViewModel, keyPath: "img.color", toKeyPath: "third.image")
        databingViewModel.img.color = "green"
    }

}
