# Naming Conventions

## 1. General Rules

- Names must not start or end with an underscore `_` or dollar sign `$`.
  - Counter-example: `_name` / `__name` / `$Object` / `name_` / `name$` / `Object$`
- Chinese, Pinyin, or Pinyin-English mixed naming is prohibited. Use accurate English spelling and grammar.
  - Positive example: `alibaba` / `taobao` / `youku` / `tianchi` (internationally recognized Chinese names are acceptable)
- No discriminatory or offensive words in naming or comments.

## 2. Class Names

- Use UpperCamelCase style.
  - Positive example: `ForceCode` / `UserDO` / `HtmlDTO` / `XmlService` / `TcpUdpDeal` / `TaPromotion`
- Exceptions: DO / BO / DTO / VO / AO / PO / UID etc.
  - Positive example: `UserDO` / `HtmlDTO` / `TcpUdpDeal` / `TaPromotion`
- Abstract class names must start with `Abstract` or `Base`.
  - Positive example: `BaseUserService`
- Exception class names must end with `Exception`.
  - Positive example: `BusinessException`
- Test class names must start with the class being tested and end with `Test`.
  - Positive example: `UserServiceTest`

## 3. Method Names, Parameter Names, Member Variables, Local Variables

- Use lowerCamelCase style.
  - Positive example: `localValue` / `getHttpMessage()` / `inputUserId`

## 4. Constant Names

- All uppercase, words separated by underscores. Names should be semantically complete and clear.
  - Positive example: `MAX_STOCK_COUNT` / `CACHE_EXPIRED_TIME`
  - Counter-example: `MAX_COUNT` / `EXPIRED_TIME`
- Constants and variables sharing similar semantics can share a prefix for grouping.
  - Positive example: `STOCK_TYPE_IN` / `STOCK_TYPE_OUT`

## 5. Package Names

- All lowercase, dot-separated. Each segment should be a single English word with semantic meaning.
  - Positive example: `com.alibaba.openapi` / `com.alibaba.util`
  - Counter-example: `com.alibaba.open.api` / `com.alibaba.utils`

## 6. Boolean Variables

- Do not prefix with `is` to avoid serialization issues in some Java frameworks.
  - Counter-example: `boolean isDeleted` (getter becomes `isDeleted()`, causing ambiguity with `deleted`)
  - Positive example: `boolean deleted` (getter is `isDeleted()`)

## 7. Array Declaration

- Brackets are part of the array type.
  - Positive example: `String[] args`
  - Counter-example: `String args[]`

## 8. Enum Names

- Use UpperCamelCase for enum class names. Enum values are all uppercase separated by underscores.
  - Positive example: `enum ProcessStatus { SUCCESS, FAILED }`

## 9. Service/DAO Layer Naming

| Object | Naming Convention |
|--------|-------------------|
| Service interface | `UserService` |
| Service implementation | `UserServiceImpl` |
| DAO interface | `UserDAO` |

## 10. Getter/Setter for Boolean

- For POJO boolean fields, do not add `is` prefix. The getter method name is `isXxx()`.
- For local boolean variables in RPC, `is` prefix is acceptable.

## 11. Abbreviations

- When using abbreviations in naming, keep the capitalization consistent.
  - Positive example: `XmlParser` / `HtmlService` / `TcpUdpDeal`
  - Counter-example: `XMLParser` / `HTMLService` / `TCPUDPDeal`

## 12. Service/DAO Method Naming Conventions

| Method Type | Naming |
|-------------|--------|
| Get single object | `getXxx` |
| Get multiple objects | `listXxx` |
| Get statistics | `countXxx` |
| Insert | `saveXxx` / `insertXxx` |
| Delete | `removeXxx` / `deleteXxx` |
| Update | `updateXxx` |

## 13. Design Pattern Naming

- When using design patterns, include the pattern name in the class name.
  - Positive example: `OrderFactory` / `LoginProxy` / `ResourceObserver`
- Interface classes should not carry the `I` prefix.
  - Positive example: `UserService` (not `IUserService`)
- Implementation classes should carry the `Impl` suffix.
  - Positive example: `UserServiceImpl`

## 14. Other Rules

- Avoid using any class name that differs only in case.
  - Counter-example: `String name` vs `String Name`
- Avoid using generic names like `key`, `value`, `item` in Map/Set.
- Do not use mixed naming conventions within the same codebase.

## Anti-Patterns

```java
// WRONG: is prefix for boolean POJO field
private boolean isSuccess;
```

## Corrected Patterns

```java
// CORRECT: No is prefix for boolean
private boolean success;
```