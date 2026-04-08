# CloudBase 集成指南

本项目已成功集成 CloudBase，可以通过 HTTP API 访问 CloudBase 的 MySQL 数据库和其他服务。

## 环境信息

- **环境ID**: yun123-8gsbq6ix06c2416b
- **区域**: ap-shanghai (上海)
- **数据库实例**: tnt-epoycdmbc
- **状态**: 已激活

## 快速开始

### 1. 配置 API Key

在 `src/main/resources/application.yml` 中配置你的 CloudBase API Key：

```yaml
cloudbase:
  env-id: yun123-8gsbq6ix06c2416b
  api-key: your-api-key-here  # 替换为你的实际 API Key
```

### 2. 获取 API Key

1. 访问 [CloudBase 控制台 - Token 管理](https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b#/identity/token-management)
2. 创建或复制 API Key
3. 将 API Key 填入 `application.yml` 文件中

### 3. 测试连接

启动应用后，访问以下 URL 测试 CloudBase 连接：

```bash
curl http://localhost:8080/api/cloudbase/test
```

成功响应示例：
```json
{
  "status": "success",
  "message": "CloudBase 连接成功！"
}
```

## 使用说明

### CloudBase REST 客户端

项目提供了 `CloudBaseRestClient` 类，封装了所有 CloudBase HTTP API 操作：

**位置**: `com.itheima.consultant.client.CloudBaseRestClient`

**主要方法**:
- `query()` - 查询记录
- `insert()` - 插入记录
- `update()` - 更新记录
- `delete()` - 删除记录
- `executeReadOnlySQL()` - 执行自定义 SQL 查询

### 使用示例

#### 1. 查询记录

```java
@Autowired
private CloudBaseRestClient cloudBaseRestClient;

// 查询所有记录
JsonNode result = cloudBaseRestClient.query(
    "reservation",  // 表名
    "*",            // 查询字段
    null,           // 过滤条件
    JsonNode.class  // 返回类型
);

// 带条件查询
Map<String, String> filters = new HashMap<>();
filters.put("id", "eq.1");
filters.put("name", "like.张三");

JsonNode result = cloudBaseRestClient.query(
    "reservation",
    "id,name,date",
    filters,
    JsonNode.class
);
```

#### 2. 插入记录

```java
Map<String, Object> data = new HashMap<>();
data.put("name", "张三");
data.put("phone", "13800138000");
data.put("date", "2026-03-15");
data.put("_openid", ""); // 必须包含 _openid 字段

JsonNode result = cloudBaseRestClient.insert(
    "reservation",
    data,
    JsonNode.class
);
```

#### 3. 更新记录

```java
Map<String, String> filters = new HashMap<>();
filters.put("id", "eq.1");

Map<String, Object> updateData = new HashMap<>();
updateData.put("name", "李四");

JsonNode result = cloudBaseRestClient.update(
    "reservation",
    filters,
    updateData,
    JsonNode.class
);
```

#### 4. 删除记录

```java
Map<String, String> filters = new HashMap<>();
filters.put("id", "eq.1");

cloudBaseRestClient.delete(
    "reservation",
    filters,
    JsonNode.class
);
```

#### 5. 执行自定义 SQL

```java
String sql = "SELECT * FROM reservation WHERE date >= '2026-03-01'";

JsonNode result = cloudBaseRestClient.executeReadOnlySQL(
    sql,
    JsonNode.class
);
```

### 数据库服务

项目提供了 `CloudBaseDatabaseService` 服务类，封装了常用的数据库操作：

**位置**: `com.itheima.consultant.service.CloudBaseDatabaseService`

**主要方法**:
- `getAllReservations()` - 获取所有预约记录
- `getReservationById(Long id)` - 根据ID获取预约记录
- `createReservation(Map data)` - 创建预约记录
- `updateReservation(Long id, Map data)` - 更新预约记录
- `deleteReservation(Long id)` - 删除预约记录
- `executeCustomQuery(String sql)` - 执行自定义查询

### REST API 接口

项目提供了测试 REST API 接口，可以通过 HTTP 请求访问：

**基础路径**: `/api/cloudbase`

**可用接口**:
- `GET /api/cloudbase/test` - 测试连接
- `GET /api/cloudbase/reservations` - 查询所有预约记录
- `GET /api/cloudbase/reservations/{id}` - 根据ID查询预约记录
- `POST /api/cloudbase/reservations` - 创建预约记录
- `PUT /api/cloudbase/reservations/{id}` - 更新预约记录
- `DELETE /api/cloudbase/reservations/{id}` - 删除预约记录
- `POST /api/cloudbase/query` - 执行自定义 SQL 查询

## 数据库表设计

### 重要说明

在 CloudBase MySQL 数据库中创建表时，**必须**包含 `_openid` 字段用于用户隔离：

```sql
CREATE TABLE reservation (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    _openid VARCHAR(64) DEFAULT '' NOT NULL COMMENT '用户标识',
    name VARCHAR(100) NOT NULL COMMENT '预约人姓名',
    phone VARCHAR(20) NOT NULL COMMENT '联系电话',
    date DATE NOT NULL COMMENT '预约日期',
    time TIME NOT NULL COMMENT '预约时间',
    status VARCHAR(20) DEFAULT 'pending' COMMENT '预约状态',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### 安全规则

CloudBase 支持配置表级别的安全规则，可以设置：
- `READONLY` - 任何人可读，不可写
- `PRIVATE` - 仅登录用户可读写
- `ADMINWRITE` - 任何人可读，仅管理员可写
- `ADMINONLY` - 仅管理员可读写
- `CUSTOM` - 自定义安全逻辑

## 常见问题

### 1. API Key 在哪里获取？

访问 CloudBase 控制台的 [Token 管理页面](https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b#/identity/token-management) 获取。

### 2. 连接失败怎么办？

检查以下几点：
- API Key 是否正确配置
- 网络是否可以访问 CloudBase API
- 环境ID是否正确

### 3. 如何查看数据库表？

访问 [CloudBase 控制台 - MySQL 数据库](https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b#/db/mysql/table/default/) 查看和管理数据库表。

### 4. 支持 MyBatis 吗？

目前项目通过 HTTP API 访问 CloudBase MySQL，不直接支持 MyBatis。如需使用 MyBatis，可以将 CloudBase MySQL 作为远程数据库配置在 `application.yml` 中：

```yaml
spring:
  datasource:
    url: jdbc:mysql://tnt-epoycdmbc.tencentcloudapi.com:3306/hmdp?useSSL=false&serverTimezone=UTC
    username: your-mysql-username
    password: your-mysql-password
```

## 参考文档

- [CloudBase HTTP API 文档](https://docs.cloudbase.net/api-reference/http/intro)
- [CloudBase MySQL RESTful API](https://docs.cloudbase.net/api-reference/http/rdb/rest)
- [CloudBase 控制台](https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b)

## 下一步

1. 配置 API Key
2. 在 CloudBase 控制台创建数据库表
3. 根据业务需求修改数据模型
4. 使用 `CloudBaseRestClient` 或 `CloudBaseDatabaseService` 操作数据
5. 如果需要，将现有的 MyBatis Mapper 迁移到 CloudBase HTTP API
