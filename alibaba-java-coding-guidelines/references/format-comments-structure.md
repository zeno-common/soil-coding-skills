# Code Format, Comments, and Project Structure Conventions

## Code Format

### 1. Indentation

- Use 4 spaces for indentation. Do not use tabs.
- Configure IDE to convert tabs to spaces.

### 2. Line Length

- Single line should not exceed 120 characters. Break long lines appropriately.

### 3. Blank Lines

- One blank line between methods.
- One blank line between logical sections within a method.
- No blank lines at the start or end of a method body.

### 4. Braces

- Opening brace on the same line as the declaration (K&R style).
  ```java
  if (condition) {
      // ...
  }
  ```
- Always use braces even for single-line blocks.

### 5. Spaces

- Space after keywords: `if (`, `for (`, `while (`, `catch (`
- Space around binary operators: `a + b`, `a == b`
- No space before method name: `foo()`, not `foo ()`
- Space after `//` in comments: `// comment`, not `//comment`
- Comma/semicolon: space after, not before: `foo(a, b)`, not `foo(a ,b)`

### 6. Import Order

- Order: static imports, third-party, javax/java, project imports.
- No wildcard imports (`import xxx.*`).
- Remove unused imports.

### 7. Method Length

- A method should not exceed 80 lines. If it does, refactor into smaller methods.

### 8. Method Parameter Count

- A method should not have more than 5 parameters. If more are needed, use a parameter object.

### 9. Nested Ternary

- Do not nest ternary operators.

### 10. Magic Numbers

- Do not use magic numbers directly. Define them as named constants.
  - Counter-example: `if (status == 3)`
  - Positive example: `if (status == OrderStatus.COMPLETED)`

## Comments

### 1. Class Comments

- Every class must have a Javadoc comment describing its purpose, author, and date.
  ```java
  /**
   * User service implementation for handling user operations.
   *
   * @author zhangsan
   * @date 2024/01/01
   */
  ```

### 2. Method Comments

- All public methods must have Javadoc comments.
- Include: description, @param, @return, @exception (if applicable).
  ```java
  /**
   * Query user by ID.
   *
   * @param userId user ID
   * @return user object
   * @throws BusinessException if user not found
   */
  ```

### 3. Internal Comments

- Use single-line `//` or multi-line `/* */` for internal logic comments.
- Comments should explain "why", not "what" the code does.
- Keep comments up to date with code changes. Delete obsolete comments.

### 4. TODO Comments

- Use `// TODO: name description` format.
- Track and resolve TODOs promptly.

### 5. Commented-Out Code

- Do not commit commented-out code. Use version control instead.

### 6. Language

- Comments should be in the same language as the codebase (Chinese or English). Be consistent.

## Project Structure

### 1. Application Layering

```
+-----------------------------------+
|         Frontend / API            |  Open API / Web
+-----------------------------------+
|       Controller / Facade         |  Request routing, parameter validation
+-----------------------------------+
|          Service (Impl)           |  Business logic
+-----------------------------------+
|            Manager                |  General business encapsulation, combo service
+-----------------------------------+
|          DAO / Mapper             |  Data access
+-----------------------------------+
|            Database               |  MySQL / Redis
+-----------------------------------+
```

### 2. Layer Naming

| Layer | Suffix | Example |
|-------|--------|---------|
| Controller | `Controller` | `UserController` |
| Service Interface | `Service` | `UserService` |
| Service Implementation | `ServiceImpl` | `UserServiceImpl` |
| Manager | `Manager` | `UserManager` |
| DAO | `DAO` / `Mapper` | `UserDAO` / `UserMapper` |

### 3. Domain Model Naming

| Model | Suffix | Description |
|-------|--------|-------------|
| Data Object | `DO` | Maps to database table |
| Data Transfer Object | `DTO` | Transfers data between layers |
| View Object | `VO` | Presentation layer data |
| Business Object | `BO` | Business logic object |
| Query Object | `QO` | Query parameters |

### 4. Package Structure

```
com.company.project
+-- controller/       # REST API controllers
+-- service/          # Business service interfaces
|   +-- impl/         # Business service implementations
+-- manager/          # General business encapsulation
+-- dao/              # Data access objects
+-- model/
|   +-- entity/       # DO classes
|   +-- dto/          # DTO classes
|   +-- vo/           # VO classes
|   +-- qo/           # QO classes
+-- config/           # Configuration classes
+-- common/
|   +-- constant/     # Constants
|   +-- enums/        # Enumerations
|   +-- exception/    # Custom exceptions
|   +-- util/         # Utility classes
+-- interceptor/      # Interceptors / Filters
```

### 5. Dependency Direction

- Dependencies must flow downward: Controller -> Service -> Manager -> DAO.
- Never create circular dependencies between layers.
- Do not call DAO directly from Controller (must go through Service).

### 6. Exception Handling per Layer

| Layer | Exception Handling |
|-------|-------------------|
| Controller | Catch and convert to HTTP response |
| Service | Throw BusinessException for business errors |
| Manager | Wrap third-party exceptions into business exceptions |
| DAO | Convert SQLException into DAOException |

### 7. Configuration Management

- Use configuration files (application.yml) for environment-specific values.
- Do not hardcode configuration values in code.
- Use Spring profiles for different environments (dev, test, prod).

## Anti-Patterns

```java
// WRONG: Magic number
if (status == 3) { ... }
```

## Corrected Patterns

```java
// CORRECT: Named constant
if (status == OrderStatus.COMPLETED) { ... }
```