//
//  AppDelegate.swift
//  AutomaticPackaging
//
//  Created by 马洪亮 on 2020/4/16.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
    /// 关闭窗口时终止应用
    /// - Parameter sender:
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

}

