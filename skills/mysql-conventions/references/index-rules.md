# Index Rules

## 1. Index Naming

- Primary key index: `pk_` prefix
- Unique index: `uk_` prefix
- Normal index: `idx_` prefix
  - ✅ `uk_user_email` / `idx_create_time`

## 2. Index Design

- Avoid duplicate or redundant indexes.
- Composite index: follow the leftmost prefix rule. Put the column with highest selectivity first.
- Limit the number of indexes per table (recommend ≤ 5).
- Index length for `VARCHAR` columns: specify prefix length to reduce index size.

## 3. Index Usage

- Avoid operations that invalidate indexes:
  - Functions on indexed columns: `WHERE YEAR(create_time) = 2024` → use `WHERE create_time >= '2024-01-01' AND create_time < '2025-01-01'`
  - Implicit type conversion: `WHERE varchar_col = 123` → use `WHERE varchar_col = '123'`
  - `LIKE` with leading wildcard: `WHERE name LIKE '%john'` → use full-text search
  - `OR` conditions across different indexes
  - `NOT IN`, `NOT EXISTS`, `!=` on indexed columns

## 4. Covering Index

- Use covering indexes to avoid table lookups.
  - ✅ `SELECT id, name FROM user WHERE name = 'test'` with index on `(name, id)`

## 5. ORDER BY and Index

- `ORDER BY` field should be part of a composite index and placed last in the index order to avoid `filesort`.

## Anti-Patterns

```sql
-- ❌ Function on indexed column
WHERE YEAR(create_time) = 2024;

-- ❌ Implicit type conversion
WHERE varchar_col = 123;

-- ❌ Leading wildcard LIKE
WHERE name LIKE '%john';
```

## Corrected Patterns

```sql
-- ✅ Range condition instead of function
WHERE create_time >= '2024-01-01' AND create_time < '2025-01-01';

-- ✅ String comparison
WHERE varchar_col = '123';

-- ✅ Full-text search or prefix LIKE
WHERE name LIKE 'john%';
```