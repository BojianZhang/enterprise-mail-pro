# 使用 Maven 构建 Spring Boot 应用
FROM maven:3.8.6-openjdk-17 AS builder

WORKDIR /app

# 复制 pom.xml 并下载依赖
COPY pom.xml .
RUN mvn dependency:go-offline -B

# 复制源代码并构建
COPY src ./src
RUN mvn clean package -DskipTests

# 运行阶段
FROM openjdk:17-jdk-slim

WORKDIR /app

# 安装必要的工具
RUN apt-get update && apt-get install -y \
    netcat \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 复制构建的 JAR 文件
COPY --from=builder /app/target/*.jar app.jar

# 创建邮件存储目录
RUN mkdir -p /var/mail/storage

# 暴露端口
EXPOSE 8080 25 465 143 993 110 995

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/api/actuator/health || exit 1

# 启动应用
ENTRYPOINT ["java", "-jar", "/app/app.jar"]