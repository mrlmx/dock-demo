//
//  DockItem.swift
//  dock-demo
//
//  Dock中的应用图标模型
//

import Foundation
import SwiftUI

/// Dock中的单个应用项
struct DockItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String // SF Symbol名称
    let color: Color
    var isHovered: Bool = false
    
    /// 执行点击动作
    var action: () -> Void = {}
}

/// 预设的一些应用图标
extension DockItem {
    static var sampleItems: [DockItem] {
        // 改为计算属性，避免静态初始化时的问题
        return [
            DockItem(
                name: "访达",
                icon: "folder.fill",
                color: .blue,
                action: {
                    if let url = URL(string: "file://\(NSHomeDirectory())") {
                        NSWorkspace.shared.open(url)
                    }
                }
            ),
            DockItem(
                name: "Safari",
                icon: "safari.fill",
                color: .blue,
                action: {
                    NSWorkspace.shared.launchApplication("Safari")
                }
            ),
            DockItem(
                name: "邮件",
                icon: "envelope.fill",
                color: .blue,
                action: {
                    NSWorkspace.shared.launchApplication("Mail")
                }
            ),
            DockItem(
                name: "音乐",
                icon: "music.note",
                color: .red,
                action: {
                    NSWorkspace.shared.launchApplication("Music")
                }
            ),
            DockItem(
                name: "系统偏好设置",
                icon: "gearshape.fill",
                color: .gray,
                action: {
                    // macOS Ventura 及以上版本使用 System Settings
                    if NSWorkspace.shared.launchApplication("System Settings") == false {
                        // 旧版本使用 System Preferences
                        NSWorkspace.shared.launchApplication("System Preferences")
                    }
                }
            ),
            DockItem(
                name: "终端",
                icon: "terminal.fill",
                color: .black,
                action: {
                    NSWorkspace.shared.launchApplication("Terminal")
                }
            )
        ]
    }
} 