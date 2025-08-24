# 企业邮件系统 (Enterprise Mail System)

一个功能完整的企业级邮件服务器系统，支持自建邮件服务器，提供完整的邮件收发功能。

## 🚀 功能特点

### 核心功能
- ✅ **完整的邮件服务器**：支持 SMTP、IMAP、POP3 协议
- ✅ **用户管理**：注册、登录、权限管理
- ✅ **邮件收发**：支持 HTML 邮件、附件、批量发送
- ✅ **邮箱别名**：支持多别名管理，统一账户查看
- ✅ **域名管理**：支持多域名配置和管理
- ✅ **邮件过滤**：垃圾邮件过滤、自定义规则
- ✅ **安全特性**：JWT 认证、SSL/TLS 加密、SPF/DKIM/DMARC 支持

### 技术栈

#### 后端
- Spring Boot 3.2.0
- MySQL 8.0
- Redis 7
- Apache James (邮件服务器核心)
- JWT 认证
- Spring Security

#### 前端
- Vue 3
- TypeScript
- Element Plus UI
- Vite 构建工具
- Pinia 状态管理

## 📦 快速开始

### 系统要求
- Docker 20.10+
- Docker Compose 2.0+
- 4GB+ RAM
- 10GB+ 磁盘空间

### 一键部署

#### Linux/Mac:
```bash
chmod +x deploy.sh
./deploy.sh
```

#### Windows:
```batch
deploy.bat
```

### 手动部署

1. **克隆项目**
```bash
git clone https://github.com/yourusername/enterprise-mail-pro.git
cd enterprise-mail-pro
```

2. **配置环境变量**
```bash
cp .env.example .env
# 编辑 .env 文件，修改数据库密码等配置
```

3. **启动服务**
```bash
docker-compose up -d
```

4. **访问系统**
- Web界面：http://localhost
- API文档：http://localhost:8080/api/swagger-ui.html

## 🔧 配置说明

### 邮件服务器端口
| 服务 | 标准端口 | SSL端口 |
|------|---------|---------|
| SMTP | 25      | 465     |
| IMAP | 143     | 993     |
| POP3 | 110     | 995     |

### 默认账号
- 用户名：admin
- 密码：admin123456
- 邮箱：admin@enterprise.mail

## 📝 API 接口

### 认证接口
- POST `/api/auth/login` - 用户登录
- POST `/api/auth/register` - 用户注册
- POST `/api/auth/refresh` - 刷新令牌
- POST `/api/auth/logout` - 退出登录

### 邮件接口
- GET `/api/emails` - 获取邮件列表
- GET `/api/emails/{id}` - 获取邮件详情
- POST `/api/emails/send` - 发送邮件
- DELETE `/api/emails/{id}` - 删除邮件
- PUT `/api/emails/{id}/read` - 标记已读
- PUT `/api/emails/{id}/star` - 标记星标

### 别名管理
- GET `/api/aliases` - 获取别名列表
- POST `/api/aliases` - 创建别名
- PUT `/api/aliases/{id}` - 更新别名
- DELETE `/api/aliases/{id}` - 删除别名

### 域名管理
- GET `/api/domains` - 获取域名列表
- POST `/api/domains` - 添加域名
- PUT `/api/domains/{id}` - 更新域名
- DELETE `/api/domains/{id}` - 删除域名

## 🔒 安全配置

### SSL/TLS 配置
1. 将SSL证书放置在 `nginx/ssl` 目录
2. 修改 `nginx/nginx.conf` 配置文件
3. 重启前端服务

### DKIM 配置
1. 生成DKIM密钥对
2. 在域名DNS添加DKIM记录
3. 在系统设置中配置DKIM

### SPF 配置
添加DNS TXT记录：
```
v=spf1 ip4:YOUR_SERVER_IP ~all
```

### DMARC 配置
添加DNS TXT记录：
```
v=DMARC1; p=quarantine; rua=mailto:admin@yourdomain.com
```

## 🛠️ 开发指南

### 后端开发

```bash
cd backend
mvn clean install
mvn spring-boot:run
```

### 前端开发

```bash
cd frontend
npm install
npm run dev
```

### 数据库迁移

```sql
-- 连接到MySQL
mysql -h localhost -P 3306 -u root -p

-- 执行初始化脚本
source backend/src/main/resources/init.sql
```

## 📊 监控和日志

### 查看日志
```bash
# 所有服务日志
docker-compose logs -f

# 特定服务日志
docker-compose logs -f backend
docker-compose logs -f frontend
```

### 健康检查
- 后端健康检查：http://localhost:8080/api/actuator/health
- 前端健康检查：http://localhost/health

## 🚨 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   # 修改 docker-compose.yml 中的端口映射
   # 或停止占用端口的服务
   ```

2. **数据库连接失败**
   ```bash
   # 检查MySQL服务状态
   docker-compose ps mysql
   
   # 查看MySQL日志
   docker-compose logs mysql
   ```

3. **邮件发送失败**
   - 检查SMTP配置
   - 确认防火墙规则
   - 验证DNS设置

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📧 联系方式

- 邮箱：support@enterprise.mail
- 官网：https://enterprise.mail

---

**注意**：这是一个用于学习和开发的项目，生产环境使用前请进行充分的安全审计和性能测试。