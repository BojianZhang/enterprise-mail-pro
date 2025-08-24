#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "停止本地运行的服务"
echo "========================================"

# 停止后端
if [ -f backend.pid ]; then
    BACKEND_PID=$(cat backend.pid)
    if ps -p $BACKEND_PID > /dev/null 2>&1; then
        echo "停止后端服务 (PID: $BACKEND_PID)..."
        kill $BACKEND_PID
        echo -e "${GREEN}✓ 后端服务已停止${NC}"
    else
        echo -e "${YELLOW}后端服务未运行${NC}"
    fi
    rm -f backend.pid
else
    echo -e "${YELLOW}未找到后端 PID 文件${NC}"
fi

# 停止前端
if [ -f frontend.pid ]; then
    FRONTEND_PID=$(cat frontend.pid)
    if ps -p $FRONTEND_PID > /dev/null 2>&1; then
        echo "停止前端服务 (PID: $FRONTEND_PID)..."
        kill $FRONTEND_PID
        echo -e "${GREEN}✓ 前端服务已停止${NC}"
    else
        echo -e "${YELLOW}前端服务未运行${NC}"
    fi
    rm -f frontend.pid
else
    echo -e "${YELLOW}未找到前端 PID 文件${NC}"
fi

# 尝试通过端口查找并停止服务
echo ""
echo "检查端口占用..."

# 检查 8080 端口（后端）
if lsof -ti:8080 > /dev/null 2>&1; then
    echo "发现 8080 端口被占用，尝试停止..."
    lsof -ti:8080 | xargs kill -9 2>/dev/null
    echo -e "${GREEN}✓ 8080 端口已释放${NC}"
fi

# 检查 5173 端口（前端开发服务器）
if lsof -ti:5173 > /dev/null 2>&1; then
    echo "发现 5173 端口被占用，尝试停止..."
    lsof -ti:5173 | xargs kill -9 2>/dev/null
    echo -e "${GREEN}✓ 5173 端口已释放${NC}"
fi

echo ""
echo -e "${GREEN}所有服务已停止${NC}"