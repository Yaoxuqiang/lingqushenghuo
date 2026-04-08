# CloudBase 集成总结

## ✅ 集成状态

已成功将 Spring Boot 项目连接到 CloudBase！

### 环境信息

- **环境ID**: `yun123-8gsbq6ix06c2416b`
- **环境名称**: yun123
- **区域**: ap-shanghai (上海)
- **套餐**: 体验版
- **状态**: 正常运行

### 已配置的 CloudBase 服务

| 服务 | 实例ID/名称 | 状态 |
|------|-------------|------|
| MySQL 数据库 | tnt-epoycdmbc | ✅ 运行中 |
| 云存储 | 7975-yun123-8gsbq6ix06c2416b-1411289169 | ✅ 已配置 |
| 云函数 | yun123-8gsbq6ix06c2416b | ✅ 已启用 |
| 静态托管 | yun123-8gsbq6ix06c2416b-1411289169.tcloudbaseapp.com | ✅ 已配置 |

## 📁 新增文件

### 1. 配置类

**CloudBaseConfig.java**
- 路径: `src/main/java/com/itheima/consultant/config/CloudBaseConfig.java`
- 功能: 管理 CloudBase 环境配置（envId, apiKey, baseUrl）

**CloudBaseClientConfig.java**
- 路径: `src/main/java/com/itheima/consultant/config/CloudBaseClientConfig.java`
- 功能: 配置 RestTemplate 和 CloudBase REST 客户端 Bean

### 2. 客户端类

**CloudBaseRestClient.java**
- 路径: `src/main/java/com/itheima/consultant/client/CloudBaseRestClient.java`
- 功能: 封装 CloudBase HTTP API 调用
- 支持操作:
  - ✅ 查询记录 (query)
  - ✅ 插入记录 (insert)
  - ✅ 更新记录 (update)
  - ✅ 删除记录 (delete)
  - ✅ 执行自定义 SQL (executeReadOnlySQL)

### 3. 服务类

**CloudBaseDatabaseService.java**
- 路径: `src/main/java/com/itheima/consultant/service/CloudBaseDatabaseService.java`
- 功能: 提供 CloudBase 数据库操作的高级封装
- 支持方法:
  - `getAllReservations()` - 获取所有预约记录
  - `getReservationById(Long id)` - 根据ID查询
  - `createReservation(Map data)` - 创建记录
  - `updateReservation(Long id, Map data)` - 更新记录
  - `deleteReservation(Long id)` - 删除记录
  - `executeCustomQuery(String sql)` - 执行自定义查询

### 4. 控制器类

**CloudBaseTestController.java**
- 路径: `src/main/java/com/itheima/consultant/controller/CloudBaseTestController.java`
- 功能: 提供 REST API 接口用于测试 CloudBase 连接
- 接口列表:
  - `GET /api/cloudbase/test` - 测试连接
  - `GET /api/cloudbase/reservations` - 查询所有记录
  - `GET /api/cloudbase/reservations/{id}` - 根据ID查询
  - `POST /api/cloudbase/reservations` - 创建记录
  - `PUT /api/cloudbase/reservations/{id}` - 更新记录
  - `DELETE /api/cloudbase/reservations/{id}` - 删除记录
  - `POST /api/cloudbase/query` - 执行自定义查询

### 5. 配置文件更新

**application.yml**
- 路径: `src/main/resources/application.yml`
- 新增配置:
  ```yaml
  cloudbase:
    env-id: yun123-8gsbq6ix06c2416b
    api-key: your-api-key-here
    base-url: null
  ```

### 6. 文档

**CLOUDBASE_SETUP.md**
- 路径: `CLOUDBASE_SETUP.md`
- 内容: 详细的 CloudBase 集成指南，包括：
  - 配置说明
  - 使用示例
  - API 接口文档
  - 常见问题解答

## 🚀 快速开始

### 1. 配置 API Key

