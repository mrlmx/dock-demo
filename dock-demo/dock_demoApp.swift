//
//  dock_demoApp.swift
//  dock-demo
//
//  Created by lmx on 2025/6/28.
//

import SwiftUI
import Combine

@main
struct dock_demoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate.dockViewModel)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

// 应用程序委托
class AppDelegate: NSObject, NSApplicationDelegate {
    private var permissionCheckTimer: Timer?
    private var permissionAlert: NSAlert?
    private var permissionWindow: NSWindow?
    let dockViewModel = DockViewModel() // 创建共享的DockViewModel实例
    
    // 状态栏相关属性
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var positionObserver: AnyCancellable?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置状态栏图标
        setupStatusBar()
        
        // 监听位置变化
        positionObserver = dockViewModel.$position.sink { [weak self] newPosition in
            // 发送位置变更通知给ContentView
            NotificationCenter.default.post(
                name: Notification.Name("DockPositionChanged"),
                object: nil,
                userInfo: ["position": newPosition]
            )
            // 更新菜单状态
            self?.updateMenuPositionState()
        }
        
        // 先检查并请求辅助功能权限
        checkAccessibilityPermission()
        
        // 延迟显示Dock窗口，给系统时间完成初始化
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if let viewModel = self?.dockViewModel {
                DockWindowManager.shared.showDockWindow(viewModel: viewModel)
            }
        }
        
        // 关闭默认的主窗口，我们使用状态栏控制显示
        for window in NSApplication.shared.windows {
            if window.contentViewController is NSHostingController<ContentView> {
                window.close()
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 清理资源
        DockWindowManager.shared.hideDockWindow()
        permissionCheckTimer?.invalidate()
    }
    
    // MARK: - 状态栏功能
    
    private func setupStatusBar() {
        // 创建状态栏项
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // 设置图标
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "dock.rectangle", accessibilityDescription: "Dock Demo")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // 创建菜单
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        // 打开设置
        let settingsItem = NSMenuItem(title: "打开设置", action: #selector(openSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        // 分隔线
        menu.addItem(NSMenuItem.separator())
        
        // Dock位置子菜单
        let positionItem = NSMenuItem(title: "Dock 位置", action: nil, keyEquivalent: "")
        let positionSubmenu = NSMenu()
        
        for position in DockPosition.allCases {
            let item = NSMenuItem(title: position.rawValue, action: #selector(changeDockPosition(_:)), keyEquivalent: "")
            item.target = self
            item.tag = position.hashValue
            if position == dockViewModel.position {
                item.state = .on
            }
            positionSubmenu.addItem(item)
        }
        
        positionItem.submenu = positionSubmenu
        menu.addItem(positionItem)
        
        // 分隔线
        menu.addItem(NSMenuItem.separator())
        
        // 退出
        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // 右键点击，显示菜单
            // 先更新菜单状态
            updateMenuPositionState()
            statusItem?.menu?.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 5), in: sender)
        } else {
            // 左键点击，打开设置
            openSettings()
        }
    }
    
    @objc private func openSettings() {
        // 如果设置窗口已存在，将其前置
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }
        
        // 创建新的设置窗口
        let contentView = ContentView()
            .environmentObject(dockViewModel)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Dock 控制中心"
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        
        // 保持窗口引用
        settingsWindow = window
        
        // 激活应用
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    @objc private func changeDockPosition(_ sender: NSMenuItem) {
        // 更新所有菜单项的选中状态
        if let menu = sender.menu {
            for item in menu.items {
                item.state = .off
            }
        }
        sender.state = .on
        
        // 根据tag找到对应的位置
        if let position = DockPosition.allCases.first(where: { $0.hashValue == sender.tag }) {
            dockViewModel.position = position
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // 更新菜单中的位置选择状态
    private func updateMenuPositionState() {
        guard let menu = statusItem?.menu,
              let positionItem = menu.items.first(where: { $0.title == "Dock 位置" }),
              let submenu = positionItem.submenu else { return }
        
        for item in submenu.items {
            if let position = DockPosition.allCases.first(where: { $0.hashValue == item.tag }) {
                item.state = position == dockViewModel.position ? .on : .off
            }
        }
    }
    
    private func checkAccessibilityPermission() {
        // 先检查是否已经有权限，不弹出提示
        let hasPermission = AXIsProcessTrusted()
        
        print("=== 辅助功能权限检查 ===")
        print("当前权限状态: \(hasPermission ? "已授权" : "未授权")")
        print("Bundle ID: \(Bundle.main.bundleIdentifier ?? "未知")")
        print("应用路径: \(Bundle.main.bundlePath)")
        
        if !hasPermission {
            // 首次运行时，先触发一次静默的权限请求，让应用出现在列表中
            // 但不显示系统提示
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
            let result = AXIsProcessTrustedWithOptions(options)
            print("静默权限请求结果: \(result)")
            
            // 然后显示我们自定义的提示
            showAccessibilityAlert()
        } else {
            print("辅助功能权限已授予")
            // 权限已授予，关闭权限窗口（如果存在）
            permissionWindow?.close()
            permissionWindow = nil
        }
    }
    
    private func showAccessibilityAlert() {
        DispatchQueue.main.async {
            // 创建一个窗口来显示提示，而不是使用模态对话框
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 250),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "需要辅助功能权限"
            window.center()
            
            // 创建提示视图
            let contentView = NSView(frame: window.contentRect(forFrameRect: window.frame))
            
            // 添加文本说明
            let textField = NSTextField(frame: NSRect(x: 20, y: 100, width: 460, height: 100))
            textField.stringValue = "为了监听全局鼠标事件并实现Dock效果，本应用需要辅助功能权限。\n\n如果您已经在系统设置中勾选了权限但仍然看到此提示，请尝试：\n1. 取消勾选后重新勾选\n2. 完全退出应用（Command+Q）后重新启动\n3. 重启电脑\n\n授权完成后，此窗口将自动关闭。"
            textField.isEditable = false
            textField.isBordered = false
            textField.backgroundColor = .clear
            textField.alignment = .left
            contentView.addSubview(textField)
            
            // 添加按钮容器
            let buttonContainer = NSView(frame: NSRect(x: 20, y: 20, width: 460, height: 40))
            
            // 打开系统设置按钮
            let openSettingsButton = NSButton(frame: NSRect(x: 0, y: 0, width: 180, height: 30))
            openSettingsButton.title = "打开系统偏好设置"
            openSettingsButton.bezelStyle = .rounded
            openSettingsButton.target = self
            openSettingsButton.action = #selector(self.openAccessibilityPreferencesWithoutPrompt)
            buttonContainer.addSubview(openSettingsButton)
            
            // 重新检查权限按钮
            let recheckButton = NSButton(frame: NSRect(x: 190, y: 0, width: 120, height: 30))
            recheckButton.title = "重新检查权限"
            recheckButton.bezelStyle = .rounded
            recheckButton.target = self
            recheckButton.action = #selector(self.manuallyCheckPermission)
            buttonContainer.addSubview(recheckButton)
            
            contentView.addSubview(buttonContainer)
            
            window.contentView = contentView
            window.makeKeyAndOrderFront(nil)
            
            // 保存窗口引用
            self.permissionWindow = window
            
            // 启动定时器，每秒检查一次权限状态
            self.startPermissionCheckTimer(window: window)
        }
    }
    
    @objc private func openAccessibilityPreferencesWithoutPrompt() {
        // 只打开系统偏好设置，不再触发额外的权限请求
        let prefPaneURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(prefPaneURL)
    }
    
    @objc private func manuallyCheckPermission() {
        let hasPermission = AXIsProcessTrusted()
        print("手动检查权限结果: \(hasPermission)")
        
        if hasPermission {
            permissionWindow?.close()
            permissionCheckTimer?.invalidate()
            permissionCheckTimer = nil
            
            // 显示成功提示
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "权限已授予"
                alert.informativeText = "辅助功能权限已成功授予！"
                alert.alertStyle = .informational
                alert.addButton(withTitle: "好的")
                alert.runModal()
            }
        } else {
            // 显示错误提示
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "权限检查失败"
                alert.informativeText = "权限仍未授予。请确保在系统设置中勾选了本应用，然后尝试重启应用。"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "确定")
                alert.runModal()
            }
        }
    }
    
    private func startPermissionCheckTimer(window: NSWindow) {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self, weak window] _ in
            if AXIsProcessTrusted() {
                // 权限已授予，关闭窗口并停止定时器
                DispatchQueue.main.async {
                    window?.close()
                    self?.permissionCheckTimer?.invalidate()
                    self?.permissionCheckTimer = nil
                    print("辅助功能权限已授予，窗口已自动关闭")
                }
            }
        }
    }
}
