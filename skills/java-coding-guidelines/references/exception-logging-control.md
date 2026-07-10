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

### 7. Exception Code Definition Rules (按层枚举 + 工厂模式)

异常编码（error code）按 COLA 各架构分层**分别定义独立枚举**，每个枚举值携带 `code` + `message`，并作为**所在层异常类型的构建工厂**：通过工厂方法统一产出 `ParamException` / `BizException` / `SysException`，调用方只抛枚举、不 `new` 异常、不硬编码字符串。

**定义规则：**

1. **分层独立枚举**：每个 COLA 分层维护自己的异常编码枚举，归属清晰、互不混杂。
2. **集中维护 code/message**：枚举值集中定义编码与提示文案，业务代码中禁止散落字符串字面量。
3. **枚举即工厂**：每个枚举提供 `exception()`（无 cause）与 `exception(Throwable cause)`（带原始异常）工厂方法，构建对应层的异常类型。
4. **编码命名格式**：`[BIZ]-[NAME]`，例如 `PARAM-MISSING`、`ORDER-TIME-OUT`、`ACCT-MISSING`、`INFRA-DB-FAILED`。**领域错误码**在 Domain 层枚举定义（表达领域规则），**系统错误码**在 Infrastructure 层枚举定义。
5. **异常类型共享、编码前缀区分来源**：`BizException` 可由 App 层与 Domain 层枚举共同产出（二者均属业务语义），但编码前缀区分来源；`ParamException` 仅由 Adapter 层枚举产出，`SysException` 仅由 Infrastructure 层枚举产出。

**基础异常与异常类型（复用 §1 定义）：**

```java
public abstract class BaseException extends RuntimeException {
    private final String code;
    protected BaseException(String code, Throwable throwable, String msgPattern, Object... msgArgs) {
        super(MessageFormat.format(msgPattern, msgArgs), throwable);
        this.code = code;
    }
    public String getCode() { return code; }
}

public class ParamException extends BaseException {
    public ParamException(String code, Throwable throwable, String msgPattern, Object... msgArgs) {
        super(code,throwable, msgPattern, msgArgs);
    }
    public ExceptionType type() { return ExceptionType.PARAM; }
}
public class BizException extends BaseException {
    public BizException(String code, Throwable throwable, String msgPattern, Object... msgArgs) {
        super(code,throwable, msgPattern, msgArgs);
    }
    public ExceptionType type() { return ExceptionType.BIZ; }
}
public class SysException extends BaseException {
    public SysException(String code, Throwable throwable, String msgPattern, Object... msgArgs) {
        super(code,throwable, msgPattern, msgArgs);
    }
    public ExceptionType type() { return ExceptionType.SYS; }
}
```

**各层异常编码枚举（每个枚举都是对应层异常类型的工厂）：**

```java
// Adapter 层：产出 ParamException
public enum Adapter[Biz]ErrorCode {
    INVALID_PARAM("[BIZ]-PARAM-IL", "{0}参数格式不合法"),
    MISSING_REQUIRED("[BIZ]-PARAM-MISS", "{0}缺少必填参数");

    private final String code;
    private final String message;
    AdapterErrorCode(String code, String message) { this.code = code; this.message = message; }

    public ParamException exception(Object... msgArgs) { return exception(null, msgArgs); }
    public ParamException exception(Throwable cause, Object... msgArgs) { return new ParamException(code, cause, message, msgArgs); }
}

// App 层：产出 BizException 应用业务异常（用例编排、前置条件不满足）
public enum AppAdapter[Biz]ErrorCode {
    PRECONDITION_NOT_MET("[BIZ]-ORDER-PC", "订单前置条件不满足"),
    STEP_CONFLICT("[BIZ]-ORDER-SC", "编排步骤冲突");  

    private final String code;
    private final String message;
    AppErrorCode(String code, String message) { this.code = code; this.message = message; }

    public WebBizException exception(Object... msgArgs) { return exception(null, msgArgs); }
    public WebBizException exception(Throwable cause, Object... msgArgs) { return new WebBizException(HttpStatus.CONFLICT, code, cause, message,msgArgs); }
}

// Domain 层：产出 BizException 领域异常（领域不变量、领域规则）
public enum [Domain]ErrorCode {
    INSUFFICIENT_BALANCE("[Domain]-ACCT-IB", "余额不足"),
    ILLEGAL_STATE_TRANSITION("[Domain]-ACCT-IST", "非法状态流转");

    private final String code;
    private final String message;
    DomainErrorCode(String code, String message) { this.code = code; this.message = message; }

    public BizException exception(Object... msgArgs) { return exception(null, msgArgs); }
    public BizException exception(Throwable cause, Object... msgArgs) { return new BizException(code, cause, message,msgArgs); }
}

// Infrastructure 层(Optional,非必要不使用)：产出 SysException（技术异常包装）
public enum InfrastructureErrorCode {
    DB_ACCESS_FAILED("[Infrastructure]-DB-FA", "数据库访问失败"),
    REDIS_CONNECTION_FAILED("[Infrastructure]-REDIS-CON", "Redis 连接失败");

    private final String code;
    private final String message;
    InfrastructureErrorCode(String code, String message) { this.code = code; this.message = message; }

    public SysException exception(Object... msgArgs) { return exception(null, msgArgs); }
    public SysException exception(Throwable cause, Object... msgArgs) { return new SysException(code, cause, message,msgArgs); }
}
```

**调用示例（各层只抛枚举，由枚举工厂构建异常）：**

```java
// Adapter 层
if (request.getName() == null) {
    throw AdapterErrorCode.MISSING_REQUIRED.exception("name");
}

// App 层
try{
    
}catch(BizException be){
    throw WebBizException.of(HttpStatus.BAD_REQUEST,be);
}

// Domain 层
if (balance < amount) {
    throw DomainErrorCode.INSUFFICIENT_BALANCE.exception("balance");
}

// Infrastructure 层 (Optional,菲必要不使用)：捕获底层技术异常，包装为 SysException
try {
    return jdbcTemplate.queryForObject(sql, mapper, id);
} catch (SQLException e) {
    throw InfrastructureErrorCode.DB_ACCESS_FAILED.exception(e, id);
}
```

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


### Examples

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
