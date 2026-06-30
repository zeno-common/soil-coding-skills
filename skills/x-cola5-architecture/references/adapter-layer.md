# Adapter Layer

适配层目录规约。Adapter 是系统的输入端，负责接收外部请求并转换为应用层调用。

## 目录结构

```
adapter
└── src/main/java/com/{company}/{project}/adapter
    ├── controller           # Web REST 控制器（面向前端）
    ├── api                  # 服务间调用接口实现（仅当 client 模块存在时）
    │   ├── http             # HTTP 服务间调用（Feign Provider）
    │   └── rpc              # Dubbo RPC 服务间调用（Dubbo Provider）
    ├── scheduler            # 定时任务
    ├── listener             # 消息监听（MQ Consumer）
    └── config               # 适配层配置（仅限适配层专用配置）
```

## controller 包

面向前端的 Web REST 控制器。HTTP 接口设计必须遵循 `restful-convention` 规约。

### RESTful 规范速查

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

- 参数校验（`@Valid` / `@Validated`）、调用 app 层、领域对象转 VO、`@ResponseStatus` 声明成功类非 200 状态码（201、204 等）；错误类状态码（4xx/5xx）通过异常处理器统一返回
- **禁止**包含业务逻辑 / 直接调用 domain 或 infrastructure

### 代码示例

```java
@RestController
@RequestMapping("/v1/orders")
public class OrderController {
    @Resource
    private OrderApplicationService orderApplicationService;

    @PostMapping @ResponseStatus(HttpStatus.CREATED)
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
    @PutMapping("/{orderId}") @ResponseStatus(HttpStatus.NO_CONTENT)
    public void update(@PathVariable String orderId, @RequestBody @Valid OrderUpdateCmd cmd) {
        orderApplicationService.updateOrder(orderId, cmd);
    }
    @DeleteMapping("/{orderId}") @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable String orderId) {
        orderApplicationService.deleteOrder(orderId);
    }
}
```

### 响应规约

遵循 `restful-convention / response-status`，核心原则：**HTTP 状态码是请求结果的首要指示，禁止一律返回 200 + body errCode。**

- 请求失败（4xx/5xx）：统一返回错误响应体 `{"errCode":"ERROR_CODE","errDesc":"error description"}`
- 请求成功（2xx）：直接返回数据或无返回体，**禁止**包装为 `{"data": ...}` 等外层结构

| 状态码 | 场景 | 状态码 | 场景 |
|--------|------|--------|------|
| 200 OK | GET 查询 / POST 返回数据 | 400 Bad Request | 参数校验失败 |
| 201 Created | POST/PUT/PATCH 创建资源 | 401 Unauthorized | 未认证 |
| 202 Accepted | 异步请求 | 403 Forbidden | 无权限 |
| 204 No Content | PUT/DELETE 成功无返回体 | 404 Not Found | 资源不存在 |
| 303 See Other | POST/PUT/DELETE 后重定向 | 405 Method Not Allowed | HTTP 方法不支持 |
| | | 415 Unsupported Media Type | 请求 Content-Type 不支持 |
| | | 429 Too Many Requests | 限流 |
| | | 500 Internal Server Error | 服务端故障 |
| | | 503 Service Unavailable | 服务不可用 |
> 405 和 415 通常由框架自动返回；303 用于状态变更操作后的重定向，通过 `Location` 头指向新资源。

❌ 禁止：`200 OK` + `{ errCode: "NOT_FOUND" }`　✅ 正确：`404 Not Found` + `{ errCode: "NOT_FOUND" }`

## api 包

面向其他微服务的服务间调用接口实现，按协议分为 `http` 和 `rpc` 两个子包。

### 命名规约

http 与 rpc 共享同一套 DTO 类型，**禁止**为不同协议定义各自的 DTO。

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| HTTP 实现 | `{Resource}HttpApi` | `OrderHttpApi` |
| RPC 实现 | `{Resource}RpcApi` | `OrderRpcApi` |
| 共享接口定义 | `{Resource}Api` | `OrderApi`（可抽到独立 API jar） |
| 写入参 | `{Resource}{Action}DTO` | `OrderCreateDTO`、`OrderUpdateDTO` |
| 读入参 | `{Resource}QueryDTO` | `OrderQueryDTO` |
| 响应 | `{Resource}DTO` | `OrderDTO` |

