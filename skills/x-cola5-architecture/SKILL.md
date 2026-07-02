---
name: "x-cola5-architecture"
description: "Enforces COLA 5 directory and layer conventions for Java projects. Invoke when creating Java project structure, adding classes, deciding which layer a class belongs to, or reviewing architecture compliance."
---

# COLA 5 Architecture Conventions

Alibaba COLA 5 clean architecture conventions for Java projects.

| Section | Reference | When to Read |
|---------|-----------|-------------|
| Project Structure | `references/project-structure.md` | New project / module setup |
| Client Module | `references/client-module.md` | Service-to-service API contracts |
| Adapter Layer | `references/adapter-layer.md` | Controller / Scheduler / Listener |
| App Layer | `references/app-layer.md` | Application Service / Executor / Processor |
| Domain Layer | `references/domain-layer.md` / `references/object-isolation.md` | Entity / Domain Service / Gateway / Object types |
| Infrastructure Layer | `references/infrastructure-layer.md` | GatewayImpl / Mapper / Client |
| Lombok Annotations | `references/lombok-usage.md` | Choosing Lombok annotations |

## Core Dependency Rule

```
adapter → app → domain ← infrastructure
```

- **adapter** depends on **app** + **client**
- **app** depends on **domain**
- **infrastructure** depends on **domain** (implements gateway interfaces)
- **domain** / **client** depend on NOTHING
- **adapter** NEVER depends on **infrastructure**

## Quick Reference

### Adding New Class
1. Identify responsibility → read corresponding layer reference
2. Read `object-isolation.md` for correct object type
3. Place in correct package, follow naming rules

### Lombok Quick Pick
| Object Type | Annotations |
|------------|-------------|
| Entity | `@Getter` only (no @Data/@Setter/@Builder) |
| ValueObject / Event | `@Getter @EqualsAndHashCode`, fields final |
| Cmd / Qry / VO | `@Data @Builder` |
| DTO / DO | `@Data @Builder @NoArgsConstructor @AllArgsConstructor` |
| Service class | `@RequiredArgsConstructor` (+ `@Slf4j` if allowed) |