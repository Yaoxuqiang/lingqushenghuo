# Consultant - AI 顾问系统

基于 Spring Boot + LangChain4j 的智能顾问系统，支持流式对话和知识库检索。

## 项目简介

本系统是一个 AI 驱动的顾问服务，提供：
- 流式对话功能
- 知识库检索（RAG）
- 工具调用（预约、店铺、优惠券）
- CloudBase 集成
- 健康检查和监控

## 技术栈

- **后端框架**: Spring Boot 3.5.0
- **AI 框架**: LangChain4j 1.0.1-beta6
- **AI 模型**: 通义千问（Qwen Plus）
- **数据库**: MySQL（MyBatis Plus）
- **缓存**: Redis
- **向量数据库**: 内存向量存储
- **云服务**: 腾讯云 CloudBase

## 项目结构

```
consultant/
├── src/main/java/com/itheima/consultant/
│   ├── aiservice/          # AI 服务接口
│   ├── config/             # 配置类（包括 CloudBase 配置）
│   ├── client/             # CloudBase REST 客户端
│   ├── controller/         # 控制器
│   ├── mapper/             # MyBatis Mapper
│   ├── pojo/              # 实体类
│   ├── repository/         # Redis 存储实现
│   ├── service/            # 业务服务（包括 CloudBase 数据库服务）
│   └── tools/             # AI 工具
├── src/main/resources/
│   ├── application.yml      # 应用配置
│   └── content/            # 知识库文档
├── Dockerfile              # Docker 镜像构建文件
├── .dockerignore           # Docker 忽略文件
├── .gitignore             # Git 忽略文件
├── pom.xml                # Maven 配置
├── deploy.sh              # Linux/Mac 部署脚本
├── deploy.ps1             # Windows 部署脚本
└── *.md                   # 文档文件
```

## 快速开始

### 本地运行

#### 前置要求

- JDK 17+
- Maven 3.6+
- MySQL 5.7+
- Redis 3.0+

#### 配置

1. 复制并修改配置：
```yaml
# application.yml
langchain4j:
  open-ai:
    chat-model:
      api-key: your-qwen-api-key  # 配置通义千问 API Key

spring:
  data:
    redis:
      host: localhost
      port: 6379
  datasource:
    url: jdbc:mysql://localhost:3306/hmdp?useSSL=false&serverTimezone=UTC
    username: root
    password: your-password

cloudbase:
  env-id: yun123-8gsbq6ix06c2416b
  api-key: your-cloudbase-api-key  # 配置 CloudBase API Key
```

2. 创建数据库：
```sql
CREATE DATABASE hmdp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

3. 运行应用：
```bash
mvn spring-boot:run
```

或使用部署脚本：

**Windows**:
```powershell
.\deploy.ps1
```

**Linux/Mac**:
```bash
chmod +x deploy.sh
./deploy.sh
```

### Docker 运行

```bash
# 构建镜像
docker build -t consultant:latest .

# 运行容器
docker run -d \
  -p 8080:8080 \
  --name consultant \
  -e SPRING_PROFILES_ACTIVE=prod \
  consultant:latest
```

## CloudBase 部署

### 前置准备

1. **CloudBase 环境**:
   - 环境ID: `yun123-8gsbq6ix06c2416b`
   - 状态: 已连接

2. **获取 API Key**:
   - 访问 [CloudBase Token 管理](https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b#/identity/token-management)
   - 创建或复制 API Key

3. **开通 CloudRun**:
   - 访问 [CloudBase CloudRun](https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b#/platform-run)
   - 点击"开通云托管"

### 部署步骤

#### 方式一：通过 CloudBase 控制台部署（推荐）

1. **准备项目**:
   ```bash
   # 清理构建产物
   mvn clean
   ```

2. **上传代码**:
   - 登录 CloudBase 控制台
   - 进入"云托管"页面
   - 选择"通过本地代码部署"
   - 上传项目目录

3. **配置服务**:
   - 服务名称: `consultant-service`
   - 部署类型: 容器服务型
   - 端口: 8080
   - CPU: 0.5 核
   - 内存: 1 GB
   - 最小实例数: 1
   - 最大实例数: 5
   - 公网访问: 开启

4. **部署**:
   - 点击"部署"
   - 等待部署完成

#### 方式二：通过镜像部署

```bash
# 1. 构建镜像
docker build -t consultant:latest .

# 2. 登录腾讯云镜像仓库
docker login ccr.ccs.tencentyun.com

# 3. 标记镜像
docker tag consultant:latest ccr.ccs.tencentyun.com/your-namespace/consultant:latest

# 4. 推送镜像
docker push ccr.ccs.tencentyun.com/your-namespace/consultant:latest
```

然后在 CloudBase 控制台选择"通过镜像部署"，填入镜像地址。

### 验证部署

```bash
# 健康检查
curl https://your-service-domain/actuator/health

# 测试聊天
curl "https://your-service-domain/chat?memoryId=test&message=你好"

