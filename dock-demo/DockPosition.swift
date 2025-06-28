//
//  DockPosition.swift
//  dock-demo
//
//  定义Dock的吸附位置
//

import Foundation
import SwiftUI

/// Dock的吸附位置
enum DockPosition: String, CaseIterable {
    case top = "顶部"
    case bottom = "底部"
    case left = "左侧"
    case right = "右侧"
    
    /// 获取Dock在隐藏状态下的偏移量
    func hiddenOffset(screenSize: CGSize, dockSize: CGSize) -> CGSize {
        switch self {
        case .top:
            return CGSize(width: 0, height: -dockSize.height)
        case .bottom:
            return CGSize(width: 0, height: dockSize.height)
        case .left:
            return CGSize(width: -dockSize.width, height: 0)
        case .right:
            return CGSize(width: dockSize.width, height: 0)
        }
    }
    
    /// 获取Dock的锚点位置
    func anchorPoint(screenSize: CGSize, dockSize: CGSize, edgeOffset: CGFloat = 0) -> CGPoint {
        switch self {
        case .top:
            return CGPoint(x: screenSize.width / 2, y: screenSize.height - dockSize.height / 2 - edgeOffset)
        case .bottom:
            return CGPoint(x: screenSize.width / 2, y: dockSize.height / 2 + edgeOffset)
        case .left:
            return CGPoint(x: dockSize.width / 2 + edgeOffset, y: screenSize.height / 2)
        case .right:
            return CGPoint(x: screenSize.width - dockSize.width / 2 - edgeOffset, y: screenSize.height / 2)
        }
    }
    
    /// 判断鼠标是否在触发区域内
    func isMouseInTriggerZone(mouseLocation: CGPoint, screenSize: CGSize, triggerDistance: CGFloat) -> Bool {
        switch self {
        case .top:
            return mouseLocation.y > screenSize.height - triggerDistance
        case .bottom:
            return mouseLocation.y < triggerDistance
        case .left:
            return mouseLocation.x < triggerDistance
        case .right:
            return mouseLocation.x > screenSize.width - triggerDistance
        }
    }
    
    /// 获取Dock的方向（水平或垂直）
    var isHorizontal: Bool {
        switch self {
        case .top, .bottom:
            return true
        case .left, .right:
            return false
        }
    }
} 