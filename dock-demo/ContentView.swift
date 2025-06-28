//
//  ContentView.swift
//  dock-demo
//
//  Created by lmx on 2025/6/28.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dockViewModel: DockViewModel
    @State private var selectedPosition: DockPosition = .right
    @State private var showInstructions = true
    @State private var hasAccessibilityPermission = false
    
    // 定时器，用于定期检查权限状态
    let permissionCheckTimer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            VStack(spacing: 10) {
                Text("Dock 控制中心")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                // 权限状态条
                HStack(spacing: 8) {
                    Image(systemName: hasAccessibilityPermission ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(hasAccessibilityPermission ? .green : .orange)
                        .font(.system(size: 14))
                    
                    Text(hasAccessibilityPermission ? "权限正常" : "需要权限")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    if !hasAccessibilityPermission {
                        Button("授权") {
                            openAccessibilitySettings()
                        }
                        .buttonStyle(.link)
                        .font(.system(size: 12))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    hasAccessibilityPermission ? 
                    Color.green.opacity(0.1) : 
                    Color.orange.opacity(0.1)
                )
                .cornerRadius(20)
            }
            .padding(.top, 20)
            .padding(.bottom, 15)
            
            Divider()
            
            // 主内容区域（可滚动）
            ScrollView {
                VStack(spacing: 20) {
                    // 使用说明卡片
                    if showInstructions {
                        CardView(title: "使用指南", icon: "questionmark.circle") {
                            VStack(alignment: .leading, spacing: 8) {
                                InstructionRow(icon: "cursorarrow.motionlines", text: "将鼠标移至屏幕边缘显示 Dock")
                                InstructionRow(icon: "arrow.left.and.right", text: "鼠标离开后自动隐藏")
                                InstructionRow(icon: "hand.tap", text: "点击图标打开应用")
                                InstructionRow(icon: "rectangle.portrait.and.arrow.right", text: "下方可切换 Dock 位置")
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    }
                    
                    // Dock 位置设置卡片
                    CardView(title: "Dock 位置", icon: "rectangle.portrait.split.2x1") {
                        VStack(spacing: 15) {
                            // 自定义的位置选择器
                            HStack(spacing: 0) {
                                ForEach(DockPosition.allCases, id: \.self) { position in
                                    Button(action: {
                                        selectedPosition = position
                                        dockViewModel.position = position
                                        updateDockPosition(position)
                                    }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: positionIcon(for: position))
                                                .font(.system(size: 20))
                                            Text(position.rawValue)
                                                .font(.system(size: 12))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedPosition == position ?
                                            Color.accentColor : Color.clear
                                        )
                                        .foregroundColor(
                                            selectedPosition == position ?
                                            .white : .primary
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if position != DockPosition.allCases.last {
                                        Divider()
                                            .frame(height: 40)
                                    }
                                }
                            }
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            
                            // 可视化预览
                            DockPositionPreview(position: selectedPosition)
                                .frame(height: 80)
                        }
                    }
                    
                    // 边缘偏移设置卡片
                    CardView(title: "边缘偏移", icon: "arrow.up.and.down.and.arrow.left.and.right") {
                        VStack(spacing: 12) {
                            HStack {
                                Text("距离边缘")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(Int(dockViewModel.edgeOffset)) 像素")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            
                            Slider(value: $dockViewModel.edgeOffset, in: 0...50)
                                .tint(.accentColor)
                            
                            Text("调整 Dock 与屏幕边缘的距离")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // 快捷操作卡片
                    CardView(title: "快捷操作", icon: "gearshape") {
                        VStack(spacing: 12) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showInstructions.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: showInstructions ? "eye.slash" : "eye")
                                    Text(showInstructions ? "隐藏使用指南" : "显示使用指南")
                                    Spacer()
                                }
                            }
                            .buttonStyle(ActionButtonStyle())
                            
                            Button(action: {
                                NSApplication.shared.terminate(nil)
                            }) {
                                HStack {
                                    Image(systemName: "power")
                                    Text("退出应用")
                                    Spacer()
                                }
                            }
                            .buttonStyle(ActionButtonStyle(isDestructive: true))
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 400, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            checkAccessibilityPermission()
            selectedPosition = dockViewModel.position
        }
        .onReceive(permissionCheckTimer) { _ in
            checkAccessibilityPermission()
        }
    }
    
    private func positionIcon(for position: DockPosition) -> String {
        switch position {
        case .top: return "rectangle.topthird.inset.filled"
        case .bottom: return "rectangle.bottomthird.inset.filled"
        case .left: return "rectangle.leftthird.inset.filled"
        case .right: return "rectangle.rightthird.inset.filled"
        }
    }
    
    private func updateDockPosition(_ position: DockPosition) {
        NotificationCenter.default.post(
            name: Notification.Name("DockPositionChanged"),
            object: nil,
            userInfo: ["position": position]
        )
    }
    
    private func checkAccessibilityPermission() {
        hasAccessibilityPermission = AXIsProcessTrusted()
    }
    
    private func openAccessibilitySettings() {
        let prefPaneURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(prefPaneURL)
    }
}

// 卡片视图组件
struct CardView<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.accentColor)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

// 说明行组件
struct InstructionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// Dock 位置预览组件
struct DockPositionPreview: View {
    let position: DockPosition
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 屏幕预览
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                // Dock 预览
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.accentColor.opacity(0.8))
                    .frame(
                        width: position.isHorizontal ? geometry.size.width * 0.6 : 12,
                        height: position.isHorizontal ? 12 : geometry.size.height * 0.6
                    )
                    .position(dockPreviewPosition(in: geometry.size))
            }
        }
    }
    
    private func dockPreviewPosition(in size: CGSize) -> CGPoint {
        switch position {
        case .top:
            return CGPoint(x: size.width / 2, y: 10)
        case .bottom:
            return CGPoint(x: size.width / 2, y: size.height - 10)
        case .left:
            return CGPoint(x: 10, y: size.height / 2)
        case .right:
            return CGPoint(x: size.width - 10, y: size.height / 2)
        }
    }
}

// 自定义按钮样式
struct ActionButtonStyle: ButtonStyle {
    let isDestructive: Bool
    
    init(isDestructive: Bool = false) {
        self.isDestructive = isDestructive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(isDestructive ? .red : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed ? 
                          Color.gray.opacity(0.2) : 
                          Color.gray.opacity(0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

#Preview {
    ContentView()
        .environmentObject(DockViewModel())
}
