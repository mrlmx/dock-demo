#!/bin/bash

# 重置 dock-demo 的辅助功能权限脚本

echo "=== 重置 dock-demo 辅助功能权限 ==="
echo ""

# 获取应用的 Bundle ID
BUNDLE_ID="com.ruguo.dock-demo"

# 检查应用是否正在运行
if pgrep -x "dock-demo" > /dev/null; then
    echo "检测到应用正在运行，正在退出..."
    killall "dock-demo" 2>/dev/null
    sleep 2
fi

# 重置权限
echo "正在重置辅助功能权限..."
tccutil reset Accessibility "$BUNDLE_ID"

if [ $? -eq 0 ]; then
    echo "✅ 权限重置成功！"
    echo ""
    echo "请执行以下步骤："
    echo "1. 重新运行 dock-demo 应用"
    echo "2. 在弹出的提示中点击'打开系统偏好设置'"
    echo "3. 在系统设置的辅助功能列表中勾选 dock-demo"
    echo ""
    echo "如果问题仍然存在，请尝试重启电脑。"
else
    echo "❌ 权限重置失败，请确保有管理员权限"
fi 