---
name: "alibaba-java-coding-guidelines"
description: "Enforces Alibaba Java Coding Guidelines for code review, generation, and refactoring. Invoke when writing Java code, reviewing Java PRs, fixing Java style issues, or when user mentions Alibaba coding standards, Java conventions, or Chinese Java development norms."
---

# Alibaba Java Coding Guidelines

This skill encodes the core rules from the Alibaba Java Coding Guidelines (v1.7.1+, Huangshan Edition). Apply when writing, reviewing, or refactoring Java code.

| Section | Reference File | When to Read |
|---------|---------------|-------------|
| Naming Conventions | `references/naming-conventions.md` | When naming classes, methods, variables, packages, constants |
| OOP Conventions | `references/oop-conventions.md` | When writing POJOs, using equals/hashCode, inheritance, casting |
| Collection & Concurrency | `references/collection-concurrency.md` | When using collections, thread pools, locks, concurrent utilities |
| Exception, Logging & Control | `references/exception-logging-control.md` | When handling exceptions, writing log statements, control flow |
| Format, Comments & Structure | `references/format-comments-structure.md` | When formatting code, writing comments, organizing project structure |
| Unit Test & Security | `references/unit-test-security.md` | When writing tests, handling security concerns |

## How to Apply

### When Writing New Java Code

1. Read the relevant reference file(s) based on what you are writing
2. Follow naming conventions for all identifiers
3. Use the correct project structure and layering pattern
4. Apply OOP rules for POJOs, service classes, and data models
5. Use proper exception handling and logging from the start
6. Write unit tests following the test conventions

### When Reviewing Java Code

1. Read the corresponding reference file for each code area
2. Verify each rule against the code
3. Categorize violations as:
   - **Mandatory**: Must be fixed. These prevent bugs, security issues, or serious maintainability problems.
   - **Recommended**: Should be fixed. These improve code quality but are not critical.
   - **Reference**: Nice to have. These are suggestions for better code style.

### When Refactoring Java Code

1. Prioritize fixing Mandatory violations first
2. Apply naming convention fixes across the entire codebase consistently
3. Refactor thread-unsafe patterns (SimpleDateFormat, improper thread pools, missing ThreadLocal cleanup)
4. Add proper exception handling and logging
