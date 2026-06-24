# Adapter Layer

适配层目录规约。Adapter 是系统的输入端，负责接收外部请求并转换为应用层调用。

## 目录结构

```
adapter
└── src/main/java/com/{company}/{project}/adapter
    ├── controller           # Web REST 控制器（面向前端）
    ├── api                  # 服务间调用接口实现（面向其他微服务）
    │   ├── http             # HTTP 服务间调用（Feign Provider）
    │   └── rpc              # Dubbo RPC 服务间调用（Dubbo Provider）
    ├── scheduler            # 定时任务
    ├── listener             # 消息监听（MQ Consumer）
    └── config               # 适配层配置（仅限适配层专用配置）
```

## controller 包

面向前端的 Web REST 控制器。HTTP 接口设计必须遵循 `restful-convention` 规约。

### RESTful 规范速查

Controller 的 URI 设计、HTTP 方法选择、状态码返回必须遵循 `restful-convention`，以下为核心要点：

| 维度 | 规则 | 详见 |
|------|------|------|
| URI 命名 | 小写、复数名词、连字符、无动词 | `restful-convention / uri-design` |
| HTTP 方法 | GET / POST / PUT / PATCH / DELETE 语义映射 | `restful-convention / http-methods` |
| 状态码 | 使用正确的 HTTP 状态码，禁止一律 200 | `restful-convention / response-status` |
| 版本与分页 | URI 路径版本 `/v1/`，`$page` / `$pageSize` 分页 | `restful-convention / versioning-filtering` |

### 命名规约

| 类别 | 命名格式 | 示例 | 归属 |
|------|---------|------|------|
| Controller | `{Resource}Controller` | `OrderController` | adapter |
| Request DTO | `{Resource}{Action}Cmd` / `{Resource}{Action}Qry` | `OrderCreateCmd`, `OrderListQry` | app（adapter 使用） |
| Response DTO | `{Resource}VO` | `OrderVO` | app（adapter 使用） |

### 职责边界

- 参数校验（`@Valid` / `@Validated`）
- 调用 app 层 Service 或 Executor
- 将领域对象转换为 VO 返回
- 返回正确的 HTTP 状态码（`@ResponseStatus` 声明非 200 状态码）
- **禁止**包含业务逻辑
- **禁止**直接调用 domain 或 infrastructure

### 代码示例

```java
@RestController
@RequestMapping("/v1/orders")
public class OrderController {

    @Resource
    private OrderApplicationService orderApplicationService;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public OrderVO create(@RequestBody @Valid OrderCreateCmd cmd) {
        return orderApplicationService.createOrder(cmd);
    }

    @GetMapping("/{orderId}")
    public OrderVO getById(@PathVariable String orderId) {
        return orderApplicationService.findById(orderId);
    }

    @GetMapping
    public PageResult<OrderVO> list(OrderListQry qry) {
        return orderApplicationService.listOrders(qry);
    }

    @PutMapping("/{orderId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void update(@PathVariable String orderId,
                       @RequestBody @Valid OrderUpdateCmd cmd) {
        orderApplicationService.updateOrder(orderId, cmd);
    }

    @DeleteMapping("/{orderId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable String orderId) {
        orderApplicationService.deleteOrder(orderId);
    }
}
```

### 响应规约

Controller 响应必须遵循 `restful-convention / response-status`，核心原则：**HTTP 状态码是请求结果的首要指示，禁止一律返回 200 + body errCode 的包装模式。**

#### 成功响应（2xx）

| 状态码 | 含义 | 使用场景 |
|--------|------|---------|
| 200 OK | 成功 | GET 查询、POST 创建并返回数据 |
| 201 Created | 已创建 | POST 创建资源成功，返回创建的资源或 Location |
| 202 Accepted | 已接受 | 异步请求，实际结果稍后可用 |
| 204 No Content | 无内容 | DELETE 删除成功、PUT/PATCH 更新成功且无返回体 |

#### 错误响应（4xx / 5xx）

