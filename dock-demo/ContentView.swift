//
//  ContentView.swift
//  dock-demo
//
//  Created by lmx on 2025/6/28.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedPosition: DockPosition = .right
    @State private var showInstructions = true
    @State private var hasAccessibilityPermission = false
    
    // 定时器，用于定期检查权限状态
    let permissionCheckTimer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 30) {
            // 标题
            Text("Dock 演示控制面板")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Divider()
            
            // 权限状态显示
            HStack {
                Image(systemName: hasAccessibilityPermission ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(hasAccessibilityPermission ? .green : .orange)
                
                Text(hasAccessibilityPermission ? "辅助功能权限已授予" : "需要辅助功能权限")
                    .font(.headline)
                
                if !hasAccessibilityPermission {
                    Button("前往设置") {
                        openAccessibilitySettings()
                    }
                    .buttonStyle(.link)
                }
            }
            .padding(.horizontal)
            
            // 使用说明
            if showInstructions {
                VStack(alignment: .leading, spacing: 10) {
                    Text("使用说明：")
                        .font(.headline)
                    
                    Text("• 将鼠标移动到屏幕边缘以显示 Dock")
                    Text("• 鼠标离开后 Dock 会自动隐藏")
                    Text("• 点击 Dock 中的图标可以打开对应的应用")
                    Text("• 使用下方的选项切换 Dock 的位置")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            
            // Dock 位置选择
            VStack(alignment: .leading, spacing: 15) {
                Text("Dock 位置")
                    .font(.headline)
                
                Picker("位置", selection: $selectedPosition) {
                    ForEach(DockPosition.allCases, id: \.self) { position in
                        Text(position.rawValue).tag(position)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedPosition) { newPosition in
                    // 更新 Dock 位置
                    updateDockPosition(newPosition)
                }
            }
            
            // 操作按钮
            HStack(spacing: 20) {
                Button("隐藏说明") {
                    withAnimation {
                        showInstructions.toggle()
                    }
                }
                
                Button("退出应用") {
                    NSApplication.shared.terminate(nil)
                }
                .foregroundColor(.red)
            }
            
            Spacer()
            
            // 提示信息
            if !hasAccessibilityPermission {
                Text("提示：需要授予辅助功能权限才能监听鼠标事件")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(30)
        .frame(width: 500, height: 450)
        .onAppear {
            checkAccessibilityPermission()
        }
        .onReceive(permissionCheckTimer) { _ in
            checkAccessibilityPermission()
        }
    }
    
    private func updateDockPosition(_ position: DockPosition) {
        // 这里需要通过某种方式通知 DockViewModel 更新位置
        // 可以使用 NotificationCenter 或其他通信机制
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

#Preview {
    ContentView()
}
