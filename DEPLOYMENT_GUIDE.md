# 部署和使用指南

## 目录结构说明

```
F:/project/enterprise-mail-pro/
├── backend/                    # 后端 Spring Boot 项目
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/          # Java源代码
│   │   │   │   └── com/enterprise/mail/
│   │   │   │       ├── config/        # 配置类
│   │   │   │       ├── controller/    # 控制器
│   │   │   │       ├── dto/          # 数据传输对象
│   │   │   │       ├── entity/       # 实体类
│   │   │   │       ├── repository/   # 数据访问层
│   │   │   │       ├── security/     # 安全相关
│   │   │   │       ├── service/      # 业务逻辑层
│   │   │   │       └── util/         # 工具类
│   │   │   └── resources/
│   │   │       ├── application.yml   # 应用配置
│   │   │       └── init.sql         # 数据库初始化脚本
│   │   └── test/              # 测试代码
│   ├── pom.xml                # Maven配置
│   └── Dockerfile             # Docker构建文件
│
├── frontend/                   # 前端 Vue 3 项目
│   ├── src/
│   │   ├── api/               # API接口
│   │   ├── assets/            # 静态资源
│   │   ├── components/        # 组件
│   │   ├── layouts/           # 布局
│   │   ├── router/            # 路由
│   │   ├── stores/            # 状态管理
│   │   ├── styles/            # 样式
│   │   ├── types/             # TypeScript类型
│   │   ├── utils/             # 工具函数
│   │   ├── views/             # 页面视图
│   │   ├── App.vue            # 根组件
│   │   └── main.ts            # 入口文件
│   ├── package.json           # Node依赖配置
│   ├── vite.config.ts         # Vite配置
│   ├── tsconfig.json          # TypeScript配置
│   └── Dockerfile             # Docker构建文件
│
├── docker/                     # Docker相关文件
├── nginx/                      # Nginx配置
├── scripts/                    # 脚本文件
├── docs/                       # 文档
├── docker-compose.yml          # Docker Compose配置
├── deploy.sh                   # Linux/Mac部署脚本
├── deploy.bat                  # Windows部署脚本
├── test.sh                     # Linux/Mac测试脚本
├── test.bat                    # Windows测试脚本
└── README.md                   # 项目说明

```

## 快速部署步骤

### 1. 系统准备

#### Windows系统：
1. 安装 Docker Desktop for Windows
2. 启动 Docker Desktop
3. 确保 Docker 正在运行

#### Linux/Mac系统：
1. 安装 Docker 和 Docker Compose
2. 启动 Docker 服务

### 2. 部署项目

#### Windows：
```batch
cd F:\project\enterprise-mail-pro
deploy.bat
```

#### Linux/Mac：
```bash
cd /path/to/enterprise-mail-pro
chmod +x deploy.sh
./deploy.sh
```

### 3. 验证部署

运行测试脚本验证所有服务是否正常：

#### Windows：
```batch
test.bat
```

#### Linux/Mac：
```bash
chmod +x test.sh
./test.sh
```

## 访问系统

### Web界面
- 地址：http://localhost
- 默认管理员账号：
  - 用户名：admin
  - 密码：admin123456

### API文档
- Swagger UI：http://localhost:8080/api/swagger-ui.html
- API Docs：http://localhost:8080/api/v3/api-docs

## 邮件客户端配置

### 配置 Outlook/Thunderbird

#### SMTP设置（发送邮件）：
- 服务器：localhost 或 您的服务器IP
- 端口：25（标准）或 465（SSL）
- 安全性：STARTTLS 或 SSL/TLS
- 认证：需要
- 用户名：您的邮箱地址
- 密码：您的邮箱密码

#### IMAP设置（接收邮件）：
- 服务器：localhost 或 您的服务器IP
- 端口：143（标准）或 993（SSL）
- 安全性：STARTTLS 或 SSL/TLS
- 认证：需要
- 用户名：您的邮箱地址
- 密码：您的邮箱密码

#### POP3设置（接收邮件）：
- 服务器：localhost 或 您的服务器IP
- 端口：110（标准）或 995（SSL）
- 安全性：STARTTLS 或 SSL/TLS
- 认证：需要
- 用户名：您的邮箱地址
- 密码：您的邮箱密码

## 常用命令

### Docker相关

```bash
# 查看所有容器状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f mysql
docker-compose logs -f redis

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 停止并删除所有数据
docker-compose down -v

# 进入容器
docker exec -it mail-backend bash
docker exec -it mail-mysql mysql -u root -p
docker exec -it mail-redis redis-cli
```

### 数据库管理

```sql
-- 连接数据库
mysql -h localhost -P 3306 -u mailuser -pmail123456 mail_system

-- 查看用户
SELECT * FROM users;

-- 查看邮件
SELECT * FROM emails;

-- 查看域名
SELECT * FROM domains;

-- 查看别名
SELECT * FROM email_aliases;
```

## 故障排除

### 1. 端口被占用

错误信息：`bind: address already in use`

解决方法：
- 修改 `docker-compose.yml` 中的端口映射
- 或停止占用端口的服务

### 2. 数据库连接失败

错误信息：`Connection refused`

解决方法：
```bash
# 检查MySQL容器状态
docker-compose ps mysql

# 查看MySQL日志
docker-compose logs mysql

# 重启MySQL服务
docker-compose restart mysql
```

### 3. 前端无法访问后端API

检查步骤：
1. 确认后端服务正在运行
2. 检查防火墙设置
3. 查看nginx配置是否正确

### 4. 邮件发送失败

检查步骤：
1. 确认SMTP服务正在运行
2. 检查防火墙是否开放25端口
3. 查看邮件服务日志

## 性能优化建议

### 1. 数据库优化
- 定期清理过期邮件
- 为大表添加适当的索引
- 调整MySQL缓冲区大小

### 2. Redis优化
- 设置合理的过期时间
- 使用持久化策略
- 调整最大内存限制

### 3. 应用优化
- 启用Gzip压缩
- 配置CDN加速
- 使用负载均衡

## 安全建议

1. **修改默认密码**
   - 立即修改admin账户密码
   - 修改数据库密码
   - 修改JWT密钥

2. **配置SSL证书**
   - 为Web界面配置HTTPS
   - 为邮件服务配置SSL/TLS

3. **配置防火墙**
   - 仅开放必要的端口
   - 限制访问IP地址

4. **定期备份**
   - 备份数据库
   - 备份邮件存储
   - 备份配置文件

## 支持与帮助

如遇到问题，请：
1. 查看日志文件
2. 查阅本文档
3. 提交Issue到项目仓库

---

祝您使用愉快！