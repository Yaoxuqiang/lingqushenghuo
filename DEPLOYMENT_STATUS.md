# 项目部署状态

## 当前状态

⚠️ **CloudRun 云托管资源未开通**

项目已完成以下准备工作：

### ✅ 已完成

1. **CloudBase 环境连接**
   - 环境ID: `yun123-8gsbq6ix06c2416b`
   - 区域: ap-shanghai (上海)
   - 状态: 正常运行

2. **Docker 镜像准备**
   - ✅ 创建了 `Dockerfile`（多阶段构建，优化镜像体积）
   - ✅ 创建了 `.dockerignore`（排除不必要文件）
   - ✅ 创建了 `.gitignore`

3. **应用配置**
   - ✅ 添加了健康检查依赖 (`spring-boot-starter-actuator`)
   - ✅ 创建了健康检查控制器 (`HealthController`)
   - ✅ 配置了 CloudBase 连接信息

4. **文档准备**
   - ✅ 创建了部署指南 (`DEPLOYMENT_GUIDE.md`)
   - ✅ 创建了 CloudBase 集成文档 (`CLOUDBASE_SETUP.md`)
   - ✅ 创建了集成总结 (`CLOUDBASE_INTEGRATION_SUMMARY.md`)

### ⚠️ 待完成

1. **开通 CloudRun 云托管服务**
   - 需要在 CloudBase 控制台开通 CloudRun 服务

2. **配置 API Key**
   - 需要在 `application.yml` 中配置实际的 CloudBase API Key

3. **数据库配置**
   - 当前使用本地 MySQL，需要配置 CloudBase MySQL
   - 当前使用本地 Redis，需要配置 Redis 连接

## 部署选项

### 选项一：在 CloudBase 控制台手动部署（推荐）

#### 步骤 1: 开通 CloudRun 服务

