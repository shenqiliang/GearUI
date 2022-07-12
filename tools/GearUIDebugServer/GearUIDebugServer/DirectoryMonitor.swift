/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 `DirectoryMonitor` is used to monitor the contents of the provided directory by using a GCD dispatch source.
 */

import Foundation

/// A protocol that allows delegates of `DirectoryMonitor` to respond to changes in a directory.
protocol DirectoryMonitorDelegate: class {
    func directoryMonitorDidObserveChange(_ directoryMonitor: DirectoryMonitor)
}

class DirectoryMonitor {
    // MARK: Properties
    
    /// The `DirectoryMonitor`'s delegate who is responsible for responding to `DirectoryMonitor` updates.
    weak var delegate: DirectoryMonitorDelegate?
    
    /// A file descriptor for the monitored directory.
    var monitoredDirectoryFileDescriptor: CInt = -1
    
    /// A dispatch source to monitor a file descriptor created from the directory.
    var directoryMonitorSource: DispatchSourceFileSystemObject?
    
    /// URL for the directory being monitored.
    var url: URL
    var name: String?
    
    // MARK: Initializers
    init(URL: URL) {
        self.url = URL
    }
    
    // MARK: Monitoring
    
    func startMonitoring() {
        // Listen for changes to the directory (if we are not already).
        if directoryMonitorSource == nil && monitoredDirectoryFileDescriptor == -1 {
            // Open the directory referenced by URL for monitoring only.
            monitoredDirectoryFileDescriptor = open((url.path as NSString).deletingLastPathComponent, O_EVTONLY)
            
            // Define a dispatch source monitoring the directory for additions, deletions, and renamings.
            directoryMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: monitoredDirectoryFileDescriptor, eventMask: [.all], queue: nil)
            
            // Define the block to call when a file change is detected.
            directoryMonitorSource?.setEventHandler(handler: {
                // Call out to the `DirectoryMonitorDelegate` so that it can react appropriately to the change.
                self.checkFile()
            })
            
            // Define a cancel handler to ensure the directory is closed when the source is cancelled.
            directoryMonitorSource?.setCancelHandler(handler: {
                close(self.monitoredDirectoryFileDescriptor)
                
                self.monitoredDirectoryFileDescriptor = -1
                
                self.directoryMonitorSource = nil
            })
            
            // Start monitoring the directory via the source.
            directoryMonitorSource?.resume()
        }
    }
    
    func checkFile() {
        if let attributes = try? FileManager.default.attributesOfItem(atPath: self.url.path) {
            if let date = attributes[.modificationDate] as? Date {
                if abs(date.timeIntervalSince(Date())) < 1 {
                    self.delegate?.directoryMonitorDidObserveChange(self)
                }
            }
        }
    }
    
    func stopMonitoring() {
        // Stop listening for changes to the directory, if the source has been created.
        if directoryMonitorSource != nil {
            // Stop monitoring the directory via the source.
            directoryMonitorSource?.cancel()
        }
    }
}
