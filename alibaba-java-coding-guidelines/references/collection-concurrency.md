# Collection and Concurrency Conventions

## Collection Rules

### 1. ArrayList vs LinkedList

- Use `ArrayList` for random access. Use `LinkedList` for frequent insertions/deletions in the middle.

### 2. Collection Initialization with Known Size

- When the size is known, initialize `ArrayList` with the specified capacity.
  - Positive example: `new ArrayList<>(expectedSize)`

### 3. SubList

- `subList()` returns a view — modifications to the subList affect the original list.
- Do not cast `subList()` return to `ArrayList`.

### 4. Map Key/Value Null Rules

| Collection | Key Null | Value Null |
|------------|----------|------------|
| HashMap | Allowed | Allowed |
| ConcurrentHashMap | Not Allowed | Not Allowed |
| Hashtable | Not Allowed | Not Allowed |
| TreeMap | Not Allowed | Allowed |

### 5. foreach and remove/add

- Do not add or remove elements in a `foreach` loop. Use `Iterator`.
  - Counter-example:
    ```java
    for (String item : list) {
        if (condition) list.remove(item);
    }
    ```
  - Positive example:
    ```java
    Iterator<String> iterator = list.iterator();
    while (iterator.hasNext()) {
        String item = iterator.next();
        if (condition) iterator.remove();
    }
    ```
- Or use Java 8+ `removeIf()`:
  ```java
  list.removeIf(item -> condition);
  ```

### 6. Map Entry Iteration

- Use `Map.entrySet()` instead of `Map.keySet()` when both keys and values are needed.

### 7. Generic Wildcards

- Do not use generic wildcards `<? extends T>` as return types for service interfaces.

### 8. toArray

- Use `toArray(T[] array)` with correct type parameter.
  - Positive example: `list.toArray(new String[0])`

### 9. asList

- `Arrays.asList()` returns a fixed-size list. Do not use add/remove/modify methods on it.
- Use `new ArrayList<>(Arrays.asList(...))` for a modifiable list.

### 10. Collection to Unmodifiable

- Use `Collections.unmodifiableList()` or Java 9+ `List.of()` for unmodifiable collections.

## Concurrency Rules

### 1. Thread Pool Creation

- Thread resources must be provided through thread pools. Do not explicitly create threads in applications.
- Thread pools must NOT be created using `Executors`. Use `ThreadPoolExecutor` directly.
  - Reason: `Executors` methods may cause OOM:
    - `newFixedThreadPool` / `newSingleThreadExecutor`: unbounded queue → OOM
    - `newCachedThreadPool`: unbounded thread count → OOM

### 2. SimpleDateFormat Thread Safety

- `SimpleDateFormat` is NOT thread-safe. Do not define it as `static`.
- Use `DateTimeFormatter` (Java 8+) or `ThreadLocal<SimpleDateFormat>`.

### 3. ThreadLocal Cleanup

- Call `remove()` on ThreadLocal after use, especially in thread pools, to prevent memory leaks.

### 4. Lock Ordering

- When multiple locks are needed, keep the lock ordering consistent across all threads to avoid deadlock.

### 5. Synchronized vs Lock

- Prefer `java.util.concurrent.locks.Lock` over `synchronized` for advanced features (tryLock, timed lock, interruptible lock).
- Use `synchronized` for simple cases.

### 6. ConcurrentHashMap

- Use `ConcurrentHashMap` for concurrent map operations.
- Do not use `Hashtable` — it is obsolete.

### 7. CountDownLatch

- Use `CountDownLatch` for waiting on multiple threads to complete.
- Ensure `countDown()` is called in a `finally` block.

### 8. Avoid Thread.stop()

- Never use `Thread.stop()` — it is deprecated and unsafe.
- Use interruption: `Thread.interrupt()` + check `isInterrupted()`.

### 9. Volatile

- Use `volatile` for flags shared between threads, but note it does not provide atomicity for compound operations.
- For atomic counters, use `AtomicInteger` / `AtomicLong`.

### 10. Double-Checked Locking

- When using double-checked locking, the instance variable must be `volatile`.

### 11. Optimistic Locking for Concurrent Updates

- When multiple threads update the same record, use optimistic locking (version field) to avoid lost updates.
- Alternatives: application-level lock, cache-level lock, or database optimistic lock.

### 12. Timer vs ScheduledExecutorService

- Use `ScheduledExecutorService` instead of `Timer`.
- Reason: `Timer` does not handle exceptions — if one `TimerTask` throws, all other tasks are terminated.

### 13. ForkJoinPool

- Use `ForkJoinPool` for CPU-intensive parallel tasks with divide-and-conquer pattern.

### 14. CompletableFuture

- Prefer `CompletableFuture` over raw `Future` for composing async operations.
- Always specify an executor instead of using the common `ForkJoinPool.commonPool()`.

## Anti-Patterns

```java
// WRONG: Executors for thread pools
ExecutorService pool = Executors.newFixedThreadPool(10);

// WRONG: SimpleDateFormat as static field
private static final SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");

// WRONG: foreach with remove
for (String item : list) {
    list.remove(item);
}
```

## Corrected Patterns

```java
// CORRECT: ThreadPoolExecutor directly
ExecutorService pool = new ThreadPoolExecutor(
    10, 10, 60L, TimeUnit.SECONDS,
    new LinkedBlockingQueue<>(1000),
    new ThreadFactoryBuilder().setNameFormat("pool-%d").build(),
    new ThreadPoolExecutor.CallerRunsPolicy()
);

// CORRECT: DateTimeFormatter (thread-safe)
private static final DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy-MM-dd");

// CORRECT: Iterator for removal
list.removeIf(item -> condition);
```