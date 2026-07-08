# Collection & Concurrency

## Collection Rules

| ID | Rule | Bad | Good |
|----|------|-----|------|
| CC01 | `ArrayList` for random access; `LinkedList` for frequent mid-list insert/delete | — | — |
| CC02 | Initialize `ArrayList` with known capacity | `new ArrayList<>()` | `new ArrayList<>(expectedSize)` |
| CC03 | `subList()` returns a view - changes affect original. Do not cast to `ArrayList` | — | — |
| CC04 | Map null rules: `HashMap`(key:OK value:OK), `ConcurrentHashMap`(key:NO value:NO), `Hashtable`(key:NO value:NO), `TreeMap`(key:NO value:OK) | — | — |
| CC05 | No add/remove in `foreach`. Use `Iterator` or `removeIf()` | `for (String item : list) { list.remove(item); }` | `list.removeIf(item -> condition);` |
| CC06 | Use `Map.entrySet()` not `keySet()` when both key+value needed | — | — |
| CC07 | No `<? extends T>` as return type for service interfaces | — | — |
| CC08 | `toArray()`: use typed version | `list.toArray()` | `list.toArray(new String[0])` |
| CC09 | `Arrays.asList()` returns fixed-size list - no add/remove. Use `new ArrayList<>(Arrays.asList(...))` for modifiable | — | — |
| CC10 | Unmodifiable: `Collections.unmodifiableList()` or `List.of()` (Java 9+) | — | — |

## Concurrency Rules

| ID | Rule | Bad | Good |
|----|------|-----|------|
| CC11 | Thread pools via `ThreadPoolExecutor` only. No `Executors` (OOM risk: unbounded queue/thread count) | `Executors.newFixedThreadPool(10)` | `new ThreadPoolExecutor(...)` |
| CC12 | `SimpleDateFormat` is NOT thread-safe. Use `DateTimeFormatter` or `ThreadLocal<SimpleDateFormat>` | static `SimpleDateFormat` | static `DateTimeFormatter` |
| CC13 | `ThreadLocal.remove()` after use, especially in thread pools | — | — |
| CC14 | Consistent lock ordering across threads to avoid deadlock | — | — |
| CC15 | Prefer `Lock` over `synchronized` for advanced features (tryLock, timed, interruptible). Use `synchronized` for simple cases | — | — |
| CC16 | `ConcurrentHashMap` not `Hashtable` (obsolete) | — | — |
| CC17 | `CountDownLatch`: call `countDown()` in `finally` block | — | — |
| CC18 | No `Thread.stop()` (deprecated/unsafe). Use `interrupt()` + `isInterrupted()` | — | — |
| CC19 | `volatile` for shared flags (no atomicity for compound ops). Atomic counters: `AtomicInteger`/`AtomicLong` | — | — |
| CC20 | Double-checked locking: instance must be `volatile` | — | — |
| CC21 | Concurrent updates: optimistic locking (version field) to avoid lost updates | — | — |
| CC22 | `ScheduledExecutorService` not `Timer` (Timer kills all tasks on one exception) | — | — |
| CC23 | `ForkJoinPool` for CPU-intensive divide-and-conquer | — | — |
| CC24 | `CompletableFuture` over raw `Future`. Always specify executor, avoid `commonPool()` | — | — |

## Examples

```java
// BAD: Executors for thread pools
ExecutorService pool = Executors.newFixedThreadPool(10);
// BAD: SimpleDateFormat as static field
private static final SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
// BAD: foreach with remove
for (String item : list) { list.remove(item); }

// GOOD: ThreadPoolExecutor directly
ExecutorService pool = new ThreadPoolExecutor(10, 10, 60L, TimeUnit.SECONDS,
    new LinkedBlockingQueue<>(1000),
    new ThreadFactoryBuilder().setNameFormat("pool-%d").build(),
    new ThreadPoolExecutor.CallerRunsPolicy());
// GOOD: DateTimeFormatter (thread-safe)
private static final DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy-MM-dd");
// GOOD: Iterator for removal
list.removeIf(item -> condition);
```