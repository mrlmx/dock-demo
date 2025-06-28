//
//  DockWindow.swift
//  dock-demo
//
//  自定义的Dock窗口
//

import Cocoa
import SwiftUI
import Combine

/// 自定义的Dock窗口类
class DockWindow: NSWindow {
    private let dockViewModel: DockViewModel
    
    init(viewModel: DockViewModel) {
        self.dockViewModel = viewModel
        
        // 获取主屏幕
        guard let screen = NSScreen.main else {
            fatalError("无法获取主屏幕")
        }
        
        // 计算Dock的初始大小和位置
        let dockSize = CGSize(width: 80, height: 400)
        let initialPosition = DockPosition.right
        var anchorPoint = initialPosition.anchorPoint(
            screenSize: screen.frame.size,
            dockSize: dockSize,
            edgeOffset: dockViewModel.edgeOffset
        )
        
        // 对于左右位置，使用visibleFrame来实现更准确的垂直居中
        if initialPosition == .left || initialPosition == .right {
            let visibleCenterY = screen.visibleFrame.origin.y + screen.visibleFrame.height / 2
            anchorPoint.y = visibleCenterY
        }
        
        // 创建Dock大小的窗口，而不是覆盖整个屏幕
        let dockFrame = CGRect(
            x: anchorPoint.x - dockSize.width / 2,
            y: anchorPoint.y - dockSize.height / 2,
            width: dockSize.width,
            height: dockSize.height
        )
        
        super.init(
            contentRect: dockFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // 窗口配置
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .normal // 改为普通层级，避免覆盖系统窗口
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.isMovableByWindowBackground = false
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        
        // 设置内容视图 - 使用包装视图来正确处理大小
        let dockView = DockView()
            .environmentObject(dockViewModel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        let hostingView = NSHostingView(rootView: dockView)
        self.contentView = hostingView
        
        // 窗口应该接收鼠标事件
        self.ignoresMouseEvents = false
        
        // 监听ViewModel的变化来更新窗口位置和大小
        setupViewModelObservers()
        
        // 设置窗口始终保持在前面，但不阻挡关键窗口
        self.orderFrontRegardless()
    }
    
    private func setupViewModelObservers() {
        // 监听位置变化
        dockViewModel.$position
            .sink { [weak self] newPosition in
                self?.updateWindowPosition(newPosition)
            }
            .store(in: &cancellables)
        
        // 监听items变化（影响窗口大小）
        dockViewModel.$items
            .sink { [weak self] _ in
                self?.updateWindowSize()
            }
            .store(in: &cancellables)
        
        // 监听边缘偏移量变化
        dockViewModel.$edgeOffset
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updateWindowPosition(self.dockViewModel.position)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func updateWindowPosition(_ position: DockPosition) {
        guard let screen = NSScreen.main else { return }
        
        let dockSize = dockViewModel.calculateDockSize()
        var anchorPoint = position.anchorPoint(
            screenSize: screen.frame.size,
            dockSize: dockSize,
            edgeOffset: dockViewModel.edgeOffset
        )
        
        // 对于左右位置，使用visibleFrame来实现更准确的垂直居中
        if position == .left || position == .right {
            let visibleCenterY = screen.visibleFrame.origin.y + screen.visibleFrame.height / 2
            anchorPoint.y = visibleCenterY
        }
        
        let newFrame = CGRect(
            x: anchorPoint.x - dockSize.width / 2,
            y: anchorPoint.y - dockSize.height / 2,
            width: dockSize.width,
            height: dockSize.height
        )
        
        // 调试信息
        print("=== Dock位置调试信息 ===")
        print("屏幕尺寸: \(screen.frame.size)")
        print("屏幕可见区域: \(screen.visibleFrame)")
        print("Dock尺寸: \(dockSize)")
        print("锚点位置: \(anchorPoint)")
        print("新的窗口frame: \(newFrame)")
        print("边缘偏移量: \(dockViewModel.edgeOffset)")
        
        self.setFrame(newFrame, display: true, animate: true)
    }
    
    private func updateWindowSize() {
        guard let screen = NSScreen.main else { return }
        
        let dockSize = dockViewModel.calculateDockSize()
        var anchorPoint = dockViewModel.position.anchorPoint(
            screenSize: screen.frame.size,
            dockSize: dockSize,
            edgeOffset: dockViewModel.edgeOffset
        )
        
        // 对于左右位置，使用visibleFrame来实现更准确的垂直居中
        if dockViewModel.position == .left || dockViewModel.position == .right {
            let visibleCenterY = screen.visibleFrame.origin.y + screen.visibleFrame.height / 2
            anchorPoint.y = visibleCenterY
        }
        
        let newFrame = CGRect(
            x: anchorPoint.x - dockSize.width / 2,
            y: anchorPoint.y - dockSize.height / 2,
            width: dockSize.width,
            height: dockSize.height
        )
        
        self.setFrame(newFrame, display: true, animate: true)
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
    func showDockWindow(viewModel: DockViewModel) {
        // 确保在主线程上执行
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showDockWindow(viewModel: viewModel)
            }
            return
        }
        
        if dockWindow == nil {
            dockWindow = DockWindow(viewModel: viewModel)
        }
        
        // 使用orderFront而不是makeKeyAndOrderFront，避免抢夺焦点
        dockWindow?.orderFront(nil)
        
        // 设置窗口层级，让它在普通窗口之上，但不会阻挡系统窗口
        dockWindow?.level = .popUpMenu
    }
    
    /// 隐藏Dock窗口
    func hideDockWindow() {
        // 确保在主线程上执行
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.hideDockWindow()
            }
            return
        }
        
        dockWindow?.close()
        dockWindow = nil
    }
    
    /// 更新Dock位置
    func updateDockPosition(_ position: DockPosition) {
        // 位置更新现在由DockWindow内部处理
    }
} 