| 状态码 | 含义 | 使用场景 |
|--------|------|---------|
| 400 Bad Request | 请求错误 | 参数格式错误、校验失败 |
| 401 Unauthorized | 未认证 | Token 缺失或无效 |
| 403 Forbidden | 无权限 | 已认证但无权访问该资源 |
| 404 Not Found | 资源不存在 | 资源 ID 无效或路径错误 |
| 429 Too Many Requests | 限流 | 请求频率超限 |
| 500 Internal Server Error | 服务器错误 | 未预期的服务端故障，禁止暴露堆栈 |
| 503 Service Unavailable | 服务不可用 | 服务维护或过载 |

#### 错误响应体格式

```json
{
  "errCode": "ERROR_CODE",
  "errDesc": "error description"
}
```

#### 反模式（禁止）

```
HTTP/1.1 200 OK
{ "errCode": "NOT_FOUND", "errDesc": "订单不存在" }
```

状态码说成功，body 说失败——**禁止**。

#### 正确模式

```
HTTP/1.1 404 Not Found
{ "errCode": "NOT_FOUND", "errDesc": "订单不存在" }
```

## api 包

面向其他微服务的服务间调用接口实现，按协议分为 `http` 和 `rpc` 两个子包。

### http 子包（Feign Provider）

提供 HTTP 协议的服务间调用接口，供其他微服务通过 Feign Client 消费。

#### 命名规约

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| 接口实现 | `{Resource}HttpApi` | `OrderHttpApi` |
| 接口定义 | `{Resource}Api` | `OrderApi`（可抽到独立 API jar） |
| 写入参 | `{Resource}{Action}DTO` | `OrderCreateDTO`、`OrderUpdateDTO` |
| 读入参 | `{Resource}QueryDTO` | `OrderQueryDTO` |
| 响应 | `{Resource}DTO` | `OrderDTO` |

#### 职责边界

- 实现 HTTP 服务间调用接口（`@RestController`）
- 调用 app 层 Service 或 Executor
- 将领域对象转换为 DTO 返回
- **禁止**包含业务逻辑
- **禁止**直接调用 domain 或 infrastructure

### rpc 子包（Dubbo Provider）

提供 Dubbo RPC 协议的服务间调用接口，供其他微服务通过 `@DubboReference` 消费。

#### 命名规约

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| 接口实现 | `{Resource}RpcApi` | `OrderRpcApi` |
| 接口定义 | `{Resource}Api` | `OrderApi`（可抽到独立 API jar） |
| 写入参 | `{Resource}{Action}DTO` | `OrderCreateDTO`、`OrderUpdateDTO` |
| 读入参 | `{Resource}QueryDTO` | `OrderQueryDTO` |
| 响应 | `{Resource}DTO` | `OrderDTO` |

#### 职责边界

- 实现 Dubbo 服务间调用接口（`@DubboService`）
- 调用 app 层 Service 或 Executor
- 将领域对象转换为 DTO 返回
- **禁止**包含业务逻辑
- **禁止**直接调用 domain 或 infrastructure

### http 与 rpc 的区别

| 维度 | http（Feign Provider） | rpc（Dubbo Provider） |
|------|----------------------|---------------------|
| 协议 | HTTP + JSON | TCP + 自定义序列化 |
| 实现注解 | `@RestController` | `@DubboService` |
| 消费方式 | `@FeignClient` | `@DubboReference` |
| 接口路径 | URI 路径（`/api/orders`） | 无路径概念，按接口 + version 路由 |
| 错误处理 | HTTP 状态码 | 异常层级 |
| 版本策略 | URI 路径版本 `/api/v1/` | Dubbo `version` 属性 |
| 性能 | 较低（HTTP 开销） | 较高（长连接 + 二进制序列化） |

### 共享接口定义

`http` 和 `rpc` 可以实现同一个 `OrderApi` 接口，接口定义抽取到独立 API jar：

```
order-api/                        # 独立 API 模块
├── OrderApi.java                 # 接口定义
├── OrderDTO.java                 # 响应 DTO
├── OrderCreateDTO.java           # 写入参 DTO
├── OrderQueryDTO.java            # 读入参 DTO
└── pom.xml

order-adapter/                    # 实现模块
└── adapter/api/
    ├── http/
    │   └── OrderHttpApi.java     # HTTP 实现
    └── rpc/
        └── OrderRpcApi.java      # RPC 实现
```

