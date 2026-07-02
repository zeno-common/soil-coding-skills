# Adapter Layer

适配层目录规约。Adapter 是系统输入端，负责接收外部请求并转换为应用层调用。**按协议组织目录，不按领域划分。**

## 目录结构

```
adapter/src/main/java/com/{company}/{project}/adapter
├── controller           # Web REST 控制器（面向前端）
├── api                  # 服务间调用接口实现（需 client 模块）
│   ├── http             # Feign Provider
│   └── rpc              # Dubbo Provider
├── scheduler            # 定时任务
├── listener             # MQ Consumer（分布式事件入口）
└── config               # 适配层专用配置
```

## controller 包

### HTTP 路径前缀

| 接口类型 | 前缀 | 示例 |
|---------|------|------|
| 前台接口 | `/v1/` | `/v1/orders` |
| 后台接口 | `/admin/v1/` | `/admin/v1/orders` |
| 服务间调用 | `/api/v1/` | `/api/v1/orders` |

### 命名规约

| 类别 | 命名格式 | 示例 | 归属 |
|------|---------|------|------|
| Controller | `{Resource}Controller` | `OrderController` | adapter |
| Request DTO | `{Resource}{Action}Cmd` / `{Resource}{Action}Qry` | `OrderCreateCmd`, `OrderListQry` | app |
| Response DTO | `{Resource}VO` | `OrderVO` | app |

### 职责边界

参数校验（`@Valid`）→ 调用 app 层 → 转 VO 返回；成功非 200 状态码用 `@ResponseStatus` 声明，错误状态码由异常处理器统一返回。**禁止业务逻辑 / 直接调 domain 或 infrastructure**

```java
@RestController
@RequestMapping("/v1/orders")
public class OrderController {
    private final OrderService orderService;

    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    public OrderVO create(@RequestBody @Valid OrderCreateCmd cmd) { return orderService.createOrder(cmd); }

    @GetMapping("/{orderId}")
    public OrderVO getById(@PathVariable String orderId) { return orderService.findById(orderId); }

    @GetMapping
    public PageResult<OrderVO> list(OrderListQry qry) { return orderService.listOrders(qry); }

    @PutMapping("/{orderId}") @ResponseStatus(HttpStatus.NO_CONTENT)
    public void update(@PathVariable String orderId, @RequestBody @Valid OrderUpdateCmd cmd) { orderService.updateOrder(orderId, cmd); }

    @DeleteMapping("/{orderId}") @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable String orderId) { orderService.deleteOrder(orderId); }
}
```

### HTTP 状态码规约

**禁止一律返回 200 + body errCode。** 成功返回数据或无体，失败用正确 HTTP 状态码。

| 状态码 | 场景 | 状态码 | 场景 |
|--------|------|--------|------|
| 200 | GET 查询 / POST 返回数据 | 400 | 参数校验失败 |
| 201 | POST 创建资源 | 401 | 未认证 |
| 204 | PUT/DELETE 成功无返回体 | 403 | 无权限 |
| 303 | 状态变更后重定向 | 404 | 资源不存在 |
| | | 500 | 服务端故障 |

❌ `200 OK` + `{errCode: "NOT_FOUND"}`　✅ `404 Not Found` + `{errCode: "NOT_FOUND"}`

## api 包

服务间调用接口实现，http 与 rpc 共享同一套 DTO。

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| HTTP 实现 | `{Resource}HttpApi` | `OrderHttpApi` |
| RPC 实现 | `{Resource}RpcApi` | `OrderRpcApi` |
| 共享接口 | `{Resource}Api` | `OrderApi`（client 模块定义） |
| 入参/出参 | `{Resource}{Action}DTO` / `{Resource}DTO` | `OrderCreateDTO` / `OrderDTO` |

| 维度 | http（Feign） | rpc（Dubbo） |
|------|-------------|-------------|
| 注解 | `@RestController` | `@DubboService` |
| 消费方 | `@FeignClient` | `@DubboReference` |
| 路径 | URI 路径 | 接口 + version 路由 |
| 版本策略 | URI `/api/v1/` | Dubbo `version` 属性 |

controller 与 api 区别：前者面向前端（Cmd/Qry/VO），后者面向微服务（DTO）；前者用户 Token 认证，后者内网信任。

## scheduler 包

命名：`{JobDescription}Job`（如 `OrderTimeoutCheckJob`）。仅触发，委托 app 层。

## listener 包

命名：`{EventDescription}Listener`（如 `PaymentResultListener`）。反序列化消息 → 调用 app 层 EventHandler。**禁止写业务逻辑。**

> Listener 仅用于**分布式事件**（跨服务 MQ）。**进程内事件**由 app 层 `@EventListener` 直接监听 Spring 事件总线。

## Mandatory 规则

1. Adapter **禁止按领域划分**，必须按协议组织（controller/api/listener/scheduler）
2. Cmd/Qry/VO 定义在 app 模块，DTO 定义在 client 模块，禁止在 adapter 中重新定义
3. Controller/HttpApi/RpcApi **禁止编写业务逻辑**，仅做校验和转发
4. Adapter **禁止直接依赖 domain 或 infrastructure**
5. Controller **必须遵循 restful-convention**；**禁止一律返回 200**
6. http 与 rpc **禁止各自定义独立 DTO**，必须共享 client 中的同一套 DTO
7. Listener **禁止直接调 domain service 或 infrastructure**，必须通过 app 层 EventHandler

## Recommended 规则

1. 一个 Controller 对应一个领域资源
2. 列表查询使用 `PageResult<T>` 封装分页
3. DTO↔领域对象转换放 Adapter 层
4. Scheduler/Listener 异常捕获后记日志，不吞异常
5. `{Resource}Api` 接口和 DTO 放 client 模块，adapter.api 实现该接口