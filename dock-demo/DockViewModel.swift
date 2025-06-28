//
//  DockViewModel.swift
//  dock-demo
//
//  Dock的视图模型，管理状态和逻辑
//

import Foundation
import SwiftUI
import Combine

class DockViewModel: ObservableObject {
    // MARK: - 发布的属性
    @Published var isVisible: Bool = false
    @Published var items: [DockItem] = []
    @Published var position: DockPosition = .right
    @Published var hoveredItemId: UUID? = nil
    @Published var edgeOffset: CGFloat = 0 // Dock与屏幕边缘的距离，默认为0（完全贴边）
    
    // MARK: - 配置属性
    let triggerDistance: CGFloat = 5 // 触发显示的距离
    let dockSize = CGSize(width: 80, height: 400) // Dock的基础尺寸
    let itemSize: CGFloat = 60 // 图标基础大小
    let itemSpacing: CGFloat = 10 // 图标间距
    let animationDuration: Double = 0.3 // 动画时长
    
    // MARK: - 私有属性
    private var mouseTracker: Any?
    private var localMouseTracker: Any?
    private var hideTimer: Timer?
    private let hideDelay: TimeInterval = 0.5 // 鼠标离开后的延迟隐藏时间
    private var permissionCheckTimer: Timer? // 权限检查定时器
    private var memoryMonitorTimer: Timer? // 内存监控定时器
    
    init() {
        print("DockViewModel 初始化")
        // 确保在主线程上初始化
        DispatchQueue.main.async { [weak self] in
            self?.items = DockItem.sampleItems
            self?.setupNotificationObservers()
            // 延迟启动鼠标追踪，给系统时间初始化
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.startMouseTracking()
            }
            
            // 启动内存监控（仅用于调试）
            #if DEBUG
            self?.startMemoryMonitoring()
            #endif
        }
    }
    
    deinit {
        print("DockViewModel 释放")
        stopMouseTracking()
        hideTimer?.invalidate()
        permissionCheckTimer?.invalidate()
        memoryMonitorTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 鼠标追踪
    private func startMouseTracking() {
        // 检查是否有辅助功能权限
        guard AXIsProcessTrusted() else {
            // 只在第一次没有权限时打印警告
            if permissionCheckTimer == nil {
                print("警告：没有辅助功能权限，无法监听全局鼠标事件")
                // 设置一个定时器，定期检查权限状态
                permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
                    if AXIsProcessTrusted() {
                        print("辅助功能权限已获得，开始鼠标追踪")
                        timer.invalidate()
                        self?.permissionCheckTimer = nil
                        self?.startMouseTracking()
                    }
                }
            }
            return
        }
        
        // 如果已经有追踪器，先停止
        stopMouseTracking()
        
        // 使用全局事件监听器追踪鼠标位置
        mouseTracker = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMoved(event)
        }
        
        // 同时监听本地事件（当鼠标在应用窗口内时）
        localMouseTracker = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMoved(event)
            return event
        }
    }
    
    private func stopMouseTracking() {
        if let tracker = mouseTracker {
            NSEvent.removeMonitor(tracker)
            mouseTracker = nil
        }
        if let localTracker = localMouseTracker {
            NSEvent.removeMonitor(localTracker)
            localMouseTracker = nil
        }
    }
    
    private func handleMouseMoved(_ event: NSEvent) {
        guard let screen = NSScreen.main else { return }
        
        // 获取鼠标在屏幕上的位置
        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = screen.frame
        
        // 转换坐标系（NSEvent使用的是左下角为原点）
        let adjustedLocation = CGPoint(
            x: mouseLocation.x,
            y: screenFrame.height - mouseLocation.y
        )
        
        // 检查鼠标是否在触发区域
        let isInTriggerZone = position.isMouseInTriggerZone(
            mouseLocation: adjustedLocation,
            screenSize: screenFrame.size,
            triggerDistance: triggerDistance
        )
        
        if isInTriggerZone {
            showDock()
        } else if isVisible {
            // 检查鼠标是否在Dock区域内
            if !isMouseInDockArea(mouseLocation: adjustedLocation, screenSize: screenFrame.size) {
                scheduleHide()
            } else {
                cancelHideTimer()
            }
        }
    }
    
    private func isMouseInDockArea(mouseLocation: CGPoint, screenSize: CGSize) -> Bool {
        let dockRect = getDockRect(screenSize: screenSize)
        return dockRect.contains(mouseLocation)
    }
    
    private func getDockRect(screenSize: CGSize) -> CGRect {
        let actualDockSize = calculateDockSize()
        let anchorPoint = position.anchorPoint(screenSize: screenSize, dockSize: actualDockSize, edgeOffset: edgeOffset)
        
        return CGRect(
            x: anchorPoint.x - actualDockSize.width / 2,
            y: anchorPoint.y - actualDockSize.height / 2,
            width: actualDockSize.width,
            height: actualDockSize.height
        )
    }
    
    // MARK: - 显示/隐藏控制
    func showDock() {
        cancelHideTimer()
        withAnimation(.spring(response: animationDuration, dampingFraction: 0.8)) {
            isVisible = true
        }
    }
    
    func hideDock() {
        withAnimation(.spring(response: animationDuration, dampingFraction: 0.8)) {
            isVisible = false
        }
    }
    
    private func scheduleHide() {
        cancelHideTimer()
        hideTimer = Timer.scheduledTimer(withTimeInterval: hideDelay, repeats: false) { [weak self] _ in
            self?.hideDock()
        }
    }
    
    private func cancelHideTimer() {
        hideTimer?.invalidate()
        hideTimer = nil
    }
    
    // MARK: - 尺寸计算
    func calculateDockSize() -> CGSize {
        let itemCount = CGFloat(items.count)
        let totalSpacing = itemSpacing * (itemCount - 1)
        
        if position.isHorizontal {
            let width = itemCount * itemSize + totalSpacing + 40 // 40为内边距
            return CGSize(width: width, height: 80)
        } else {
            let height = itemCount * itemSize + totalSpacing + 40
            return CGSize(width: 80, height: height)
        }
    }
    
    // MARK: - 项目管理
    func setHoveredItem(_ itemId: UUID?) {
        withAnimation(.easeInOut(duration: 0.2)) {
            hoveredItemId = itemId
        }
    }
    
    func addItem(_ item: DockItem) {
        items.append(item)
    }
    
    func removeItem(_ item: DockItem) {
        items.removeAll { $0.id == item.id }
    }
    
    // MARK: - 通知观察
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePositionChange(_:)),
            name: Notification.Name("DockPositionChanged"),
            object: nil
        )
    }
    
    @objc private func handlePositionChange(_ notification: Notification) {
        if let position = notification.userInfo?["position"] as? DockPosition {
            DispatchQueue.main.async { [weak self] in
                self?.position = position
            }
        }
    }
    
    // MARK: - 内存监控（调试用）
    #if DEBUG
    private func startMemoryMonitoring() {
        memoryMonitorTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let info = ProcessInfo.processInfo
            let physicalMemory = info.physicalMemory
            let memoryUsage = self.getMemoryUsage()
            print("=== 内存使用情况 ===")
            print("物理内存: \(physicalMemory / 1024 / 1024) MB")
            print("当前使用: \(memoryUsage / 1024 / 1024) MB")
            print("==================")
        }
    }
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? info.resident_size : 0
    }
    #endif
} 