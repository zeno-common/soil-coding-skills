# Exception, Logging & Control (COLA 5)

本文件合并了通用 Java 异常处理、日志、控制流规范，以及 COLA 5 分层架构下的异常处理规则。COLA 强调依赖倒置与领域驱动，异常设计需体现业务语义并与架构层级严格对应。

## Exception

### General Rules

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

### COLA 5 Layered Exception Handling

核心原则：**尽早抛出带有明确语义的异常；按需捕获、统一兜底、禁止吞掉异常。**

#### 1. 异常类型设计

以 `BaseException`（继承 `RuntimeException`）为基类，派生业务异常与系统异常，并结合 `ExceptionType` 枚举标识异常来源分类。

```java
// 异常来源分类
public enum ExceptionType {
  UNDEFINED,
  BIZ,    // 业务异常 (Application/Domain 层使用)
  SYS,    // 系统异常 (Infrastructure 层使用)
  PARAM   // 参数校验异常 (Adapter 层使用)
}

// 基础异常抽象类 (定义通用属性：code, message)
public abstract class BaseException extends RuntimeException {
  private final String code;
  public ExceptionType type() { return ExceptionType.UNDEFINED; }
}

public class BizException   extends BaseException { public ExceptionType type() { return ExceptionType.BIZ; } }
public class SysException   extends BaseException { public ExceptionType type() { return ExceptionType.SYS; } }
public class ParamException extends BaseException { public ExceptionType type() { return ExceptionType.PARAM; } }
```

错误码 `code` 作为枚举按领域划分独立管理，建议分为两部分：**`BizCode`（业务级）+ 错误编码**。格式建议 `[业务]-[编码]`，例如 `UC-ACCOUNT-EXISTED`。**领域错误码**在 Domain 层定义（表达领域规则），**系统错误码**在 Infrastructure 层或基础模块定义。

#### 2. 抛出异常的规则（按层级）

- **Adapter 层**：入参基本校验（非空、格式）失败抛出 `ParamException`；不处理业务逻辑，不抛出底层技术异常（如 `SQLException`）。
- **App 层**：不抛出技术异常；前置条件不满足（如步骤前置状态不满足）抛出 `BizException`；调用 Domain/Infrastructure 时通常**不捕获不抛出**让其冒泡，必要时包装为更高级别业务异常重新抛出。
- **Domain 层**：违反领域不变量必须抛出 `BizException`（如 `if (balance < amount) throw new BizException("BIZ-ACCT-001", "余额不足");`）；绝不抛出 `SQLException`、`NullPointerException` 等技术异常；常见预期检查可返回 `boolean`/`Optional`，阻断流程的错误才抛异常。
- **Infrastructure 层**：必须捕获底层技术异常（`SQLException`、`RedisConnectionException`、`HttpClientException` 等），包装转换为 `SysException` 抛出（如 `catch (SQLException e) { throw new SysException("SYS-DB-001", "数据库访问失败", e); }`）；外部接口返回的业务错误转换为当前领域 `BizException`。

#### 3. 捕获异常的规则（按层级）

- **Infrastructure 层**：**必须捕获**所有第三方/中间件技术异常，转换为 `SysException` 或特定领域 `BizException` 后向上抛出，不泄露技术细节到上层。
- **Domain 层**：**通常不捕获**，让业务异常自然冒泡到 App 层。例外：领域内部需同时执行 A、B 且 B 失败需回滚 A 时，捕获 B 异常执行回滚后重新抛出。
- **App 层**：事务控制点（`@Transactional` 默认仅对 `RuntimeException` 回滚，因 `BaseException` 继承 `RuntimeException`，无需为事务 `catch`）；必要时 `catch` 并重新 `throw` 做异常翻译（粗粒度化）；严禁 `catch (Exception e) {}`。
- **Adapter 层 & 全局兜底**：Adapter 层不写 `try-catch` 处理业务/系统异常；必须使用全局异常处理器（如 `@RestControllerAdvice`）统一捕获转换。

