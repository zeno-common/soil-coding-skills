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

> Service API docs are named by the **client interface** (`{Resource}Api`), not by the provider implementation (`{Resource}Http`/`{Resource}Rpc`). Consumer programs against the interface.

### File Splitting Rules

1. **One file per class/interface** — each Controller or Api interface gets its own file
2. **Layer separation** — web controllers go in web/, service APIs go in service/
3. **No monolithic files** — MUST NOT combine multiple classes into one file
4. **Shared usage** — service/usage.md contains Maven Dependency and Consumer integration guide shared by all service API docs
5. **Coverage file** — coverage.md at root level provides cross-reference

## Web API File Structure

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
**Params**: [path] id(Long) [query] keyword(String, n) $page(Integer, n, default=1)
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

Each service API file includes: file header, **Endpoints**, **Object Definitions**.

> Maven Dependency and Consumer integration guide are in [usage.md](./usage.md) — MUST NOT duplicate in each API file.
> Provider implementation details MUST NOT appear in documentation.

### File Header

```markdown
# {Resource}Api

Audience: service
Transport: {HTTP (Feign) | RPC (Dubbo)}

> Maven Dependency and Consumer integration: see [usage.md](./usage.md)
```

### Section 1: Endpoints

HTTP endpoints use the same table format as web API (see Endpoint Table Columns). RPC endpoints use:

```markdown
## Endpoints

| Method | Desc | Params | Return |
|--------|------|--------|--------|
| createOrder | 创建订单 | dto: OrderCreateDTO | OrderDTO |
```

> RPC Method naming MUST use business semantics. MUST NOT use CRUD naming.

### Section 2: Object Definitions

```markdown
## Object Definitions

### {ClassName}
| Field | Type | Req | Constraints | Desc |
|-------|------|-----|-------------|------|
| id | Long | | | 账户ID |
```

## Coverage File Structure

coverage.md maps operations across web and service layers:

```markdown
# Endpoint Coverage

## {Resource}
| Op | Web(Frontend) | Web(Admin) | Service(Api) |
|----|--------------|-----------|--------------|
```

## Format Rules

### Rule 1: One-line per endpoint
Each endpoint = one table row. No nested blocks, no code fences for examples.

### Rule 2: Compact parameter tables
For endpoints with path/query/body params, append inline after main table:

```
**Params**: [path] paramName(Type) [query] paramName(Type, y/n, default) [body] ClassName
**Body Fields**: username(String, y, @Size4-64), password(String, y)
**Response Fields**: id(Long), status(String), createdAt(OffsetDateTime)
```

Examples:
- [path] orderId(Long) — single path param
- [query] $page(Integer, n, default=1) $pageSize(Integer, n, default=20) — pagination
- [body] OrderCreateCmd — request body class (Cmd)

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
| Request | Cmd/Qry/DTO class or param list | OrderCreateCmd |
| Response | VO/DTO class or type | OrderVO, void, PagedResult<T> |

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

## Language Rule

Output language matches source code javadoc language. Technical terms remain in English.