# Adapter Layer

适配层目录规约。Adapter 是系统的输入端，负责接收外部请求并转换为应用层调用。

## 目录结构

```
adapter
└── src/main/java/com/{company}/{project}/adapter
    ├── web
    │   └── controller      # REST 控制器
    ├── scheduler           # 定时任务
    ├── listener            # 消息监听（MQ Consumer）
    └── config              # 适配层配置（仅限适配层专用配置）
```

## web/controller 包

### 命名规约

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| Controller | `{Resource}Controller` | `OrderController` |
| DTO (Request) | `{Resource}{Action}Cmd` / `{Resource}{Action}Qry` | `OrderCreateCmd`, `OrderListQry` |
| DTO (Response) | `{Resource}VO` | `OrderVO` |

### 职责边界

- 参数校验（`@Valid` / `@Validated`）
- 调用 app 层 Service 或 Executor
- 将领域对象转换为 VO 返回
- **禁止**包含业务逻辑
- **禁止**直接调用 domain 或 infrastructure

### 代码示例

```java
@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {

    @Resource
    private OrderApplicationService orderApplicationService;

    @PostMapping
    public SingleResponse<OrderVO> create(@RequestBody @Valid OrderCreateCmd cmd) {
        return SingleResponse.of(orderApplicationService.createOrder(cmd));
    }
}
```

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

- 反序列化消息体
- 转换为 app 层入参并调用
- **禁止**在 listener 中写业务逻辑

## Mandatory 规则

1. Controller 类必须放在 `adapter.web.controller` 包下
2. Request DTO 命名必须以 `Cmd`（写操作）或 `Qry`（读操作）结尾
3. Response DTO 命名必须以 `VO` 结尾
4. Controller 中**禁止**编写业务逻辑，仅做参数校验和调用转发
5. Adapter 层**禁止**直接依赖 domain 或 infrastructure 模块
6. DTO 类**禁止**泄露到 app 层或 domain 层

## Recommended 规则

1. 一个 Controller 对应一个领域资源，不要按 CRUD 拆分多个 Controller
2. 使用统一响应体包装返回值（如 `SingleResponse` / `MultiResponse` / `CommonResponse`）
3. DTO 与领域对象之间的转换放在 Adapter 层，不要在 app 层做
4. Scheduler 和 Listener 中捕获异常后记录日志，不要吞掉异常