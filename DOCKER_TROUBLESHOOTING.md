# Docker 构建和部署故障排除指南

## 常见问题和解决方案

### 1. Docker Hub 连接问题

**错误信息:**
```
failed to fetch oauth token: Post "https://auth.docker.io/token": dial tcp...
```

**解决方案:**

#### 方案 A: 使用国内镜像源

编辑 Docker 配置文件:

**Linux:**
```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
}
EOF
sudo systemctl restart docker
```

**Windows (Docker Desktop):**
1. 打开 Docker Desktop 设置
2. 进入 Docker Engine 选项
3. 添加镜像配置:
```json
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}
```
4. 点击 Apply & Restart

#### 方案 B: 使用代理

设置 Docker 代理:
```bash
# Linux
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=http://your-proxy:port"
Environment="HTTPS_PROXY=http://your-proxy:port"
Environment="NO_PROXY=localhost,127.0.0.1"
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

#### 方案 C: 本地运行（不使用 Docker）

使用本地运行脚本:
```bash
./run-local.sh
```

### 2. Maven 依赖下载失败

**解决方案:**

配置 Maven 国内镜像:
```xml
<!-- ~/.m2/settings.xml -->
<settings>
  <mirrors>
    <mirror>
      <id>aliyun</id>
      <mirrorOf>central</mirrorOf>
      <name>Aliyun Maven Mirror</name>
      <url>https://maven.aliyun.com/repository/public</url>
    </mirror>
  </mirrors>
</settings>
```

### 3. NPM 依赖安装失败

**解决方案:**

使用淘宝镜像:
```bash
npm config set registry https://registry.npmmirror.com
```

### 4. 端口被占用

**错误信息:**
```
bind: address already in use
```

**解决方案:**

查找并停止占用端口的进程:

**Linux/Mac:**
```bash
# 查看端口占用
lsof -i:8080
lsof -i:3306
lsof -i:80

# 停止进程
kill -9 <PID>
```

**Windows:**
```cmd
# 查看端口占用
netstat -ano | findstr :8080
netstat -ano | findstr :3306

# 停止进程
taskkill /PID <PID> /F
```

### 5. MySQL 连接失败

**错误信息:**
```
Access denied for user 'mailuser'@'localhost'
```

**解决方案:**

手动创建数据库和用户:
```sql
-- 登录 MySQL
mysql -u root -p

-- 创建数据库
CREATE DATABASE mail_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 创建用户
CREATE USER 'mailuser'@'localhost' IDENTIFIED BY 'mail123456';
CREATE USER 'mailuser'@'%' IDENTIFIED BY 'mail123456';

-- 授予权限
GRANT ALL PRIVILEGES ON mail_system.* TO 'mailuser'@'localhost';
GRANT ALL PRIVILEGES ON mail_system.* TO 'mailuser'@'%';

-- 刷新权限
FLUSH PRIVILEGES;
```

### 6. Docker Compose 版本问题

**错误信息:**
```
the attribute `version` is obsolete
```

**解决方案:**

这只是警告，不影响使用。如果要消除警告，删除 docker-compose.yml 第一行的 `version: '3.8'`。

### 7. 内存不足

**错误信息:**
```
Container killed due to memory limit
```

**解决方案:**

增加 Docker 内存限制:

**Docker Desktop:**
1. 打开设置
2. Resources → Advanced
3. 增加 Memory 到至少 4GB

**Linux:**
编辑 docker-compose.yml，为服务添加内存限制:
```yaml
services:
  backend:
    mem_limit: 2g
    mem_reservation: 1g
```

### 8. 构建缓存问题

**解决方案:**

清理 Docker 缓存:
```bash
# 清理所有未使用的镜像、容器、网络
docker system prune -a

# 清理构建缓存
docker builder prune

# 重新构建（不使用缓存）
docker compose build --no-cache
```

## 快速诊断脚本

创建诊断脚本 `diagnose.sh`:
```bash
#!/bin/bash
echo "=== Docker 环境诊断 ==="
echo ""

echo "1. Docker 版本:"
docker --version

echo ""
echo "2. Docker Compose 版本:"
docker compose version || docker-compose --version

echo ""
echo "3. Docker 服务状态:"
docker info > /dev/null 2>&1 && echo "运行中" || echo "未运行"

echo ""
echo "4. 网络连接测试:"
curl -I https://hub.docker.com 2>/dev/null && echo "Docker Hub 可访问" || echo "Docker Hub 不可访问"

echo ""
echo "5. 端口占用检查:"
for port in 80 443 3306 6379 8080; do
    lsof -i:$port > /dev/null 2>&1 && echo "端口 $port: 被占用" || echo "端口 $port: 可用"
done

echo ""
echo "6. 磁盘空间:"
df -h / | tail -1

echo ""
echo "7. 内存使用:"
free -h | grep Mem
```

## 替代部署方案

### 方案 1: 使用 Podman（Docker 替代品）
```bash
# 安装 Podman
sudo apt install podman

# 使用 podman-compose
pip install podman-compose
podman-compose up -d
```

### 方案 2: 使用 Kubernetes
```bash
# 转换 docker-compose 为 k8s 配置
kompose convert
kubectl apply -f .
```

### 方案 3: 手动部署
1. 安装 MySQL 8.0
2. 安装 Redis 7
3. 安装 Java 17
4. 安装 Node.js 18
5. 运行 `./run-local.sh`

## 获取帮助

如果以上方案都无法解决问题，请提供以下信息：

1. 操作系统版本
2. Docker 版本
3. 错误日志（完整）
4. `diagnose.sh` 输出结果

可以通过以下方式获取帮助：
- 查看项目 Issues
- 提交新的 Issue
- 查看 Docker 官方文档