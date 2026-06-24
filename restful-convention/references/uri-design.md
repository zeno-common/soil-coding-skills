# URI Design Rules

## 1. Protocol

- Use HTTPS protocol for all API endpoints.
  - ✅ `https://api.example.com/v1/users`
  - ❌ `http://api.example.com/v1/users`

## 2. Domain & Entry Point

- Place API under the main domain with a domain name as the first path segment.
  - ✅ `example.com/{domain_name}/*`
  - This preserves flexibility and scalability across services.

## 3. Path Naming

- All path segments must be **lowercase**.
  - ✅ `/v1/users` / `/v1/order-items`
  - ❌ `/v1/Users` / `/v1/orderItems`
- Resource names must be **nouns**, not verbs. The HTTP method already conveys the action.
  - ✅ `/v1/users` / `/v1/orders`
  - ❌ `/v1/getUser` / `/v1/createOrder`
- Resource names must be **plural**.
  - ✅ `/v1/users` / `/v1/zoos`
  - ❌ `/v1/user` / `/v1/zoo`
- Use hyphens (`-`) instead of underscores (`_`) for multi-word segments.
  - ✅ `/v1/order-items`
  - ❌ `/v1/order_items`
- Do **not** use a trailing slash (`/`) at the end of URIs.
  - ✅ `https://api.example.com/v1/devices`
  - ❌ `https://api.example.com/v1/devices/`
- Do **not** include file extensions in URIs.
  - ✅ `/v1/users`
  - ❌ `/v1/users.json` / `/v1/users.xml`
- Do **not** embed CRUD function names in URIs.
  - ✅ `GET /v1/users`
  - ❌ `GET /v1/users/list` / `POST /v1/users/create`
- Use query parameters for filtering, sorting, and pagination — not path segments.
  - ✅ `/v1/devices?region=USA&brand=XYZ&?$sortBy=installation-date`
  - ❌ `/v1/devices/region/USA/brand/XYZ`

## 4. Resource Hierarchy

- Use path segments to express resource relationships.
  - `GET /v1/zoos/{id}/animals` — list animals in a specific zoo
  - `GET /v1/users/{id}/orders` — list orders of a specific user
- Keep nesting to a maximum of 2 levels deep. Deeper relationships should use query parameters.

## 5. Anti-Patterns

```
❌ api.example.com/user/getUser
❌ api.example.com/user/addUser
❌ api.example.com/user/devices/managed-devices.xml
❌ api.example.com/v1/Users/
❌ api.example.com/v1/order_items
```

## 6. Correct Examples

```
✅ api.example.com/v1/zoos
✅ api.example.com/v1/zoos/{id}
✅ api.example.com/v1/zoos/{id}/animals
✅ api.example.com/v1/order-items?status=active&?$sortBy=created-at
```