**全局异常处理器示例：**

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    // 处理参数校验异常 (ParamException — Adapter 层手工校验抛出)
    @ExceptionHandler(ParamException.class)
    public ResponseEntity<RestExceptionResponse> handleParam(ParamException e) {
        log.warn("参数校验失败: {}", e.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(RestExceptionResponse.createFrom(e));
    }

    // 处理 @Valid / @Validated 校验失败 (MethodArgumentNotValidException)
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<RestExceptionResponse> handleValidation(MethodArgumentNotValidException e) {
        log.warn("参数校验失败: {}", e.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(RestExceptionResponse.createFrom(e));
    }

    // 处理 Web 业务异常 (带自定义 HTTP 状态码，如数据冲突返回 409)
    @ExceptionHandler(WebBizException.class)
    public ResponseEntity<RestExceptionResponse> handleWebBiz(WebBizException e) {
        log.warn("Web 业务异常: {}", e.getMessage());
        return ResponseEntity.status(e.status())
                .body(RestExceptionResponse.createFrom(e));
    }

    // 处理通用业务异常 (BizException — App/Domain 层抛出)
    @ExceptionHandler(BizException.class)
    public ResponseEntity<RestExceptionResponse> handleBiz(BizException e) {
        log.warn("业务处理失败: {}", e.getMessage());
        return ResponseEntity.status(HttpStatus.OK)
                .body(RestExceptionResponse.createFrom(e));
    }

    // 处理系统异常 (SysException — Infrastructure 层抛出)
    @ExceptionHandler(SysException.class)
    public ResponseEntity<RestExceptionResponse> handleSys(SysException e) {
        log.error("系统异常: ", e);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(RestExceptionResponse.createFrom(e));
    }

    // 兜底处理 BaseException 自定义异常 (未被上面匹配到的子类)
    @ExceptionHandler(BaseException.class)
    public ResponseEntity<RestExceptionResponse> handleBase(BaseException e) {
        log.error("未分类异常: ", e);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(RestExceptionResponse.createFrom(e));
    }

    // 终极兜底 (处理所有未预料到的异常，如 NPE)
    @ExceptionHandler(Throwable.class)
    public ResponseEntity<RestExceptionResponse> handleThrowable(Throwable throwable) {
        log.error("未知系统异常: ", throwable);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(RestExceptionResponse.createFrom(throwable));
    }
}
```

> **说明**：`WebBizException` 是 `BizException` 的子类，用于需要携带特定 HTTP 状态码的 Web 层业务异常（如资源冲突返回 409、未授权返回 403）。`RestExceptionResponse.createFrom(...)` 是统一响应体工厂方法，根据异常类型提取 `code`、`message` 等字段。

#### 4. 分层异常处理矩阵

| 层级 | 抛出什么异常？ | 捕获处理规则？ | 典型场景 |
| :--- | :--- | :--- | :--- |
| **Adapter** | `ParamException` | 不捕获业务/系统异常，交由全局处理器兜底。 | 入参非空、格式校验失败。 |
| **App** | `BizException` | 通常不捕获，让其冒泡触发事务回滚；必要时做异常翻译。 | 编排流程时前置条件不满足。 |
| **Domain** | `BizException` | 不捕获，直接抛出。绝不抛出技术异常。 | 余额不足、状态机流转非法。 |
| **Infrastructure** | `SysException` / `BizException` | **必须捕获**技术异常，包装为 `SysException` 或 `BizException`。 | 数据库连接超时转为 `SysException`。 |
| **Global Handler** | N/A | **统一捕获**所有异常，转换为标准 API 响应格式。 | 统一封装错误码和提示信息给前端。 |

#### 5. 最佳实践建议

1. **防腐败层（ACL）的异常转换**：在 App 层或 Infrastructure 层调用外部服务时，外部服务的异常体系可能会污染我们的系统。必须在外部调用的边界处（通常在 Infrastructure 的实现类中）`catch` 外部异常，转换为我们内部的 `SysException` 或 `BizException`。
2. **事务回滚**：确保自定义异常继承自 `RuntimeException`，否则 Spring 的 `@Transactional` 默认不会回滚。

## Logging

11. SLF4J + Logback/Log4j2. No `System.out.println()`. No direct Log4j/Commons Logging.
12. Log levels: ERROR (immediate attention) > WARN (potential issue) > INFO (business milestone) > DEBUG (dev only).
13. Parameterized logging with `{}`. ❌ `log.info("User " + id)` ✅ `log.info("User {}", id)`
14. Guard debug logging: `if (log.isDebugEnabled()) { log.debug("Detail: {}", expensive()); }`
15. Always log the exception in catch blocks (never swallow). **Log level & stack trace follow exception type**: `BizException`/`ParamException` → `WARN` without full stack trace (业务预期内错误); `SysException`/unknown `Exception` → `ERROR` with full stack trace. ❌ `log.error("Error: " + e.getMessage())` ✅ `log.error("Error: {}", id, e)`
16. No sensitive data in logs (passwords, tokens, ID numbers). Mask: `phone: 138****1234`.
17. App logs ≥ 15 days. Error logs ≥ 30 days.
18. Log entry/exit of important service methods.

## Control

19. Every `switch` must have `default`. Every `case` ends with `break`/`return` or fall-through comment. Handle `null` on `String` switch.
20. Always use braces `{}` even for single-line blocks. ❌ `if (cond) doSomething();` ✅ `if (cond) { doSomething(); }`
21. No complex boolean in `if`. Extract to named variable. ✅ `boolean eligible = active && age >= 18; if (eligible) { ... }`
22. Prefer positive conditions. No double negation. ❌ `if (!isNotValid)` ✅ `if (isValid)`
23. Ternary only for simple conditions. No nesting.
24. No `else` after `if` that returns. ❌ `if (c) { return a; } else { return b; }` ✅ `if (c) { return a; } return b;`
25. Max 3 nesting levels. Use guard clauses or extract methods.
26. Declare loop variables in for statement. ✅ `for (int i = 0; ...)`
27. No modifying loop variable inside for body.
28. Enhanced for when index not needed. No foreach for modifying collection (use `Iterator`/`removeIf`).

## Anti-Patterns
```java
// ❌ Catching Exception broadly
catch (Exception e) { }
// ❌ String concatenation in log
log.info("User " + userId + " logged in");
// ❌ Swallowing business exception
catch (BizException e) { /* nothing */ }
// ❌ Logging only message, losing stack trace for system errors
catch (SysException e) { log.error("Error: " + e.getMessage()); }
```

## Corrected
```java
// ✅ Catch specific exception
catch (IOException e) { log.error("IO error: {}", filePath, e); }
// ✅ Parameterized logging
log.info("User {} logged in", userId);
// ✅ Business exception: WARN, no full stack
catch (BizException e) { log.warn("业务处理失败: {}", e.getMessage()); }
// ✅ System exception: ERROR with full stack trace
catch (SysException e) { log.error("系统异常: ", e); }
```
