# Index Rules

## 1. Index Naming

- MongoDB does not support custom index names in the same way as relational databases, but follow a consistent naming convention for index keys:
  - Unique index: ensure `unique: true` is set explicitly
  - Compound index: document the field order and purpose in code comments
  - TTL index: clearly mark with `expireAfterSeconds`
- Use `name` option in `createIndex` for compound indexes to make them self-documenting:
  ```javascript
  db.orders.createIndex({ userId: 1, createdAt: -1 }, { name: "idx_userId_createdAt" })
  ```

## 2. ESR Rule (Equality, Sort, Range)

- When creating compound indexes, follow the ESR rule for optimal performance:
  1. **E**quality: Put equality filters first (`{status: 1}`)
  2. **S**ort: Put sort fields next (`{createdAt: -1}`)
  3. **R**ange: Put range filters last (`{amount: 1}`)
- OK: Compound index for `find({status: "active"}).sort({createdAt: -1}).range({amount: {$gt: 100}})`:
  ```javascript
  db.orders.createIndex({ status: 1, createdAt: -1, amount: 1 })
  ```
- BAD: Wrong order (range before sort prevents index sort optimization):
  ```javascript
  db.orders.createIndex({ status: 1, amount: 1, createdAt: -1 })
  ```

## 3. Index Design

- Avoid redundant indexes. If you have index `{a: 1, b: 1}`, you do not need `{a: 1}` (leftmost prefix is covered).
- Limit the number of indexes per collection (recommend <= 5). Each index adds write overhead and consumes memory.
- Create indexes in the background for production deployments to avoid blocking operations:
  ```javascript
  db.orders.createIndex({ userId: 1 }, { background: true })
  ```
- Use partial indexes to reduce index size when queries always include a specific condition:
  ```javascript
  db.orders.createIndex(
    { status: 1, createdAt: -1 },
    { partialFilterExpression: { status: "active" } }
  )
  ```

## 4. Index Usage Verification

- Always use `explain("executionStats")` to verify index usage for new or modified queries.
  ```javascript
  db.orders.find({ userId: "u123", status: "active" }).explain("executionStats")
  ```
- Key metrics to check:
  - `totalDocsExamined`: Should be close to `nReturned` (ideal: 1:1 ratio)
  - `executionTimeMillis`: Should be acceptable for SLA
  - `winningPlan.stage`: Should be `IXScan` not `COLLSCAN`
  - `winningPlan.sortPattern`: Should use index, not in-memory sort

## 5. Covered Queries

- A covered query returns all fields from the index without fetching the document (no `FETCH` stage).
- To create a covered query, include all projected fields in the index.
  ```javascript
  // Index
  db.users.createIndex({ status: 1, name: 1, email: 1 })
  // Covered query - all returned fields are in the index
  db.users.find({ status: "active" }, { name: 1, email: 1, _id: 0 })
  ```
- Covered queries are significantly faster as they avoid disk I/O for document fetch.

## 6. Index Invalidation Patterns

- Avoid patterns that prevent index usage:
  - `$or` with different index fields (use `$in` instead when possible)
  - `$ne` / `$nin` (full scan, cannot use index efficiently)
  - `$regex` with leading wildcard: `{name: /.*john/}` -> use `{name: /^john/}` or Atlas Search
  - `$exists: true` on large collections
  - Negation operators: `$not`, `$nor`
  - Case-insensitive regex without a collation index: `{name: /^john/i}`

## 7. Special Index Types

- **TTL Index**: Auto-delete expired documents. Use for session data, logs, temporary records.
  ```javascript
  db.sessions.createIndex({ createdAt: 1 }, { expireAfterSeconds: 3600 })
  ```
  - TTL index field must be a Date type.
  - TTL cleanup runs approximately every 60 seconds; do not rely on exact deletion timing.
- **Text Index**: For full-text search. Only one text index per collection.
  ```javascript
  db.articles.createIndex({ title: "text", content: "text" })
  ```
  - For complex search needs, prefer Atlas Search (Lucene-based) over MongoDB text indexes.
- **Geospatial Index**: Use `2dsphere` for geo queries on GeoJSON data.
  ```javascript
  db.stores.createIndex({ location: "2dsphere" })
  ```
- **Wildcard Index**: Use sparingly for schemaless fields. Prefer explicit indexes.
  ```javascript
  db.logs.createIndex({ "attributes.$**": 1 })
  ```

## 8. Sharding Key Considerations

- If the collection may be sharded, choose a shard key early. Shard keys are immutable.
- Ideal shard key properties:
  - High cardinality (many distinct values)
  - Low frequency (evenly distributed, no hot chunks)
  - Non-monotonic (avoid Snowflake ID `_id` or `createdAt` as sole shard key -- they are time-ordered and cause hot shard on inserts)
  - Targeted queries (queries include the shard key to be routed to a single shard)
- OK: Hashed shard key on high-cardinality field: `{ userId: "hashed" }`
- OK: Compound shard key with low-cardinality prefix: `{ region: 1, userId: 1 }`
- BAD: Monotonically increasing shard key: `{ _id: 1 }` (Snowflake IDs are time-ordered, all inserts go to one shard)

## Anti-Patterns

```javascript
// BAD: Range before sort (violates ESR)
db.orders.createIndex({ status: 1, amount: 1, createdAt: -1 });

// BAD: Redundant index (covered by compound)
db.orders.createIndex({ status: 1 }); // when {status: 1, createdAt: -1} exists

// BAD: Leading wildcard regex
db.users.find({ name: /.*john/ });

// BAD: Monotonic shard key
sh.shardCollection("db.orders", { _id: 1 });
```

## Corrected Patterns

```javascript
// OK: ESR rule: Equality -> Sort -> Range
db.orders.createIndex({ status: 1, createdAt: -1, amount: 1 });

// OK: Remove redundant single-field index when compound covers it
// Only keep: { status: 1, createdAt: -1 }

// OK: Prefix regex (can use index)
db.users.find({ name: /^john/ });

// OK: Hashed shard key for even distribution
sh.shardCollection("db.orders", { userId: "hashed" });
```