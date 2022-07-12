//
//  FileScanner.swift
//  GearUIDebugServer
//
//  Created by 谌启亮 on 06/07/2017.
//  Copyright © 2017 Tencent. All rights reserved.
//

import Foundation

class FileScanner {
    
    let rootPath: String
    
    var result: [String:String] = [:]
    
    init(rootPath: String) {
        self.rootPath = rootPath
    }
    
    func scan() {
    
        let paths = FileManager.default.subpaths(atPath: rootPath)!
        for path in paths {
            let fileName = (path as NSString).lastPathComponent
            if (fileName as NSString).pathExtension == "xml" {
                result[(fileName as NSString).deletingPathExtension] = (rootPath as NSString).appendingPathComponent(path)
            }
        }
    }
    
}
