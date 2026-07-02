# Service API Documentation Extraction Spec

Rules for extracting service-to-service API documentation from COLA 5 client module and adapter.api implementations.

## Source Location

- Api interfaces: `{module}-client/src/main/java/{basePackage}/api/`
- DTO classes: `{module}-client/src/main/java/{basePackage}/dto/`
- HTTP implementation: `{module}-adapter/src/main/java/{basePackage}/adapter/api/http/`
- RPC implementation: `{module}-adapter/src/main/java/{basePackage}/adapter/api/rpc/`

## When Client Module Exists

Client module exists when:
- There is a `{module}-client` directory in the project
- Other microservices need to call this service via Feign/Dubbo

If no client module exists, skip service API documentation entirely.

> 有 client → 有 adapter.api；无 client → 无 adapter.api

## Api Interface Extraction

For each `{Resource}Api` interface, extract:

| Field | Source | Example |
|-------|--------|---------|
| Resource Name | Interface javadoc or name derivation | "Order" from OrderApi |
| Methods | Interface method signatures | See method extraction below |

## Method-Level Extraction

For each method in the Api interface:

| Field | Source | Example |
|-------|--------|---------|
| Method Name | Java method name | "createOrder" |
| Description | Method javadoc | "创建订单" |
| Parameters | Method params with DTO types | OrderCreateDTO |
| Return Type | Method return type | OrderDTO |

> Api method naming MUST use business semantics, **禁止 CRUD 风格** (e.g., use `createOrder` not `save`).

## Transport Detection

Check `adapter/api/` for implementations:

| Implementation | Location | Annotation | Transport | Path Prefix |
|---------------|----------|------------|-----------|-------------|
| `{Resource}HttpApi` | adapter/api/http/ | `@RestController` | HTTP (Feign) | `/api/v1/` |
| `{Resource}RpcApi` | adapter/api/rpc/ | `@DubboService` | RPC (Dubbo) | Dubbo `version` |

| Transport | Consumer Annotation | Version Strategy |
|-----------|-------------------|-----------------|
| HTTP (Feign) | `@FeignClient` | URI `/api/v1/` |
| RPC (Dubbo) | `@DubboReference` | Dubbo `version` 属性 |

> http 与 rpc **禁止各自定义独立 DTO**，必须共享 client 同一套 DTO。

## DTO Extraction

For each DTO class, extract every field:

| Field | Source |
|-------|--------|
| Field Name | Java field name |
| Type | Java type |
| Required | `@NotBlank`, `@NotNull`, `@NotEmpty` |
| Constraints | `@Size`, `@Email`, `@Pattern`, `@Min`, `@Max` |
| Description | Field javadoc |

## DTO Naming Convention

| DTO Type | Naming Pattern | Purpose |
|----------|---------------|---------|
| Write DTO | `{Resource}{Action}DTO` | Create/update input (e.g., OrderCreateDTO) |
| Query DTO | `{Resource}QueryDTO` | Query/filter input (e.g., OrderQueryDTO) |
| Response DTO | `{Resource}DTO` | Response output (e.g., OrderDTO) |

## DTO Rules (from client-module convention)

- **禁止实现 Serializable**，不声明 serialVersionUID
- 字段使用包装类型（`Long` 非 `long`），避免 NPE
- 日期字段用 `OffsetDateTime` / `LocalDate`
- **禁止包含领域内部实现细节**

## Cross-Reference with Controller

When both controller and client module exist:

1. Controller (Cmd/Qry/VO) vs Api (DTO) — different object types for different audiences
2. Controller: frontend-facing, user Token auth, path `/v1/`
3. Api: microservice-facing, internal trust, path `/api/v1/`
4. Both share the same app layer entry points
5. Identify operations available only via controller (web-only) or only via api (service-only)

## Object Isolation Reference

| Object Type | Suffix | Layer | Usage |
|------------|--------|-------|-------|
| Command | Cmd | app | Write operation input |
| Query | Qry | app | Read operation input |
| View Object | VO | app | Frontend response |
| DTO | DTO | client | Service-to-service input/output |

> Cmd/Qry/VO defined in app module. DTO defined in client module. **禁止在 adapter 中重新定义。**

## Mandatory Rules

1. **Must** read actual source code — never fabricate interface information
2. **Must** document all methods in each Api interface
3. **Must** include parameter and return type details
4. **Must** note the transport type (HTTP/RPC/both)
5. **Must** document DTO fields with types and constraints
6. **Must** use `/api/v1/` path prefix for service-to-service HTTP endpoints (not `/v1/`)
