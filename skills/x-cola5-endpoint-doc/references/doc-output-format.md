# Documentation Output Format

## File Structure

`
docs/cola5-endpoints/
  web/
    {ControllerClassName}.md    — one file per @RestController in adapter/controller/
  service/
    {ApiClassName}.md           — one file per @RestController/@DubboService in adapter/api/
  coverage.md                   — cross-reference between web and service layers
`

### File Naming Examples

| Source Class | File Path |
|-------------|-----------|
| AuthController | web/AuthController.md |
| AccountController | web/AccountController.md |
| AccountAdminController | web/AccountAdminController.md |
| AuditLogAdminController | web/AuditLogAdminController.md |
| AccountHttp | service/AccountHttp.md |
| AccountRpc | service/AccountRpc.md |

### File Splitting Rules

1. **One file per class** — each Controller or Api implementation class gets its own file
2. **Layer separation** — web controllers go in web/, service APIs go in service/
3. **No monolithic files** — MUST NOT combine multiple classes into one file
4. **Coverage file** — coverage.md at root level provides cross-reference

## Web API File Structure

Each web API file follows this structure:

``markdown
# {ClassName}

Base Path: {@RequestMapping value}
Audience: {frontend|admin}

| Method | Path | Desc | Status | Request | Response |
|--------|------|------|--------|---------|----------|
| POST | /v1/orders | 创建订单 | 201 | OrderCreateCmd | OrderVO |
``

For endpoints with params, append inline details:

`
**POST /v1/orders**
**Body Fields**: username(String, y, @Size4-64), password(String, y)
**Response Fields**: id(Long), status(String), createdAt(OffsetDateTime)

**GET /v1/orders**
**Params**: [query] keyword(String, n) $page(Integer, n, default=1)
**Response Fields**: id(Long), status(String)
`

## Service API File Structure

Each service API file MUST include three sections: **Usage**, **Endpoints**, **Object Definitions**.

### Section 1: Usage

Explains how consumer services integrate with this API. Contains:

1. **Maven Dependency** — the client module coordinates
2. **Interface** — the {Resource}Api interface in client/api/ that consumers program against
3. **Implementation** — how the provider implements the interface (HTTP/RPC)

``markdown
# {ClassName}

Base Path: /api/v1/{resource}
Audience: service
Transport: {HTTP (Feign) | RPC (Dubbo)}

## Usage

### Maven Dependency

`xml
<dependency>
    <groupId>{groupId}</groupId>
    <artifactId>{artifactId}</artifactId>
    <version>{version}</version>
</dependency>
`

### Interface

`java
// {package}.{Resource}Api
{method signatures with javadoc}
`

### Implementation

{Transport-specific description}

For HTTP (Feign):
> Provider: {package}.adapter.api.http.{Resource}Http implements {Resource}Api
> Exposed as REST endpoints under /api/v1/{resource}.
> Consumer: Add @EnableFeignClients(basePackages = "{package}.client.api") and create Feign client interface.

For RPC (Dubbo):
> Provider: {package}.adapter.api.rpc.{Resource}Rpc implements {Resource}Api
> Exposed as Dubbo service with @DubboService.
> Consumer: Add @DubboReference(interfaceClass = {Resource}Api.class) to inject.
``

### Section 2: Endpoints

``markdown
## Endpoints

| Method | Path | Desc | Status | Request | Response |
|--------|------|------|--------|---------|----------|
| GET | /api/v1/accounts/{id} | 根据ID查询账户信息 | 200 | - | AccountDTO |

**GET /api/v1/accounts/{id}**
**Params**: [path] id(Long)
**Response Fields**: id(Long), username(String), status(String), createdAt(OffsetDateTime)
``

### Section 3: Object Definitions

``markdown
## Object Definitions

### AccountDTO
| Field | Type | Req | Constraints | Desc |
|-------|------|-----|-------------|------|
| id | Long | | | 账户ID |
``

## Coverage File Structure

coverage.md maps operations across web and service layers:

``markdown
# Endpoint Coverage

## Account
| Op | Web(Frontend) | Web(Admin) | Service(Api) |
|----|--------------|-----------|--------------|
| Create | POST /v1/accounts | - | - |
| Page | - | GET /admin/v1/accounts | - |
| GetById | - | - | GET /api/v1/accounts/{id} |
| ChangePassword | PUT /v1/accounts/{id}/password | - | - |
| UpdateStatus | - | PATCH /admin/v1/accounts/{id}/status | - |
| ResetPassword | - | PATCH /admin/v1/accounts/{id}/password/reset | - |
| UpdateProfile | - | PUT /admin/v1/accounts/{id}/profile | - |
| Remove | - | DELETE /admin/v1/accounts/{id} | - |

