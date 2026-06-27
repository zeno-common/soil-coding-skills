# Collection & Concurrency

## Collection

1. `ArrayList` for random access; `LinkedList` for frequent mid-list insert/delete.
2. Initialize `ArrayList` with known capacity. ✅ `new ArrayList<>(expectedSize)`
3. `subList()` returns a view — changes affect original. Don't cast to `ArrayList`.
4. Map null rules: `HashMap` (key✅ value✅), `ConcurrentHashMap` (key❌ value❌), `Hashtable` (key❌ value❌), `TreeMap` (key❌ value✅).
5. No add/remove in `foreach`. Use `Iterator` or `removeIf()`. ❌ `for (String item : list) { list.remove(item); }` ✅ `list.removeIf(item -> condition);`
6. Use `Map.entrySet()` not `keySet()` when both key+value needed.
7. No `<? extends T>` as return type for service interfaces.
8. `toArray()`: use typed version. ✅ `list.toArray(new String[0])`
9. `Arrays.asList()` returns fixed-size list — no add/remove. Use `new ArrayList<>(Arrays.asList(...))` for modifiable.
10. Unmodifiable: `Collections.unmodifiableList()` or `List.of()` (Java 9+).

## Concurrency

11. Thread pools via `ThreadPoolExecutor` only. No `Executors` (OOM risk: unbounded queue/thread count).
12. `SimpleDateFormat` is NOT thread-safe. Use `DateTimeFormatter` or `ThreadLocal<SimpleDateFormat>`.
13. `ThreadLocal.remove()` after use, especially in thread pools.
14. Consistent lock ordering across threads to avoid deadlock.
15. Prefer `Lock` over `synchronized` for advanced features (tryLock, timed, interruptible). Use `synchronized` for simple cases.
16. `ConcurrentHashMap` not `Hashtable` (obsolete).
17. `CountDownLatch`: call `countDown()` in `finally` block.
18. No `Thread.stop()` (deprecated/unsafe). Use `interrupt()` + `isInterrupted()`.
19. `volatile` for shared flags (no atomicity for compound ops). Atomic counters: `AtomicInteger`/`AtomicLong`.
20. Double-checked locking: instance must be `volatile`.
21. Concurrent updates: optimistic locking (version field) to avoid lost updates.
22. `ScheduledExecutorService` not `Timer` (Timer kills all tasks on one exception).
23. `ForkJoinPool` for CPU-intensive divide-and-conquer.
24. `CompletableFuture` over raw `Future`. Always specify executor, avoid `commonPool()`.

## Anti-Patterns
```java
// ❌ Executors for thread pools
ExecutorService pool = Executors.newFixedThreadPool(10);
// ❌ SimpleDateFormat as static field
private static final SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
// ❌ foreach with remove
for (String item : list) { list.remove(item); }
```

## Corrected
```java
// ✅ ThreadPoolExecutor directly
ExecutorService pool = new ThreadPoolExecutor(10, 10, 60L, TimeUnit.SECONDS,
    new LinkedBlockingQueue<>(1000),
    new ThreadFactoryBuilder().setNameFormat("pool-%d").build(),
    new ThreadPoolExecutor.CallerRunsPolicy());
// ✅ DateTimeFormatter (thread-safe)
private static final DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy-MM-dd");
// ✅ Iterator for removal
list.removeIf(item -> condition);
```