# hm-dianping（黑马点评）

一个 Spring Boot 本地生活服务后端：店铺浏览、优惠券秒杀、探店笔记、关注与签到。
骨架是常规 CRUD，**技术重心集中在「秒杀优惠券」这一条高并发链路上** —— Redis Lua 原子校验 → 消息队列异步下单 → Redisson 分布式锁 → MySQL 行级扣减。

## 技术栈

| 类别 | 选型 | 版本 |
|---|---|---|
| 框架 | Spring Boot | 2.3.12.RELEASE（`java.version = 1.8`） |
| Web | spring-boot-starter-web | Tomcat 9.0.46，端口 `8081` |
| 持久层 | MyBatis-Plus | 3.4.3 |
| 数据库 | MySQL | 8.0（connector 5.1.47），库名 `hmdp` |
| 缓存 | spring-data-redis + Lettuce | 2.6.2 / 6.1.6，连接池 `max-active=10` |
| 分布式锁 | Redisson | 3.13.6 |
| 消息队列 | spring-kafka + kafka-clients | 2.9.13 / 2.6.0 |
| 本地缓存 | Caffeine | Spring Boot 托管版本 |
| 工具 | Hutool | 5.7.17 |

> **JDK 建议用 11。** pom 里声明的是 1.8，用 JDK 17 会因 Lombok 注解处理器报错。

## 项目结构

```
src/main/java/com/hmdp/
├── controller/    9 个 HTTP 入口：Shop / ShopType / Voucher / VoucherOrder
│                  / User / Blog / BlogComments / Follow / Upload
├── service/       11 组业务逻辑，含 service.cache.VoucherListCacheService（多级缓存）
├── mapper/        10 个 MyBatis-Plus BaseMapper + VoucherMapper.xml
├── entity/ dto/   11 个表实体 + 统一响应 Result / 4 个 DTO
├── config/        Mvc / Mybatis / Redisson / Kafka / 缓存参数 / 全局异常
├── utils/         CacheClient、RedisIdWorker、双拦截器、UserHolder、SimpleRedisLock
├── limiter/       滑动窗口限流：注解 + AOP 切面 + 自定义异常
└── consumer/      Kafka 消费者（当前被注释，见「已知问题」）

src/main/resources/
├── seckill.lua / limiter.lua / unlock.lua   Lua 脚本
├── mapper/VoucherMapper.xml
└── db/hmdp.sql                              建库建表 + 初始数据
```

## 功能模块

| 模块 | 入口接口 | 核心技术点 |
|---|---|---|
| 登录鉴权 | `POST /user/code`、`POST /user/login` | Redis Hash 存 token、双拦截器（order 0 刷新 / order 1 校验）、ThreadLocal 透传用户 |
| 店铺查询 | `GET /shop/{id}`、`GET /shop/of/type` | 缓存穿透（空值写入）、缓存击穿（互斥锁 / 逻辑过期两套方案）、Redis GEO 附近店铺 + 距离排序分页 |
| 优惠券秒杀 | `POST /voucher-order/seckill/{id}` | Lua 原子校验 + 扣减、Kafka 异步入库、Redisson 锁、全局唯一 ID |
| 优惠券列表缓存 | `GET /voucher/list/{shopId}` | Caffeine(L1) → Redis(L2) → MySQL，可配置降级 |
| 笔记与点赞 | `PUT /blog/like/{id}`、`GET /blog/of/follow` | 点赞用 ZSet 存「谁在何时点的」；Feed 流用 ZSet + 滚动分页游标 |
| 关注与签到 | `PUT /follow/{id}/{isFollow}`、`POST /user/sign` | Set 存关注 + `SINTER` 求共同关注；BitMap 签到 + `BITFIELD` 统计连续天数 |

## 核心技术点

**1. Lua 把「校验 + 扣减」压成一次原子操作** —— `seckill.lua` 在 Redis 单线程内一次完成库存判断、一人一单判断、`incrby -1`、`sadd`，中间不可能被插队，因此不需要额外加锁。

**2. 三种缓存问题各有一套方案且并存可切换** —— `CacheClient` 里同时保留 `queryWithPassThrough`（穿透）、`queryWithMutex`（击穿·互斥锁）、`queryWithLogicalExpire`（击穿·逻辑过期），取舍关系可直接对比。

**3. 多级缓存可降级** —— `hmdp.cache.voucher-list.mode` 决定走 `mysql` / `redis` / `caffeine`，等于把「加缓存」变成可 A/B 对比的实验开关；刷新与过期时间全部外置到 `application.yaml`。

