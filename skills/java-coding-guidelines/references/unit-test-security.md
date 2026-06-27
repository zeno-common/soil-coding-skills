# Unit Test & Security

## Unit Test

1. Core business logic must have tests. Target ≥ 70% coverage for new code.
2. Test class: `XxxTest`. Method: `test_methodName_scenario_expectedResult`. ✅ `test_getUserById_whenExists_returnsUser`
3. Tests must be independent. Each test sets up and cleans up its own data.
4. Mock external deps (DB, RPC, HTTP) with Mockito. Don't mock class under test.
5. Meaningful assertions. No `assertTrue(true)`. Use `assertEquals(expected, actual, message)`.
6. Test boundaries: null, empty, max, min, negative, zero. Test exception paths.
7. No reliance on pre-existing DB data. Use `@BeforeEach`/`@BeforeAll`. Clean up after.
8. No `Thread.sleep()` in tests. Use Awaitility for async.
9. Integration tests: `@SpringBootTest` + separate profile. Not in default `mvn test`.

## Security

10. SQL injection: parameterized queries only (`#{}` in MyBatis). No string concat. Whitelist `ORDER BY` columns.
11. XSS: escape all user input in HTML. Use framework auto-escaping (e.g., Thymeleaf).
12. CSRF: tokens for state-changing requests (POST/PUT/DELETE).
13. Auth: all endpoints must authenticate. RBAC. Least privilege.
14. Sensitive data: no logging passwords/tokens/IDs. Mask in responses: `138****1234`. Encrypt passwords with BCrypt/Argon2 (not MD5/SHA1). Encrypt config passwords.
15. File upload: validate size/type/content. Don't trust client filename/content-type. Store outside web root. Use UUID filenames.
16. HTTPS for all production APIs. Disable HTTP.
17. Scan dependencies for vulnerabilities. Keep updated. Use OWASP Dependency-Check.
18. Error responses: no stack traces/internal details. Generic message to client. Log details server-side.
19. Rate limit public APIs. Exponential backoff for retries.
20. Secure cookies: HTTP-only, SameSite, secure flag. Appropriate timeout. Invalidate on logout.
21. Validate all input server-side. Bean Validation (JSR-380). Max length for strings.