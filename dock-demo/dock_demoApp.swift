//
//  dock_demoApp.swift
//  dock-demo
//
//  Created by lmx on 2025/6/28.
//

import SwiftUI

@main
struct dock_demoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
    }
}

// 应用程序委托
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 显示Dock窗口
        DockWindowManager.shared.showDockWindow()
        
        // 请求辅助功能权限（用于全局鼠标事件监听）
        requestAccessibilityPermission()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 清理资源
        DockWindowManager.shared.hideDockWindow()
    }
    
    private func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            print("请在系统偏好设置中授予辅助功能权限")
        }
    }
}
