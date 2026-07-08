# App Layer

用例编排层，协调领域服务完成业务流程。**不包含业务规则。按领域聚合组织目录。**

## Structure

```
app/src/main/java/{basePackage}/app
└── {biz}/
    ├── service/                 # 应用服务（用例入口）
    ├── executor/
    │   ├── command/             # 写操作执行器
    │   └── query/               # 读操作执行器
    ├── eventhandler/            # 领域事件处理器
    ├── processor/               # 流程编排器（可选）
    ├── command/                 # Cmd
    ├── query/                   # Qry
    └── vo/                      # VO
```

## Naming

| Type | Pattern | Example |
|------|---------|---------|
| Command | `{Resource}{Action}Cmd` | `OrderCreateCmd` |
| Query | `{Resource}{Action}Qry` | `OrderListQry` |
| View Object | `{Resource}VO` | `OrderVO` |
| Service | `{Domain}Service` | `OrderService` |
| CmdExe | `{Action}{Resource}CmdExe` | `CreateOrderCmdExe` |
| QryExe | `{Action}{Resource}QryExe` | `ListOrderQryExe` |
| Processor | `{ProcessDescription}Processor` | `OrderCreateProcessor` |
| EventHandler | `{Domain}EventHandler` | `OrderEventHandler` |

## Responsibilities

| Component | Responsibility |
|-----------|---------------|
| Service | Use case entry, orchestrate domain services, `@Transactional`, persist then publish events |
| CmdExe | Receive Cmd → convert to domain object → call domain service/Gateway → return VO |
| QryExe | Receive Qry → may call Gateway directly → assemble paged response |
| Processor | Multi-step orchestration for complex use cases (optional) |
| EventHandler | Handle events per domain aggregate, orchestrate domain services for follow-up |

## Event Handling

| Scenario | Mechanism | Transaction |
|----------|-----------|-------------|
| In-process | `@EventListener` | Same as publisher |
| Distributed | Called by adapter.listener | Independent `@Transactional` |

> Publish events AFTER aggregate `save()`, then `clearEvents()` to prevent duplicate.

## Mandatory

1. MUST organize by domain aggregate — MUST NOT flat-layout by technical concern
2. Suffix: Service/CmdExe/QryExe/EventHandler
3. MUST NOT contain business rules — those belong in domain
4. `@Transactional` only on Service or EventHandler (distributed); in-process events MUST NOT add extra `@Transactional`
5. Cmd/Qry MUST NOT call each other; App MUST NOT depend on infrastructure directly
6. Event handling MUST be in app.eventhandler — MUST NOT be in adapter listener or domain service
7. One EventHandler per domain — MUST NOT create one handler per event
8. In-process events: `@EventListener`; distributed events: called by adapter listener

## Recommended

1. One Service per domain aggregate; simple use cases: orchestrate directly in Service, no Processor
2. QryExe may call Gateway directly, no need to go through domain service
3. MUST inject and use existing DomainService — MUST NOT re-implement same logic
4. MUST NOT directly `new` domain entities — use DomainService factory methods