# SQL Rules

## 1. Count

- Use `COUNT(*)` instead of `COUNT(column)` or `COUNT(1)`.
  - Reason: `COUNT(*)` counts all rows including NULL; `COUNT(column)` does not count NULL values.
- `COUNT(*)` is optimized by the engine and does not fetch all columns.

## 2. Avoid SELECT *

- Never use `SELECT *`. Specify the exact columns needed.
  - Reason: wastes network bandwidth, prevents covering index optimization, breaks when columns are added/removed.

## 3. INSERT Column List

- Always specify column list in INSERT statements.
  - Positive example: `INSERT INTO user (name, age) VALUES ('test', 20)`
  - Counter-example: `INSERT INTO user VALUES ('test', 20)` (breaks if columns are reordered)

## 4. Transaction Size

- Keep transactions small. Avoid long-running transactions that hold locks.
- Do not include RPC calls inside transactions.

## 5. IN Clause

- Limit the number of values in `IN` clause (recommend ≤ 500). Use batch queries or temporary tables for large sets.

## 6. Pagination

- Avoid deep pagination with large offsets.
  - Counter-example: `SELECT * FROM user LIMIT 1000000, 10`
  - Positive example: Use deferred join or seek method:
    ```sql
    SELECT u.* FROM user u
    INNER JOIN (SELECT id FROM user ORDER BY id LIMIT 1000000, 10) t
    ON u.id = t.id
    ```

## 7. UPDATE/DELETE with WHERE

- Always use `WHERE` clause in UPDATE and DELETE statements.
- Use `LIMIT 1` for single-row updates to prevent accidental mass updates.

## 8. Avoid Multiple Column Updates in One SQL

- Do not update multiple columns that are not logically related in one SQL statement.

## 9. IS NULL vs = NULL

- Use `IS NULL` / `IS NOT NULL` to check for NULL. Never use `= NULL` or `!= NULL`.

## 10. Large Text Fields

- Store large text (articles, descriptions) in a separate table to avoid affecting main table query performance.

## Anti-Patterns

```sql
-- WRONG: SELECT *
SELECT * FROM user WHERE id = 1;

-- WRONG: Deep pagination
SELECT * FROM user LIMIT 1000000, 10;

-- WRONG: UPDATE without WHERE
UPDATE user SET status = 1;

-- WRONG: = NULL instead of IS NULL
WHERE name = NULL;
```

## Corrected Patterns

```sql
-- CORRECT: Specify columns
SELECT id, name, age FROM user WHERE id = 1;

-- CORRECT: Deferred join for deep pagination
SELECT u.* FROM user u
INNER JOIN (SELECT id FROM user ORDER BY id LIMIT 1000000, 10) t
ON u.id = t.id;

-- CORRECT: UPDATE with WHERE and LIMIT
UPDATE user SET status = 1 WHERE id = 100 LIMIT 1;

-- CORRECT: IS NULL
WHERE name IS NULL;
```