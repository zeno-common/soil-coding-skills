# Exception, Logging & Control (COLA 5)

Merged general Java exception handling, logging, control flow rules, and COLA 5 layered architecture exception handling. COLA emphasizes dependency inversion and domain-driven design; exception design must reflect business semantics and strictly correspond to architecture layers.

## Exception - General Rules

| ID | Rule | Bad | Good |
|----|------|-----|------|
| E01 | Catch specific exceptions, not `Exception`/`Throwable`/`RuntimeException` | `catch (Exception e)` | `catch (IOException e)` |
| E02 | No empty catch blocks. At minimum log the exception | `catch (Exception e) { }` | `catch (Exception e) { log.warn("...", e); }` |
| E03 | No business logic in catch - only log, wrap, rethrow | — | — |
| E04 | No `return` in finally block (overrides return/exception from try/catch) | — | — |
| E05 | Use try-with-resources for `AutoCloseable` | `try { InputStream is = ...; } finally { is.close(); }` | `try (InputStream is = new FileInputStream("f")) { ... }` |
| E06 | Preserve cause when rethrowing | `throw new BaseException("msg")` | `throw new BaseException("msg", e)` |
| E07 | NPE prevention: `Objects.requireNonNull()` or `Optional`. Check null on method params | — | — |
| E08 | `RuntimeException` for business exceptions. Checked exceptions only for recoverable conditions | — | — |
| E09 | Use exceptions not return codes for errors. No exceptions for normal flow control | — | — |
| E10 | Declare checked exceptions in method signature. No `RuntimeException` in throws clause | — | — |

## Exception - COLA 5 Layered Handling

Core principle: **Throw exceptions with clear semantics early; catch as needed, handle uniformly at the top, never swallow exceptions.**

### 1. Exception Type Design

Use `BaseException` (extends `RuntimeException`) as the base class, deriving business and system exceptions, combined with `ExceptionType` enum to identify exception source categories.

```java
public enum ExceptionType {
  UNDEFINED,
  BIZ,    // Business exception (Application/Domain layer)
  SYS,    // System exception (Infrastructure layer)
  PARAM   // Parameter validation exception (Adapter layer)
}

public abstract class BaseException extends RuntimeException {
  private final String code;
  public ExceptionType type() { return ExceptionType.UNDEFINED; }
}

public class BizException   extends BaseException { public ExceptionType type() { return ExceptionType.BIZ; } }
public class SysException   extends BaseException { public ExceptionType type() { return ExceptionType.SYS; } }
public class ParamException extends BaseException { public ExceptionType type() { return ExceptionType.PARAM; } }
```

Error code `code` is managed as enums by domain, split into two parts: **`BizCode` (business-level) + error code**. Format: `[BUSINESS]-[CODE]`, e.g. `UC-ACCOUNT-EXISTED`. **Domain error codes** are defined in the Domain layer (expressing domain rules). **System error codes** are defined in the Infrastructure layer or base module.

### 2. Throwing Rules by Layer

| Layer | Throw What | Rules |
|-------|-----------|-------|
| **Adapter** | `ParamException` | Throw on basic input validation failure (non-null, format). No business logic, no low-level technical exceptions (e.g. `SQLException`). |
| **App** | `BizException` | No technical exceptions. Throw `BizException` when preconditions not met. When calling Domain/Infrastructure, typically do not catch or rethrow - let it bubble up. Wrap into higher-level business exception if needed. |
| **Domain** | `BizException` | Must throw `BizException` when domain invariant violated (e.g. `if (balance < amount) throw new BizException("BIZ-ACCT-001", "Insufficient balance");`). Never throw technical exceptions (`SQLException`, `NullPointerException`). Common expected checks can return `boolean`/`Optional`; only throw exceptions for flow-blocking errors. |
| **Infrastructure** | `SysException` / `BizException` | Must catch low-level technical exceptions (`SQLException`, `RedisConnectionException`, `HttpClientException`), wrap and convert to `SysException` (e.g. `catch (SQLException e) { throw new SysException("SYS-DB-001", "Database access failed", e); }`). External interface business errors convert to current domain `BizException`. |

### 3. Catching Rules by Layer

| Layer | Catch Rules |
|-------|------------|
| **Infrastructure** | **Must catch** all third-party/middleware technical exceptions, convert to `SysException` or domain-specific `BizException` then rethrow. Never leak technical details to upper layers. |
| **Domain** | **Typically no catch** - let business exceptions bubble up to App layer. Exception: when domain internally needs to execute A and B, and B failure requires rolling back A - catch B exception, execute rollback, then rethrow. |
| **App** | Transaction control point (`@Transactional` defaults to rollback on `RuntimeException` only; since `BaseException` extends `RuntimeException`, no need to catch for transaction). When necessary, catch and rethrow for exception translation (coarse-graining). **Strictly forbidden**: `catch (Exception e) {}`. |
| **Adapter & Global Fallback** | Adapter layer: no `try-catch` for business/system exceptions. Must use global exception handler (e.g. `@RestControllerAdvice`) for unified catch and conversion. |

