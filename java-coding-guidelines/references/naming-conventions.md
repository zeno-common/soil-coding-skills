# Naming Conventions

1. Names must not start/end with `_` or `$`. ❌ `_name` / `name$` / `Object$`
2. No Chinese/Pinyin/mixed naming. Use English. ✅ `alibaba` / `taobao` (internationally recognized names OK)
3. No discriminatory or offensive words.
4. Class names: UpperCamelCase. ✅ `ForceCode` / `UserDO` / `HtmlDTO`
5. DO/BO/DTO/VO/AO/PO/UID suffixes allowed. ✅ `UserDO` / `HtmlDTO`
6. Abstract classes: `Abstract`/`Base` prefix. ✅ `BaseUserService`
7. Exception classes: `Exception` suffix. ✅ `BusinessException`
8. Test classes: `{Class}Test`. ✅ `UserServiceTest`
9. Method/parameter/member/local variable: lowerCamelCase. ✅ `localValue` / `getHttpMessage()`
10. Constants: UPPER_SNAKE_CASE, semantically complete. ✅ `MAX_STOCK_COUNT` ❌ `MAX_COUNT`
11. Group related constants with shared prefix. ✅ `STOCK_TYPE_IN` / `STOCK_TYPE_OUT`
12. Packages: all lowercase, dot-separated, single word per segment. ✅ `com.alibaba.openapi` ❌ `com.alibaba.open.api`
13. Boolean fields: no `is` prefix (serialization ambiguity). ❌ `boolean isDeleted` ✅ `boolean deleted`
14. POJO boolean getter: `isXxx()`. RPC local boolean: `is` prefix OK.
15. Arrays: brackets with type. ✅ `String[] args` ❌ `String args[]`
16. Enums: UpperCamelCase class, UPPER_SNAKE_CASE values. ✅ `enum ProcessStatus { SUCCESS, FAILED }`
17. Service/DAO: Interface `UserService`, Impl `UserServiceImpl`, DAO `UserDAO`.
18. Method naming: get→`getXxx`, list→`listXxx`, count→`countXxx`, insert→`saveXxx`/`insertXxx`, delete→`removeXxx`/`deleteXxx`, update→`updateXxx`.
19. Design patterns: include pattern name. ✅ `OrderFactory` / `LoginProxy`
20. No `I` prefix on interfaces. ✅ `UserService` ❌ `IUserService`
21. `Impl` suffix on implementations. ✅ `UserServiceImpl`
22. No names differing only in case. ❌ `name` vs `Name`
23. No generic Map/Set keys: `key`, `value`, `item`.
24. Consistent naming convention across codebase.

## Anti-Patterns
```java
// ❌ is prefix for boolean POJO field
private boolean isSuccess;
```

## Corrected
```java
// ✅ No is prefix
private boolean success;
```