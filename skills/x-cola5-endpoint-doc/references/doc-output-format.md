# Documentation Output Format

## File Structure

```
docs/cola5-endpoints/
  web/
    {ClassName}.md          — one file per @RestController in adapter/controller/
  service/
    usage.md                — shared Maven Dependency + Consumer integration guide
    {Resource}Api.md        — one file per {Resource}Api interface in client/api/
```

> Service API docs are named by the **client interface** (`{Resource}Api.md`), not by the provider implementation class. Consumer programs against the interface, not the implementation.

### File Splitting Rules

1. **One file per class/interface** — each Controller or Api interface gets its own file
2. **Layer separation** — web controllers go in web/, service APIs go in service/
3. **No monolithic files** — MUST NOT combine multiple classes into one file
4. **Shared usage** — service/usage.md contains Maven Dependency and Consumer integration guide shared by all service API docs

## Web API File Format

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

## Service usage.md Format

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

## Service API File Format

Each service API file includes: file header, **Endpoints**, **Object Definitions**.

> Maven Dependency and Consumer integration guide are in [usage.md](./usage.md) — MUST NOT duplicate in each API file.
> Provider implementation details MUST NOT appear in documentation.

### File Header

```markdown
# {Resource}Api

Transport: {HTTP (Feign) | RPC (Dubbo)}

> Maven Dependency and Consumer integration: see [usage.md](./usage.md)
```

### Section 1: Endpoints

Unified method-level table for both HTTP and RPC:

```markdown
## Endpoints

| Method | Desc | Params | Return |
|--------|------|--------|--------|
| getAccountById | 根据ID查询账户信息 | id: Long | AccountDTO |
| createOrder | 创建订单 | dto: OrderCreateDTO | OrderDTO |
```

> Method naming MUST use business semantics, MUST NOT use CRUD naming.
> Consumer calls Java methods on the `{Resource}Api` interface, not HTTP endpoints directly. Feign/Dubbo handles the transport mapping automatically.

### Section 2: Object Definitions

```markdown
## Object Definitions

### {ClassName}
| Field | Type | Req | Constraints | Desc |
|-------|------|-----|-------------|------|
| id | Long | | | 账户ID |
```

## Web API Endpoint Table Columns

| Column | Content | Example |
|--------|---------|---------|
| Method | HTTP verb uppercase | POST, GET, PUT, DELETE |
| Path | Full path with base prefix | /v1/orders/{id}, /api/v1/orders |
| Description | Javadoc first line | 创建订单 |
| Status | Numeric code only | 201, 200, 204 |
| Request | Cmd/Qry/DTO class or param list | OrderCreateCmd |
| Response | VO/DTO class or type | OrderVO, void, PagedResult<T> |

## Field Table Format

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

## Format Rules

### Rule 1: One-line per endpoint/method
Each endpoint (web) or method (service) = one table row. No nested blocks, no code fences for examples.

### Rule 2: Compact parameter inline
Append after main table for endpoints/methods with params:

Web:
```
**POST /v1/orders**
**Body Fields**: username(String, y, @Size4-64), password(String, y)
**Response Fields**: id(Long), status(String), createdAt(OffsetDateTime)

**GET /v1/orders**
**Params**: [path] id(Long) [query] keyword(String, n) $page(Integer, n, default=1)
**Response Fields**: id(Long), status(String)
```

Service:
```
**getAccountById**
**Params**: id(Long)
**Return Fields**: id(Long), username(String), status(String)

**createOrder**
**Params**: dto: OrderCreateDTO
**Body Fields**: username(String, y, @Size4-64), password(String, y)
**Return Fields**: id(Long), status(String), createdAt(OffsetDateTime)
```

### Rule 3: No decorative elements
- Remove: "Status Code:", "Request Body:", "Response:" section headers
- Remove: Example request/response blocks
- Remove: Empty separator lines (---)
- Keep: Tables only, minimal bold labels

### Rule 4: Type notation
- Basic: String, Long, Integer, Boolean, OffsetDateTime, LocalDate
- Enum: EnumName(VALUE1,VALUE2)
- Generic: List<T>, Map<K,V>, PagedResult<T>
- Void: void or -

### Rule 5: Required/Optional shorthand
- y = required (has @NotNull/@NotBlank/@NotEmpty)
- n = optional
- default value in parens: (default=20)

## Output Mandatory Rules

1. **Must** follow the output format defined in this file
2. **Must** generate one documentation file per Controller/Api class — MUST NOT dump all endpoints into a single monolithic file
3. **Must** separate web and service docs into `web/` and `service/` subdirectories
4. **Must** generate `service/usage.md` containing shared Maven Dependency and Consumer integration guide. Each service API doc file links to `usage.md` and includes only Endpoints and Object Definitions
5. **Must** name service API doc files by the client interface (`{Resource}Api.md`), NOT by the provider implementation class. Provider implementation details MUST NOT appear in documentation — they are internal to the provider service

## Output Recommended Rules

1. Include field details when Cmd/VO/DTO fields are available

## Language Rule

Output language matches source code javadoc language. Technical terms remain in English.