### 4. Global Exception Handler Example

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ParamException.class)
    public ResponseEntity<RestExceptionResponse> handleParam(ParamException e) {
        log.warn("Parameter validation failed: {}", e.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(RestExceptionResponse.createFrom(e));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<RestExceptionResponse> handleValidation(MethodArgumentNotValidException e) {
        log.warn("Parameter validation failed: {}", e.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(RestExceptionResponse.createFrom(e));
    }

    @ExceptionHandler(WebBizException.class)
    public ResponseEntity<RestExceptionResponse> handleWebBiz(WebBizException e) {
        log.warn("Web business exception: {}", e.getMessage());
        return ResponseEntity.status(e.status())
                .body(RestExceptionResponse.createFrom(e));
    }

    @ExceptionHandler(BizException.class)
    public ResponseEntity<RestExceptionResponse> handleBiz(BizException e) {
        log.warn("Business processing failed: {}", e.getMessage());
        return ResponseEntity.status(HttpStatus.OK)
                .body(RestExceptionResponse.createFrom(e));
    }

    @ExceptionHandler(SysException.class)
    public ResponseEntity<RestExceptionResponse> handleSys(SysException e) {
        log.error("System exception: ", e);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(RestExceptionResponse.createFrom(e));
    }

    @ExceptionHandler(BaseException.class)
    public ResponseEntity<RestExceptionResponse> handleBase(BaseException e) {
        log.error("Unclassified exception: ", e);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(RestExceptionResponse.createFrom(e));
    }

    @ExceptionHandler(Throwable.class)
    public ResponseEntity<RestExceptionResponse> handleThrowable(Throwable throwable) {
        log.error("Unknown system exception: ", throwable);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(RestExceptionResponse.createFrom(throwable));
    }
}
```

> **Note**: `WebBizException` is a subclass of `BizException` for Web-layer business exceptions that need a specific HTTP status code (e.g. 409 for resource conflict, 403 for unauthorized). `RestExceptionResponse.createFrom(...)` is a unified response body factory method that extracts `code`, `message` etc. based on exception type.

### 5. Layered Exception Handling Matrix

| Layer | Throw What | Catch Rules | Typical Scenario |
|-------|-----------|-------------|-----------------|
| **Adapter** | `ParamException` | Do not catch business/system exceptions; delegate to global handler | Input non-null, format validation failure |
| **App** | `BizException` | Typically no catch, let bubble up to trigger transaction rollback; translate exceptions when necessary | Precondition not met during orchestration |
| **Domain** | `BizException` | No catch, throw directly. Never throw technical exceptions | Insufficient balance, illegal state transition |
| **Infrastructure** | `SysException` / `BizException` | **Must catch** technical exceptions, wrap as `SysException` or `BizException` | Database connection timeout -> `SysException` |
| **Global Handler** | N/A | **Unified catch** of all exceptions, convert to standard API response format | Unified error code and message for frontend |

### 6. Best Practices

1. **Anti-Corruption Layer (ACL) exception translation**: When calling external services from App or Infrastructure layer, the external service exception system may pollute our system. Must catch external exceptions at the boundary (typically in Infrastructure implementation classes), convert to internal `SysException` or `BizException`.
2. **Transaction rollback**: Ensure custom exceptions extend `RuntimeException`, otherwise Spring `@Transactional` will not roll back by default.

## Logging Rules

| ID | Rule | Bad | Good |
|----|------|-----|------|
| L01 | SLF4J + Logback/Log4j2. No `System.out.println()`. No direct Log4j/Commons Logging | — | — |
| L02 | Log levels: ERROR (immediate attention) > WARN (potential issue) > INFO (business milestone) > DEBUG (dev only) | — | — |
| L03 | Parameterized logging with `{}` | `log.info("User " + id)` | `log.info("User {}", id)` |
| L04 | Guard debug logging for expensive operations | — | `if (log.isDebugEnabled()) { log.debug("Detail: {}", expensive()); }` |
| L05 | Always log exception in catch blocks (never swallow). Log level follows exception type: `BizException`/`ParamException` -> WARN without full stack; `SysException`/unknown -> ERROR with full stack | `log.error("Error: " + e.getMessage())` | `log.error("Error: {}", id, e)` |
| L06 | No sensitive data in logs (passwords, tokens, ID numbers). Mask: `phone: 138****1234` | — | — |
| L07 | App logs >= 15 days. Error logs >= 30 days | — | — |
| L08 | Log entry/exit of important service methods | — | — |

## Control Flow Rules

| ID | Rule | Bad | Good |
|----|------|-----|------|
| C01 | Every `switch` must have `default`. Every `case` ends with `break`/`return` or fall-through comment. Handle `null` on `String` switch | — | — |
| C02 | Always use braces `{}` even for single-line blocks | `if (cond) doSomething();` | `if (cond) { doSomething(); }` |
| C03 | No complex boolean in `if`. Extract to named variable | — | `boolean eligible = active && age >= 18; if (eligible) { ... }` |
| C04 | Prefer positive conditions. No double negation | `if (!isNotValid)` | `if (isValid)` |
| C05 | Ternary only for simple conditions. No nesting | — | — |
| C06 | No `else` after `if` that returns | `if (c) { return a; } else { return b; }` | `if (c) { return a; } return b;` |
| C07 | Max 3 nesting levels. Use guard clauses or extract methods | — | — |
| C08 | Declare loop variables in for statement | — | `for (int i = 0; ...)` |
| C09 | No modifying loop variable inside for body | — | — |
| C10 | Enhanced for when index not needed. No foreach for modifying collection (use `Iterator`/`removeIf`) | — | — |

## Examples

```java
// BAD: Catching Exception broadly
catch (Exception e) { }
// BAD: String concatenation in log
log.info("User " + userId + " logged in");
// BAD: Swallowing business exception
catch (BizException e) { /* nothing */ }
// BAD: Logging only message, losing stack trace for system errors
catch (SysException e) { log.error("Error: " + e.getMessage()); }

// GOOD: Catch specific exception
catch (IOException e) { log.error("IO error: {}", filePath, e); }
// GOOD: Parameterized logging
log.info("User {} logged in", userId);
// GOOD: Business exception: WARN, no full stack
catch (BizException e) { log.warn("Business processing failed: {}", e.getMessage()); }
// GOOD: System exception: ERROR with full stack trace
catch (SysException e) { log.error("System exception: ", e); }
```