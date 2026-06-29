# Response & Status Codes

## 1. Core Principle

- **Must** use proper HTTP status codes. Do **not** always return 200 with a custom `code` field in the body.
- The HTTP status code is the primary indicator of request outcome. A custom business code in the response body is supplementary, not a replacement.
- When the HTTP request is successful (with a 2xx status), either the response body is not returned or the response body is directly returned.
- When the HTTP request fails (with a 4xx/5xx status), a unified error response body `{"errCode":"ERROR_CODE","errDesc":"error description"}` is returned.

### Anti-Pattern

```
HTTP/1.1 200 OK
Content-Type: application/json

{ "errCode": "NOT_FOUND", "errDesc": "该活动不存在" }
```

This is wrong — the status code says success but the body says failure.

### Correct Pattern

```
HTTP/1.1 404 Not Found
Content-Type: application/json

{ "errCode": "NOT_FOUND", "errDesc": "Activity not found" }
```

## 2. Success Status Codes (2xx)

| Status Code | Name | When to Use |
|-------------|------|-------------|
| 200 | OK | Successful GET or POST that returns data |
| 201 | Created | Successful POST/PUT/PATCH that creates a resource. Return the created resource or its location. |
| 202 | Accepted | Request accepted for async processing. The actual result will be available later. |
| 204 | No Content | Successful DELETE, or successful PUT/PATCH that returns no body |

- Use 200 for successful GET or POST requests that return data.

## 3. Redirection Status Codes (3xx)

| Status Code | Name | When to Use |
|-------------|------|-------------|
| 303 | See Other | Redirect after POST/PUT/DELETE. Use `Location` header to point to the new resource. |

- 301 (permanent redirect) and 302/307 (temporary redirect) are handled at the application/browser level — API layer does not need them.
- 303 is specifically for redirecting after state-changing operations (POST/PUT/DELETE).

## 4. Client Error Status Codes (4xx)

| Status Code | Name | When to Use |
|-------------|------|-------------|
| 400 | Bad Request | Malformed request syntax, invalid parameters, validation failure |
| 401 | Unauthorized | Missing or invalid authentication token/credentials |
| 403 | Forbidden | Authenticated but not authorized to access this resource |
| 404 | Not Found | Resource does not exist or path is invalid |
| 405 | Method Not Allowed | HTTP method not supported for this endpoint (e.g., POST on a GET-only endpoint) |
| 406 | Not Acceptable | Requested response format not available (e.g., client wants XML but only JSON is supported) |
| 408 | Request Timeout | Client took too long to send the request |
| 410 | Gone | Resource permanently deleted (stronger than 404 — client should not retry) |
| 415 | Unsupported Media Type | Request Content-Type not supported (e.g., sending XML to a JSON-only API) |
| 429 | Too Many Requests | Rate limit exceeded |

### 401 vs 403 Distinction

- **401**: The user is **not authenticated** — identity is unknown or token is invalid.
- **403**: The user is **authenticated but not authorized** — identity is known but lacks permission.

## 5. Server Error Status Codes (5xx)

| Status Code | Name | When to Use |
|-------------|------|-------------|
| 500 | Internal Server Error | Unexpected server-side failure. Do **not** expose stack traces or internal details. |
| 503 | Service Unavailable | Server is temporarily unable to handle the request (maintenance, overload). |

- API should **not** expose server internals. 500 and 503 are sufficient for most cases.
- Avoid returning 501/502/504/505 unless you are operating an infrastructure-level gateway.

## 6. Error Response Format

When returning errors, include a structured error body:

```json
{
  "errCode": "ERROR_CODE",
  "errDesc": "error description"
}
```

- `code`: Error identification code.
- `message`: Human-readable description of the error.