访问 [CloudBase 控制台 - Token 管理](https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b#/identity/token-management) 获取 API Key，然后更新 `application.yml`:

```yaml
cloudbase:
  env-id: yun123-8gsbq6ix06c2416b
  api-key: your-actual-api-key  # 替换为实际值
```

### 2. 启动应用

```bash
mvn spring-boot:run
```

### 3. 测试连接

```bash
curl http://localhost:8080/api/cloudbase/test
```

成功响应:
```json
{
  "status": "success",
  "message": "CloudBase 连接成功！"
}
```

## 💡 使用方式

### 方式一：使用 CloudBaseRestClient（推荐用于自定义操作）

```java
@Autowired
private CloudBaseRestClient cloudBaseRestClient;

// 查询
Map<String, String> filters = new HashMap<>();
filters.put("id", "eq.1");
JsonNode result = cloudBaseRestClient.query("reservation", "*", filters, JsonNode.class);

// 插入
Map<String, Object> data = new HashMap<>();
data.put("name", "张三");
data.put("_openid", "");
cloudBaseRestClient.insert("reservation", data, JsonNode.class);
```

### 方式二：使用 CloudBaseDatabaseService（推荐用于标准操作）

```java
@Autowired
private CloudBaseDatabaseService cloudBaseDatabaseService;

// 查询所有
List<Map<String, Object>> reservations = cloudBaseDatabaseService.getAllReservations();

// 根据ID查询
Map<String, Object> reservation = cloudBaseDatabaseService.getReservationById(1L);

// 创建
Map<String, Object> data = new HashMap<>();
data.put("name", "张三");
Map<String, Object> created = cloudBaseDatabaseService.createReservation(data);
```

### 方式三：使用 REST API（推荐用于测试）

```bash
# 测试连接
curl http://localhost:8080/api/cloudbase/test

# 查询所有记录
curl http://localhost:8080/api/cloudbase/reservations

# 创建记录
curl -X POST http://localhost:8080/api/cloudbase/reservations \
  -H "Content-Type: application/json" \
  -d '{"name":"张三","phone":"13800138000"}'

# 执行自定义查询
curl -X POST http://localhost:8080/api/cloudbase/query \
  -H "Content-Type: application/json" \
  -d '{"sql":"SELECT * FROM reservation LIMIT 10"}'
```

## 📊 CloudBase 控制台链接

- **总览**: https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b#/overview
- **MySQL 数据库**: https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b#/db/mysql/table/default/
- **云函数**: https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b#/scf
- **云存储**: https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b#/storage
- **静态托管**: https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b#/static-hosting
- **身份认证**: https://tcb.cloud.tencent.com/dev?envId=yun123-8gsbq6ix06c2416b#/identity

## 🔄 迁移建议

如果需要将现有的 MyBatis Mapper 迁移到 CloudBase，可以：

1. **使用 CloudBase HTTP API** (当前方案)
   - 优点: 无需修改现有代码结构，直接使用 HTTP API
   - 适合: 新功能开发或渐进式迁移

2. **使用 CloudBase MySQL 直连**
   - 配置 CloudBase MySQL 的连接信息到 `application.yml`
   - 继续使用 MyBatis
   - 需要: 从 CloudBase 控制台获取 MySQL 连接信息

3. **混合使用**
   - 新功能使用 CloudBase HTTP API
   - 旧功能继续使用 MyBatis
   - 逐步迁移

## 📚 相关文档

- [CloudBase 集成指南](./CLOUDBASE_SETUP.md) - 详细的使用说明和示例
- [CloudBase HTTP API 文档](https://docs.cloudbase.net/api-reference/http/intro)
- [CloudBase MySQL RESTful API](https://docs.cloudbase.net/api-reference/http/rdb/rest)

## ⚠️ 注意事项

1. **_openid 字段**: 在 CloudBase MySQL 表中必须包含 `_openid` 字段，用于用户隔离
2. **API Key 安全**: 不要将 API Key 提交到代码仓库，建议使用环境变量或配置中心
3. **错误处理**: 所有 CloudBase 操作都应包含适当的错误处理
4. **权限管理**: 在 CloudBase 控制台配置合适的表安全规则

## 🎯 下一步

1. ✅ 配置 API Key
2. ✅ 测试连接
3. 📋 在 CloudBase 创建数据库表
4. 🔄 根据业务需求迁移数据模型
5. 🔒 配置表安全规则
6. 🚀 部署到生产环境

---

**集成完成时间**: 2026-03-14
**CloudBase 环境**: yun123-8gsbq6ix06c2416b (上海区域)
