# App Layer

应用层目录规约。App 层负责用例编排，协调领域服务完成业务流程，不包含业务规则。

## 目录结构

App 层按领域聚合组织目录，每个领域独立子包，与 domain 层的领域子包一一对应。

```
app
└── src/main/java/com/{company}/{project}/app
    ├── {domain1}/                   # 领域 1（如 order）
    │   ├── service/                 # 应用服务（用例入口）
    │   ├── executor/
    │   │   ├── command/             # 写操作执行器
    │   │   └── query/               # 读操作执行器
    │   ├── eventhandler/            # 领域事件处理器
    │   ├── processor/               # 流程编排器（可选）
    │   ├── command/                 # 写操作入参（Cmd）
    │   ├── query/                   # 读操作入参（Qry）
    │   └── vo/                      # 视图对象（VO）
    └── {domain2}/                   # 领域 2（如 inventory）
        ├── service/
        ├── executor/
        │   ├── command/
        │   └── query/
        ├── eventhandler/
        ├── command/
        ├── query/
        └── vo/
```

> 按领域聚合划分目录，Cmd / Qry / VO 跟随所属领域，避免所有入参对象混在一起。

## 对象类型命名规约

App 模块定义 Cmd / Qry / VO 三种对象类型，供 adapter 层使用。详见 `references/object-isolation.md`。

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| Command | `{Resource}{Action}Cmd` | `OrderCreateCmd` |
| Query | `{Resource}{Action}Qry` | `OrderListQry` |
| View Object | `{Resource}VO` | `OrderVO` |

## service 包

### 命名规约

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| Application Service | `{Domain}Service` | `OrderService` |

### 职责边界

- 对外暴露用例方法（Adapter 层的调用入口）、编排领域服务/Executor/Processor
- 事务边界控制（`@Transactional`）、持久化成功后发布领域事件
- **禁止**包含业务规则判断 / 直接操作数据库

> **事件发布时机**：必须在聚合根持久化成功（`save`）之后才发布事件，确保消费者查询时数据已落库。发布后调用 `clearEvents()` 避免重复发布。

## executor/command 包

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| Command Executor | `{Action}{Resource}Cmd` | `OrderCreateCmd` |

- 接收 Cmd → 转换为领域对象 → 调用领域服务或 Gateway → 转换为 VO 返回
- 一个 Cmd 对应一个写操作用例

## executor/query 包

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| Query Executor | `{Action}{Resource}Qry` | `OrderListQry` |

- 接收 Qry → 可绕过领域层直接调用 infrastructure 的查询 Gateway → 组装分页响应
- 一个 Qry 对应一个读操作用例

## processor 包（可选）

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| Processor | `{ProcessDescription}Processor` | `OrderCreateProcessor` |

当用例流程复杂（多步骤编排）时，从 Service 中抽取。编排多个领域服务调用，**禁止**包含业务规则。

## eventhandler 包

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| 事件处理器 | `{Domain}EventHandler` | `OrderEventHandler` |

### 职责边界

- 按领域聚合组织，一个 EventHandler 处理该领域下的所有事件，避免碎片化
- 接收领域事件 → 按事件类型分发 → 编排领域服务 / Gateway 完成事件触发的后续操作（如跨聚合状态变更、通知发送等）
- **禁止**包含业务规则，业务规则由领域服务或实体承担
- **禁止**在 Handler 中直接 `new` 领域实体，必须通过领域服务工厂方法创建

### 两种监听场景

领域事件监听分为**进程内**和**分布式**两种场景，EventHandler 必须根据场景选择正确的监听机制：

| 场景 | 监听机制 | 适用条件 | 事务控制 | 是否经过 adapter |
|------|---------|---------|---------|----------------|
| 进程内事件 | `@EventListener` | 同 JVM 内跨聚合协作 | 与发布者同一事务（`@Transactional` 在 Service 上即可） | 否，Spring 事件总线直接分发 |
| 分布式事件 | 被 adapter listener 调用 | 跨服务通信，需 MQ | 消费者侧独立事务（`@Transactional` 在 EventHandler 方法上） | 是，adapter listener 反序列化后调用 |

