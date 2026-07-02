# App Layer

应用层目录规约。App 层负责用例编排，协调领域服务完成业务流程，**不包含业务规则**。**按领域聚合组织目录。**

## 目录结构

```
app/src/main/java/com/{company}/{project}/app
└── {domain}/                    # 领域子包（如 order）
    ├── service/                 # 应用服务（用例入口）
    ├── executor/
    │   ├── command/             # 写操作执行器
    │   └── query/               # 读操作执行器
    ├── eventhandler/            # 领域事件处理器
    ├── processor/               # 流程编排器（可选）
    ├── command/                 # 写操作入参（Cmd）
    ├── query/                   # 读操作入参（Qry）
    └── vo/                      # 视图对象（VO）
```

## 对象类型命名

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| Command | `{Resource}{Action}Cmd` | `OrderCreateCmd` |
| Query | `{Resource}{Action}Qry` | `OrderListQry` |
| View Object | `{Resource}VO` | `OrderVO` |

## 各包职责

| 包 | 命名格式 | 示例 | 职责 |
|----|---------|------|------|
| service | `{Domain}Service` | `OrderService` | 用例入口、编排领域服务、事务控制（`@Transactional`）、持久化后发布事件 |
| executor/command | `{Action}{Resource}CmdExe` | `OrderCreateCmdExe` | 接收 Cmd → 转领域对象 → 调领域服务/Gateway → 返回 VO |
| executor/query | `{Action}{Resource}QryExe` | `OrderListQryExe` | 接收 Qry → 可直调 Gateway 查询 → 组装分页响应 |
| processor | `{ProcessDescription}Processor` | `OrderCreateProcessor` | 复杂用例的多步骤编排（可选） |
| eventhandler | `{Domain}EventHandler` | `OrderEventHandler` | 按领域聚合处理事件，编排领域服务完成后续操作 |

## EventHandler 事件监听

| 场景 | 监听机制 | 适用条件 | 事务 | 经由 adapter |
|------|---------|---------|------|-------------|
| 进程内事件 | `@EventListener` | 同 JVM 跨聚合协作 | 与发布者同事务 | 否 |
| 分布式事件 | 被 listener 调用 | 跨服务 MQ 通信 | 消费者侧独立 `@Transactional` | 是 |

```java
// 进程内事件
@Component
@RequiredArgsConstructor
public class OrderEventHandler {
    private final InventoryDomainService inventoryDomainService;

    @EventListener
    public void onOrderSubmitted(OrderSubmittedEvent event) { inventoryDomainService.reserveStock(event.getOrderId()); }
}

// 分布式事件（被 adapter.listener 调用）
@Transactional
public void onOrderSubmitted(OrderSubmittedEvent event) { inventoryDomainService.reserveStock(event.getOrderId()); }
```

> 事件发布时机：必须在聚合根 `save()` 之后，确保消费者查询时数据已落库。发布后调用 `clearEvents()`。

## Mandatory 规则

1. App 层**必须按领域聚合组织**，每个领域一个子包，**禁止按技术职责平铺**
2. Service 以 `Service` 结尾；CmdExe 以 `CmdExe` 结尾；QryExe 以 `QryExe` 结尾；EventHandler 以 `EventHandler` 结尾
3. App 层**禁止包含业务规则**，业务规则在 domain 层
4. `@Transactional` 只能出现在 Service 或 EventHandler（分布式场景）；进程内事件**禁止额外加 `@Transactional`**
5. Cmd / Qry 不得互相调用；App 层**禁止直接依赖 infrastructure**
6. 领域事件处理**必须放在 app.eventhandler**，**禁止在 adapter listener 或 domain service 中处理**
7. 一个 EventHandler 处理该领域下所有事件，**禁止一个事件一个 Handler**
8. 进程内事件**必须用 `@EventListener`**，分布式事件**必须由 adapter listener 调用**

## Recommended 规则

1. 一个 Service 对应一个领域聚合；简单用例直接在 Service 编排，无需 Processor
2. QueryExe 可直调 Gateway 查询方法，不必经领域服务
3. App 层**必须注入并使用已有的 DomainService**，**禁止重新实现相同逻辑**
4. App 层**禁止直接 new 领域实体**，必须通过 DomainService 工厂方法创建