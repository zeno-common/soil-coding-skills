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

| Type | Pattern | Example                  | Folder (under `app/{biz}/`) |
|------|---------|--------------------------|-----------------------------|
| Command | `{Resource}{Action}Cmd` | `OrderCreateCmd`         | `command/`                  |
| Query | `{Resource}{Action}Qry` | `OrderListQry`           | `query/`                    |
| View Object | `{Resource}VO` | `OrderVO`                | `vo/`                       |
| Service | `{Domain}Service` | `OrderService`           | `service/`                  |
| CmdExe | `{Resource}{Action}CmdExe` | `OrderCreateCmdExe`      | `executor/command/`         |
| QryExe | `{Resource}{Action}QryExe` | `OrderListQryExe`        | `executor/query/`           |
| Processor | `{ProcessDescription}Processor` | `ExpiredOrdersProcessor` | `processor/`                |
| EventHandler | `{Domain}EventHandler` | `OrderEventHandler`      | `eventhandler/`             |

## Responsibilities

| Component | Responsibility |
|-----------|---------------|
| Service | Use case entry, orchestrate domain services, `@Transactional`, persist then publish events |
| CmdExe (write) | Single `execute(Cmd)`; convert Cmd → domain object → call domain service/Gateway → return VO. MUST go through domain Gateway, MUST NOT touch Mapper directly. Translate Sys→Biz exceptions, compensation/degradation |
| QryExe (read) | Single `execute(Qry)`; read-only data assembly & DTO conversion (may call Gateway directly). No complex business validation — validation belongs in domain |
| Processor | Multi-step orchestration for complex use cases (optional) |
| EventHandler | Handle events per domain aggregate, orchestrate domain services for follow-up |

## CQRS Read/Write Separation

| Aspect | CmdExe (Command / write) | QryExe (Query / read) |
|--------|--------------------------|-----------------------|
| Method | single `execute(Cmd)` | single `execute(Qry)` |
| Data access | via domain Gateway only | via Gateway; may bypass domain service |
| Business rules | orchestrate DomainService | none (assembly only) |
| Mapping | 1 Cmd ↔ 1 CmdExe | 1 Qry ↔ 1 QryExe |

```java
@Component @RequiredArgsConstructor
public class OrderCreateCmdExe {
    public OrderVO execute(OrderCreateCmd cmd) {
        // 1. convert Cmd → domain object
        // 2. call DomainService / Gateway (never Mapper directly)
        // 3. translate Sys→Biz exceptions, return VO
    }
}

@Component @RequiredArgsConstructor
public class OrderListQryExe {
    public PagedResult<OrderVO> execute(OrderListQry qry) {
        // read-only assembly via Gateway, no business validation
    }
}
```

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
9. Each executor exposes a single `execute()` method — MUST NOT expose multiple public entry methods
10. One Cmd ↔ one CmdExe, one Qry ↔ one QryExe (single responsibility) — MUST NOT merge multiple scenarios into one executor
11. CmdExe (write) MUST access data via domain Gateway — MUST NOT operate Mapper/DO directly; QryExe (read) may bypass domain service via Gateway but MUST NOT touch Mapper directly

## Recommended

1. One Service per domain aggregate; simple use cases: orchestrate directly in Service, no Processor
2. QryExe may call Gateway directly, no need to go through domain service
3. MUST inject and use existing DomainService — MUST NOT re-implement same logic
4. MUST NOT directly `new` domain entities — use DomainService factory methods