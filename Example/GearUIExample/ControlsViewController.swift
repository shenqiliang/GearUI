//
//  ControlsViewController.swift
//  GearUIExample
//
//  Created by 谌启亮 on 2021/12/24.
//  Copyright © 2021 Tencent. All rights reserved.
//

import UIKit
import GearUI

class ControlsViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    let tabControlViewController = TabControlViewController()
    let buttonViewController = ButtonViewController()
    
    let tabControl = GUTabControl(frame: CGRect(x: 0, y: 0, width: 200, height: 32))

    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        self.dataSource = self
        self.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setViewControllers([tabControlViewController], direction: .forward, animated: false, completion: nil)
        tabControl.items = ["Tabs", "Buttons"]
        tabControl.titleColor = .black
        tabControl.selectedTitleColor = self.view.tintColor
        tabControl.indicatorColor = self.view.tintColor
        tabControl.addTarget(self, action: #selector(tabControlChanged), for: .valueChanged)
        self.navigationItem.titleView = tabControl
    }
    
    @objc func tabControlChanged() {
        if tabControl.selectedIndex == 0 {
            self.setViewControllers([tabControlViewController], direction: .forward, animated: false, completion: nil)
        }
        else {
            self.setViewControllers([buttonViewController], direction: .forward, animated: false, completion: nil)
        }
    }
    
    // UIPageViewControllerDataSource
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if viewController == buttonViewController {
            return tabControlViewController
        }
        else {
            return nil
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if viewController == tabControlViewController {
            return buttonViewController
        }
        else {
            return nil
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if self.viewControllers?.contains(tabControlViewController) == true {
            self.tabControl.selectedIndex = 0
        }
        else {
            self.tabControl.selectedIndex = 1
        }
    }

}
