# Documentation Output Format

## File Structure

```
docs/cola5-endpoints/
  web/
    {ControllerClassName}.md    — one file per @RestController in adapter/controller/
  service/
    usage.md                    — shared Maven Dependency + Consumer integration guide
    {Resource}Api.md            — one file per {Resource}Api interface in client/api/
  coverage.md                   — cross-reference between web and service layers
```

### File Naming Examples

| Source | File Path | Note |
|--------|-----------|------|
| AuthController | web/AuthController.md | Controller class name |
| AccountController | web/AccountController.md | Controller class name |
| AccountAdminController | web/AccountAdminController.md | Controller class name |
| (shared) | service/usage.md | Maven Dependency + Consumer integration |
| AccountApi | service/AccountApi.md | Client interface name, NOT provider implementation |
| OrderApi | service/OrderApi.md | Client interface name, NOT provider implementation |

> Service API docs are named by the **client interface** (`{Resource}Api`), not by the provider implementation (`{Resource}Http`/`{Resource}Rpc`). Consumer programs against the interface.

### File Splitting Rules

1. **One file per class/interface** — each Controller or Api interface gets its own file
2. **Layer separation** — web controllers go in web/, service APIs go in service/
3. **No monolithic files** — MUST NOT combine multiple classes into one file
4. **Shared usage** — service/usage.md contains Maven Dependency and Consumer integration guide shared by all service API docs
5. **Coverage file** — coverage.md at root level provides cross-reference

## Web API File Structure

Each web API file follows this structure:

```markdown
# {ClassName}

Base Path: {@RequestMapping value}
Audience: {frontend|admin}

| Method | Path | Desc | Status | Request | Response |
|--------|------|------|--------|---------|----------|
| POST | /v1/orders | 创建订单 | 201 | OrderCreateCmd | OrderVO |
```

For endpoints with params, append inline details:

```
**POST /v1/orders**
**Body Fields**: username(String, y, @Size4-64), password(String, y)
**Response Fields**: id(Long), status(String), createdAt(OffsetDateTime)

**GET /v1/orders**
**Params**: [query] keyword(String, n) $page(Integer, n, default=1)
**Response Fields**: id(Long), status(String)
```

## Service usage.md Structure

Shared file for all service API docs. Contains Maven Dependency and Consumer integration guide.

> `service-name` value comes from the provider's `spring.application.name` in `application.yml`.

```markdown
# Service API Usage

## Maven Dependency

```xml
<dependency>
    <groupId>{groupId}</groupId>
    <artifactId>{artifactId}</artifactId>
    <version>{version}</version>
</dependency>
```

## Consumer Integration

### HTTP (Feign)

1. Add `@EnableFeignClients(basePackages = "{package}.client.api")` to Spring Boot application class
2. Create Feign client interface:

```java
// With service discovery (Nacos/Eureka) — url not needed
@FeignClient(name = "{service-name}")
public interface {Resource}FeignClient extends {Resource}Api {}

// Without service discovery (direct URL) — url required
@FeignClient(name = "{service-name}", url = "${service-name.url}")
public interface {Resource}FeignClient extends {Resource}Api {}
```

> `name` is always required (used as bean name and log identifier). `url` is only needed when NOT using service discovery.
> `{Resource}Api` already defines `@RequestMapping` + HTTP method annotations. Feign client inherits them automatically. MUST NOT redeclare path annotations.

### RPC (Dubbo)

1. Add Dubbo dependency and configure registry
2. Inject service reference:

```java
@DubboReference(interfaceClass = {Resource}Api.class)
private {Resource}Api {resource}Api;
```
```

## Service API File Structure

Each service API file includes: file header, **Interface**, **Endpoints**, **Object Definitions**.

> Maven Dependency and Consumer integration guide are in [usage.md](./usage.md) — MUST NOT duplicate in each API file.
> Provider implementation details MUST NOT appear in documentation.

### File Header

Consumer-facing metadata only:

```markdown
# {Resource}Api

Base Path: /api/v1/{resource}
Audience: service
Transport: {HTTP (Feign) | RPC (Dubbo)}
```

### Section 1: Interface

The `{Resource}Api` interface full source code that consumers program against.

```markdown
## Interface

> Maven Dependency and Consumer integration: see [usage.md](./usage.md)

```java
// {package}.client.api.{Resource}Api
/**
 * {class javadoc}
 */
@RequestMapping("/api/v1/{resource}")
public interface {Resource}Api {
    /**
     * {method javadoc}
     */
    @GetMapping("/{id}")
    {Resource}DTO get{Resource}(@PathVariable("id") Long id);
}
```
```

### Section 2: Endpoints

```markdown
## Endpoints

| Method | Path | Desc | Status | Request | Response |
|--------|------|------|--------|---------|----------|
| GET | /api/v1/accounts/{id} | 根据ID查询账户信息 | 200 | - | AccountDTO |

**GET /api/v1/accounts/{id}**
**Params**: [path] id(Long)
**Response Fields**: id(Long), username(String), status(String), createdAt(OffsetDateTime)
```

### Section 3: Object Definitions

```markdown
## Object Definitions

### AccountDTO
| Field | Type | Req | Constraints | Desc |
|-------|------|-----|-------------|------|
| id | Long | | | 账户ID |
```

## Full Service API File Example

```markdown
# AccountApi

Base Path: /api/v1/accounts
Audience: service
Transport: HTTP (Feign)

## Interface

> Maven Dependency and Consumer integration: see [usage.md](./usage.md)

```java
// io.soil.usercenter.client.api.AccountApi
/**
 * 账户服务间调用接口
 */
@RequestMapping("/api/v1/accounts")
public interface AccountApi {
    /**
     * 根据ID查询账户信息
     *
     * @param id 账户ID
     * @return 账户DTO
     */
    @GetMapping("/{id}")
    AccountDTO getAccountById(@PathVariable("id") Long id);
}
```

## Endpoints

| Method | Path | Desc | Status | Request | Response |
|--------|------|------|--------|---------|----------|
| GET | /api/v1/accounts/{id} | 根据ID查询账户信息 | 200 | - | AccountDTO |

**GET /api/v1/accounts/{id}**
**Params**: [path] id(Long)
**Response Fields**: id(Long), username(String), status(String), createdAt(OffsetDateTime)

## Object Definitions

### AccountDTO
| Field | Type | Req | Constraints | Desc |
|-------|------|-----|-------------|------|
| id | Long | | | 账户ID |
| username | String | y | @Size4-64 | 用户名 |
| status | String | | | 状态 |
| createdAt | OffsetDateTime | | | 创建时间 |
```

## Coverage File Structure

coverage.md maps operations across web and service layers:

```markdown
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
```

## Format Rules

### Rule 1: One-line per endpoint
Each endpoint = one table row. No nested blocks, no code fences for examples.

### Rule 2: Compact parameter tables
For endpoints with path/query/body params, append inline after main table:

```
**Params**: [path] id(Long) [query] keyword(String, n) [body] CreateCmd
**Body Fields**: username(String, y, @Size4-64), password(String, y)
**Response Fields**: id(Long), status(String), createdAt(OffsetDateTime)
```

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
- n = optional
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

```
[path] paramName(Type) [query] paramName(Type, y/n, default) [body] ClassName
```

Examples:
- [path] orderId(Long) — single path param
- [query] $page(Integer, n, default=1) $pageSize(Integer, n, default=20) — pagination
- [body] OrderCreateCmd — request body class (Cmd)

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