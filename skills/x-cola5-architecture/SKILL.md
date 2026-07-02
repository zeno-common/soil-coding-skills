---
name: "x-cola5-architecture"
description: "Enforces COLA 5 directory and layer conventions for Java projects. Invoke when creating Java project structure, adding classes, deciding which layer a class belongs to, or reviewing architecture compliance."
---

# COLA 5 Architecture

| Section | Reference | When to Read |
|---------|-----------|-------------|
| Project Structure | `references/project-structure.md` | New project / module setup |
| Client Module | `references/client-module.md` | Service-to-service API contracts |
| Adapter Layer | `references/adapter-layer.md` | Controller / Scheduler / Listener |
| App Layer | `references/app-layer.md` | Application Service / Executor / Processor |
| Domain Layer | `references/domain-layer.md` / `references/object-isolation.md` | Entity / Domain Service / Gateway / Object types |
| Infrastructure Layer | `references/infrastructure-layer.md` | GatewayImpl / Mapper / Client |
| Lombok Annotations | `references/lombok-usage.md` | Choosing Lombok annotations |

## Dependency Rule

```
adapter → app → domain ← infrastructure
adapter → client
```

- domain / client depend on NOTHING
- adapter NEVER depends on infrastructure

## Lombok Quick Pick

| Object Type | Annotations |
|------------|-------------|
| Entity | `@Getter` only |
| ValueObject / Event | `@Getter @EqualsAndHashCode`, fields final |
| Cmd / Qry / VO | `@Data @Builder` |
| DTO / DO | `@Data @Builder @NoArgsConstructor @AllArgsConstructor` |
| Service class | `@RequiredArgsConstructor` (+ `@Slf4j` if allowed) |