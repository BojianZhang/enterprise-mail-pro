# 🚀 快速启动指南

## 一、环境准备

### Windows 用户

1. **安装 Docker Desktop**
   - 下载地址：https://www.docker.com/products/docker-desktop
   - 安装后确保 Docker Desktop 正在运行

2. **检查安装**
   ```batch
   docker --version
   docker-compose --version
   ```

### Linux/Mac 用户

1. **安装 Docker**
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install docker.io docker-compose
   
   # CentOS/RHEL
   sudo yum install docker docker-compose
   
   # Mac
   brew install docker docker-compose
   ```

2. **启动 Docker 服务**
   ```bash
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

## 二、快速启动

### 方法一：一键部署（推荐）

#### Windows:
```batch
cd F:\project\enterprise-mail-pro
deploy.bat
```

#### Linux/Mac:
```bash
cd /path/to/enterprise-mail-pro
chmod +x deploy.sh
./deploy.sh
```

### 方法二：手动部署

1. **创建环境配置文件**
   ```bash
   cp .env.example .env
   # 编辑 .env 文件，修改必要的配置
   ```

2. **构建并启动服务**
   ```bash
   # 构建镜像
   docker-compose build
   
   # 启动服务
   docker-compose up -d
   
   # 查看服务状态
   docker-compose ps
   ```

3. **初始化数据库**
   ```bash
   # 数据库会自动初始化，如需手动执行：
   docker exec -i mail-mysql mysql -u root -proot123456 mail_system < backend/src/main/resources/init.sql
   ```

## 三、验证服务

### 运行测试脚本

#### Windows:
```batch
test.bat
```

#### Linux/Mac:
```bash
chmod +x test.sh
./test.sh
```

### 手动验证

1. **访问Web界面**
   - 打开浏览器访问：http://localhost
   - 使用默认账号登录：
     - 用户名：admin
     - 密码：admin123456

2. **检查API文档**
   - Swagger UI：http://localhost:8080/api/swagger-ui.html

3. **检查服务健康状态**
   ```bash
   # 后端健康检查
   curl http://localhost:8080/api/actuator/health
   
   # 前端健康检查
   curl http://localhost/health
   ```

## 四、常见问题解决

### 1. Docker 未启动

**错误信息：**
```
Cannot connect to the Docker daemon
```

**解决方法：**
- Windows: 启动 Docker Desktop
- Linux: `sudo systemctl start docker`

### 2. 端口被占用

**错误信息：**
```
bind: address already in use
```

**解决方法：**

查找占用端口的进程：
```bash
# Windows
netstat -ano | findstr :8080

# Linux/Mac
lsof -i :8080
```

修改端口或停止占用的服务。

### 3. 数据库连接失败

**错误信息：**
```
Connection refused: connect
```

**解决方法：**

1. 检查MySQL容器状态：
   ```bash
   docker-compose ps mysql
   docker-compose logs mysql
   ```

2. 重启MySQL服务：
   ```bash
   docker-compose restart mysql
   ```

3. 验证连接：
   ```bash
   docker exec -it mail-mysql mysql -u root -proot123456 -e "SELECT 1"
   ```

### 4. 前端无法访问

**解决方法：**

1. 检查前端容器：
   ```bash
   docker-compose ps frontend
   docker-compose logs frontend
   ```

2. 检查nginx配置：
   ```bash
   docker exec -it mail-frontend nginx -t
   ```

3. 重启前端服务：
   ```bash
   docker-compose restart frontend
   ```

## 五、服务管理命令

### 查看服务状态
```bash
docker-compose ps
```

### 查看日志
```bash
# 所有服务
docker-compose logs -f

# 特定服务
docker-compose logs -f backend
docker-compose logs -f mysql
```

### 重启服务
```bash
# 重启所有服务
docker-compose restart

# 重启特定服务
docker-compose restart backend
```

### 停止服务
```bash
docker-compose stop
```

### 停止并删除容器
```bash
docker-compose down
```

### 停止并删除所有数据
```bash
docker-compose down -v
```

## 六、配置邮件客户端

### Outlook 配置

1. **添加账户**
   - 文件 → 添加账户
   - 选择"手动配置"

2. **IMAP设置**
   - 接收邮件服务器：localhost
   - 端口：143
   - 加密方法：无
   - 发送邮件服务器：localhost
   - 端口：25
   - 加密方法：无

3. **登录信息**
   - 用户名：admin@enterprise.mail
   - 密码：admin123456

### Thunderbird 配置

类似Outlook，使用相同的服务器设置。

## 七、生产环境部署

### 1. 修改配置

编辑 `.env` 文件：
```env
# 修改密码
MYSQL_ROOT_PASSWORD=<strong_password>
JWT_SECRET=<random_secret_key>
MAIL_ADMIN_PASSWORD=<admin_password>

# 配置域名
MAIL_DOMAIN=yourdomain.com
```

### 2. 配置SSL

1. 获取SSL证书
2. 将证书放置在 `nginx/ssl/` 目录
3. 修改nginx配置启用HTTPS

### 3. 配置防火墙

```bash
# 开放必要端口
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 25/tcp    # SMTP
sudo ufw allow 465/tcp   # SMTP SSL
sudo ufw allow 143/tcp   # IMAP
sudo ufw allow 993/tcp   # IMAP SSL
sudo ufw allow 110/tcp   # POP3
sudo ufw allow 995/tcp   # POP3 SSL
```

### 4. 配置DNS

在域名DNS管理中添加：

```
MX记录：
@ MX 10 mail.yourdomain.com

A记录：
mail A your.server.ip

TXT记录（SPF）：
@ TXT "v=spf1 ip4:your.server.ip ~all"
```

## 八、性能监控

### 查看资源使用
```bash
docker stats
```

### 查看容器日志大小
```bash
docker ps -s
```

### 清理未使用的资源
```bash
docker system prune -a
```

## 九、备份与恢复

### 备份数据库
```bash
docker exec mail-mysql mysqldump -u root -proot123456 mail_system > backup.sql
```

### 恢复数据库
```bash
docker exec -i mail-mysql mysql -u root -proot123456 mail_system < backup.sql
```

### 备份邮件数据
```bash
docker run --rm -v enterprise-mail-pro_mail_data:/data -v $(pwd):/backup alpine tar czf /backup/mail_backup.tar.gz /data
```

## 十、获取帮助

如果遇到其他问题：

1. 查看详细日志：`docker-compose logs -f --tail=100`
2. 查看容器内部：`docker exec -it <container_name> bash`
3. 查阅项目文档：`DEPLOYMENT_GUIDE.md`
4. 提交Issue：在项目仓库提交问题

---

**提示：** 首次启动可能需要几分钟时间来下载镜像和初始化服务，请耐心等待。