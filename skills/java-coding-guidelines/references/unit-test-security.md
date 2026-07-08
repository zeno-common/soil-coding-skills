# Unit Test & Security

## Unit Test Rules

| ID | Rule | Bad | Good |
|----|------|-----|------|
| UT01 | Core business logic must have tests. Target >= 70% coverage for new code | — | — |
| UT02 | Test class: `XxxTest`. Method: `test_methodName_scenario_expectedResult` | — | `test_getUserById_whenExists_returnsUser` |
| UT03 | Tests must be independent. Each test sets up and cleans up its own data | — | — |
| UT04 | Mock external deps (DB, RPC, HTTP) with Mockito. Do not mock class under test | — | — |
| UT05 | Meaningful assertions. No `assertTrue(true)`. Use `assertEquals(expected, actual, message)` | — | — |
| UT06 | Test boundaries: null, empty, max, min, negative, zero. Test exception paths | — | — |
| UT07 | No reliance on pre-existing DB data. Use `@BeforeEach`/`@BeforeAll`. Clean up after | — | — |
| UT08 | No `Thread.sleep()` in tests. Use Awaitility for async | — | — |
| UT09 | Integration tests: `@SpringBootTest` + separate profile. Not in default `mvn test` | — | — |

## Security Rules

| ID | Rule |
|----|------|
| SEC01 | SQL injection: parameterized queries only (`#{}` in MyBatis). No string concat. Whitelist `ORDER BY` columns |
| SEC02 | XSS: escape all user input in HTML. Use framework auto-escaping (e.g. Thymeleaf) |
| SEC03 | CSRF: tokens for state-changing requests (POST/PUT/DELETE) |
| SEC04 | Auth: all endpoints must authenticate. RBAC. Least privilege |
| SEC05 | Sensitive data: no logging passwords/tokens/IDs. Mask in responses: `138****1234`. Encrypt passwords with BCrypt/Argon2 (not MD5/SHA1). Encrypt config passwords |
| SEC06 | File upload: validate size/type/content. Do not trust client filename/content-type. Store outside web root. Use UUID filenames |
| SEC07 | HTTPS for all production APIs. Disable HTTP |
| SEC08 | Scan dependencies for vulnerabilities. Keep updated. Use OWASP Dependency-Check |
| SEC09 | Error responses: no stack traces/internal details. Generic message to client. Log details server-side |
| SEC10 | Rate limit public APIs. Exponential backoff for retries |
| SEC11 | Secure cookies: HTTP-only, SameSite, secure flag. Appropriate timeout. Invalidate on logout |
| SEC12 | Validate all input server-side. Bean Validation (JSR-380). Max length for strings |