### DTO 命名规约

http 与 rpc 共享同一套 DTO 类型，通过方法名区分读写，不按协议拆分 DTO。

| 类别 | 命名格式 | 示例 | 说明 |
|------|---------|------|------|
| 写入参 | `{Resource}{Action}DTO` | `OrderCreateDTO`、`OrderUpdateDTO` | Action 体现操作意图 |
| 读入参 | `{Resource}QueryDTO` | `OrderQueryDTO` | 查询条件封装 |
| 响应 | `{Resource}DTO` | `OrderDTO` | 资源表示，读写共用 |

> **核心原则**：DTO 是服务契约，不是传输细节。HTTP 和 RPC 只是同一契约的两种传输实现，**禁止**为不同协议定义各自的 DTO。

### controller 与 api 的区别

| 维度 | controller | api（http / rpc） |
|------|-----------|-------------------|
| 消费者 | 前端 / 移动端 | 其他微服务 |
| 协议 | REST + JSON | HTTP + JSON / Dubbo RPC |
| 入参风格 | CQRS 分离（`Cmd` / `Qry`） | 统一 DTO（`OrderCreateDTO` / `OrderQueryDTO`） |
| 出参风格 | 面向 UI 裁剪（`VO`） | 面向服务契约（`DTO`） |
| 认证方式 | 用户 Token | 服务间签名 / 内网信任 |
| 版本策略 | URI 路径版本 `/v1/`（遵循 `restful-convention`） | URI 版本 / Dubbo `version` |

## scheduler 包

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| 定时任务 | `{JobDescription}Job` | `OrderTimeoutCheckJob` |

- 仅负责触发，业务逻辑委托给 app 层
- 使用 `@Scheduled` 或 XXL-Job 等框架注解

## listener 包

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| 消息监听 | `{EventDescription}Listener` | `PaymentResultListener` |

### 职责边界

- 反序列化消息体
- 转换为 app 层入参并调用
- **禁止**在 listener 中写业务逻辑

## Mandatory 规则

1. Controller 类必须放在 `adapter.controller` 包下
2. HTTP 服务间调用实现类必须放在 `adapter.api.http` 包下，Dubbo RPC 实现类必须放在 `adapter.api.rpc` 包下
3. Cmd / Qry / VO 定义在 app 模块，adapter 通过依赖 app 使用，禁止在 adapter 中重新定义
4. 服务间调用 DTO 命名规约：写入参 `{Resource}{Action}DTO`、读入参 `{Resource}QueryDTO`、响应 `{Resource}DTO`，定义在 adapter.api 或独立 API jar，禁止泄露到 app 或 domain
5. Controller、HttpApi、RpcApi 中**禁止**编写业务逻辑，仅做参数校验和调用转发
6. Adapter 层**禁止**直接依赖 domain 或 infrastructure 模块
7. DTO 类**禁止**泄露到 app 层或 domain 层
8. Controller HTTP 接口设计**必须**遵循 `restful-convention`（URI 命名、HTTP 方法、状态码、版本与分页）
9. Controller **禁止**一律返回 200，非 200 状态码必须通过 `@ResponseStatus` 声明（201 / 204 等）
10. http 与 rpc **禁止**各自定义独立的 DTO，必须共享同一套 DTO 类型

## Recommended 规则

1. 一个 Controller 对应一个领域资源，不要按 CRUD 拆分多个 Controller
2. 列表查询使用 `PageResult<T>` 封装分页信息，直接返回数据而非业务包装体
3. DTO 与领域对象之间的转换放在 Adapter 层，不要在 app 层做
4. Scheduler 和 Listener 中捕获异常后记录日志，不要吞掉异常
5. 服务间调用接口定义（`{Resource}Api`）抽取到独立 API jar，供调用方依赖，实现类留在 adapter
6. controller 和 api 共享相同的 app 层入口，不要为 api 单独创建应用服务