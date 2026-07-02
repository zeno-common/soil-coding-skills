# Endpoint Documentation Extraction Spec

Rules for extracting endpoint documentation from COLA 5 adapter layer source code.

## Source Location

| Layer | Directory | Annotation |
|-------|-----------|------------|
| Web Controller | `adapter/controller/` | `@RestController` |
| Service HTTP | `adapter/api/http/` | `@RestController` |
| Service RPC | `adapter/api/rpc/` | `@DubboService` |
| Client Interface | `client/api/` | interface (reference only) |
| Client DTO | `client/dto/` | `@Data` class |

## Path Prefix Convention

| Interface Type | Prefix | Audience |
|---------------|--------|----------|
| Frontend API | `/v1/` | Frontend / Mobile |
| Admin API | `/admin/v1/` | Backend Admin |
| Service-to-Service | `/api/v1/` | Other microservices |

## Web Controller Extraction

### Class-Level

| Field | Source | Example |
|-------|--------|---------|
| Resource Name | Class javadoc (first line) or derive from class name | "订单管理" from OrderController |
| Base Path | `@RequestMapping` value | "/v1/orders" |
| Audience | Derived from path prefix | frontend / admin |

### Endpoint-Level

| Field | Source | Example |
|-------|--------|---------|
| HTTP Method | Annotation type | GET, POST, PUT, PATCH, DELETE |
| Path | Annotation value + base path | "/v1/orders/{id}" |
| Description | Method javadoc (first line) | "查询订单详情" |
| Parameters | Method params + annotations | See parameter extraction below |
| Request Body | `@RequestBody` param type | OrderCreateCmd |
| Response Type | Method return type | OrderVO, void, PagedResult<OrderVO> |
| Status Code | `@ResponseStatus` annotation | 201, 204 (default 200) |

## Service HTTP Extraction (adapter/api/http/)

### Class-Level

| Field | Source | Example |
|-------|--------|---------|
| Resource Name | Class javadoc or derive from class name | "Account" from AccountHttp |
| Base Path | `@RequestMapping` value | "/api/v1/accounts" |
| Transport | Always "HTTP (Feign)" | HTTP (Feign) |

### Endpoint-Level

| Field | Source | Example |
|-------|--------|---------|
| HTTP Method | Annotation type | GET, POST, PUT, DELETE |
| Path | Annotation value + base path | "/api/v1/accounts/{id}" |
| Description | Method javadoc, fallback to client Api interface javadoc | "根据ID查询账户信息" |
| Parameters | Method params + annotations | Same rules as web, but types are DTO |
| Request Body | `@RequestBody` param type (DTO) | OrderCreateDTO |
| Response Type | Method return type (DTO) | OrderDTO, void |
| Status Code | `@ResponseStatus` annotation | 201, 204 (default 200) |

## Service RPC Extraction (adapter/api/rpc/)

### Class-Level

| Field | Source | Example |
|-------|--------|---------|
| Resource Name | Class javadoc or derive from class name | "Account" from AccountRpc |
| Service Interface | `implements` clause | AccountApi |
| Transport | Always "RPC (Dubbo)" | RPC (Dubbo) |
| Version | `@DubboService.version` attribute | "1.0.0" |

### Method-Level

| Field | Source | Example |
|-------|--------|---------|
| Method Name | Java method name | "getAccountById" |
| Description | Method javadoc, fallback to client Api interface javadoc | "根据ID查询账户信息" |
| Parameters | Method params with DTO types | id: Long, dto: OrderCreateDTO |
| Return Type | Method return type | OrderDTO |

> Method naming MUST use business semantics, MUST NOT use CRUD naming.

## Parameter Extraction Rules

### @RequestParam

| Field | Source |
|-------|--------|
| Name | `@RequestParam.name` or parameter name |
| Type | Java type |
| Required | `@RequestParam.required` (default true) |
| Default Value | `@RequestParam.defaultValue` (if present) |
| Description | Javadoc `@param` |

### @PathVariable

| Field | Source |
|-------|--------|
| Name | `@PathVariable.value` or parameter name |
| Type | Java type |
| Description | Javadoc `@param` |

### @RequestBody

| Field | Source |
|-------|--------|
| Type | Java class name (Cmd/Qry for web, DTO for service) |
| Validation | `@Valid` annotation presence |
| Description | Javadoc `@param` |

## Object Field Extraction

For Cmd/Qry/VO/DTO classes, extract each field:

| Field | Source |
|-------|--------|
| Field Name | Java field name |
| Type | Java type |
| Required | `@NotBlank`, `@NotNull`, `@NotEmpty` |
| Constraints | `@Size`, `@Email`, `@Pattern`, `@Min`, `@Max` |
| Description | Field javadoc |

### Object Source Location

| Object | Suffix | Module | Usage |
|--------|--------|--------|-------|
| Command | Cmd | app | Web write input |
| Query | Qry | app | Web read input |
| View Object | VO | app | Web response |
| DTO | DTO | client | Service input/output |

### DTO Naming Convention

| DTO Type | Naming Pattern | Purpose |
|----------|---------------|---------|
| Write DTO | `{Resource}{Action}DTO` | Create/update input (e.g., OrderCreateDTO) |
| Query DTO | `{Resource}QueryDTO` | Query/filter input (e.g., OrderQueryDTO) |
| Response DTO | `{Resource}DTO` | Response output (e.g., OrderDTO) |

## Pagination Pattern Recognition

When a method has `$page`, `$pageSize`, `$sortBy`, `$order` parameters and returns `PagedResult<T>`:

- `$page`: Page number starting from 1, default 1
- `$pageSize`: Items per page, default 20
- `$sortBy`: Sort field name, optional
- `$order`: Sort direction (asc/desc), default asc

> Qry object may be used directly as method param (no `@RequestBody`).

## Status Code Determination

| Condition | Status Code |
|-----------|-------------|
| `@ResponseStatus(HttpStatus.CREATED)` | 201 |
| `@ResponseStatus(HttpStatus.NO_CONTENT)` | 204 |
| No `@ResponseStatus` + returns value | 200 |
| No `@ResponseStatus` + returns void | 200 |

## Client Api Interface as Reference

The `{Resource}Api` interface in `client/api/` is NOT the primary source. It serves as:

1. **Javadoc fallback** — if implementation class lacks javadoc, use Api interface javadoc
2. **Method naming convention** — Api interface defines business-semantic method names
3. **Consumer integration** — Feign client extends this interface

## Special Cases

1. **HttpServletRequest parameter**: Skip (internal use only)
2. **Enum parameters**: List all enum values
3. **@DateTimeFormat parameters**: Note expected format (ISO DATE_TIME)
4. **Qry as method param without @RequestBody**: Document Qry fields as query parameters
5. **Admin controllers**: Identified by `/admin/v1/` prefix, audience = admin