1. 访问 [CloudBase 控制台 - CloudRun](https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b#/platform-run)
2. 点击"开通云托管"或"新建服务"
3. 选择部署方式：通过本地代码或通过镜像

#### 步骤 2: 准备项目

```bash
# 1. 进入项目目录
cd e:/yuerufeng_heimadianping/consultant

# 2. 配置 API Key（修改 application.yml）
# 将 your-api-key-here 替换为实际值

# 3. 删除 node_modules 和 target（如果有）
rm -rf target/
```

#### 步骤 3: 上传代码部署

**方式 A: 通过本地代码包部署**

1. 在 CloudBase 控制台选择"通过本地代码"
2. 填写配置信息：
   - 代码包类型: 选择文件夹
   - 代码包: 选择项目目录 `e:/yuerufeng_heimadianping/consultant`
   - 服务名称: `consultant-service`
   - 部署类型: 容器服务型
   - 端口: 8080
   - Dockerfile 名称: Dockerfile
3. 配置资源：
   - CPU: 0.5 核
   - 内存: 1 GB
   - 最小实例数: 1
   - 最大实例数: 5
4. 配置访问：
   - 公网访问: 开启
   - 内网访问: 关闭
5. 点击"部署"

**方式 B: 通过镜像部署**

```bash
# 1. 构建镜像
cd e:/yuerufeng_heimadianping/consultant
docker build -t consultant:latest .

# 2. 登录腾讯云镜像仓库
docker login ccr.ccs.tencentyun.com

# 3. 标记镜像（需要先在腾讯云容器镜像服务创建命名空间）
docker tag consultant:latest ccr.ccs.tencentyun.com/your-namespace/consultant:latest

# 4. 推送镜像
docker push ccr.ccs.tencentyun.com/your-namespace/consultant:latest
```

然后在 CloudBase 控制台：
1. 选择"通过镜像部署"
2. 填写镜像地址: `ccr.ccs.tencentyun.com/your-namespace/consultant:latest`
3. 填写其他配置信息
4. 点击"部署"

### 选项二：本地部署

如果不想使用 CloudBase CloudRun，可以：

#### 方式 A: 本地 Docker 运行

```bash
# 构建镜像
cd e:/yuerufeng_heimadianping/consultant
docker build -t consultant:latest .

# 运行容器
docker run -d \
  -p 8080:8080 \
  --name consultant \
  -e SPRING_PROFILES_ACTIVE=prod \
  consultant:latest
```

访问: http://localhost:8080

#### 方式 B: 直接运行 JAR

```bash
# 构建项目
cd e:/yuerufeng_heimadianping/consultant
mvn clean package -DskipTests

# 运行 JAR
java -jar target/consultant-0.0.1-SNAPSHOT.jar
```

访问: http://localhost:8080

## 配置说明

### CloudBase API Key

获取地址: [CloudBase 控制台 - Token 管理](https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b#/identity/token-management)

在 `application.yml` 中配置：

```yaml
cloudbase:
  env-id: yun123-8gsbq6ix06c2416b
  api-key: your-actual-api-key  # 替换为实际值
```

### MySQL 数据库连接

如果使用 CloudBase MySQL：

1. 访问 [CloudBase MySQL 控制台](https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b#/db/mysql/table/default/)
2. 获取 MySQL 连接信息
3. 在 `application.yml` 中配置：

```yaml
spring:
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://your-mysql-host:3306/your-database?useSSL=false&serverTimezone=Asia/Shanghai
    username: your-username
    password: your-password
```

### Redis 连接

如果使用外部 Redis：

```yaml
spring:
  data:
    redis:
      host: your-redis-host
      port: 6379
      password: your-redis-password
```

## 验证部署

### 1. 健康检查

```bash
curl https://your-service-domain/actuator/health
```

预期响应：
```json
{
  "status": "UP",
  "service": "consultant",
  "timestamp": 1234567890
}
```

### 2. 测试聊天接口

```bash
curl "https://your-service-domain/chat?memoryId=test&message=你好"
```

### 3. 测试 CloudBase 连接

```bash
curl https://your-service-domain/api/cloudbase/test
```

## 常见问题

### 1. CloudRun 资源未开通

**错误**: `[CreateCloudRunServer] 云托管资源未开通`

**解决方案**:
1. 访问 [CloudBase 控制台](https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b)
2. 进入"云托管"页面
3. 点击"开通云托管"
4. 按照提示完成开通

### 2. 镜像构建失败

**错误**: Docker 构建失败

**解决方案**:
- 检查 Dockerfile 语法是否正确
- 确认 Maven 依赖可以正常下载
- 查看构建日志了解详细错误

### 3. 健康检查失败

**错误**: 容器健康检查一直失败

**解决方案**:
- 确认应用监听的端口正确（8080）
- 检查健康检查端点 `/actuator/health` 是否可访问
- 增加启动宽限期

### 4. 无法连接数据库

**错误**: 应用无法连接 CloudBase MySQL

**解决方案**:
- 确认数据库连接信息正确
- 检查网络访问权限
- 确认数据库安全规则允许 CloudRun 访问

## 相关链接

- [CloudBase 控制台](https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b)
- [CloudBase CloudRun 文档](https://docs.cloudbase.net/cloud-run/intro)
- [Spring Boot Docker 部署指南](https://docs.spring.io/spring-boot/docs/current/reference/html/docker.html)
- [CloudBase MySQL 文档](https://docs.cloudbase.net/rdb/mysql/intro)

## 下一步

1. 在 CloudBase 控制台开通 CloudRun 服务
2. 配置 API Key
3. 根据需要配置数据库连接
4. 选择一种部署方式进行部署
5. 部署完成后验证应用功能
6. 配置监控和告警

## 联系支持

如果遇到问题，可以：
- 查看 [CloudBase 文档](https://docs.cloudbase.net/)
- 提交 [工单](https://console.cloud.tencent.com/workorder)
- 联系技术支持

---

**最后更新**: 2026-03-14
**CloudBase 环境**: yun123-8gsbq6ix06c2416b
