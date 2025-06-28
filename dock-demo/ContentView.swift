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
    @State private var tempEdgeOffset: CGFloat = 0
    
    init() {
        print("ContentView 初始化")
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 顶部区域
                VStack(spacing: 20) {
                    // 标题和权限状态
                    VStack(spacing: 16) {
                        Text("Dock 控制中心")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        // 权限状态条
                        HStack(spacing: 10) {
                            Image(systemName: hasAccessibilityPermission ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(hasAccessibilityPermission ? .green : .orange)
                                .font(.system(size: 16))
                            
                            Text(hasAccessibilityPermission ? "权限正常" : "需要辅助功能权限")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            if !hasAccessibilityPermission {
                                Button("前往授权") {
                                    openAccessibilitySettings()
                                }
                                .buttonStyle(.link)
                                .font(.system(size: 14))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            hasAccessibilityPermission ? 
                            Color.green.opacity(0.1) : 
                            Color.orange.opacity(0.1)
                        )
                        .cornerRadius(24)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    
                    // 主内容区域
                    VStack(spacing: 30) {
                        // 使用说明区域
                        if showInstructions {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Image(systemName: "lightbulb.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.yellow)
                                    
                                    Text("快速上手")
                                        .font(.system(size: 20, weight: .semibold))
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            showInstructions.toggle()
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.secondary.opacity(0.6))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16)
                                ], spacing: 16) {
                                    InstructionCard(
                                        icon: "cursorarrow.motionlines",
                                        title: "触发显示",
                                        description: "将鼠标移至屏幕边缘即可显示 Dock"
                                    )
                                    InstructionCard(
                                        icon: "arrow.left.and.right",
                                        title: "自动隐藏",
                                        description: "鼠标离开后 Dock 会自动隐藏"
                                    )
                                    InstructionCard(
                                        icon: "hand.tap.fill",
                                        title: "快速启动",
                                        description: "点击 Dock 中的图标即可打开应用"
                                    )
                                    InstructionCard(
                                        icon: "rectangle.portrait.and.arrow.right",
                                        title: "灵活定位",
                                        description: "可随时切换 Dock 显示位置"
                                    )
                                }
                            }
                            .padding(30)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        }
                        
                        // 主要功能区域 - 使用两列布局
                        HStack(alignment: .top, spacing: 20) {
                            // 左列 - Dock 位置设置
                            VStack(spacing: 20) {
                                // Dock 位置选择
                                CardView(title: "Dock 位置", icon: "rectangle.portrait.split.2x1") {
                                    VStack(spacing: 20) {
                                        // 位置选择网格
                                        LazyVGrid(columns: [
                                            GridItem(.flexible()),
                                            GridItem(.flexible())
                                        ], spacing: 12) {
                                            ForEach(DockPosition.allCases, id: \.self) { position in
                                                PositionButton(
                                                    position: position,
                                                    isSelected: selectedPosition == position,
                                                    action: {
                                                        selectedPosition = position
                                                        // 只通过通知更新，避免重复设置
                                                        updateDockPosition(position)
                                                    }
                                                )
                                            }
                                        }
                                        
                                        // 大尺寸预览
                                        DockPositionPreview(position: selectedPosition)
                                            .frame(height: 150)
                                            .background(Color.gray.opacity(0.05))
                                            .cornerRadius(12)
                                    }
                                }
                                
                                // 边缘偏移设置
                                CardView(title: "边缘偏移", icon: "arrow.up.and.down.and.arrow.left.and.right") {
                                    VStack(spacing: 16) {
                                        HStack {
                                            Text("距离边缘")
                                                .font(.system(size: 15))
                                                .foregroundColor(.secondary)
                                            
                                            Spacer()
                                            
                                            Text("\(Int(tempEdgeOffset)) 像素")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.primary)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 4)
                                                .background(Color.accentColor.opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                        
                                        Slider(value: $tempEdgeOffset, in: 0...50) { editing in
                                            // 只在用户停止拖动时才更新ViewModel
                                            if !editing {
                                                dockViewModel.edgeOffset = tempEdgeOffset
                                            }
                                        }
                                        .tint(.accentColor)
                                        
                                        Text("调整 Dock 与屏幕边缘的距离，让显示位置更符合你的使用习惯")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            
                            // 右列 - 快捷操作和其他设置
                            VStack(spacing: 20) {
                                // 快捷操作
                                CardView(title: "快捷操作", icon: "gearshape.fill") {
                                    VStack(spacing: 12) {
                                        ActionButton(
                                            icon: showInstructions ? "eye.slash" : "eye",
                                            title: showInstructions ? "隐藏使用指南" : "显示使用指南",
                                            description: "切换使用指南的显示状态",
                                            action: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                    showInstructions.toggle()
                                                }
                                            }
                                        )
                                        
                                        Divider()
                                        
                                        ActionButton(
                                            icon: "arrow.clockwise",
                                            title: "重置设置",
                                            description: "恢复到默认配置",
                                            action: {
                                                selectedPosition = .right
                                                tempEdgeOffset = 10
                                                dockViewModel.edgeOffset = 10
                                                // 只通过通知更新position，避免重复设置
                                                updateDockPosition(.right)
                                            }
                                        )
                                        
                                        Divider()
                                        
                                        ActionButton(
                                            icon: "power",
                                            title: "退出应用",
                                            description: "关闭 Dock 控制中心",
                                            isDestructive: true,
                                            action: {
                                                NSApplication.shared.terminate(nil)
                                            }
                                        )
                                    }
                                }
                                
                                // 关于信息
                                CardView(title: "关于", icon: "info.circle.fill") {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text("版本")
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text("1.0.0")
                                                .foregroundColor(.primary)
                                        }
                                        .font(.system(size: 14))
                                        
                                        Text("一个优雅的 macOS Dock 增强工具，让你的工作流更加高效。")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 700)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            checkAccessibilityPermission()
            selectedPosition = dockViewModel.position
            tempEdgeOffset = dockViewModel.edgeOffset
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // 当应用被激活时重新检查权限
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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.accentColor)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// 说明卡片组件
struct InstructionCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 图标和标题部分
            HStack(alignment: .center, spacing: 12) {
                // 图标容器
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.accentColor)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// 位置选择按钮组件
struct PositionButton: View {
    let position: DockPosition
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: positionIcon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(position.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
    
    private var positionIcon: String {
        switch position {
        case .top: return "rectangle.topthird.inset.filled"
        case .bottom: return "rectangle.bottomthird.inset.filled"
        case .left: return "rectangle.leftthird.inset.filled"
        case .right: return "rectangle.rightthird.inset.filled"
        }
    }
}

// 操作按钮组件
struct ActionButton: View {
    let icon: String
    let title: String
    let description: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isDestructive ? .red : .accentColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isDestructive ? .red : .primary)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .opacity(0.5)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// Dock 位置预览组件
struct DockPositionPreview: View {
    let position: DockPosition
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 屏幕预览背景
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.05),
                            Color.gray.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                // 屏幕内容模拟
                VStack(spacing: 8) {
                    // 模拟菜单栏
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 20)
                    
                    // 模拟窗口
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.1))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.1))
                    }
                    .padding(.horizontal, 12)
                    
                    Spacer()
                }
                .padding(8)
                
                // Dock 预览
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color.accentColor,
                            Color.accentColor.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(
                        width: position.isHorizontal ? geometry.size.width * 0.7 : 16,
                        height: position.isHorizontal ? 16 : geometry.size.height * 0.7
                    )
                    .position(dockPreviewPosition(in: geometry.size))
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                
                // Dock 图标模拟
                if position.isHorizontal {
                    HStack(spacing: 4) {
                        ForEach(0..<5) { _ in
                            Circle()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .position(dockPreviewPosition(in: geometry.size))
                } else {
                    VStack(spacing: 4) {
                        ForEach(0..<5) { _ in
                            Circle()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .position(dockPreviewPosition(in: geometry.size))
                }
            }
        }
    }
    
    private func dockPreviewPosition(in size: CGSize) -> CGPoint {
        switch position {
        case .top:
            return CGPoint(x: size.width / 2, y: 12)
        case .bottom:
            return CGPoint(x: size.width / 2, y: size.height - 12)
        case .left:
            return CGPoint(x: 12, y: size.height / 2)
        case .right:
            return CGPoint(x: size.width - 12, y: size.height / 2)
        }
    }
}



#Preview {
    ContentView()
        .environmentObject(DockViewModel())
}
