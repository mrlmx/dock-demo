//
//  DockWindow.swift
//  dock-demo
//
//  自定义的Dock窗口
//

import Cocoa
import SwiftUI

/// 自定义的Dock窗口类
class DockWindow: NSWindow {
    init() {
        // 获取主屏幕
        guard let screen = NSScreen.main else {
            fatalError("无法获取主屏幕")
        }
        
        // 创建一个覆盖整个屏幕的窗口
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // 窗口配置
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .floating // 浮动在其他窗口上方
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        self.isMovableByWindowBackground = false
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        
        // 设置内容视图
        let dockView = DockView()
        let hostingView = NSHostingView(rootView: dockView)
        hostingView.frame = screen.frame
        self.contentView = hostingView
        
        // 忽略鼠标事件（除了Dock区域）
        self.ignoresMouseEvents = false
    }
}

/// Dock窗口管理器
class DockWindowManager: NSObject {
    static let shared = DockWindowManager()
    
    private var dockWindow: DockWindow?
    
    private override init() {
        super.init()
    }
    
    /// 显示Dock窗口
    func showDockWindow() {
        if dockWindow == nil {
            dockWindow = DockWindow()
        }
        
        dockWindow?.makeKeyAndOrderFront(nil)
        
        // 确保窗口不会获得焦点
        NSApp.activate(ignoringOtherApps: false)
    }
    
    /// 隐藏Dock窗口
    func hideDockWindow() {
        dockWindow?.close()
        dockWindow = nil
    }
    
    /// 更新Dock位置
    func updateDockPosition(_ position: DockPosition) {
        // 这里可以添加更新Dock位置的逻辑
        // 通过EnvironmentObject或其他方式传递给DockView
    }
} 