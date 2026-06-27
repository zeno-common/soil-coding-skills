# OOP Conventions

1. Access static members via class name, not object ref. ❌ `new User().staticMethod()` ✅ `User.staticMethod()`
2. All override methods must have `@Override`. (Detects typos like `getObject` vs `get0bject`)
3. Declare variable with same type as return type. ✅ `HashMap<K,V> map = new HashMap<>()` ❌ `Map<K,V> map = new HashMap<>()` (unless abstraction needed)
4. No deprecated classes: `Hashtable`/`Vector`/`Stack` → `ConcurrentHashMap`/`ArrayList`/`Deque`.
5. Use `Objects.equals()` not `object.equals()` (NPE risk). ✅ `Objects.equals(a, b)` ❌ `a.equals(b)`
6. All POJOs must override `equals()` and `hashCode()`.
7. Use constant/determinate value for `equals()` LHS. ✅ `"test".equals(obj)` ❌ `obj.equals("test")`
8. Integer cache: -128~127 cached. Use `equals()` not `==`. `Integer(200) == Integer(200)` → false.
9. POJO: must have no-arg constructor + `toString()`. If inheriting, add `super.toString()`.
10. POJO: no default values on attributes. ❌ `private Integer count = 0;` ✅ `private Integer count;`
11. No business logic in constructors. Use `init()` method.
12. Do not modify `serialVersionUID` when adding fields. Only change for incompatible upgrades.
13. POJO attributes/RPC params/returns: wrapper types. Local variables: primitive types.
14. `final` on classes not designed for inheritance; on params/locals that shouldn't be reassigned.
15. No `+` string concat in loops. Use `StringBuilder`.
16. `BigDecimal` comparison: use `compareTo()` not `equals()`. `1.0.equals(1.00)` → false.
17. `subList()` returns a view — modifying it affects original. Don't cast to `ArrayList`.
18. `toArray()`: use typed version. ✅ `list.toArray(new String[0])` ❌ `list.toArray()`
19. Use `Map.entrySet()` not `keySet()` when both key+value needed.
20. Avoid `instanceof` + cast. Use polymorphism.
21. Call `ThreadLocal.remove()` after use to prevent memory leaks in thread pools.

## Anti-Patterns
```java
// ❌ NPE-prone equals
name.equals("test");
```

## Corrected
```java
// ✅ Null-safe equals
Objects.equals(name, "test");
// or
"test".equals(name);
```