# Format, Comments & Project Structure

## Format Rules

| ID | Rule | Bad | Good |
|----|------|-----|------|
| F01 | 4 spaces indentation. No tabs | — | — |
| F02 | Line length <= 120 chars | — | — |
| F03 | Blank line between methods and logical sections. No blank lines at method start/end | — | — |
| F04 | K&R braces. Always use braces even for single-line | — | — |
| F05 | Spaces: after keywords `if (` / `for (`; around binary ops `a + b`; after `//`; after comma/semicolon. No space before method name `foo()` | — | — |
| F06 | Import order: static -> third-party -> javax/java -> project. No wildcard imports. Remove unused | — | — |
| F07 | Method length <= 80 lines. Refactor if longer | — | — |
| F08 | Method params <= 5. Use parameter object if more | — | — |
| F09 | No nested ternary operators | — | — |
| F10 | No magic numbers | `3` | `OrderStatus.COMPLETED` |

## Comment Rules

| ID | Rule |
|----|------|
| CM01 | Every class: Javadoc with purpose, `@author`, `@date` |
| CM02 | All public methods: Javadoc with `@param`, `@return`, `@throws` |
| CM03 | Internal comments: explain "why" not "what". Keep current. Delete obsolete |
| CM04 | TODO format: `// TODO: name description`. Resolve promptly |
| CM05 | No committed commented-out code. Use VCS |
| CM06 | Consistent comment language across codebase |

## Project Structure Rules

| ID | Rule |
|----|------|
| PS01 | Layering: `Controller/Facade -> Service(Impl) -> Manager -> DAO/Mapper -> Database` |
| PS02 | Layer naming: Controller->`XxxController`, Service->`XxxService`, ServiceImpl->`XxxServiceImpl`, Manager->`XxxManager`, DAO->`XxxDAO`/`XxxMapper` |
| PS03 | Domain model suffixes: DO (DB table mapping), DTO (cross-layer transfer), VO (presentation), BO (business logic), QO (query params) |
| PS04 | Package layout: `controller/ service/impl/ manager/ dao/ model/{entity,dto,vo,qo}/ config/ common/{constant,enums,exception,util}/ interceptor/` |
| PS05 | Dependencies flow downward only. No circular deps. No Controller->DAO bypass |
| PS06 | Exception handling per layer: Controller -> HTTP response; Service -> BusinessException; Manager -> wrap third-party; DAO -> DAOException |
| PS07 | Config via `application.yml`. No hardcoded values. Spring profiles for environments |

## Examples

```java
// BAD: Magic number
if (status == 3) { ... }

// GOOD: Named constant
if (status == OrderStatus.COMPLETED) { ... }
```