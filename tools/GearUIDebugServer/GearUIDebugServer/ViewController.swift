//
//  ViewController.swift
//  GearUIDebugServer
//
//  Created by 谌启亮 on 07/07/2017.
//  Copyright © 2017 Tencent. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet var tableView: NSTableView?

    
    var sessions: [String:DirectoryMonitor] = [:]
    
    var keyPaths: [String:String] = [:]
    
    var connectedDeviceInfo: String?
    
    var folder: String?
    
    var deviceManager: GUDeviceManager = GUDeviceManager()
    
    func shell(launchPath: String, arguments: [String]) -> String
    {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8)!
        if output.characters.count > 0 {
            //remove newline character.
            let lastIndex = output.index(before: output.endIndex)
            return String(output[output.startIndex ..< lastIndex])
        }
        return output
    }
    
    func bash(command: String, arguments: [String]) -> String {
        let whichPathForCommand = shell(launchPath: "/bin/bash", arguments: [ "-l", "-c", "which \(command)" ])
        return shell(launchPath: whichPathForCommand, arguments: arguments)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        DebugServer.server.start()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NBTCPClientDidChangeConnectionStatus, object: nil, queue: OperationQueue.main) { (_) in
            self.tableView?.reloadData()
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 2
    }
    
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if row == 0 {
            if tableColumn?.identifier.rawValue == "first" {
                return NSAttributedString(string: "真机")
            }
            else {
                if DebugServer.server.client?.isConnected == true {
                    return NSAttributedString(string: "已连接", attributes: [.foregroundColor : NSColor.green])
                }
                else {
                    return NSAttributedString(string: "未连接", attributes: [.foregroundColor : NSColor.red])
                }
            }
        }
        else {
            if tableColumn?.identifier.rawValue == "first" {
                return NSAttributedString(string: "模拟器")
            }
            else {
                if DebugServer.server.simulatorClient?.isConnected == true {
                    return NSAttributedString(string: "已连接", attributes: [.foregroundColor : NSColor.green])
                }
                else {
                    return NSAttributedString(string: "未连接", attributes: [.foregroundColor : NSColor.red])
                }
            }
        }
    }
    
    
    

}