# 测试 CloudBase 连接
curl https://your-service-domain/api/cloudbase/test
```

## API 接口

### 主要接口

| 接口 | 方法 | 描述 |
|------|------|------|
| `/chat` | GET | 流式聊天 |
| `/actuator/health` | GET | 健康检查 |
| `/actuator/health/liveness` | GET | 存活探针 |
| `/actuator/health/readiness` | GET | 就绪探针 |
| `/api/cloudbase/test` | GET | CloudBase 连接测试 |
| `/api/cloudbase/reservations` | GET/POST/PUT/DELETE | 预约管理 |

### CloudBase 数据库接口

| 接口 | 方法 | 描述 |
|------|------|------|
| `/api/cloudbase/reservations` | GET | 查询所有预约 |
| `/api/cloudbase/reservations/{id}` | GET | 根据 ID 查询 |
| `/api/cloudbase/reservations` | POST | 创建预约 |
| `/api/cloudbase/reservations/{id}` | PUT | 更新预约 |
| `/api/cloudbase/reservations/{id}` | DELETE | 删除预约 |
| `/api/cloudbase/query` | POST | 执行自定义 SQL |

## CloudBase 集成

### 功能特性

- ✅ MySQL 数据库通过 HTTP API 访问
- ✅ 支持查询、插入、更新、删除操作
- ✅ 支持自定义 SQL 查询
- ✅ 自动用户隔离（_openid 字段）

### 使用示例

```java
@Autowired
private CloudBaseRestClient cloudBaseRestClient;

// 查询
Map<String, String> filters = new HashMap<>();
filters.put("id", "eq.1");
JsonNode result = cloudBaseRestClient.query(
    "reservation", "*", filters, JsonNode.class
);

// 插入
Map<String, Object> data = new HashMap<>();
data.put("name", "张三");
data.put("_openid", "");
cloudBaseRestClient.insert("reservation", data, JsonNode.class);

// 更新
Map<String, Object> updateData = new HashMap<>();
updateData.put("name", "李四");
cloudBaseRestClient.update("reservation", filters, updateData, JsonNode.class);
```

详细文档见: [CLOUDBASE_SETUP.md](./CLOUDBASE_SETUP.md)

## 监控和日志

### 健康检查

应用提供多个健康检查端点：

```bash
# 总体健康
curl http://localhost:8080/actuator/health

# 存活探针
curl http://localhost:8080/actuator/health/liveness

# 就绪探针
curl http://localhost:8080/actuator/health/readiness
```

### 查看日志

**本地运行**:
```bash
# Maven 运行
mvn spring-boot:run

# Docker 运行
docker logs -f consultant
```

**CloudBase 部署**:
- 访问 [CloudBase 日志控制台](https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b#/devops/log)
- 选择服务查看日志

## 配置说明

### 应用配置 (application.yml)

```yaml
# LangChain4j AI 配置
langchain4j:
  open-ai:
    chat-model:
      base-url: https://dashscope.aliyuncs.com/compatible-mode/v1
      api-key: your-api-key
      model-name: qwen-plus

# Spring 配置
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/hmdp?useSSL=false&serverTimezone=UTC
    username: root
    password: your-password
  data:
    redis:
      host: localhost
      port: 6379

# CloudBase 配置
cloudbase:
  env-id: yun123-8gsbq6ix06c2416b
  api-key: your-api-key-here
```

### 环境变量

支持通过环境变量覆盖配置：

| 变量名 | 描述 |
|--------|------|
| `SPRING_PROFILES_ACTIVE` | Spring Profile（prod/dev） |
| `LANGCHAIN4J_OPENAI_CHAT_MODEL_API_KEY` | 通义千问 API Key |
| `CLOUDBASE_ENV_ID` | CloudBase 环境 ID |
| `CLOUDBASE_API_KEY` | CloudBase API Key |
| `SPRING_DATASOURCE_URL` | 数据库 URL |
| `SPRING_DATASOURCE_USERNAME` | 数据库用户名 |
| `SPRING_DATASOURCE_PASSWORD` | 数据库密码 |

## 故障排查

### 常见问题

**1. 应用无法启动**
- 检查 JDK 版本（需要 JDK 17+）
- 检查 Maven 依赖是否完整
- 查看启动日志

**2. 数据库连接失败**
- 检查数据库服务是否运行
- 检查连接信息是否正确
- 检查网络连接

**3. Redis 连接失败**
- 检查 Redis 服务是否运行
- 检查 Redis 配置是否正确
- 检查网络连接

**4. AI 调用失败**
- 检查 API Key 是否正确
- 检查网络连接
- 查看错误日志

**5. CloudBase 连接失败**
- 检查 API Key 是否正确
- 检查网络连接
- 检查环境 ID 是否正确

## 文档

- [部署指南](./DEPLOYMENT_GUIDE.md) - 详细的部署说明
- [CloudBase 集成指南](./CLOUDBASE_SETUP.md) - CloudBase 使用说明
- [CloudBase 集成总结](./CLOUDBASE_INTEGRATION_SUMMARY.md) - 集成总结
- [部署状态](./DEPLOYMENT_STATUS.md) - 当前部署状态

## 相关链接

- [CloudBase 控制台](https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b)
- [CloudBase 文档](https://docs.cloudbase.net/)
- [Spring Boot 文档](https://docs.spring.io/spring-boot/)
- [LangChain4j 文档](https://docs.langchain4j.dev/)

## 许可证

本项目采用 MIT 许可证。

## 支持

如有问题，请：
- 查看 [文档](./README.md)
- 提交 [Issue](https://github.com/your-repo/issues)
- 联系技术支持

---

**最后更新**: 2026-03-14
**CloudBase 环境**: yun123-8gsbq6ix06c2416b
