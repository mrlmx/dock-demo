//
//  DockView.swift
//  dock-demo
//
//  Dock的主视图
//

import SwiftUI

struct DockView: View {
    @EnvironmentObject var viewModel: DockViewModel
    
    var body: some View {
        // 计算一次并缓存结果
        let dockSize = viewModel.calculateDockSize()
        
        ZStack {
            // 背景
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // 图标容器
            if viewModel.position.isHorizontal {
                HStack(spacing: viewModel.itemSpacing) {
                    ForEach(viewModel.items) { item in
                        DockItemView(
                            item: item,
                            isHovered: viewModel.hoveredItemId == item.id,
                            itemSize: viewModel.itemSize
                        )
                        .id(item.id)
                        .onHover { isHovered in
                            viewModel.setHoveredItem(isHovered ? item.id : nil)
                        }
                        .onTapGesture {
                            item.action()
                        }
                    }
                }
                .padding()
            } else {
                VStack(spacing: viewModel.itemSpacing) {
                    ForEach(viewModel.items) { item in
                        DockItemView(
                            item: item,
                            isHovered: viewModel.hoveredItemId == item.id,
                            itemSize: viewModel.itemSize
                        )
                        .id(item.id)
                        .onHover { isHovered in
                            viewModel.setHoveredItem(isHovered ? item.id : nil)
                        }
                        .onTapGesture {
                            item.action()
                        }
                    }
                }
                .padding()
            }
        }
        .frame(
            width: dockSize.width,
            height: dockSize.height
        )
        .offset(
            viewModel.isVisible ? .zero : viewModel.position.hiddenOffset(
                screenSize: NSScreen.main?.frame.size ?? .zero,
                dockSize: dockSize
            )
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.isVisible)
    }
}

/// 单个Dock图标视图
struct DockItemView: View {
    let item: DockItem
    let isHovered: Bool
    let itemSize: CGFloat
    
    var body: some View {
        ZStack {
            // 背景
            if isHovered {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: itemSize + 10, height: itemSize + 10)
            }
            
            // 图标
            Image(systemName: item.icon)
                .font(.system(size: itemSize * 0.5))
                .foregroundColor(item.color)
                .frame(width: itemSize, height: itemSize)
                .scaleEffect(isHovered ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
        }
        .help(item.name) // 工具提示
    }
}

// 预览
struct DockView_Previews: PreviewProvider {
    static var previews: some View {
        DockView()
            .environmentObject(DockViewModel())
            .frame(width: 400, height: 80)
    }
} 