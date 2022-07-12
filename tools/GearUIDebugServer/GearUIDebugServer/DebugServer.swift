//
//  DebugServer.swift
//  GearUIDebugServer
//
//  Created by 谌启亮 on 16/12/2017.
//  Copyright © 2017 Tencent. All rights reserved.
//

import Cocoa

class DebugServer: NSObject, NBTCPClientDelegate {
    
    private var fileWatcher: FileWatcher?
    
    private var sessions: [String] = []
    private var simulatorSession: [String] = []

    static let server = DebugServer()
    
    var client: NBTCPClient?
    var simulatorClient: NBTCPClient?

    
    private override init() {
        super.init()
    }
    
    func shell(launchPath: String, arguments: [String]) -> String
    {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        task.standardError = FileHandle.nullDevice
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8)!
        if output.count > 0 {
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

    
    func start() {
        
        DispatchQueue.global().async {
            while (true) {
                let lsof = self.bash(command: "lsof", arguments: ["-n", "-i", ":6783"])
                for lsofLine in lsof.components(separatedBy: "\n") {
                    if lsofLine.range(of: "LISTEN") != nil {
                        var cols = lsofLine.components(separatedBy: CharacterSet.whitespaces)
                        while cols.index(of: "") != nil {
                            cols.remove(at: cols.index(of: "")!)
                        }
                        if cols.count > 2 {
                            let pid = cols[1]
                            let _ = self.bash(command: "kill", arguments: ["-9", pid])
                        }
                    }
                }
                let _ = self.bash(command: "python", arguments: [Bundle.main.path(forResource: "tcprelay", ofType: "py")!, "6783:6783"])
                sleep(3);
            }
        }

        let homePath = NSHomeDirectory()
        fileWatcher = FileWatcher([homePath])
        fileWatcher?.callback = { event in
            let path = event.path
            let fileName = path.components(separatedBy: "/").last ?? ""
            if fileName.hasSuffix(".xml") {
                print(fileName)
                let key = fileName.prefix(fileName.count-4)
                if self.sessions.contains(String(key)) {
                    guard let xml = try? String(contentsOfFile: path, encoding: .utf8) else {
                        return
                    }
                    let result = "\(key):\(xml)"
                    self.client?.write(result.data(using: .utf8))
                    print("write:\n\(result)")
                }
                if self.simulatorSession.contains(String(key)) {
                    guard let xml = try? String(contentsOfFile: path, encoding: .utf8) else {
                        return
                    }
                    let result = "\(key):\(xml)"
                    self.simulatorClient?.write(result.data(using: .utf8))
                    print("write:\n\(result)")
                }
            }
        }
        fileWatcher?.start()
        
        client = NBTCPClient()
        client?.delegate = self
        
        simulatorClient = NBTCPClient(port: 6785)
        simulatorClient?.delegate = self

    }
    
    
    func client(_ client: NBTCPClient!, didReceivedData data: Data!) {
        let receivedSessionValue = String(bytes: data, encoding: .utf8)
        if client == simulatorClient {
            if receivedSessionValue != "ACK" {
                simulatorSession = receivedSessionValue?.components(separatedBy: "|") ?? [String]()
                print("did receive simulatorSession \(simulatorSession)")
            }
        }
        else {
            if receivedSessionValue != "ACK" {
                sessions = receivedSessionValue?.components(separatedBy: "|") ?? [String]()
                print("did receive session \(sessions)")
            }
        }
    }

}
