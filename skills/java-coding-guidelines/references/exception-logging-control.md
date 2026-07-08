# Exception, Logging & Control

## Exception

1. Catch specific exceptions, not `Exception`/`Throwable`/`RuntimeException`. ❌ `catch (Exception e)` ✅ `catch (IOException e)`
2. No empty catch blocks. At minimum log the exception.
3. No business logic in catch — only log, wrap, rethrow.
4. No `return` in finally block (overrides return/exception from try/catch).
5. Use try-with-resources for `AutoCloseable`. ✅ `try (InputStream is = new FileInputStream("f")) { ... }`
6. Preserve cause when rethrowing. ✅ `throw new BaseException("msg", e)` ❌ `throw new BaseException("msg")`
7. NPE prevention: `Objects.requireNonNull()` or `Optional`. Check null on method params.
8. `RuntimeException` for business exceptions. Checked exceptions only for recoverable conditions.
9. Use exceptions not return codes for errors. No exceptions for normal flow control.
10. Declare checked exceptions in method signature. No `RuntimeException` in throws clause.

## Logging

11. SLF4J + Logback/Log4j2. No `System.out.println()`. No direct Log4j/Commons Logging.
12. Log levels: ERROR (immediate attention) > WARN (potential issue) > INFO (business milestone) > DEBUG (dev only).
13. Parameterized logging with `{}`. ❌ `log.info("User " + id)` ✅ `log.info("User {}", id)`
14. Guard debug logging: `if (log.isDebugEnabled()) { log.debug("Detail: {}", expensive()); }`
15. Always log full exception with stack trace. ❌ `log.error("Error: " + e.getMessage())` ✅ `log.error("Error: {}", id, e)`
16. No sensitive data in logs (passwords, tokens, ID numbers). Mask: `phone: 138****1234`.
17. App logs ≥ 15 days. Error logs ≥ 30 days.
18. Always log in catch block. Never swallow silently.
19. Log entry/exit of important service methods.

## Control

20. Every `switch` must have `default`. Every `case` ends with `break`/`return` or fall-through comment. Handle `null` on `String` switch.
21. Always use braces `{}` even for single-line blocks. ❌ `if (cond) doSomething();` ✅ `if (cond) { doSomething(); }`
22. No complex boolean in `if`. Extract to named variable. ✅ `boolean eligible = active && age >= 18; if (eligible) { ... }`
23. Prefer positive conditions. No double negation. ❌ `if (!isNotValid)` ✅ `if (isValid)`
24. Ternary only for simple conditions. No nesting.
25. No `else` after `if` that returns. ❌ `if (c) { return a; } else { return b; }` ✅ `if (c) { return a; } return b;`
26. Max 3 nesting levels. Use guard clauses or extract methods.
27. Declare loop variables in for statement. ✅ `for (int i = 0; ...)`
28. No modifying loop variable inside for body.
29. Enhanced for when index not needed. No foreach for modifying collection (use `Iterator`/`removeIf`).

## Anti-Patterns
```java
// ❌ Catching Exception broadly
catch (Exception e) { }
// ❌ String concatenation in log
log.info("User " + userId + " logged in");
```

## Corrected
```java
// ✅ Catch specific exception
catch (IOException e) { log.error("IO error: {}", filePath, e); }
// ✅ Parameterized logging
log.info("User {} logged in", userId);
```