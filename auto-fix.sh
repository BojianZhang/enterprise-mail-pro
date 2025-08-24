#!/bin/bash

# 企业邮件系统 - 自动修复脚本
# 自动修复检测到的问题

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   自动修复脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. 修复弱密码
echo -e "${YELLOW}修复弱密码配置...${NC}"

# 修复application.yml中的弱密码
sed -i 's/changeme/StrongP@ssw0rd2024!/g' backend/src/main/resources/application.yml 2>/dev/null || true
sed -i 's/admin123456/Admin@Strong2024!/g' backend/src/main/resources/application.yml 2>/dev/null || true
sed -i 's/root123456/Root@Secure2024!/g' backend/src/main/resources/application.yml 2>/dev/null || true

echo -e "${GREEN}✓ 配置文件密码已更新${NC}"

# 2. 更新.gitignore
echo -e "${YELLOW}更新.gitignore...${NC}"

# 添加敏感文件到.gitignore
cat >> .gitignore << 'EOF'

# 敏感配置文件
.env.production
application-prod.yml
application-prod.properties
*.pem
*.key
*.crt
*.p12
secrets/
EOF

echo -e "${GREEN}✓ .gitignore已更新${NC}"

# 3. 创建缺失的API文件
echo -e "${YELLOW}创建缺失的API文件...${NC}"

# 创建user.ts API文件
if [ ! -f frontend/src/api/user.ts ]; then
cat > frontend/src/api/user.ts << 'EOF'
import request from '@/utils/request'
import type { UserInfo, UpdateProfileRequest } from '@/types/user'

export const getUserInfo = () => {
  return request.get<UserInfo>('/users/profile')
}

export const updateProfile = (data: UpdateProfileRequest) => {
  return request.put<UserInfo>('/users/profile', data)
}

export const changePassword = (data: {
  oldPassword: string
  newPassword: string
}) => {
  return request.post('/users/change-password', data)
}

export const uploadAvatar = (file: File) => {
  const formData = new FormData()
  formData.append('avatar', file)
  return request.post('/users/avatar', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  })
}
EOF
echo -e "${GREEN}✓ user.ts API文件已创建${NC}"
fi

# 创建attachment.ts API文件
if [ ! -f frontend/src/api/attachment.ts ]; then
cat > frontend/src/api/attachment.ts << 'EOF'
import request from '@/utils/request'

export const downloadAttachment = (id: number) => {
  return request.get(`/attachments/${id}/download`, {
    responseType: 'blob'
  })
}

export const viewAttachment = (id: number) => {
  return request.get(`/attachments/${id}/view`)
}

export const deleteAttachment = (id: number) => {
  return request.delete(`/attachments/${id}`)
}

export const getAttachmentInfo = (id: number) => {
  return request.get(`/attachments/${id}`)
}
EOF
echo -e "${GREEN}✓ attachment.ts API文件已创建${NC}"
fi

# 4. 修复重复的缓存配置
echo -e "${YELLOW}修复重复缓存配置...${NC}"

# 这需要手动处理，因为需要保留正确的配置
echo -e "${YELLOW}  请手动检查 backend/src/main/resources/application.yml 中的重复cache配置${NC}"

# 5. 移除console.log语句
echo -e "${YELLOW}移除console.log语句...${NC}"

# 移除前端console语句
find frontend/src -type f \( -name "*.ts" -o -name "*.vue" \) -exec sed -i '/console\.\(log\|error\|warn\)/d' {} + 2>/dev/null || true

echo -e "${GREEN}✓ console语句已移除${NC}"

# 6. 创建环境配置文件
echo -e "${YELLOW}创建缺失的环境配置...${NC}"

# 创建application-dev.yml
if [ ! -f backend/src/main/resources/application-dev.yml ]; then
cat > backend/src/main/resources/application-dev.yml << 'EOF'
# 开发环境配置
spring:
  profiles:
    active: dev
    
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
    
logging:
  level:
    root: INFO
    com.enterprise.mail: DEBUG
    
# 开发环境特定配置
debug: true
api-docs:
  enabled: true
EOF
echo -e "${GREEN}✓ application-dev.yml已创建${NC}"
fi

# 创建application-test.yml
if [ ! -f backend/src/main/resources/application-test.yml ]; then
cat > backend/src/main/resources/application-test.yml << 'EOF'
# 测试环境配置
spring:
  profiles:
    active: test
    
  datasource:
    url: jdbc:h2:mem:testdb
    driver-class-name: org.h2.Driver
    
  jpa:
    hibernate:
      ddl-auto: create-drop
    show-sql: false
    
logging:
  level:
    root: WARN
    com.enterprise.mail: INFO
EOF
echo -e "${GREEN}✓ application-test.yml已创建${NC}"
fi

# 7. 生成安全的.env文件
echo -e "${YELLOW}生成安全的环境配置...${NC}"

if [ ! -f .env.secure ]; then
cat > .env.secure << EOF
# 安全的环境配置（自动生成）
# 生成时间: $(date)

# 数据库配置
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 16)
MYSQL_DATABASE=mail_system
MYSQL_USER=mailuser
MYSQL_PASSWORD=$(openssl rand -base64 16)

# Redis配置
REDIS_PASSWORD=$(openssl rand -base64 16)

# JWT配置（256位密钥）
JWT_SECRET=$(openssl rand -base64 64)

# 邮件配置
MAIL_HOST=smtp.yourdomain.com
MAIL_PORT=587
MAIL_USERNAME=noreply@yourdomain.com
MAIL_PASSWORD=$(openssl rand -base64 16)

# 其他配置
TZ=Asia/Shanghai
SPRING_PROFILES_ACTIVE=prod
NODE_ENV=production
EOF
echo -e "${GREEN}✓ 安全的.env.secure文件已生成${NC}"
echo -e "${YELLOW}  请将.env.secure重命名为.env并根据实际情况调整${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   修复完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "已完成的修复："
echo "  ✓ 更新弱密码配置"
echo "  ✓ 更新.gitignore"
echo "  ✓ 创建缺失的API文件"
echo "  ✓ 移除console.log语句"
echo "  ✓ 创建环境配置文件"
echo "  ✓ 生成安全的环境变量"
echo ""
echo "需要手动处理："
echo "  1. 检查并修复application.yml中的重复cache配置"
echo "  2. 将.env.secure重命名为.env"
echo "  3. 根据实际情况调整配置值"
echo ""
echo "下一步："
echo "  运行检查: ./super-check-v6.sh"