**4. 滑动窗口限流做成注解** —— `@RateLimiter(key, window, limit, message, type)`，底层 `limiter.lua` 用 ZSet（score = 毫秒时间戳）实现，支持 IP / USER / METHOD 三种维度，避免固定窗口的「边界双倍流量」。

**5. 全局唯一订单 ID 无中心化发号器** —— `RedisIdWorker`：`timestamp << 32 | 序列`，序列来自 `INCR icr:order:yyyy:MM:dd`（按天分 key）。趋势递增对聚簇索引友好，又不用管雪花算法的机器号。

**6. GEO 与滚动分页** —— `GEOSEARCH ... BYRADIUS ... WITHDISTANCE` 后配合 `ORDER BY FIELD(id, ...)` 保持 Redis 给出的顺序；Feed 流用 score 时间戳作游标，返回 `minTime` + `offset` 处理同时间戳多条记录的边界。

## 快速开始

### 环境要求

JDK 11、Maven、MySQL 8.0、Redis；秒杀链路要跑通还需 Kafka（可选，见「已知问题」）。

### 1. 初始化数据库

```bash
mysql -uroot -p < src/main/resources/db/hmdp.sql
```

### 2. 配置

`src/main/resources/application.yaml` 中与本机相关的项：

- **MySQL 密码**走环境变量，仓库里是占位符：

  ```yaml
  password: ${MYSQL_PASSWORD:123456}
  ```

  设置真实密码（改后需重开终端）：

  ```powershell
  setx MYSQL_PASSWORD "你的密码"
  ```

- **Redis 若设了密码**，需自行在 `spring.redis` 下补 `password`，并同步 `RedissonConfig` 里 `setPassword(...)`。

- Kafka 默认连 `localhost:9092`。不启动 Kafka 应用也能起来，但秒杀接口会在发送消息时阻塞。

### 3. 启动

```bash
mvn spring-boot:run
```

默认端口 `8081`。

### 4. 预热秒杀库存（必做）

Lua 第一行就 `tonumber(redis.call('get', stockKey))`，**key 不存在时会直接抛错导致接口 500**，而代码里没有预热逻辑，必须手工刷：

```bash
redis-cli -a <redis密码> set seckill:stock:10 100
```

### 5. 验证

```bash
# 登录取 token
curl -X POST "http://localhost:8081/user/code?phone=13686869696"
curl -X POST "http://localhost:8081/user/login" -H "Content-Type: application/json" \
     -d '{"phone":"13686869696","code":"<Redis 里的验证码>"}'

# 发起点秒杀
curl -X POST "http://localhost:8081/voucher-order/seckill/10" -H "authorization: <token>"

# 缓存链路
redis-cli -a <redis密码> del cache:shop:1
curl "http://localhost:8081/shop/1"
redis-cli -a <redis密码> ttl cache:shop:1     # 约 1800 秒
```

## 已知问题

| 级别 | 问题 | 说明 |
|---|---|---|
| P0 | **MQ 消费端被注释，订单不会落库** | `SeckillVoucherConsumer` 的 `@KafkaListener` 和 `KafkaConfig` 的三个 Bean 都包在 `/* */` 里。结果：Redis 侧库存扣减和一人一单都生效，用户也拿到了订单号，但 `tb_voucher_order` 永远不新增。 |
| P0 | **生产端与消费端消息类型不匹配** | 生产端 `kafkaTemplate.send(topic, voucherOrder.toString())` 发的是 `String`，消费端却 `(VoucherOrder) record.value()` 强转，即使打开监听也会直接 `ClassCastException`。应改为发送对象并按 `JsonDeserializer` 配置消费。 |
| P1 | **秒杀券有效期未校验** | `tb_seckill_voucher` 的 `begin_time` / `end_time` 在秒杀链路里没有被检查，过期券仍可抢。 |
| P1 | **扣库存与落单无事务** | `createVoucherOrder` 没有 `@Transactional`，`save()` 失败时 Redis 已 `sadd`，会永久丢单。 |
| P2 | **`kafkaTemplate.send` 无回调无降级** | broker 挂掉会阻塞到 `max.block.ms`（默认 60 秒），接口假死。 |
| P2 | **上传目录硬编码** | `SystemConstants` 里是写死的本机路径，换机器上传功能不可用。 |

## 文档

- [项目架构与秒杀全流程实测](docs/项目架构与秒杀全流程实测.md) —— 分层结构、7 个模块、6 个技术亮点详解，以及一条秒杀请求的 10 步全链路实测记录与证据。
