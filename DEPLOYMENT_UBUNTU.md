# 🚀 Ubuntu服务器部署指南

## 快速部署步骤

### 1. 下载项目
```bash
# 如果还没有下载
git clone <your-repo-url> enterprise-mail-pro
cd enterprise-mail-pro
```

### 2. 给脚本执行权限
```bash
chmod +x docker-deploy.sh
chmod +x super-check.sh
chmod +x quick-start.sh
```

### 3. 运行部署脚本
```bash
./docker-deploy.sh
```

选择选项1进行完整构建和部署。

## 如果构建失败的解决方案

### 方案A: 分步构建

1. **先启动数据库服务**
```bash
docker compose -f docker-compose.prod.yml up -d mysql redis
```

2. **单独构建后端**
```bash
cd backend
docker build -t mail-backend .
cd ..
```

3. **单独构建前端**
```bash
cd frontend
docker build -f Dockerfile.simple -t mail-frontend .
cd ..
```

4. **启动所有服务**
```bash
docker compose -f docker-compose.prod.yml up -d
```

### 方案B: 使用预构建镜像

如果构建一直失败，可以直接使用官方镜像运行服务：

1. **只运行MySQL和Redis**
```bash
# 创建docker-compose.minimal.yml
cat > docker-compose.minimal.yml << 'EOF'
services:
  mysql:
    image: mysql:8.0
    container_name: mail-mysql
    environment:
      MYSQL_ROOT_PASSWORD: root123456
      MYSQL_DATABASE: mail_system
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    restart: always

  redis:
    image: redis:7-alpine
    container_name: mail-redis
    ports:
      - "6379:6379"
    command: redis-server --requirepass redis123456
    restart: always

volumes:
  mysql_data:
  redis_data:
EOF

docker compose -f docker-compose.minimal.yml up -d
```

2. **本地运行应用（开发模式）**
```bash
# 后端
cd backend
./mvnw spring-boot:run &

# 前端
cd frontend
npm install
npm run dev
```

## 常见问题解决

### 1. npm install失败
```bash
# 清理npm缓存
npm cache clean --force

# 使用淘宝镜像
npm config set registry https://registry.npmmirror.com

# 强制安装
npm install --force
```

### 2. Maven构建失败
```bash
# 清理Maven缓存
cd backend
./mvnw clean
./mvnw dependency:purge-local-repository

# 重新构建
./mvnw clean package -DskipTests
```

### 3. 端口被占用
```bash
# 查看占用端口的进程
sudo lsof -i :80
sudo lsof -i :8080
sudo lsof -i :3306

# 停止占用的服务或修改端口
```

### 4. Docker磁盘空间不足
```bash
# 清理Docker
docker system prune -a --volumes
```

## 验证部署

### 检查服务状态
```bash
# 查看容器状态
docker ps

# 查看日志
docker compose -f docker-compose.prod.yml logs -f

# 测试API
curl http://localhost:8080/api/actuator/health

# 测试前端
curl http://localhost
```

### 默认访问信息
- 前端: http://localhost
- 后端API: http://localhost:8080/api
- 默认账号: admin@enterprise.mail / Admin@123

## 生产环境配置

### 1. 修改密码
编辑 `.env` 文件，修改所有默认密码

### 2. 配置域名和SSL
```bash
# 安装Nginx作为反向代理
sudo apt install nginx

# 配置SSL证书（使用Let's Encrypt）
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

### 3. 配置防火墙
```bash
# 开放必要端口
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 25/tcp   # SMTP
sudo ufw allow 143/tcp  # IMAP
sudo ufw allow 110/tcp  # POP3
```

## 监控和维护

### 查看日志
```bash
# 所有服务日志
docker compose -f docker-compose.prod.yml logs -f

# 特定服务日志
docker logs mail-backend -f
docker logs mail-frontend -f
docker logs mail-mysql -f
```

### 备份数据
```bash
# 备份MySQL
docker exec mail-mysql mysqldump -u root -proot123456 mail_system > backup.sql

# 备份整个数据卷
docker run --rm -v mail_mysql_data:/data -v $(pwd):/backup alpine tar czf /backup/mysql_backup.tar.gz /data
```

### 更新系统
```bash
# 拉取最新代码
git pull

# 重新构建
./docker-deploy.sh
```

## 技术支持

如遇问题，请检查：
1. 运行 `./super-check.sh` 进行系统检查
2. 查看 `SUPER_CHECK_REPORT.md` 了解系统状态
3. 查看容器日志定位问题

---
祝部署顺利！🎉