# OOP Conventions

## 1. Accessing Static Members

- Access static variables or methods via the class name directly, not through an object reference.
  - Counter-example: `new User().staticMethod()`
  - Positive example: `User.staticMethod()`

## 2. @Override Annotation

- All overriding methods must have the `@Override` annotation.
  - Reason: `getObject()` vs `get0bject()` (letter O vs digit 0) — `@Override` can accurately determine if the override is successful.

## 3. Variable Casting

- Use the same type for variable declaration as the return type. Avoid using parent classes or interfaces.
  - Positive example: `HashMap<String, String> map = new HashMap<>()`
  - Counter-example: `Map<String, String> map = new HashMap<>()` (only acceptable if you need the abstraction)

## 4. Avoid Using Deprecated or Obsolete Classes

- e.g., `Hashtable`, `Vector`, `Stack` — use `ConcurrentHashMap`, `ArrayList`, `Deque` instead.

## 5. Equals Method

- Use `Objects.equals()` instead of `object.equals()` to avoid NPE.
  - Positive example: `Objects.equals(a, b)`
  - Counter-example: `a.equals(b)` (NPE if `a` is null)
- All POJO classes must override `equals()` and `hashCode()`.
- Use constant or determinate value for `equals()` comparison.
  - Positive example: `"test".equals(object)`
  - Counter-example: `object.equals("test")`

## 6. Integer Cache

- All wrapper classes for integers between -128 and 127 are cached. Use `equals()` for comparison, not `==`.
  ```java
  Integer a = 100;
  Integer b = 100;
  a == b; // true (cached)
  Integer c = 200;
  Integer d = 200;
  c == d; // false (not cached)
  ```

## 7. POJO Class Rules

- POJO class must have a default (no-argument) constructor.
- POJO class must write `toString()` method.
- When using IDE to generate `toString()`, if inheriting from another POJO, add `super.toString()`.
- Do not set default values for any attribute in POJO class definitions.
  - Counter-example: `private Integer count = 0;` (should be `private Integer count;`)

## 8. Constructor Rules

- No business logic in constructors. Put initialization logic in `init()` method.

## 9. serialVersionUID

- When adding new attributes to a serializable class, do not modify `serialVersionUID` to avoid deserialization failure.
- If completely incompatible upgrade is needed, modify `serialVersionUID`.

## 10. Primitive vs Wrapper Types

- All POJO class attributes must use wrapper types.
- RPC method parameters and return values must use wrapper types.
- All local variables use primitive types.
- Class member variables must use wrapper types. Method return values and parameters must use wrapper types.

## 11. Final Keyword

- Declare classes as `final` if they are not designed for inheritance.
- Use `final` for method parameters and local variables that should not be reassigned.

## 12. String Concatenation

- Avoid concatenating strings using `+` in loops. Use `StringBuilder` or `StringBuffer`.
  - Counter-example:
    ```java
    String str = "start";
    for (int i = 0; i < 10000; i++) {
        str = str + "hello";
    }
    ```

## 13. Object Comparison

- Use `BigDecimal` for monetary or precise decimal comparisons. Use `compareTo()` instead of `equals()`.
  - Reason: `new BigDecimal("1.0").equals(new BigDecimal("1.00"))` returns `false`.
  - Positive example: `new BigDecimal("1.0").compareTo(new BigDecimal("1.00")) == 0`

## 14. ArrayList SubList

- The `subList()` method returns a view of the original list. Modifying the subList affects the original list.
- Do not cast `subList()` return to `ArrayList`.

## 15. Collection to Array

- Use `toArray(T[] array)` with the correct type.
  - Positive example: `list.toArray(new String[0])`
  - Counter-example: `list.toArray()` (returns `Object[]`)

## 16. Map Entry

- Use `Map.entrySet()` instead of `Map.keySet()` when iterating over both keys and values.

## 17. Avoid instanceof + Cast

- Avoid using `instanceof` followed by casting. Use polymorphism instead.

## 18. ThreadLocal

- Call `remove()` on ThreadLocal after use to prevent memory leaks, especially in thread pools.

## Anti-Patterns

```java
// WRONG: NPE-prone equals
name.equals("test");
```

## Corrected Patterns

```java
// CORRECT: Null-safe equals
Objects.equals(name, "test");
// or
"test".equals(name);
```