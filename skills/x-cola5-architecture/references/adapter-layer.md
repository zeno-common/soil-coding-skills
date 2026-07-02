# Adapter Layer

系统输入端，接收外部请求并转换为应用层调用。**按协议组织目录，不按领域划分。**

## Structure

```
adapter/src/main/java/{basePackage}/adapter
├── controller           # Web REST（面向前端）
├── api
│   ├── http             # Feign Provider
│   └── rpc              # Dubbo Provider
├── scheduler            # 定时任务
├── listener             # MQ Consumer
└── config               # 适配层配置
```

## controller

### Path Prefix

| Type | Prefix | Example |
|------|--------|---------|
| Frontend | `/v1/` | `/v1/orders` |
| Admin | `/admin/v1/` | `/admin/v1/orders` |
| Service-to-service | `/api/v1/` | `/api/v1/orders` |

### Naming

| Type | Pattern | Example | Owner |
|------|---------|---------|-------|
| Controller | `{Resource}Controller` | `OrderController` | adapter |
| Request | `{Resource}{Action}Cmd` / `Qry` | `OrderCreateCmd` | app |
| Response | `{Resource}VO` | `OrderVO` | app |

### Pattern

Validate(`@Valid`) → call app layer → return VO. Non-200 success: `@ResponseStatus`. Errors: exception handler. **No business logic / no direct domain or infrastructure calls.**

```java
@RestController @RequestMapping("/v1/orders")
public class OrderController {
    private final OrderService orderService;

    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    public OrderVO create(@RequestBody @Valid OrderCreateCmd cmd) { return orderService.createOrder(cmd); }

    @GetMapping("/{orderId}")
    public OrderVO getById(@PathVariable String orderId) { return orderService.findById(orderId); }

    @GetMapping
    public PagedResult<OrderVO> list(OrderListQry qry) { return orderService.listOrders(qry); }

    @PutMapping("/{orderId}") @ResponseStatus(HttpStatus.NO_CONTENT)
    public void update(@PathVariable String orderId, @RequestBody @Valid OrderUpdateCmd cmd) { orderService.updateOrder(orderId, cmd); }

    @DeleteMapping("/{orderId}") @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable String orderId) { orderService.deleteOrder(orderId); }
}
```

### Status Codes

MUST NOT always return 200 + body errCode.

| Code | Scenario | Code | Scenario |
|------|----------|------|----------|
| 200 | GET / POST with data | 400 | Validation failure |
| 201 | POST create | 401 | Unauthenticated |
| 204 | PUT/DELETE no body | 403 | Forbidden |
| 303 | Redirect after state change | 404 | Not found |
| | | 500 | Server error |

## api

服务间调用接口实现。**HTTP 路径注解由 client Api 接口预定义，实现类继承，MUST NOT 重复声明。**

### Naming

| Type | Pattern | Example | Note |
|------|---------|---------|------|
| HTTP impl | `{Resource}Http` | `OrderHttp` | `@RestController implements {Resource}Api`, path inherited |
| RPC impl | `{Resource}Rpc` | `OrderRpc` | `@DubboService implements {Resource}Api`, no HTTP annotations |
| Contract | `{Resource}Api` | `OrderApi` | client module (with `@RequestMapping` + HTTP Method) |
| Params | `{Resource}{Action}DTO` / `{Resource}DTO` | `OrderCreateDTO` | client module |

### HTTP vs RPC

| Dimension | http (Feign) | rpc (Dubbo) |
|-----------|-------------|-------------|
| Annotation | `@RestController` (path inherited) | `@DubboService` |
| Consumer | `@FeignClient extends {Resource}Api` | `@DubboReference` |
| Path | From client Api `@RequestMapping` | Interface + version routing |
| Versioning | URI `/api/v1/` | Dubbo `version` attribute |

> controller = frontend (Cmd/Qry/VO, Token auth); api = microservice (DTO, internal trust)

### HTTP Impl Example

```java
@RestController @RequiredArgsConstructor
public class OrderHttp implements OrderApi {
    private final OrderApplicationService orderService;
    @Override public OrderDTO getOrder(Long orderId) { return orderService.findById(orderId); }
    @Override public PagedResult<OrderDTO> listOrders(OrderQueryDTO qry) { return orderService.listOrders(qry); }
    @Override public Long createOrder(OrderCreateDTO dto) { return orderService.createOrder(dto); }
}
```

## scheduler

Naming: `{JobDescription}Job` (e.g., `OrderTimeoutCheckJob`). Trigger only, delegate to app layer.

## listener

Naming: `{EventDescription}Listener` (e.g., `PaymentResultListener`). Deserialize → call app EventHandler. **No business logic.**

> Distributed events only (cross-service MQ). In-process events: app layer `@EventListener` on Spring event bus.

## Mandatory

1. Adapter MUST organize by protocol (controller/api/listener/scheduler), NOT by domain
2. Cmd/Qry/VO in app module, DTO in client module — MUST NOT redefine in adapter
3. Controller/Http/Rpc MUST NOT contain business logic — validate and forward only
4. Adapter MUST NOT depend on domain or infrastructure directly
5. Controller MUST follow RESTful conventions; MUST NOT always return 200
6. http and rpc MUST share client DTO — MUST NOT define independent DTOs
7. Listener MUST NOT call domain service or infrastructure directly — must go through app EventHandler