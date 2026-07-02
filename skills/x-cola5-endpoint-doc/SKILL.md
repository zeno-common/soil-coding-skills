---
name: x-cola5-endpoint-doc
description: Generates endpoint documentation from COLA 5 adapter layer for both web calls (controller) and service-to-service calls (adapter.api). Invoke when user asks to generate API docs, interface documentation, or list all endpoints from COLA5 project.
---

# Endpoint Documentation Generator

Based on COLA 5 architecture adapter layer, generate structured interface documentation for both **web calls** (controller) and **service-to-service calls** (adapter.api HTTP/RPC implementations).

| Section | Reference File | When to Read |
|---------|---------------|-------------|
| Extraction Spec | `references/extraction-spec.md` | Extracting endpoint info from source code |
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
2. Find all Cmd/Qry/VO classes under `app/` module (referenced by controllers)

**Service API (adapter.api)**:
1. Find all `@RestController` classes under `adapter/api/http/` package (HTTP/Feign provider endpoints)
2. Find all `@DubboService` classes under `adapter/api/rpc/` package (Dubbo provider endpoints)
3. Find all DTO classes under `client/dto/` package (referenced by adapter.api)
4. Find `{Resource}Api` interfaces under `client/api/` package (contract definition, used for method signatures)

### Step 2: Read `references/extraction-spec.md`

Follow the extraction rules to parse source code and extract information:
- **Web**: endpoint-level extraction (HTTP method, path, status code, Cmd/Qry/VO)
- **Service**: method-level extraction (method name, params, return type, DTO)

All extraction rules and conventions are defined in this file.

### Step 3: Extract Consumer Usage information (service API only)

For service API docs, extract what Consumer services need to integrate:

1. **Maven coordinates** — read `client/pom.xml` to extract `groupId`, `artifactId`, `version`
2. **Service name** — read `spring.application.name` from the provider's `application.yml` (used as `@FeignClient(name = ...)` value)
3. **Consumer integration** — see `references/extraction-spec.md` Consumer Integration section for Feign/Dubbo rules

> Provider implementation details (class name, package) are Provider-side internal info, NOT Consumer usage info. Do NOT include in documentation.

> Web API docs do NOT need Consumer Usage information — they serve frontend/admin developers who call HTTP endpoints directly.

### Step 4: Read `references/doc-output-format.md`

Format the extracted information into the standard documentation output. All output rules, file structure, and format conventions are defined in this file.

**Output location**: `docs/cola5-endpoints/` directory.