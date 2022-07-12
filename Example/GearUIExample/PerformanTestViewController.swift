//
//  PerformanTestViewController.swift
//  GearUI
//
//  Created by 谌启亮 on 02/04/2018.
//Copyright © 2018 谌启亮. All rights reserved.
//

import UIKit
import GearUI

class PerformanTestViewController: GUViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var timeXMLLoadTotal = 0.0;
        var timeBinLoadTotal = 0.0;
        var fileSizeXMLTotal = 0;
        var fileSizeBinTotal = 0;
        
        
        let xmlFile = "NewsDialogViewCell.xml"
        let gbiFile = xmlFile.replacingOccurrences(of: ".xml", with: ".gbi")
        let filePath = Bundle.main.bundlePath + "/PerformanceTest/" + xmlFile
        let filePathGbi = Bundle.main.bundlePath + "/PerformanceTest/" + gbiFile
        let xmlData = try! Data(contentsOf: URL(fileURLWithPath: filePath))
        var time = CFAbsoluteTimeGetCurrent()
        let xmlString = String(data: xmlData, encoding: .utf8)
        let node = GUNode(xmlString: xmlString)!
        let timeXMLLoad = CFAbsoluteTimeGetCurrent() - time
        let fileSizeXML = try! FileManager.default.attributesOfItem(atPath: filePath)[.size]! as! Int
        let fileSizeBin = try! FileManager.default.attributesOfItem(atPath: filePathGbi)[.size]! as! Int
//        let binData = try? Data(contentsOf: URL(fileURLWithPath: filePathGbi))
        let binData = GUNodeBinCoder.encode(with: node)
        time = CFAbsoluteTimeGetCurrent()
        let nodeBin = GUNode(binData: binData)!
        let timeBinLoad = CFAbsoluteTimeGetCurrent() - time
        print("xml load: \(timeXMLLoad) size:\(fileSizeXML)")
        print("bin load: \(timeBinLoad) size:\(fileSizeBin)")
        if (!node.isEqual(nodeBin)) {
            printDifferent(a: node, b: nodeBin)
        }
        timeBinLoadTotal += timeBinLoad
        timeXMLLoadTotal += timeXMLLoad
        fileSizeBinTotal += fileSizeBin
        fileSizeXMLTotal += fileSizeXML


        if let xmlFiles = FileManager.default.subpaths(atPath: Bundle.main.bundlePath.appending("/PerformanceTest"))?.filter({$0.hasSuffix(".xml")}) {
            for xmlFile in xmlFiles {
                let gbiFile = xmlFile.replacingOccurrences(of: ".xml", with: ".gbi")
                let filePath = Bundle.main.bundlePath + "/PerformanceTest/" + xmlFile
                let filePathGbi = Bundle.main.bundlePath + "/PerformanceTest/" + gbiFile
                let xmlData = try! Data(contentsOf: URL(fileURLWithPath: filePath))
                var time = CFAbsoluteTimeGetCurrent()
                let xmlString = String(data: xmlData, encoding: .utf8)
                let node = GUNode(xmlString: xmlString)!
                let timeXMLLoad = CFAbsoluteTimeGetCurrent() - time
                let fileSizeXML = try! FileManager.default.attributesOfItem(atPath: filePath)[.size]! as! Int
                let fileSizeBin = try! FileManager.default.attributesOfItem(atPath: filePathGbi)[.size]! as! Int
                //        let binData = try? Data(contentsOf: URL(fileURLWithPath: filePathGbi))
                let binData = GUNodeBinCoder.encode(with: node)
                time = CFAbsoluteTimeGetCurrent()
                let nodeBin = GUNode(binData: binData)!
                let timeBinLoad = CFAbsoluteTimeGetCurrent() - time
                print("xml load: \(timeXMLLoad) size:\(fileSizeXML)")
                print("bin load: \(timeBinLoad) size:\(fileSizeBin)")
                if (!node.isEqual(nodeBin)) {
                    printDifferent(a: node, b: nodeBin)
                }
                timeBinLoadTotal += timeBinLoad
                timeXMLLoadTotal += timeXMLLoad
                fileSizeBinTotal += fileSizeBin
                fileSizeXMLTotal += fileSizeXML
            }
        }
        
        print("total xml load: \(timeXMLLoadTotal) size:\(fileSizeXMLTotal)")
        print("total bin load: \(timeBinLoadTotal) size:\(fileSizeBinTotal)")

    }
    
    func printDifferent(a: GUNode, b: GUNode) {
        if (!a.isEqual(b)) {
            if a.name != b.name {
                print("not equal name")
            }
            if a.nodeId != b.nodeId {
                print("not equal id")
            }
            if a.content != b.content {
                print("not equal content")
            }
            if a.attributes as? [String: String] ?? [:] != b.attributes as? [String: String]  ?? [:] {
                print("not equal attributes")
            }
            if a.subNodes ?? [] != b.subNodes ?? [] {
                if a.subNodes.count == b.subNodes.count {
                    for (a1, b1) in zip(a.subNodes, b.subNodes) {
                        self.printDifferent(a: a1, b: b1)
                    }
                }
                else {
                    print("not equal subNodes count")
                }
            }
        }
    }
}

