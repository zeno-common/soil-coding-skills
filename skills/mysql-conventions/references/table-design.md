# Table Design Rules

## 1. Table and Column Naming

- Table names and column names use lowercase letters or numbers separated by underscores.
  - ✅ `user_info` / `order_detail`
  - ❌ `UserInfo` / `userInfo` / `ORDER_DETAIL`
- Table names must not start with a number.
  - ❌ `1_user_info`
- Disable reserved words as table/column names (e.g., `order`, `group`, `desc`). Use backticks if unavoidable.

## 2. Primary Key

- Every table must have a primary key.
- Use auto-increment `BIGINT UNSIGNED` for primary key.
- Primary key name should be `id` or `table_name_id`.

## 3. Column Types

- Use `DECIMAL` for monetary amounts. Do not use `FLOAT` or `DOUBLE`.
- Use `VARCHAR` for variable-length strings. Specify a reasonable length.
- Use `DATETIME` or `TIMESTAMP` for time fields.
  - `TIMESTAMP` range: 1970-01-01 to 2038-01-19
  - `DATETIME` range: 1000-01-01 to 9999-12-31
- Use `UNSIGNED` for non-negative integers.

## 4. Logical Deletion

- Use logical deletion (is_deleted / deleted) instead of physical deletion.
  - ✅ `ALTER TABLE user ADD COLUMN is_deleted TINYINT DEFAULT 0;`

## 5. Common Fields

- Every table should include: `id`, `create_time`, `update_time`, `is_deleted`.
- `create_time` / `update_time` should use `DATETIME` type with `DEFAULT CURRENT_TIMESTAMP`.

## 6. Character Set

- Use `utf8mb4` character set (not `utf8`, which only supports 3-byte characters and cannot store emoji).
- Use `utf8mb4_general_ci` or `utf8mb4_unicode_ci` collation.

## 7. Table Design

- Single table column count should not exceed 30.
- Single table row size should not exceed 8KB.
- Use appropriate data types to minimize storage: `TINYINT` vs `INT` vs `BIGINT`.

## Anti-Patterns

```sql
-- ❌ No column list in INSERT
INSERT INTO user VALUES (1, 'test', 20);
```

## Corrected Patterns

```sql
-- ✅ Column list in INSERT
INSERT INTO user (name, age) VALUES ('test', 20);
```