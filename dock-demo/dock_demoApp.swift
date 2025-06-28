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
        // 先检查并请求辅助功能权限
        checkAccessibilityPermission()
        
        // 延迟显示Dock窗口，给系统时间完成初始化
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            DockWindowManager.shared.showDockWindow()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 清理资源
        DockWindowManager.shared.hideDockWindow()
    }
    
    private func checkAccessibilityPermission() {
        // 先检查是否已经有权限，不弹出提示
        let hasPermission = AXIsProcessTrusted()
        
        if !hasPermission {
            // 只有在没有权限时才提示用户
            showAccessibilityAlert()
        } else {
            print("辅助功能权限已授予")
        }
    }
    
    private func showAccessibilityAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "需要辅助功能权限"
            alert.informativeText = "为了监听全局鼠标事件并实现Dock效果，本应用需要辅助功能权限。\n\n点击\"打开系统偏好设置\"后，请在列表中勾选本应用。"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "打开系统偏好设置")
            alert.addButton(withTitle: "稍后再说")
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                // 打开辅助功能设置页面
                self.openAccessibilityPreferences()
            }
        }
    }
    
    private func openAccessibilityPreferences() {
        // 打开系统偏好设置的辅助功能页面
        let prefPaneURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(prefPaneURL)
        
        // 在打开设置后，再次触发权限请求（这会让应用出现在列表中）
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
    }
}
