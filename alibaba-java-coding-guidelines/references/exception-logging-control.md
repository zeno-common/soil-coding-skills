# Exception, Logging, and Control Statement Conventions

## Exception Rules

### 1. Catch Specific Exceptions

- Do not catch `Exception` / `Throwable` / `RuntimeException` directly. Catch the most specific exception type.
  - Counter-example: `catch (Exception e) { ... }`
  - Positive example: `catch (IOException e) { ... }`

### 2. No Empty Catch Blocks

- Never leave a catch block empty. At minimum, log the exception.
  - Counter-example: `catch (Exception e) { }`
  - Positive example: `catch (Exception e) { log.error("Failed to process order: {}", orderId, e); }`

### 3. No Business Logic in Catch

- Do not place business logic in catch blocks. Catch blocks should handle exceptions only (log, wrap, rethrow).

### 4. Finally Block

- Do not use `return` in a finally block. It will override the return value or exception from try/catch.

### 5. Try-with-resources

- Use try-with-resources (Java 7+) for `AutoCloseable` resources instead of try-finally.
  - Positive example:
    ```java
    try (InputStream is = new FileInputStream("file.txt")) {
        // use resource
    }
    ```

### 6. Exception Wrapping

- When rethrowing, preserve the original cause using the cause constructor.
  - Positive example: `throw new BusinessException("msg", e)`
  - Counter-example: `throw new BusinessException("msg")` (lost stack trace)

### 7. NPE Prevention

- Use `Objects.requireNonNull()` or `Optional` to prevent NPE.
- Always check null for method parameters when the caller might pass null.

### 8. RuntimeException vs Checked Exception

- Use `RuntimeException` (or its subclasses) for business exceptions.
- Use checked exceptions only for recoverable conditions that callers must handle.

### 9. Return Code vs Exception

- Do not use return codes to indicate errors. Use exceptions.
- Do not use exceptions for normal flow control.

### 10. Method Throws Declaration

- Declare checked exceptions in method signature. Do not declare RuntimeException in throws clause.

## Logging Rules

### 1. Logging Framework

- Use SLF4J + Logback (or Log4j2). Do not use `System.out.println()` or `System.err.println()`.
- Do not use Log4j or Commons Logging directly — use SLF4J facade.

### 2. Log Level Usage

| Level | Usage |
|-------|-------|
| ERROR | System error, needs immediate attention |
| WARN | Potential issues, not critical |
| INFO | Key business flow milestones |
| DEBUG | Debug information, disabled in production |

### 3. Parameterized Logging

- Use placeholder `{}` instead of string concatenation.
  - Positive example: `log.info("User {} logged in from {}", userId, ip)`
  - Counter-example: `log.info("User " + userId + " logged in from " + ip)`

### 4. Debug Logging Guard

- Guard debug/trace logging with level check to avoid unnecessary evaluation.
  - Positive example:
    ```java
    if (log.isDebugEnabled()) {
        log.debug("Detail: {}", expensiveOperation());
    }
    ```

### 5. Exception Logging

- Always log the full exception with stack trace.
  - Positive example: `log.error("Error processing order: {}", orderId, e)`
  - Counter-example: `log.error("Error: " + e.getMessage())` (lost stack trace)

### 6. Sensitive Data

- Do not log sensitive information: passwords, ID numbers, bank card numbers, tokens.
- Mask sensitive data in logs: `phone: 138****1234`

### 7. Log File Retention

- Keep application logs for at least 15 days.
- Keep error logs for at least 30 days.

### 8. Log in catch Block

- Always log in catch block. Do not swallow exceptions silently.

### 9. First/Last Log

- Log the entry and exit of important methods, especially service layer methods.

## Control Statement Rules

### 1. Switch Statement

- Every `switch` block must contain a `default` case.
- Every `case` must end with `break` / `return` / or a comment explaining fall-through.
- In a `switch` block on `String`, handle `null` case explicitly.

### 2. Braces for if/else/for/while/do

- Always use braces `{}` even for single-line blocks.
  - Counter-example: `if (condition) doSomething();`
  - Positive example: `if (condition) { doSomething(); }`

### 3. Avoid Complex Conditions

- Do not write complex boolean expressions in `if` conditions. Extract to well-named boolean variables.
  - Positive example:
    ```java
    boolean isEligible = user.isActive() && user.getAge() >= 18 && user.hasVerifiedEmail();
    if (isEligible) { ... }
    ```

### 4. Avoid Negation in Conditions

- Prefer positive conditions. Avoid double negation.
  - Counter-example: `if (!isNotValid)`
  - Positive example: `if (isValid)`

### 5. Ternary Operator

- Use ternary operator `? :` only for simple conditions. Do not nest ternary operators.

### 6. Avoid return in else

- If the `if` block returns, do not add an `else` block.
  - Counter-example:
    ```java
    if (condition) {
        return a;
    } else {
        return b;
    }
    ```
  - Positive example:
    ```java
    if (condition) {
        return a;
    }
    return b;
    ```

### 7. Avoid Excessive Nesting

- Maximum 3 levels of nesting. Use guard clauses or extract methods.

### 8. for Loop Variable Scope

- Declare loop variables inside the for statement.
  - Positive example: `for (int i = 0; i < n; i++)`

### 9. Avoid Modifying Loop Variable

- Do not modify the loop variable inside a for loop body.

### 10. Enhanced for (foreach)

- Use enhanced for loop when index is not needed.
- Do not use foreach for modifying the collection (use Iterator or `removeIf`).

## Anti-Patterns

```java
// WRONG: Catching Exception broadly
catch (Exception e) { }

// WRONG: String concatenation in log
log.info("User " + userId + " logged in");
```

## Corrected Patterns

```java
// CORRECT: Catch specific exception
catch (IOException e) {
    log.error("IO error reading file: {}", filePath, e);
}

// CORRECT: Parameterized logging
log.info("User {} logged in", userId);
```