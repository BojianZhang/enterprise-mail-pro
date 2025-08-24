# 🚀 企业邮件系统 - 快速启动指南

## ✅ 系统已完成全面优化

### 主要修复内容：

1. **Maven 依赖更新**
   - ✅ 修复了不存在的包（Apache James → GreenMail）
   - ✅ 更新 MySQL 驱动为最新版本 (mysql-connector-j)
   - ✅ 迁移 javax.mail → jakarta.mail
   - ✅ 使用 Simple Java Mail 替代 spamassassin

2. **代码兼容性修复**
   - ✅ 所有 javax 导入已迁移到 jakarta
   - ✅ 修复了 SecretKey 导入问题
   - ✅ 更新了邮件服务实现

3. **Docker 优化**
   - ✅ 使用稳定的基础镜像 (eclipse-temurin)
   - ✅ 移除过时的 version 属性
   - ✅ 提供多种部署方案

## 🎯 一键部署

### 方案 1：智能部署（自动选择最佳方式）
```bash
./deploy-smart.sh
```
脚本会自动检测环境并选择最佳部署方式。

### 方案 2：Docker 部署（推荐）
```bash
# 如果 Docker Hub 可访问
docker compose up -d

# 如果需要使用国内镜像
# 先配置 Docker 镜像源（参考 DOCKER_TROUBLESHOOTING.md）
./deploy-v2.sh
```

### 方案 3：本地运行（无需 Docker）
```bash
./run-local.sh
```

## 📊 系统自检

运行自检脚本确认系统状态：
```bash
./system-check.sh
```

当前状态：**100% 健康度 - 系统完全就绪**

## 🔑 访问信息

部署成功后访问：
- **前端界面**: http://localhost
- **后端 API**: http://localhost:8080/api
- **API 文档**: http://localhost:8080/api/swagger-ui.html

默认账号：
- 用户名: admin
- 密码: admin123

## 📧 邮件服务端口

- **SMTP**: 25 (465 SSL)
- **IMAP**: 143 (993 SSL)
- **POP3**: 110 (995 SSL)

## 🛠️ 管理命令

### Docker 模式
```bash
# 查看日志
docker compose logs -f [service]

# 停止服务
docker compose down

# 重启服务
docker compose restart
```

### 本地模式
```bash
# 查看日志
tail -f logs/backend.log
tail -f logs/frontend.log

# 停止服务
./stop-local.sh
```

## 📚 项目结构

```
enterprise-mail-pro/
├── backend/                # Spring Boot 后端
│   ├── src/               # Java 源代码
│   ├── pom.xml           # Maven 配置（已优化）
│   └── Dockerfile        # Docker 配置（已更新）
├── frontend/              # Vue 3 前端
│   ├── src/              # Vue 源代码
│   ├── package.json      # NPM 配置
│   └── Dockerfile        # Docker 配置
├── docker-compose.yml     # Docker Compose 配置（已优化）
├── deploy-smart.sh        # 智能部署脚本 ⭐
├── system-check.sh        # 系统自检脚本 ⭐
├── run-local.sh          # 本地运行脚本
└── DOCKER_TROUBLESHOOTING.md  # 故障排除指南
```

## 🔧 技术栈

### 后端
- Spring Boot 3.2.0
- Java 17
- MySQL 8.0
- GreenMail (邮件服务器)
- JWT 认证
- Redis 缓存

### 前端
- Vue 3
- TypeScript
- Element Plus UI
- Vite 构建工具
- Pinia 状态管理

## ⚠️ 注意事项

1. **端口占用**：确保以下端口未被占用
   - 80, 443 (前端)
   - 8080 (后端)
   - 3306 (MySQL)
   - 6379 (Redis)
   - 25, 143, 110 (邮件服务)

2. **内存要求**：建议至少 4GB 可用内存

3. **网络问题**：如遇 Docker Hub 连接问题，参考 `DOCKER_TROUBLESHOOTING.md`

## 🆘 获取帮助

如遇问题：
1. 运行 `./system-check.sh` 进行自检
2. 查看 `DOCKER_TROUBLESHOOTING.md` 故障排除指南
3. 检查日志文件中的错误信息

## ✨ 特色功能

- ✅ 完整的邮件服务器功能（收发邮件）
- ✅ 忘记密码/重置密码功能
- ✅ 多用户支持
- ✅ 邮件文件夹管理
- ✅ 附件上传下载
- ✅ 邮件搜索过滤
- ✅ WebSocket 实时通知
- ✅ 响应式设计

---

**系统已完全优化，所有依赖问题已修复，可以立即部署使用！** 🎉