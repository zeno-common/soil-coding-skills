---
name: "x-cola5-light-architecture"
description: "COLA 5 Light architecture conventions for Java: single Maven module with package-level layered structure (adapter → application → domain ← infrastructure), derived from cola-framework-archetype-light, plus a standalone client contract module (API contract jar, independently publishable). Invoke when scaffolding or structuring a Java project, creating/adding/moving classes, deciding which layer a class belongs to, splitting API contracts into a client module, enforcing dependency direction (no adapter→infrastructure, domain/client depend on nothing, consumer depends on client jar only), or reviewing/auditing architecture compliance."
---

# COLA 5 Light Architecture

> 基于 `cola-framework-archetype-light`：**Light = 单 Maven 模块，分层用 Java 包实现**，没有 `client`/`start` 等独立模块，`Application` 启动类在根包。本规范按需求将 API 契约**单独拆分为 `client` 模块**，作为对外发布的**契约包**（可独立发布为 jar，供消费方依赖）。

| Section | Reference | When to Read |
|---------|-----------|-------------|
| Project Structure | `references/project-structure.md` | New project / module setup |
| Client Module (外部契约包) | `references/client-module.md` | Service-to-service API contracts |
| Adapter Layer | `references/adapter-layer.md` | Controller / Scheduler / Listener |
| App Layer | `references/app-layer.md` | Application Service / Executor / Processor |
| Domain Layer | `references/domain-layer.md` / `references/object-isolation.md` | Entity / Domain Service / Gateway / Object types |
| Infrastructure Layer | `references/infrastructure-layer.md` | GatewayImpl / Mapper / Client |
| Lombok Annotations | `references/lombok-usage.md` | Choosing Lombok annotations |

## Dependency Rule

```
app module:  adapter → application → domain ← infrastructure
adapter → client ; application → client ; infrastructure → client
```

- domain / client depend on NOTHING
- adapter NEVER depends on infrastructure
- consumer depends on client jar only

## Lombok Quick Pick

| Object Type | Annotations |
|------------|-------------|
| Entity | `@Getter` only |
| ValueObject / Event | `@Getter @EqualsAndHashCode`, fields final |
| Cmd / Qry / VO | `@Data @Builder` |
| DTO / DO | `@Data @Builder @NoArgsConstructor @AllArgsConstructor` |
| Service class | `@RequiredArgsConstructor` (+ `@Slf4j` if allowed) |
