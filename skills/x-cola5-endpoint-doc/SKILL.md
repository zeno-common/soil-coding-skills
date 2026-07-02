---
name: "x-cola5-endpoint-doc"
description: "Generates http or rpc endpoints documentation from COLA 5 adapter layer. Invoke when user asks to generate API docs, interface documentation, or list all endpoints from COLA5 adapter modules."
---

# Adapter API Documentation Generator

Based on COLA 5 architecture adapter layer, generate structured interface documentation for both **web calls** (controller) and **service-to-service calls** (client module Api interfaces).

| Section | Reference File | When to Read |
|---------|---------------|-------------|
| Web API Doc Spec | `references/web-api-doc-spec.md` | Generating documentation for controller endpoints |
| Service API Doc Spec | `references/service-api-doc-spec.md` | Generating documentation for client module Api interfaces |
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

**Service API (client + adapter.api)**:
1. Find all `{Resource}Api` interfaces under `adapter/api/` package (if client module exists)
2. Find all DTO classes under `client/dto/` package
3. Find `{Resource}HttpApi` under `adapter/api/http/` (Feign provider)
4. Find `{Resource}RpcApi` under `adapter/api/rpc/` (Dubbo provider)

### Step 2: Read `references/web-api-doc-spec.md`

Follow the extraction rules to parse each controller class and extract:
- Controller-level info: class javadoc, base path (`@RequestMapping`)
- Endpoint-level info: HTTP method, path, method javadoc, parameters, request body, response type, status code

### Step 3: Read `references/service-api-doc-spec.md`

Follow the extraction rules to parse each Api interface and DTO class:
- Api interface info: interface javadoc, methods, parameters, return types
- DTO info: field names, types, validation annotations, javadoc
- Transport detection: check `adapter/api/http/` and `adapter/api/rpc/` for implementation

### Step 4: Read `references/doc-output-format.md`

Format the extracted information into the standard documentation output.

### Step 5: Cross-Reference

If both controller and client module exist:
- Controller (Cmd/Qry/VO) serves frontend; Api (DTO) serves microservices
- Note which operations are web-only vs service-only
- Identify gaps (api methods without controller endpoints or vice versa)

## Key Conventions

1. **Controller** serves frontend/mobile via HTTP, uses CQRS style (Cmd/Qry/VO)
2. **Api** (in client module) serves other microservices, uses unified DTO style
3. Controller and Api share the same app layer entry points
4. HTTP path prefix convention:
   - Frontend: `/v1/` (e.g., `/v1/orders`)
   - Admin: `/admin/v1/` (e.g., `/admin/v1/orders`)
   - Service-to-service: `/api/v1/` (e.g., `/api/v1/orders`)
5. HTTP method mapping: GET=read, POST=create, PUT=full update, PATCH=partial update, DELETE=remove
6. Pagination uses `$page`, `$pageSize`, `$sortBy`, `$order` query parameters, returns `PagedResult<T>`
7. Success status codes: 201 for create, 204 for no-content operations (via `@ResponseStatus`)
8. Api implementation naming: `{Resource}HttpApi` (Feign) / `{Resource}RpcApi` (Dubbo)
9. Api method naming: business semantics, NOT CRUD style
10. DTO rules: no Serializable, wrapper types only, OffsetDateTime/LocalDate for dates

## Mandatory Rules

1. **Must** read actual source code to extract documentation — never fabricate endpoint information
2. **Must** include HTTP method, full path, and response type for every endpoint
3. **Must** distinguish required vs optional parameters
4. **Must** include field-level documentation for request/response objects
5. **Must** follow the output format defined in `references/doc-output-format.md`
6. **Must** differentiate path prefix: `/v1/` (frontend) vs `/api/v1/` (service-to-service) vs `/admin/v1/` (admin)

## Recommended Rules

1. Group endpoints by controller/resource
2. Include field details when Cmd/VO/DTO fields are available
3. Note authentication requirements if visible from code
4. Highlight deprecated endpoints if `@Deprecated` annotation is present
5. Include enum values when parameter types are enums

