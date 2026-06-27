# Versioning & Filtering

## 1. API Versioning

APIs evolve over time. Versioning ensures backward compatibility while allowing incremental changes.

### Recommended: URI Path Versioning

- Embed the version number in the URI path as the first segment after the domain.
- Simple, explicit, and widely adopted.

```
✅ api.example.com/v1/users
✅ api.example.com/v2/users
```

- Each version operates as an independent route set.
- Older versions continue to function until explicitly deprecated.
- 
### Versioning Rules

- Version numbers must be **positive integers**: `v1`, `v2`, etc.
- Increment the major version only when breaking changes are introduced.
- Maintain older versions with a documented deprecation timeline.
- Include the version prefix in all endpoint definitions.


## 2. Filtering & Pagination

When returning collections, the server must support filtering and pagination to avoid returning unbounded result sets.

### Pagination Parameters

| Parameter   | Description | Example          |
|-------------|-------------|------------------|
| `$page`     | Page number (1-based) | `?$page=2`       |
| `$pageSize` | Number of records per page | `?$pageSize=100` |
| `$limit`    | Maximum number of records to return | `?$limit=10`      |
| `$offset`   | Number of records to skip | `?$offset=10`     |

- Use either `$page`/`$pageSize` **or** `$limit`/`$offset` — do not mix.
- Set a reasonable default and maximum for `$pageSize`/`$limit` to prevent abuse.

### Sorting Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `$sortBy`   | Field name to sort by | `?$sortBy=name`   |
| `$order`    | Sort direction | `?$order=asc` / `?$order=desc` |

- Default sort order should be documented.
- Validate `$sortBy` against an allowlist of sortable fields to prevent injection.

### Filtering Parameters

- Use query parameters that match the resource field names.
- Combine multiple filters with `&`.

```
✅ GET /v1/devices?region=USA&brand=XYZ&?$sortBy=installation-date
✅ GET /v1/orders?status=active&$page=1&$pageSize=20&?$sortBy=createdAt&?$order=desc
```