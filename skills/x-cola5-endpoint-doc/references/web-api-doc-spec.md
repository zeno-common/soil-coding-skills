# Web API Documentation Extraction Spec

Rules for extracting web API documentation from COLA 5 adapter controller classes.

## Source Location

- `{module}-adapter/src/main/java/{basePackage}/adapter/controller/`

## Path Prefix Convention

| Interface Type | Prefix | Example | Audience |
|---------------|--------|---------|----------|
| Frontend API | `/v1/` | `/v1/orders` | Frontend / Mobile |
| Admin API | `/admin/v1/` | `/admin/v1/orders` | Backend Admin |

## Controller-Level Extraction

For each `@RestController` class, extract:

| Field | Source | Example |
|-------|--------|---------|
| Resource Name | Class javadoc (first line) or derive from class name | "订单管理" from OrderController |
| Base Path | `@RequestMapping` value | "/v1/orders" |
| Audience | Derived from path prefix | frontend / admin |

## Endpoint-Level Extraction

For each method annotated with HTTP mapping annotations, extract:

| Field | Source | Example |
|-------|--------|---------|
| HTTP Method | Annotation type | GET, POST, PUT, PATCH, DELETE |
| Path | Annotation value + base path | "/v1/orders/{id}" |
| Description | Method javadoc (first line) | "查询订单详情" |
| Parameters | Method params + `@RequestParam` / `@PathVariable` / `@RequestBody` | See parameter extraction below |
| Request Body | `@RequestBody` param type | OrderCreateCmd |
| Response Type | Method return type | OrderVO, void, PagedResult<OrderVO> |
| Status Code | `@ResponseStatus` annotation | 201 CREATED, 204 NO_CONTENT (default 200 OK) |

## Parameter Extraction Rules

### @RequestParam Parameters

| Field | Source |
|-------|--------|
| Name | `@RequestParam.name` or parameter name |
| Type | Java type (String, Integer, Long, OffsetDateTime, enum) |
| Required | `@RequestParam.required` (default true) |
| Default Value | `@RequestParam.defaultValue` (if present) |
| Description | Javadoc `@param` for this parameter |

### @PathVariable Parameters

| Field | Source |
|-------|--------|
| Name | `@PathVariable.value` or parameter name |
| Type | Java type (typically Long or String) |
| Description | Javadoc `@param` for this parameter |

### @RequestBody Parameters

| Field | Source |
|-------|--------|
| Type | Java class name (typically Cmd class) |
| Validation | `@Valid` annotation presence |
| Description | Javadoc `@param` for this parameter |

## Request Body Object Extraction

For Cmd/Qry classes used as `@RequestBody`, extract each field:

| Field | Source |
|-------|--------|
| Field Name | Java field name |
| Type | Java type |
| Required | Presence of `@NotBlank`, `@NotNull`, `@NotEmpty` |
| Constraints | `@Size`, `@Email`, `@Pattern`, `@Min`, `@Max` etc. |
| Description | Field javadoc |

> Cmd/Qry are defined in **app module**, NOT in adapter.

## Response Object Extraction

For VO classes used as return types, extract each field:

| Field | Source |
|-------|--------|
| Field Name | Java field name |
| Type | Java type |
| Description | Field javadoc |

> VO is defined in **app module**, NOT in adapter.

## Pagination Pattern Recognition

When a method has `$page`, `$pageSize`, `$sortBy`, `$order` parameters and returns `PagedResult<T>`, recognize it as a paginated query:

- `$page`: Page number starting from 1, default 1
- `$pageSize`: Items per page, default 20
- `$sortBy`: Sort field name, optional
- `$order`: Sort direction (asc/desc), default asc

> Note: Qry object may be used directly as method param (no `@RequestBody`).

## Status Code Determination

| Condition | Status Code |
|-----------|-------------|
| `@ResponseStatus(HttpStatus.CREATED)` | 201 Created |
| `@ResponseStatus(HttpStatus.NO_CONTENT)` | 204 No Content |
| No `@ResponseStatus` + returns value | 200 OK |
| No `@ResponseStatus` + returns void | 200 OK |

> Controller MUST follow restful-convention. MUST NOT always return 200. Error status codes use correct HTTP semantics (400/401/403/404/500).

## Special Cases

1. **HttpServletRequest parameter**: Skip in parameter documentation (internal use only)
2. **Enum parameters**: List all enum values in description
3. **@DateTimeFormat parameters**: Note the expected format (ISO DATE_TIME)
4. **Qry as method param without @RequestBody**: GET list queries often accept Qry directly — document the Qry fields as query parameters
5. **Admin controllers**: Identified by `/admin/v1/` prefix, note audience as "admin"