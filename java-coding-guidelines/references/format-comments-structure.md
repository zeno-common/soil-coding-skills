# Format, Comments & Project Structure

## Format

1. 4 spaces indentation. No tabs.
2. Line length ≤ 120 chars.
3. Blank line between methods and logical sections. No blank lines at method start/end.
4. K&R braces. Always use braces even for single-line.
5. Spaces: after keywords `if (` / `for (`; around binary ops `a + b`; after `//`; after comma/semicolon. No space before method name `foo()`.
6. Import order: static → third-party → javax/java → project. No wildcard imports. Remove unused.
7. Method length ≤ 80 lines. Refactor if longer.
8. Method params ≤ 5. Use parameter object if more.
9. No nested ternary operators.
10. No magic numbers. ✅ `OrderStatus.COMPLETED` ❌ `3`

## Comments

11. Every class: Javadoc with purpose, `@author`, `@date`.
12. All public methods: Javadoc with `@param`, `@return`, `@throws`.
13. Internal comments: explain "why" not "what". Keep current. Delete obsolete.
14. TODO format: `// TODO: name description`. Resolve promptly.
15. No committed commented-out code. Use VCS.
16. Consistent comment language (Chinese or English) across codebase.

## Project Structure

Layering: `Controller/Facade → Service(Impl) → Manager → DAO/Mapper → Database`

Layer naming: Controller→`XxxController`, Service→`XxxService`, ServiceImpl→`XxxServiceImpl`, Manager→`XxxManager`, DAO→`XxxDAO`/`XxxMapper`.

Domain model suffixes: DO (DB table mapping), DTO (cross-layer transfer), VO (presentation), BO (business logic), QO (query params).

Package layout: `controller/ service/impl/ manager/ dao/ model/{entity,dto,vo,qo}/ config/ common/{constant,enums,exception,util}/ interceptor/`

17. Dependencies flow downward only. No circular deps. No Controller→DAO bypass.
18. Exception handling per layer: Controller → HTTP response; Service → BusinessException; Manager → wrap third-party; DAO → DAOException.
19. Config via `application.yml`. No hardcoded values. Spring profiles for environments.

## Anti-Patterns
```java
// ❌ Magic number
if (status == 3) { ... }
```

## Corrected
```java
// ✅ Named constant
if (status == OrderStatus.COMPLETED) { ... }
```