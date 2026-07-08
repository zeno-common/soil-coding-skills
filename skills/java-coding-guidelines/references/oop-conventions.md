# OOP Conventions

## Rules

| ID | Rule | Bad | Good |
|----|------|-----|------|
| O01 | Access static members via class name, not object ref | `new User().staticMethod()` | `User.staticMethod()` |
| O02 | All override methods must have `@Override` (detects typos like `getObject` vs `get0bject`) | — | — |
| O03 | Declare variable with same type as return type (unless abstraction needed) | `Map<K,V> map = new HashMap<>()` | `HashMap<K,V> map = new HashMap<>()` |
| O04 | No deprecated classes: `Hashtable`/`Vector`/`Stack` -> `ConcurrentHashMap`/`ArrayList`/`Deque` | — | — |
| O05 | Use `Objects.equals()` not `object.equals()` (NPE risk) | `a.equals(b)` | `Objects.equals(a, b)` |
| O06 | All POJOs must override `equals()` and `hashCode()` | — | — |
| O07 | Use constant/determinate value for `equals()` LHS | `obj.equals("test")` | `"test".equals(obj)` |
| O08 | Integer cache: -128~127 cached. Use `equals()` not `==` | `Integer(200) == Integer(200)` | `Integer(200).equals(Integer(200))` |
| O09 | POJO: must have no-arg constructor + `toString()`. If inheriting, add `super.toString()` | — | — |
| O10 | POJO: no default values on attributes | `private Integer count = 0;` | `private Integer count;` |
| O11 | No business logic in constructors. Use `init()` method | — | — |
| O12 | Do not modify `serialVersionUID` when adding fields. Only change for incompatible upgrades | — | — |
| O13 | POJO attributes/RPC params/returns: wrapper types. Local variables: primitive types | — | — |
| O14 | `final` on classes not designed for inheritance; on params/locals that should not be reassigned | — | — |
| O15 | No `+` string concat in loops. Use `StringBuilder` | — | — |
| O16 | `BigDecimal` comparison: use `compareTo()` not `equals()` | `1.0.equals(1.00)` (false) | `1.0.compareTo(1.00) == 0` (true) |
| O17 | `subList()` returns a view - modifying it affects original. Do not cast to `ArrayList` | — | — |
| O18 | `toArray()`: use typed version | `list.toArray()` | `list.toArray(new String[0])` |
| O19 | Use `Map.entrySet()` not `keySet()` when both key+value needed | — | — |
| O20 | Avoid `instanceof` + cast. Use polymorphism | — | — |
| O21 | Call `ThreadLocal.remove()` after use to prevent memory leaks in thread pools | — | — |

## Examples

```java
// BAD: NPE-prone equals
name.equals("test");

// GOOD: Null-safe equals
Objects.equals(name, "test");
// or
"test".equals(name);
```