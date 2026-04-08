# 部署指南

本文档介绍如何将 consultant 项目部署到 CloudBase CloudRun。

## 部署前准备

### 1. 确认 CloudBase 环境

- 环境ID: `yun123-8gsbq6ix06c2416b`
- 区域: `ap-shanghai` (上海)
- 状态: ✅ 已连接

### 2. 检查项目配置

确保以下配置项已正确设置：

#### application.yml 配置

```yaml
# CloudBase 配置
cloudbase:
  env-id: yun123-8gsbq6ix06c2416b
  api-key: your-api-key-here  # ⚠️ 需要替换为实际值
```

#### Redis 和数据库配置

当前项目使用本地 Redis 和 MySQL，部署到云端后需要：

1. **Redis**：使用 CloudBase Redis 或云托管 Redis
2. **MySQL**：使用 CloudBase MySQL（已配置）

### 3. 获取 API Key

访问 [CloudBase 控制台 - Token 管理](https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b#/identity/token-management) 获取 API Key。

## 部署步骤

### 方式一：使用 CloudBase CloudRun 自动部署（推荐）

使用 CloudBase CloudRun 工具自动部署，工具会自动构建 Docker 镜像并部署。

#### 步骤 1: 构建项目

```bash
cd e:/yuerufeng_heimadianping/consultant
mvn clean package -DskipTests
```

#### 步骤 2: 部署到 CloudRun

使用 `manageCloudRun` 工具部署：

```bash
# 部署配置说明
# - serverName: 服务名称（如 consultant-service）
# - serverType: container（容器模式）
# - targetPath: 项目根目录的绝对路径
# - serverConfig: 服务配置
#   - Cpu: CPU 核数（0.25, 0.5, 1, 2, 4, 8）
#   - Mem: 内存（必须是 CPU 的 2 倍，如 0.5, 1, 2, 4, 8, 16）
#   - MinNum: 最小实例数（0 表示可缩容到 0，节省费用）
#   - MaxNum: 最大实例数（自动扩容上限）
#   - Port: 服务端口（默认 8080）
#   - EnvParams: 环境变量（JSON 字符串格式）
```

**部署命令将通过工具执行**，配置如下：

```json
{
  "action": "deploy",
  "serverName": "consultant-service",
  "serverType": "container",
  "targetPath": "e:/yuerufeng_heimadianping/consultant",
  "serverConfig": {
    "Cpu": 0.5,
    "Mem": 1,
    "MinNum": 1,
    "MaxNum": 5,
    "Port": 8080,
    "OpenAccessTypes": ["PUBLIC"],
    "EnvParams": "{\"SPRING_PROFILES_ACTIVE\":\"prod\",\"CLOUDBASE_ENV_ID\":\"yun123-8gsbq6ix06c2416b\"}"
  }
}
```

### 方式二：手动部署

#### 步骤 1: 本地构建 Docker 镜像

```bash
cd e:/yuerufeng_heimadianping/consultant
docker build -t consultant:latest .
```

#### 步骤 2: 测试本地镜像

```bash
docker run -p 8080:8080 consultant:latest
```

访问 http://localhost:8080/actuator/health 检查健康状态。

#### 步骤 3: 推送镜像到镜像仓库

```bash
# 登录腾讯云镜像仓库
docker login ccr.ccs.tencentyun.com

# 标记镜像
docker tag consultant:latest ccr.ccs.tencentyun.com/your-namespace/consultant:latest

# 推送镜像
docker push ccr.ccs.tencentyun.com/your-namespace/consultant:latest
```

#### 步骤 4: 在 CloudBase 控制台创建 CloudRun 服务

1. 访问 [CloudBase CloudRun 控制台](https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b#/platform-run)
2. 点击"新建服务"
3. 配置服务：
   - 服务名称: `consultant-service`
   - 镜像: `ccr.ccs.tencentyun.com/your-namespace/consultant:latest`
   - CPU: 0.5 核
   - 内存: 1 GB
   - 最小实例数: 1
   - 最大实例数: 5
   - 端口: 8080
   - 访问类型: 公网访问
4. 点击"部署"

## 部署配置说明

### 资源配置

| 配置项 | 推荐值 | 说明 |
|--------|--------|------|
| CPU | 0.5 核 | 适合中小流量应用 |
| 内存 | 1 GB | 必须是 CPU 的 2 倍 |
| 最小实例数 | 1 | 保持至少 1 个实例运行，避免冷启动 |
| 最大实例数 | 5 | 自动扩容上限 |

### 访问类型

- **PUBLIC**: 公网访问（推荐用于 Web 应用）
- **PRIVATE**: 私有网络访问（仅云开发内部）
- **VPC**: VPC 内网访问
- **MINIAPP**: 小程序访问

### 环境变量

建议通过环境变量配置敏感信息：

```yaml
EnvParams: |
  {
    "SPRING_PROFILES_ACTIVE": "prod",
    "CLOUDBASE_ENV_ID": "yun123-8gsbq6ix06c2416b",
    "CLOUDBASE_API_KEY": "your-api-key",
    "REDIS_HOST": "your-redis-host",
    "REDIS_PORT": "6379",
    "REDIS_PASSWORD": "your-redis-password"
  }
```

## 部署后验证

### 1. 检查服务状态

访问 CloudBase CloudRun 控制台查看服务状态。

### 2. 访问健康检查端点

```bash
# 获取服务访问地址后测试
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

### 3. 测试主要功能

```bash
# 测试聊天接口
curl https://your-service-domain/chat?memoryId=test&message=你好
```

### 4. 查看 CloudRun 日志

访问 [CloudBase 日志控制台](https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b#/devops/log) 查看应用日志。

## 常见问题

### 1. 部署失败

**问题**: 镜像构建失败或部署超时

**解决方案**:
- 检查 Dockerfile 是否正确
- 确认网络连接正常
- 查看构建日志了解详细错误信息

### 2. 健康检查失败

**问题**: 健康检查一直失败

**解决方案**:
- 确认应用监听的端口是 `PORT` 环境变量指定的端口
- 检查健康检查端点 `/actuator/health` 是否可访问
- 增加 `start-period` 参数（启动宽限期）

### 3. 应用启动慢

**问题**: 冷启动时间过长

**解决方案**:
- 将 `MinNum` 设置为 1，保持至少 1 个实例运行
- 优化应用启动时间（减少依赖初始化）
- 增加资源配置（CPU/内存）

### 4. 内存溢出

**问题**: OutOfMemoryError

**解决方案**:
- 增加内存配置（Mem = 2 × CPU）
- 优化应用内存使用
- 设置 JVM 参数：`-XX:MaxRAMPercentage=75.0`

### 5. 无法连接数据库

**问题**: 应用无法连接 CloudBase MySQL

**解决方案**:
- 确认数据库连接信息正确
- 检查网络访问权限
- 确认数据库安全规则允许 CloudRun 访问

## 性能优化建议

### 1. 减少镜像体积

- 使用多阶段构建（已实现）
- 使用 Alpine 基础镜像（已实现）
- 清理不必要的依赖和文件

### 2. 优化启动时间

- 延迟加载非关键组件
- 减少应用初始化逻辑
- 使用 Spring Boot 的延迟初始化

### 3. 配置自动扩缩容

```json
{
  "PolicyDetails": [
    {
      "PolicyType": "cpu",
      "PolicyThreshold": 60
    },
    {
      "PolicyType": "mem",
      "PolicyThreshold": 70
    }
  ]
}
```

### 4. 监控和告警

- 配置 CloudBase 监控
- 设置 CPU、内存、响应时间告警
- 定期查看日志分析问题

## 费用说明

CloudRun 按量计费：

- **CPU**: ¥0.000111/核/秒（约 ¥0.4/核/小时）
- **内存**: ¥0.0000556/GB/秒（约 ¥0.2/GB/小时）
- **网络流量**: ¥0.5/GB（出网流量）

**示例配置费用**（0.5核 + 1GB，最小1实例）：
- 每小时: ¥0.2 × 1 + ¥0.4 × 0.5 = ¥0.4
- 每天: ¥0.4 × 24 = ¥9.6
- 每月: ¥9.6 × 30 = ¥288

注意：实例数扩容时费用会相应增加。

## 回滚策略

如果新版本部署出现问题：

1. 在 CloudBase 控制台找到服务
2. 点击"版本管理"
3. 选择之前的稳定版本
4. 点击"回滚"

## 相关链接

- [CloudBase CloudRun 文档](https://docs.cloudbase.net/cloud-run/intro)
- [CloudBase 控制台](https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b)
- [Spring Boot Docker 部署指南](https://docs.spring.io/spring-boot/docs/current/reference/html/docker.html)
