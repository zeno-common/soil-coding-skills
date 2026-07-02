# Documentation Output Format

Agent-consumable compact format. Output must be machine-readable, high information density, no decorative text.

## Overall Structure

```
# {Service Name} API Doc

## Web APIs (Frontend)

### {ResourceName}
| Method | Path | Desc | Status | Request | Response |
|--------|------|------|--------|---------|----------|
| POST | /v1/orders | 创建订单 | 201 | OrderCreateCmd | OrderVO |

## Web APIs (Admin)

### {ResourceName}
| Method | Path | Desc | Status | Request | Response |
|--------|------|------|--------|---------|----------|
| GET | /admin/v1/orders | 订单列表 | 200 | OrderListQry | PagedResult<OrderVO> |

## Service APIs ({ResourceName}Api, Transport: HTTP/RPC)
| Method | Desc | Params | Return |
|--------|------|--------|--------|
| createOrder | 创建订单 | OrderCreateDTO | OrderDTO |

## Object Definitions
### {ClassName}
| Field | Type | Req | Constraints | Desc |
```

## Format Rules

### Rule 1: One-line per endpoint
Each endpoint = one table row. No nested blocks, no code fences for examples.

### Rule 2: Compact parameter tables
For endpoints with path/query/body params, append inline after main table:

```
**Params**: [path] id(Long) [query] keyword(String, opt) [body] CreateCmd
**Body Fields**: username(String, req, @Size4-64), password(String, req)
**Response Fields**: id(Long), status(String), createdAt(OffsetDateTime)
```

### Rule 3: No decorative elements
- Remove: "Status Code:", "Request Body:", "Response:" section headers
- Remove: Example request/response blocks
- Remove: Empty separator lines (`---`)
- Keep: Tables only, minimal bold labels

### Rule 4: Type notation
Use short type names in parentheses:
- Basic: String, Long, Integer, Boolean, OffsetDateTime, LocalDate
- Enum: EnumName(VALUE1,VALUE2)
- Generic: List<T>, Map<K,V>, PagedResult<T>
- Void: void or -

### Rule 5: Required/Optional shorthand
- req / y = required (has @NotNull/@NotBlank/@NotEmpty)
- opt / n = optional
- default value in parens if present: (default=20)

## Endpoint Table Columns

| Column | Content | Example |
|--------|---------|---------|
| Method | HTTP verb uppercase | POST, GET, PUT, DELETE |
| Path | Full path with base prefix | `/v1/orders/{id}`, `/api/v1/orders` |
| Description | Javadoc first line | 创建订单 |
| Status | Numeric code only | 201, 200, 204 |
| Request | Cmd/Qry class or param list | OrderCreateCmd |
| Response | VO class or type | OrderVO, void, PagedResult<T> |

## Path Prefix Convention (MUST follow)

| Prefix | Audience | Source Location |
|--------|----------|-----------------|
| `/v1/` | Frontend/Mobile | adapter/controller/ |
| `/admin/v1/` | Backend Admin | adapter/controller/ |
| `/api/v1/` | Other microservices | adapter/api/http/ |

When documenting, group by audience and note the correct prefix.

## Param Inline Format

```
[path] paramName(Type) [query] paramName(Type, req/opt, default) [body] ClassName
```

Examples:
- `[path] orderId(Long)` — single path param
- `[query] $page(Integer, opt, default=1) $pageSize(Integer, opt, default=20)` — pagination
- `[body] OrderCreateCmd` — request body class (Cmd)

## Field Table Format (for Cmd/Qry/VO/DTO)

```
### {ClassName}
| Field | Type | Req | Constraints | Desc |
|-------|------|-----|-------------|------|
| orderNo | String | y | @Size4-64 | 订单号 |
| totalAmount | BigDecimal | n | @Positive | 总金额 |
| status | OrderStatus | n | | 状态 |
```

Shorthand constraints:
- `@Size(min,max)` → `@Size4-64`
- `@NotBlank` → implied by `Req=y`
- `@Email` → `@Email`
- `@Pattern(regexp)` → `@Pattern`
- `@Min/@Max` → `@Range(min,max)`
- Multiple → comma separated: `@NotBlank,@Size1-200`

## Service API Table Columns

| Column | Content | Example |
|--------|---------|---------|
| Method | Java method name (business semantics) | createOrder |
| Description | Javadoc first line | 创建订单 |
| Params | param name + DTO type | dto: OrderCreateDTO |
| Return | Return type | OrderDTO |

> Api method naming MUST use business semantics. **禁止 CRUD 风格**。

## Cross-Reference Summary (compact)

```
## Coverage
| Op | Web(Frontend) | Web(Admin) | Service(Api) |
|----|--------------|-----------|--------------|
| Create | POST /v1/orders | - | Api.createOrder |
| List | GET /v1/orders | GET /admin/v1/orders | Api.listOrders |
| Delete | DELETE /v1/orders/{id} | - | - (web only) |
```

## Language Rule

Output language matches source code javadoc language. Technical terms remain in English.

