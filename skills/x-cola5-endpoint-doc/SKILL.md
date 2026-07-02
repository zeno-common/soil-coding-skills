---
name: x-cola5-endpoint-doc
description: Generates http or rpc endpoints documentation from COLA 5 adapter layer. Invoke when user asks to generate API docs, interface documentation, or list all endpoints from COLA5 project.
---

# Adapter API Documentation Generator

Based on COLA 5 architecture adapter layer, generate structured interface documentation for both **web calls** (controller) and **service-to-service calls** (adapter.api HTTP/RPC implementations).

| Section | Reference File | When to Read |
|---------|---------------|-------------|
| Web API Doc Spec | `references/web-api-doc-spec.md` | Generating documentation for controller endpoints |
| Service API Doc Spec | `references/service-api-doc-spec.md` | Generating documentation for adapter.api HTTP/RPC endpoints |
| Doc Output Format | `references/doc-output-format.md` | Formatting the final documentation output |

## When to Invoke

- User asks to generate API documentation / interface documentation
- User asks to list all endpoints or APIs
- User asks to document controller or client module interfaces
- User asks for web call or service-to-service call documentation

## How to Apply

### Step 1: Locate Source Files

**Web API (controller)**:
1. Find all `@RestController` classes under `adapter/controller/` package

**Service API (adapter.api)**:
1. Find all `@RestController` classes under `adapter/api/http/` package (HTTP/Feign provider endpoints)
2. Find all `@DubboService` classes under `adapter/api/rpc/` package (Dubbo provider endpoints)
3. Find all DTO classes under `client/dto/` package (referenced by adapter.api)
4. Find `{Resource}Api` interfaces under `client/api/` package (contract definition, used for method signatures)

### Step 2: Read `references/web-api-doc-spec.md` (if documenting web APIs)

Follow the extraction rules to parse each controller class and extract:
- Controller-level info: class javadoc, base path (`@RequestMapping`)
- Endpoint-level info: HTTP method, path, method javadoc, parameters, request body, response type, status code

### Step 3: Read `references/service-api-doc-spec.md` (if documenting service APIs)

Follow the extraction rules to parse each adapter.api HTTP/RPC implementation class:
- HTTP endpoint info: `@RestController` in `adapter/api/http/`, extract HTTP method, path (`/api/v1/`), parameters, response type (DTO)
- RPC service info: `@DubboService` in `adapter/api/rpc/`, extract service interface, version, methods
- DTO info: field names, types, validation annotations, javadoc (from `client/dto/`)
- Client Api interface: used as reference for method signatures and javadoc (from `client/api/`)
- Transport type: infer from directory — `adapter/api/http/` → HTTP (Feign), `adapter/api/rpc/` → RPC (Dubbo)

### Step 4: Extract Consumer Usage information (for service API docs)

Extract only what Consumer services need to integrate:

1. **Maven coordinates** — read `client/pom.xml` to extract `groupId`, `artifactId`, `version`
2. **Service name** — read `spring.application.name` from the provider's `application.yml` (used as `@FeignClient(name = ...)` value)
3. **Consumer integration** — based on transport type (determined in Step 3):
   - HTTP (Feign): consumer creates `@FeignClient` interface extends `{Resource}Api`, plus `@EnableFeignClients(basePackages = "{package}.client.api")`. `name` is always required; `url` is only needed when NOT using service discovery (Nacos/Eureka).
   - RPC (Dubbo): consumer uses `@DubboReference(interfaceClass = {Resource}Api.class)` to inject

> Provider implementation details (class name, package) are Provider-side internal info, NOT Consumer usage info. Do NOT include in documentation.

### Step 5: Read `references/doc-output-format.md`

Format the extracted information into the standard documentation output.

**Output location**: `docs/cola5-endpoints/` directory.

**File splitting rules** — one file per Controller/Api class, organized by layer:

```
docs/cola5-endpoints/
  web/
    {ClassName}.md          — one file per @RestController in adapter/controller/
  service/
    usage.md                — shared Maven Dependency + Consumer integration guide
    {Resource}Api.md        — one file per {Resource}Api interface in client/api/
  coverage.md               — cross-reference between web and service layers
```

> Service API docs are named by the **client interface** (`{Resource}Api.md`), not by the provider implementation class. Consumer programs against the interface, not the implementation.

Examples:
- `web/AuthController.md` — AuthController (/v1/auth)
- `web/AccountController.md` — AccountController (/v1/accounts)
- `web/AccountAdminController.md` — AccountAdminController (/admin/v1/accounts)
- `service/usage.md` — shared Maven Dependency + Consumer integration guide
- `service/AccountApi.md` — AccountApi (/api/v1/accounts)

### Step 6: Cross-Reference

Generate a `docs/cola5-endpoints/coverage.md` file that maps operations across web and service layers:
- Controller (Cmd/Qry/VO) serves frontend; adapter.api (DTO) serves microservices
- Note which operations are web-only vs service-only
- Identify gaps (adapter.api endpoints without controller endpoints or vice versa)

## Key Conventions

1. **Controller** serves frontend/mobile via HTTP, uses CQRS style (Cmd/Qry/VO)
2. **adapter.api** (HTTP/RPC implementations) serves other microservices, uses unified DTO style
3. Controller and adapter.api share the same app layer entry points
4. HTTP path prefix convention: `/v1/` (frontend), `/admin/v1/` (admin), `/api/v1/` (service-to-service) — see reference files for details
5. Api method naming MUST use business semantics, MUST NOT use CRUD naming
6. DTO rules: MUST NOT implement Serializable, wrapper types only, OffsetDateTime/LocalDate for dates

## Mandatory Rules

1. **Must** read actual source code to extract documentation — never fabricate endpoint information
2. **Must** include HTTP method, full path, and response type for every endpoint
3. **Must** distinguish required vs optional parameters
4. **Must** include field-level documentation for request/response objects
5. **Must** follow the output format defined in `references/doc-output-format.md`
6. **Must** differentiate path prefix: `/v1/` (frontend) vs `/api/v1/` (service-to-service) vs `/admin/v1/` (admin)
7. **Must** follow HTTP method semantics: GET=read, POST=create, PUT=full update, PATCH=partial update, DELETE=remove
8. **Must** use correct HTTP status codes: 201 for create, 204 for no-content operations — MUST NOT always return 200
9. **Must** follow pagination convention: `$page`, `$pageSize`, `$orderby`, `$keywords` query parameters, returns `PagedResult<T>`
10. **Must** generate one documentation file per Controller/Api class — MUST NOT dump all endpoints into a single monolithic file. See file splitting rules above.
11. **Must** separate web and service docs into `web/` and `service/` subdirectories.
12. **Must** generate `service/usage.md` containing shared Maven Dependency and Consumer integration guide. Each service API doc file links to `usage.md` and includes only Endpoints and Object Definitions.
13. **Must** name service API doc files by the client interface (`{Resource}Api.md`), NOT by the provider implementation class. Provider implementation details MUST NOT appear in documentation — they are internal to the provider service.

## Recommended Rules

1. Include field details when Cmd/VO/DTO fields are available
2. Note authentication requirements if visible from code
3. Highlight deprecated endpoints if `@Deprecated` annotation is present
4. Include enum values when parameter types are enums
5. Generate coverage.md for cross-reference between web and service layers