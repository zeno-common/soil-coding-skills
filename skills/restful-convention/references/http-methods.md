# HTTP Methods & Idempotency

## 1. CRUD Mapping

| HTTP Verb | Path | Description | SQL Equivalent |
|-----------|------|-------------|----------------|
| GET | `/v1/zoos` | List all zoos | SELECT |
| POST | `/v1/zoos` | Create a new zoo | INSERT |
| GET | `/v1/zoos/{id}` | Get a specific zoo | SELECT |
| PUT | `/v1/zoos/{id}` | Replace entire zoo resource | UPDATE |
| PATCH | `/v1/zoos/{id}` | Partially update zoo resource | UPDATE |
| DELETE | `/v1/zoos/{id}` | Delete a specific zoo | DELETE |
| GET | `/v1/zoos/{id}/animals` | List animals in a specific zoo | SELECT |

## 2. Method Semantics

### GET
- Retrieve resource representation. Must **never** modify server state.
- Cacheable by default.
- Use for read operations only.

### POST
- Create a new resource. Send the resource representation in the request body.
- **Not idempotent** — repeated calls create multiple resources.
- Use for creation and non-idempotent operations.

### PUT
- Replace the entire resource with the provided representation.
- **Idempotent** — repeated calls produce the same result.
- Client must send the **complete** resource representation.
- Use for full updates.

### PATCH (Optional)
- Partially update a resource. Only the fields provided in the request body are modified.
- **Idempotent** — repeated calls with the same patch produce the same result.
- Use for partial updates.

### DELETE
- Remove a resource identified by its ID.
- **Idempotent** — deleting a resource that no longer exists returns 404 but does not change state.
- First call: `200 OK` or `204 No Content`. Subsequent calls: `404 Not Found`.

## 3. Idempotency Summary

| Method | Idempotent | Reason |
|--------|-----------|--------|
| GET | ✅ | Read-only, no side effects |
| HEAD | ✅ | Read-only, no side effects |
| OPTIONS | ✅ | Read-only, no side effects |
| TRACE | ✅ | Read-only, no side effects |
| PUT | ✅ | Repeated calls overwrite with same state |
| DELETE | ✅ | Resource already deleted, state unchanged |
| PATCH | ✅ | Same patch applied repeatedly yields same state |
| POST | ❌ | Each call creates a new resource |

## 4. Non-Idempotent DELETE Warning

- `DELETE /items/last` is **not** idempotent — each call deletes a different resource.
- Refactor to use a resource identifier: `DELETE /items/{id}`.
- If the operation is inherently non-idempotent, use `POST` instead.

```