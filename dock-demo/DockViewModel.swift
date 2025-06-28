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
    @Published var items: [DockItem] = DockItem.sampleItems
    @Published var position: DockPosition = .right
    @Published var hoveredItemId: UUID? = nil
    
    // MARK: - 配置属性
    let triggerDistance: CGFloat = 5 // 触发显示的距离
    let dockSize = CGSize(width: 80, height: 400) // Dock的基础尺寸
    let itemSize: CGFloat = 60 // 图标基础大小
    let itemSpacing: CGFloat = 10 // 图标间距
    let animationDuration: Double = 0.3 // 动画时长
    
    // MARK: - 私有属性
    private var mouseTracker: Any?
    private var hideTimer: Timer?
    private let hideDelay: TimeInterval = 0.5 // 鼠标离开后的延迟隐藏时间
    
    init() {
        startMouseTracking()
        setupNotificationObservers()
    }
    
    deinit {
        stopMouseTracking()
        hideTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 鼠标追踪
    private func startMouseTracking() {
        // 使用全局事件监听器追踪鼠标位置
        mouseTracker = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMoved(event)
        }
        
        // 同时监听本地事件（当鼠标在应用窗口内时）
        NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMoved(event)
            return event
        }
    }
    
    private func stopMouseTracking() {
        if let tracker = mouseTracker {
            NSEvent.removeMonitor(tracker)
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
        let anchorPoint = position.anchorPoint(screenSize: screenSize, dockSize: actualDockSize)
        
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
} 