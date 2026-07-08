# Naming Conventions

## Rules

| ID | Rule | Bad | Good |
|----|------|-----|------|
| N01 | Names must not start/end with `_` or `$` | `_name`, `name$`, `Object$` | `name`, `objectRef` |
| N02 | No Chinese/Pinyin/mixed naming. Use English. Internationally recognized names (e.g. `alibaba`, `taobao`) are OK | `mingzi`, `zhangSan` | `userName`, `orderList` |
| N03 | No discriminatory or offensive words | — | — |
| N04 | Class names: UpperCamelCase | — | `ForceCode`, `UserDO`, `HtmlDTO` |
| N05 | DO/BO/DTO/VO/AO/PO/UID suffixes allowed. UID = Unique Identifier for wrapping identity (e.g. `UserUID`) | — | `UserDO`, `HtmlDTO` |
| N06 | Abstract classes: `Abstract` or `Base` prefix | — | `BaseUserService` |
| N07 | Exception classes: `Exception` suffix | — | `BusinessException` |
| N08 | Test classes: `{Class}Test` | — | `UserServiceTest` |
| N09 | Method/parameter/member/local variable: lowerCamelCase | — | `localValue`, `getHttpMessage()` |
| N10 | Constants: UPPER_SNAKE_CASE, semantically complete | `MAX_COUNT` | `MAX_STOCK_COUNT` |
| N11 | Group related constants with shared prefix | — | `STOCK_TYPE_IN`, `STOCK_TYPE_OUT` |
| N12 | Packages: all lowercase, dot-separated, single word per segment | `com.alibaba.open.api` | `com.alibaba.openapi` |
| N13 | Boolean fields: no `is` prefix (serialization ambiguity in RPC frameworks) | `boolean isDeleted` | `boolean deleted` |
| N14 | POJO boolean getter: `isXxx()`. RPC local boolean: `is` prefix OK | — | — |
| N15 | Arrays: brackets with type, not after variable | `String args[]` | `String[] args` |
| N16 | Enums: UpperCamelCase class, UPPER_SNAKE_CASE values | — | `enum ProcessStatus { SUCCESS, FAILED }` |
| N17 | Service/DAO: Interface `UserService`, Impl `UserServiceImpl`, DAO `UserDAO` | — | — |
| N18 | Method naming by action: get->`getXxx`, list->`listXxx`, count->`countXxx`, insert->`saveXxx`/`insertXxx`, delete->`removeXxx`/`deleteXxx`, update->`updateXxx` | — | — |
| N19 | Design patterns: include pattern name in class | — | `OrderFactory`, `LoginProxy` |
| N20 | No `I` prefix on interfaces | `IUserService` | `UserService` |
| N21 | `Impl` suffix on implementations | — | `UserServiceImpl` |
| N22 | No names differing only in case | `name` vs `Name` | — |
| N23 | No generic Map/Set keys: `key`, `value`, `item` | — | — |
| N24 | Consistent naming convention across codebase | — | — |

## Examples

```java
// BAD: is prefix for boolean POJO field
private boolean isSuccess;

// GOOD: No is prefix
private boolean success;
```