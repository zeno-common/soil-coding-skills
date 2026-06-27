# ORM Rules

## 1. Query Result Mapping

- Do not use `SELECT *` in MyBatis mappings. Map only the columns needed.

## 2. Parameter Binding

- Always use `#{}` (parameterized) instead of `${}` (string substitution) to prevent SQL injection.
  - Exception: `ORDER BY` dynamic column names may use `${}` but must be validated against a whitelist.

## 3. Batch Operations

- Use batch insert/update for multiple records. Avoid looping single operations.

## 4. Transaction Annotation

- Use `@Transactional` carefully. Understand rollback rules:
  - Default rollback only on `RuntimeException`.
  - Specify `rollbackFor = Exception.class` for checked exceptions.