### 代码示例

#### 进程内事件（同 JVM）

```java
@Component
@RequiredArgsConstructor
public class OrderEventHandler {
    private final InventoryDomainService inventoryDomainService;

    @EventListener
    public void onOrderSubmitted(OrderSubmittedEvent event) {
        inventoryDomainService.reserveStock(event.getOrderId());
    }

    @EventListener
    public void onOrderCancelled(OrderCancelledEvent event) {
        inventoryDomainService.releaseStock(event.getOrderId());
    }
}
```

> 进程内事件使用 `@EventListener`，由 Spring `ApplicationEventPublisher` 分发，与发布者在同一事务内，无需额外 `@Transactional`。

#### 分布式事件（跨服务）

```java
@Component
@RequiredArgsConstructor
public class OrderEventHandler {
    private final InventoryDomainService inventoryDomainService;

    @Transactional
    public void onOrderSubmitted(OrderSubmittedEvent event) {
        inventoryDomainService.reserveStock(event.getOrderId());
    }

    @Transactional
    public void onOrderCancelled(OrderCancelledEvent event) {
        inventoryDomainService.releaseStock(event.getOrderId());
    }
}
```

> 分布式事件由 adapter listener 调用，消费者侧独立事务，EventHandler 方法需加 `@Transactional`。

### 事件处理流程

#### 进程内（同 JVM）

```
domain entity                app service                   app eventhandler
     │                           │                              │
     ▼                           ▼                              ▼
 registerEvent()            ApplicationEventPublisher       @EventListener
     │                      .publishEvent()                     │
     ▼                           ▼                              ▼
 存入聚合根内存列表       Spring 事件总线分发          EventHandler.onXxx()
                           (同步，同一事务内)          编排领域服务
```

#### 分布式（跨服务）

```
domain entity          app service          infra publisher         adapter listener        app eventhandler
     │                     │                      │                      │                      │
     ▼                     ▼                      ▼                      ▼                      ▼
 registerEvent()      publish 到 MQ          DomainEventPublisher    MQ Consumer             EventHandler.onXxx()
     │                (事务提交后)            发送到 MQ               反序列化                 编排领域服务
     ▼                     ▼                      ▼                      ▼                      ▼
 存入聚合根内存列表    clearEvents()          序列化 + 重试           转换为事件对象           @Transactional
```

## Mandatory 规则

1. App 层**必须**按领域聚合组织目录，每个领域一个独立子包，与 domain 层领域子包一一对应，**禁止**按技术职责平铺
2. Application Service 命名必须以 `Service` 结尾
3. Command Executor 命名必须以 `Cmd` 结尾，Query Executor 命名必须以 `Qry` 结尾
4. App 层**禁止**包含业务规则，业务规则必须在 domain 层
5. 事务注解 `@Transactional` 只能出现在 Application Service 或 EventHandler（分布式场景）上；进程内事件使用 `@EventListener`，与发布者同一事务，**禁止**额外加 `@Transactional`
6. Cmd / Qry 不得互相调用
7. App 层**禁止**直接依赖 infrastructure 模块的具体实现类
8. 当领域服务（`XxxDomainService`）已存在时，App 层**必须**注入并使用它，**禁止**在 App 层重新实现相同逻辑
9. 领域事件的处理逻辑**必须**放在 `app.eventhandler` 包中，**禁止**在 adapter listener 或 domain service 中直接处理事件触发的后续操作
10. EventHandler 命名必须以 `EventHandler` 结尾，按领域聚合组织，一个 EventHandler 处理该领域下的所有事件，**禁止**一个事件一个 Handler
11. 进程内事件**必须**使用 `@EventListener`，分布式事件**必须**由 adapter listener 调用 EventHandler，**禁止**混用

## Recommended 规则

1. 一个 Application Service 对应一个领域聚合
2. 一个 Cmd / Qry 只做一件事（单一职责）
3. 简单用例直接在 Service 中编排，不需要额外 Processor
4. Query Executor 中可直接调用 Gateway 的查询方法，不必经过领域服务
5. Cmd / Qry / VO 定义在 app 模块，供 adapter 层使用，不要在 adapter 层重新定义