## Auth
| Op | Web(Frontend) | Web(Admin) | Service(Api) |
|----|--------------|-----------|--------------|
| Login | POST /v1/auth/login | - | - |
| Logout | POST /v1/auth/logout | - | - |

## AuditLog
| Op | Web(Frontend) | Web(Admin) | Service(Api) |
|----|--------------|-----------|--------------|
| Page | - | GET /admin/v1/audit-logs | - |
``

## Format Rules

### Rule 1: One-line per endpoint
Each endpoint = one table row. No nested blocks, no code fences for examples.

### Rule 2: Compact parameter tables
For endpoints with path/query/body params, append inline after main table:

`
**Params**: [path] id(Long) [query] keyword(String, n) [body] CreateCmd
**Body Fields**: username(String, y, @Size4-64), password(String, y)
**Response Fields**: id(Long), status(String), createdAt(OffsetDateTime)
`

### Rule 3: No decorative elements
- Remove: "Status Code:", "Request Body:", "Response:" section headers
- Remove: Example request/response blocks
- Remove: Empty separator lines (---)
- Keep: Tables only, minimal bold labels

### Rule 4: Type notation
Use short type names in parentheses:
- Basic: String, Long, Integer, Boolean, OffsetDateTime, LocalDate
- Enum: EnumName(VALUE1,VALUE2)
- Generic: List<T>, Map<K,V>, PagedResult<T>
- Void: void or -

### Rule 5: Required/Optional shorthand
- y = required (has @NotNull/@NotBlank/@NotEmpty)
- 
 = optional
- default value in parens if present: (default=20)

## Endpoint Table Columns

| Column | Content | Example |
|--------|---------|---------|
| Method | HTTP verb uppercase | POST, GET, PUT, DELETE |
| Path | Full path with base prefix | /v1/orders/{id}, /api/v1/orders |
| Description | Javadoc first line | 创建订单 |
| Status | Numeric code only | 201, 200, 204 |
| Request | Cmd/Qry class or param list | OrderCreateCmd |
| Response | VO class or type | OrderVO, void, PagedResult<T> |

## Path Prefix Convention

| Prefix | Audience | Source Location | Doc Directory |
|--------|----------|-----------------|---------------|
| /v1/ | Frontend/Mobile | adapter/controller/ | web/ |
| /admin/v1/ | Backend Admin | adapter/controller/ | web/ |
| /api/v1/ | Other microservices | adapter/api/http/ | service/ |

## Param Inline Format

`
[path] paramName(Type) [query] paramName(Type, y/n, default) [body] ClassName
`

Examples:
- [path] orderId(Long) — single path param
- [query] $page(Integer, n, default=1) $pageSize(Integer, n, default=20) — pagination
- [body] OrderCreateCmd — request body class (Cmd)

## Field Table Format (for Cmd/Qry/VO/DTO)

`
### {ClassName}
| Field | Type | Req | Constraints | Desc |
|-------|------|-----|-------------|------|
| orderNo | String | y | @Size4-64 | 订单号 |
| totalAmount | BigDecimal | n | @Positive | 总金额 |
| status | OrderStatus | n | | 状态 |
`

Shorthand constraints:
- @Size(min,max) → @Size4-64
- @NotBlank → implied by Req=y
- @Email → @Email
- @Pattern(regexp) → @Pattern
- @Min/@Max → @Range(min,max)
- Multiple → comma separated: @NotBlank,@Size1-200

## Service API Table Columns

### HTTP Endpoints (adapter/api/http/)

Documented the same way as web API endpoints, but under /api/v1/ prefix and using DTO types:

| Column | Content | Example |
|--------|---------|---------|
| Method | HTTP verb uppercase | GET, POST |
| Path | Full path with /api/v1/ prefix | /api/v1/accounts/{id} |
| Description | Javadoc first line | 根据ID查询账户信息 |
| Status | Numeric code only | 200, 201 |
| Request | DTO class or param list | OrderCreateDTO |
| Response | DTO class or type | OrderDTO |

### RPC Services (adapter/api/rpc/)

| Column | Content | Example |
|--------|---------|---------|
| Method | Java method name (business semantics) | createOrder |
| Description | Javadoc first line | 创建订单 |
| Params | param name + DTO type | dto: OrderCreateDTO |
| Return | Return type | OrderDTO |

> Method naming MUST use business semantics. MUST NOT use CRUD naming.

## Language Rule

Output language matches source code javadoc language. Technical terms remain in English.