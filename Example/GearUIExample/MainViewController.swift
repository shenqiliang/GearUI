//
//  MainViewController.swift
//  GearUI
//
//  Created by 谌启亮 on 13/10/2017.
//Copyright © 2017 谌启亮. All rights reserved.
//

import UIKit
import GearUI

extension TimeInterval {
    
    fileprivate static let minute: TimeInterval = 60.0
    fileprivate static let hour: TimeInterval = minute * 60
    fileprivate static let day: TimeInterval = hour * 24
    fileprivate static let month: TimeInterval = day * 30
    fileprivate static let halfYear: TimeInterval = month * 6
    
    fileprivate func timeUnit() -> TimeInterval? {
        let times: [TimeInterval] = [.month, .day, .hour, .minute]
        var time: TimeInterval?
        for idx in 0..<times.count {
            if self >= times[idx] {
                time = times[idx]
                break
            }
        }
        return time
    }
    
    func timeDesc() -> String {
        guard self < TimeInterval.halfYear else {
            return "半年前"
        }
        
        let timeUnits: [TimeInterval: String] = [
            .month: "个月",
            .day: "天",
            .hour: "小时",
            .minute: "分钟"
        ]
        guard let time = timeUnit(), let unit: String = timeUnits[time] else {
            return "刚刚"
        }
        let count: Int = Int(self / time)
        return "\(count)\(unit)前"
    }
    
}



class MainViewController: GUViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @objc func gotoTextDemo() {
        self.navigationController?.pushViewController(TextDemoViewController(), animated: true)
    }

    @objc func gotoLayoutDemo() {
        self.navigationController?.pushViewController(LayoutDemoViewController(), animated: true)
    }

    @objc func gotoTableViewDemo() {
        self.navigationController?.pushViewController(TableViewDemoViewController(), animated: true)
    }
    
    @objc func gotoComplexDemo() {
        self.navigationController?.pushViewController(DatabindingViewController(), animated: true)
    }
    
    @objc func gotoAnimationDemo() {
        self.navigationController?.pushViewController(AnimationDemoViewController(), animated: true)
    }

    @objc func dup() {
        self.navigationController?.pushViewController(MainViewController(), animated: true)
    }
    
    @objc func gotoPerformanceTest() {
        self.navigationController?.pushViewController(PerformanTestViewController(), animated: true)
    }
    
    @objc func gotoControlsDemo() {
        self.navigationController?.pushViewController(ControlsViewController(), animated: true)

//        let nav = UINavigationController(rootViewController: ControlsViewController())
//        nav.modalPresentationStyle = .fullScreen
//        self.present(nav, animated: true, completion: nil)
    }

    @objc func gotoPageControl() {
        self.navigationController?.pushViewController(PageControlViewController(), animated: true)
    }
    
    
    deinit {
        print("mainviewcontroller deinit")
    }


}
