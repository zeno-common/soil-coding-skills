# Query Rules

## 1. Projection

- Always use projection to limit returned fields. Never return entire documents unnecessarily.
  - OK: `db.users.find({status: "active"}, {name: 1, email: 1, _id: 0})`
  - BAD: `db.users.find({status: "active"})`
- In Spring Data MongoDB, use `@Query(fields = "...")` or `include/exclude` in `Query`.

## 2. Avoid `$where` and JavaScript Expressions

- Never use `$where` operator or JavaScript expressions in queries. They are slow and cannot use indexes.
  - BAD: `db.users.find({ $where: "this.age > 18" })`
  - OK: `db.users.find({ age: { $gt: 18 } })`

## 3. Query Selectivity

- Ensure queries are selective. A query that scans a large portion of a collection will be slow regardless of indexes.
- Target query selectivity should return < 5% of documents for optimal index usage.
- For low-selectivity queries, consider adding more filter conditions or using covered queries.

## 4. Pagination

- Avoid `skip` + `limit` for deep pagination (large offset values). Use range-based (seek/cursor) pagination instead.
  - BAD: Deep skip pagination:
    `db.orders.find({}).sort({createdAt: -1}).skip(100000).limit(20)`
  - OK: Range-based pagination:
    `db.orders.find({ createdAt: { $lt: lastCreatedAt } }).sort({createdAt: -1}).limit(20)`
- For Spring Data MongoDB, use `Pageable` for small offsets. For large datasets, implement cursor-based pagination manually.

## 5. Aggregation Pipeline Optimization

- Place `$match` as early as possible in the pipeline to reduce documents processed by subsequent stages.
  - OK: `[$match -> $group -> $sort]`
  - BAD: `[$sort -> $group -> $match]`
- Place `$project` after `$match` but before expensive stages like `$group` or `$lookup` to reduce field overhead.
- Use `$limit` early if you only need a subset of results.
- Avoid `$lookup` (join) when possible. Prefer denormalization for read-heavy workloads.
  - If `$lookup` is necessary, ensure the foreign field is indexed.

## 6. `$lookup` Rules

- `$lookup` performs a left outer join and is expensive. Follow these rules:
  - Always index the `foreignField` in the joined collection.
  - Limit the number of documents processed by `$lookup` with a preceding `$match`.
  - Avoid nested `$lookup` (lookup within lookup).
  - Consider embedding instead of joining for frequently co-accessed data.

## 7. Bulk Write Operations

- Use `bulkWrite` for batch inserts/updates instead of individual operations.
  - OK: `db.orders.bulkWrite([insertOp1, insertOp2, updateOp1])`
  - BAD: Loop with individual `insertOne` / `updateOne`
- In Spring Data MongoDB, use `MongoTemplate.bulkOps()` or `MongoRepository.saveAll()` for batch operations.
- Set `ordered: false` for independent operations to allow parallel execution.

## 8. Update Operators

- Always use update operators (`$set`, `$inc`, `$push`, `$pull`) instead of full document replacement.
  - OK: `db.users.updateOne({_id: id}, {$set: {name: "New Name"}})`
  - BAD: `db.users.replaceOne({_id: id}, entireNewDocument)` (loses unset fields)
- Use `$set` for partial updates. Never replace entire documents for single-field changes.
- Use `$inc` for atomic increments instead of read-modify-write.
  - OK: `db.counters.updateOne({_id: "orderId"}, {$inc: {seq: 1}})`
  - BAD: Read -> increment in app -> write back (race condition)

## 9. Transactions

- MongoDB supports multi-document ACID transactions (4.0+ for replica sets, 4.2+ for sharded clusters).
- **Minimize transaction usage**. Prefer schema design that avoids cross-document transactions:
  - Embed related data that must be updated atomically
  - Use denormalization for consistency
- When transactions are necessary:
  - Keep transactions short. Do not include external API calls inside transactions.
  - Retry transactions on `WriteConflict` errors with exponential backoff.
  - Use `@Transactional` in Spring Data MongoDB with `MongoTransactionManager`.
- In Spring Data MongoDB:
  ```java
  @Transactional(rollbackFor = Exception.class)
  public void transferOrder(OrderDoc from, OrderDoc to) { ... }
  ```

## 10. Read Preference and Write Concern

- For read-heavy workloads, use `ReadPreference.secondaryPreferred()` to offload reads from primary.
- For critical writes (financial transactions), use `WriteConcern.MAJORITY` to ensure durability.
- Configure at the operation level, not globally, based on business requirements.

## Anti-Patterns

```javascript
// BAD: No projection
db.users.find({status: "active"});

// BAD: Deep skip pagination
db.orders.find({}).skip(100000).limit(20);

// BAD: $match after $group
[{$group: {...}}, {$match: {status: "active"}}];

// BAD: Full document replacement for partial update
db.users.replaceOne({_id: id}, {name: "New Name"});

// BAD: $where with JavaScript
db.users.find({$where: "this.age > 18"});
```

## Corrected Patterns

```javascript
// OK: With projection
db.users.find({status: "active"}, {name: 1, email: 1});

// OK: Range-based pagination
db.orders.find({createdAt: {$lt: lastCreatedAt}}).sort({createdAt: -1}).limit(20);

// OK: $match before $group
[{$match: {status: "active"}}, {$group: {...}}];

// OK: Partial update with $set
db.users.updateOne({_id: id}, {$set: {name: "New Name"}});

// OK: Native query operator
db.users.find({age: {$gt: 18}});
```