> DTO 是服务契约，不是传输细节。HTTP 和 RPC 只是同一契约的两种传输实现。

### 职责边界

- http：`@RestController` 实现，rpc：`@DubboService` 实现
- 调用 app 层 Service、领域对象转 DTO
- **禁止**包含业务逻辑 / 直接调用 domain 或 infrastructure

### http 与 rpc 的区别

| 维度 | http（Feign Provider） | rpc（Dubbo Provider） |
|------|----------------------|---------------------|
| 协议 | HTTP + JSON | TCP + 自定义序列化 |
| 实现注解 | `@RestController` | `@DubboService` |
| 消费方式 | `@FeignClient` | `@DubboReference` |
| 接口路径 | URI 路径（`/api/orders`） | 无路径，按接口 + version 路由 |
| 错误处理 | HTTP 状态码 | 异常层级 |
| 版本策略 | URI 路径版本 `/api/v1/` | Dubbo `version` 属性 |
| 性能 | 较低（HTTP 开销） | 较高（长连接 + 二进制序列化） |

### 共享接口定义

`http` 和 `rpc` 可实现同一个 `{Resource}Api` 接口，接口定义抽取到独立 API jar：

```
order-api/                    # 独立 API 模块：OrderApi + OrderDTO + OrderCreateDTO + OrderQueryDTO
order-adapter/                # 实现模块
└── adapter/api/
    ├── http/OrderHttpApi.java
    └── rpc/OrderRpcApi.java
```

### controller 与 api 的区别

| 维度 | controller | api（http / rpc） |
|------|-----------|-------------------|
| 消费者 | 前端 / 移动端 | 其他微服务 |
| 入参风格 | CQRS 分离（`Cmd` / `Qry`） | 统一 DTO（`OrderCreateDTO` / `OrderQueryDTO`） |
| 出参风格 | 面向 UI 裁剪（`VO`） | 面向服务契约（`DTO`） |
| 认证方式 | 用户 Token | 服务间签名 / 内网信任 |
| 版本策略 | URI 路径版本 `/v1/` | URI 版本 / Dubbo `version` |

## scheduler 包

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| 定时任务 | `{JobDescription}Job` | `OrderTimeoutCheckJob` |

仅负责触发，业务逻辑委托给 app 层。使用 `@Scheduled` 或 XXL-Job 等框架注解。

## listener 包

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| 消息监听 | `{EventDescription}Listener` | `PaymentResultListener` |

反序列化消息体 → 转换为 app 层入参并调用。**禁止**在 listener 中写业务逻辑。

## Mandatory 规则

1. Controller 放 `adapter.controller`，HttpApi 放 `adapter.api.http`，RpcApi 放 `adapter.api.rpc`
2. Cmd / Qry / VO 定义在 app 模块，adapter 通过依赖 app 使用，禁止在 adapter 中重新定义
3. DTO 定义在 client 模块，禁止泄露到 app 或 domain；命名：写入参 `{Resource}{Action}DTO`、读入参 `{Resource}QueryDTO`、响应 `{Resource}DTO`
4. Controller、HttpApi、RpcApi 中**禁止**编写业务逻辑，仅做参数校验和调用转发
5. Adapter 层**禁止**直接依赖 domain 或 infrastructure 模块
6. Controller HTTP 接口**必须**遵循 ``restful-convention``；**禁止**一律返回 200，成功类非 200 状态码（201、204 等）通过 ``@ResponseStatus`` 声明，错误类状态码（4xx/5xx）通过异常处理器统一返回
7. http 与 rpc **禁止**各自定义独立的 DTO，必须共享同一套 DTO 类型

## Recommended 规则

1. 一个 Controller 对应一个领域资源，不要按 CRUD 拆分
2. 列表查询使用 `PageResult<T>` 封装分页信息
3. DTO 与领域对象之间的转换放在 Adapter 层
4. Scheduler 和 Listener 中捕获异常后记录日志，不要吞掉异常
5. 服务间调用接口定义（`{Resource}Api`）和 DTO 放在 client 模块，adapter.api 实现该接口
6. controller 和 api 共享相同的 app 层入口
