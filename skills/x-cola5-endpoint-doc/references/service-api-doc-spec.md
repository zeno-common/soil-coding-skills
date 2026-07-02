# Service API Documentation Extraction Spec

Rules for extracting service-to-service API documentation from COLA 5 adapter.api HTTP/RPC implementation classes.

## Core Principle

The primary source for service API documentation is the **adapter.api implementation layer** — the actual HTTP endpoints (`adapter/api/http/`) and RPC services (`adapter/api/rpc/`) that other microservices call. The client module Api interface is a secondary reference for method signatures and javadoc.

## Source Location

- HTTP endpoints: `{module}-adapter/src/main/java/{basePackage}/adapter/api/http/`
- RPC services: `{module}-adapter/src/main/java/{basePackage}/adapter/api/rpc/`
- DTO classes: `{module}-client/src/main/java/{basePackage}/dto/`
- Api interfaces (contract reference): `{module}-client/src/main/java/{basePackage}/api/`

## When Service API Documentation Exists

Service API documentation exists when `adapter/api/` directory contains implementation classes:
- `adapter/api/http/` has `@RestController` classes → HTTP (Feign) endpoints
- `adapter/api/rpc/` has `@DubboService` classes → RPC (Dubbo) services

If neither directory has implementation classes, skip service API documentation entirely.

> adapter.api exists ⇔ client module exists. No client module ⇔ no adapter.api.

## HTTP Endpoint Extraction (adapter/api/http/)

For each `@RestController` class under `adapter/api/http/`, extract:

### Class-Level Extraction

| Field | Source | Example |
|-------|--------|---------|
| Resource Name | Class javadoc or derive from class name | "Account" from AccountHttp |
| Base Path | `@RequestMapping` value | "/api/v1/accounts" |
| Transport | Always "HTTP (Feign)" | HTTP (Feign) |

### Endpoint-Level Extraction

For each method annotated with HTTP mapping annotations, extract:

| Field | Source | Example |
|-------|--------|---------|
| HTTP Method | Annotation type | GET, POST, PUT, DELETE |
| Path | Annotation value + base path | "/api/v1/accounts/{id}" |
| Description | Method javadoc (first line), fallback to client Api interface method javadoc | "根据ID查询账户信息" |
| Parameters | Method params + `@PathVariable` / `@RequestParam` / `@RequestBody` | See parameter extraction below |
| Request Body | `@RequestBody` param type (DTO) | OrderCreateDTO |
| Response Type | Method return type (DTO) | OrderDTO, void |
| Status Code | `@ResponseStatus` annotation | 201, 204 (default 200) |

### Parameter Extraction Rules

Same as web API parameter extraction rules (see `references/web-api-doc-spec.md`), but parameter and body types are DTOs instead of Cmd/Qry.

## RPC Service Extraction (adapter/api/rpc/)

For each `@DubboService` class under `adapter/api/rpc/`, extract:

### Class-Level Extraction

| Field | Source | Example |
|-------|--------|---------|
| Resource Name | Class javadoc or derive from class name | "Account" from AccountRpc |
| Service Interface | `implements` clause | AccountApi |
| Transport | Always "RPC (Dubbo)" | RPC (Dubbo) |
| Version | `@DubboService.version` attribute | "1.0.0" |

### Method-Level Extraction

For each public method, extract:

| Field | Source | Example |
|-------|--------|---------|
| Method Name | Java method name | "getAccountById" |
| Description | Method javadoc, fallback to client Api interface method javadoc | "根据ID查询账户信息" |
| Parameters | Method params with DTO types | id: Long, dto: OrderCreateDTO |
| Return Type | Method return type | OrderDTO |

> Method naming MUST use business semantics, MUST NOT use CRUD naming (e.g., use `createOrder` not `save`).

## Client Api Interface as Reference

The `{Resource}Api` interface in `client/api/` is NOT the primary source for documentation. It serves as:

1. **Method signature reference** — when adapter.api implementation delegates to app layer, the Api interface clarifies the intended contract
2. **Javadoc fallback** — if the implementation class lacks javadoc, use the Api interface method javadoc
3. **Method naming convention** — Api interface defines the business-semantic method names

## DTO Extraction

For each DTO class under `client/dto/`, extract every field:

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

- MUST NOT implement Serializable, MUST NOT declare serialVersionUID
- Use wrapper types (`Long` not `long`) to avoid NPE
- Date fields use `OffsetDateTime` / `LocalDate`
- MUST NOT include domain internal implementation details

## Cross-Reference with Controller

When both controller and adapter.api exist:

1. Controller (Cmd/Qry/VO) vs adapter.api (DTO) — different object types for different audiences
2. Controller: frontend-facing, user Token auth, path `/v1/`
3. adapter.api: microservice-facing, internal trust, path `/api/v1/`
4. Both share the same app layer entry points
5. Identify operations available only via controller (web-only) or only via adapter.api (service-only)

## Object Isolation Reference

| Object Type | Suffix | Layer | Usage |
|------------|--------|-------|-------|
| Command | Cmd | app | Write operation input |
| Query | Qry | app | Read operation input |
| View Object | VO | app | Frontend response |
| DTO | DTO | client | Service-to-service input/output |

> Cmd/Qry/VO defined in app module. DTO defined in client module. MUST NOT redefine in adapter.

## Mandatory Rules

1. **Must** read actual source code — never fabricate endpoint information
2. **Must** document all HTTP endpoints in `adapter/api/http/` and all RPC services in `adapter/api/rpc/`
3. **Must** include HTTP method, full path, and response type for every HTTP endpoint
4. **Must** include service interface, version, and method details for every RPC service
5. **Must** note the transport type (HTTP/RPC/both) for each resource
6. **Must** document DTO fields with types and constraints
7. **Must** use `/api/v1/` path prefix for service-to-service HTTP endpoints (not `/v1/`)
8. **Must** use adapter.api implementation as primary source; client Api interface as secondary reference only