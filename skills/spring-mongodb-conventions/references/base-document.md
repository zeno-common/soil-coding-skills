# Base Document Class

## 1. Overview

- All Document classes must extend a common `BaseDoc` abstract class that encapsulates ID generation and auditing. Do not duplicate these fields in each entity.
- `BaseDoc` consolidates cross-cutting concerns that every document shares, ensuring consistency and reducing boilerplate.
- Document class names use `Doc` suffix (e.g., `UserDoc`, `OrderDoc`). See `references/document-design.md` for naming rules.
- `BaseDoc` only includes universally required fields: `id` and auditing fields. `version` (optimistic locking) and `deleted` (logical deletion) are NOT included — they are optional concerns that subclasses add as needed.

## 2. BaseDoc Design

```java
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public abstract class BaseDoc {

    @Id
    private Long id;

    @CreatedDate
    @Field("createdAt")
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Field("updatedAt")
    private LocalDateTime updatedAt;

    @CreatedBy
    @Field("createdBy")
    private String createdBy;

    @LastModifiedBy
    @Field("updatedBy")
    private String updatedBy;

    @PrePersist
    public void prePersist() {
        if (this.id == null) {
            this.id = SpringContextHolder.getBean(SnowflakeIdGenerator.class).nextId();
        }
    }
}
```

## 3. Field Design Decisions

| Field | Type | Annotation | Purpose |
|-------|------|-----------|---------|
| `id` | `Long` | `@Id`  | Snowflake ID as int64|
| `createdAt` | `LocalDateTime` | `@CreatedDate` + `@Field("createdAt")` | Auto-filled on insert by Spring Data auditing |
| `updatedAt` | `LocalDateTime` | `@LastModifiedDate` + `@Field("updatedAt")` | Auto-filled on insert and update by Spring Data auditing |
| `createdBy` | `String` | `@CreatedBy` + `@Field("createdBy")` | Auto-filled with current auditor on insert |
| `updatedBy` | `String` | `@LastModifiedBy` + `@Field("updatedBy")` | Auto-filled with current auditor on insert and update |

### Why `version` and `deleted` are NOT in BaseDoc

- **`version`** (optimistic locking): Not all documents face concurrent updates. For example, log documents are append-only and never updated. Forcing `@Version` on all documents adds unnecessary overhead and confusion.
- **`deleted`** (logical deletion): Not all documents require soft delete. For example, system config documents are never logically deleted. Forcing a `deleted` flag on all documents wastes storage and complicates queries.
- Subclasses add these fields when the business scenario requires them.

## 4. Optional Fields: version and deleted

### Adding `@Version` for Optimistic Locking

Add `@Version` only when the document may be concurrently updated by multiple threads or processes.

```java
@Document(collection = "orders")
public class OrderDoc extends BaseDoc {

    @Field("totalAmount")
    private BigDecimal totalAmount;

    @Version
    @Field("version")
    private Long version;
}
```

- Spring Data MongoDB automatically increments `version` on each update and throws `OptimisticLockingFailureException` on conflict.
- Handle `OptimisticLockingFailureException` with retry logic in the service layer.

### Adding `deleted` for Logical Deletion

Add `deleted` only when the document requires soft delete instead of physical removal.

```java
@Document(collection = "users")
public class UserDoc extends BaseDoc {

    @Field("name")
    private String name;

    @Field("email")
    private String email;

    @Field("deleted")
    private Boolean deleted = false;

    @PrePersist
    public void initDefaults() {
        super.prePersist();
        if (this.deleted == null) {
            this.deleted = false;
        }
    }
}
```

- All queries on soft-delete documents must include `deleted: false` filter by default.
- In Repository:
  ```java
  @Query("{ 'deleted': false }")
  List<UserDoc> findAllActive();
  ```
- In MongoTemplate:
  ```java
  query.addCriteria(Criteria.where("deleted").is(false));
  ```
- Consider a custom `SoftDeleteRepository` implementation that automatically appends `deleted: false` to all queries.

### Combining Both

```java
@Document(collection = "products")
public class ProductDoc extends BaseDoc {

    @Field("name")
    private String name;

    @Field("price")
    private BigDecimal price;

    @Field("deleted")
    private Boolean deleted = false;

    @Version
    @Field("version")
    private Long version;

    @PrePersist
    public void initDefaults() {
        super.prePersist();
        if (this.deleted == null) {
            this.deleted = false;
        }
    }
}
```

## 5. Snowflake ID Generation in @PrePersist

- Since `BaseDoc` is not a Spring-managed bean, dependency injection is not available in entity classes.
- Use one of the following approaches to obtain `SnowflakeIdGenerator`:

### Approach 1: SpringContextHolder (Recommended)

A utility class that holds `ApplicationContext` and provides `getBean()` static access.

```java
@Component
public class SpringContextHolder implements ApplicationContextAware {
    private static ApplicationContext context;

    @Override
    public void setApplicationContext(ApplicationContext ctx) {
        context = ctx;
    }

    public static <T> T getBean(Class<T> clazz) {
        return context.getBean(clazz);
    }
}
```

Usage in `BaseDoc`:
```java
@PrePersist
public void prePersist() {
    if (this.id == null) {
        this.id = SpringContextHolder.getBean(SnowflakeIdGenerator.class).nextId();
    }
}
```

### Approach 2: Static Field Injection

Set the generator reference via `@PostConstruct` in a configuration class.

```java
public abstract class BaseDoc {
    private static SnowflakeIdGenerator idGenerator;

    public static void setSnowflakeIdGenerator(SnowflakeIdGenerator generator) {
        idGenerator = generator;
    }

    @PrePersist
    public void prePersist() {
        if (this.id == null) {
            this.id = idGenerator.nextId();
        }
    }
}

@Configuration
public class SnowflakeConfig {
    private final SnowflakeIdGenerator generator;

    public SnowflakeConfig(SnowflakeIdGenerator generator) {
        this.generator = generator;
    }

    @PostConstruct
    public void init() {
        BaseDoc.setSnowflakeIdGenerator(generator);
    }

    @Bean
    public SnowflakeIdGenerator snowflakeIdGenerator(
            @Value("${snowflake.worker-id}") long workerId,
            @Value("${snowflake.datacenter-id}") long datacenterId) {
        return new SnowflakeIdGenerator(workerId, datacenterId);
    }
}
```

### What NOT to Do

- **Do not** pass `SnowflakeIdGenerator` via constructor in entity classes — Spring Data MongoDB requires a no-arg constructor.
- **Do not** use `@Autowired` in entity classes — entities are not Spring-managed beans.

## 6. Prerequisites Configuration

`BaseDoc` relies on the following Spring configurations. All must be present:

```java
@Configuration
@EnableMongoAuditing
public class MongoConfig {

    @Bean
    public MongoTransactionManager transactionManager(MongoDatabaseFactory dbFactory) {
        return new MongoTransactionManager(dbFactory);
    }
}

@Component
public class SpringSecurityAuditorAware implements AuditorAware<String> {
    @Override
    public Optional<String> getCurrentAuditor() {
        return Optional.of(
            SecurityContextHolder.getContext().getAuthentication().getName()
        );
    }
}
```

- `@EnableMongoAuditing`: Activates `@CreatedDate`, `@LastModifiedDate`, `@CreatedBy`, `@LastModifiedBy`.
- `AuditorAware<String>` bean: Provides the current user for `@CreatedBy` / `@LastModifiedBy`.
- `MongoTransactionManager`: Required if using `@Transactional` (optional if no multi-doc transactions).

## 7. Entity Class Example

```java
@Document(collection = "users")
@CompoundIndexes({
    @CompoundIndex(name = "idx_status_createdAt", def = "{'status': 1, 'createdAt': -1}")
})
public class UserDoc extends BaseDoc {

    @Field("name")
    private String name;

    @Field("email")
    private String email;

    @Field("status")
    private String status;

    @Field("deleted")
    private Boolean deleted = false;

    @PrePersist
    public void initDefaults() {
        super.prePersist();
        if (this.deleted == null) {
            this.deleted = false;
        }
    }
}
```

## 8. Rules for Extending BaseDoc

- Document class names must use `Doc` suffix (e.g., `UserDoc`, `OrderDoc`, `ProductDoc`).
- Never re-declare `id`, `createdAt`, `updatedAt`, `createdBy`, `updatedBy` in subclasses.
- Subclasses must use `@Document(collection = "...")` annotation explicitly with the collection name.
- Subclasses may override `@PrePersist` but must call `super.prePersist()` first.
  ```java
  @PrePersist
  public void initDefaults() {
      super.prePersist(); // MUST call super first — ensures ID generation
      // entity-specific defaults here
  }
  ```
- Do not add `@PreUpdate` in subclasses for audit fields — `@LastModifiedDate` / `@LastModifiedBy` are handled by Spring Data auditing automatically.
- Add `@Version` only when the document faces concurrent updates. Do not add it proactively.
- Add `deleted` only when the document requires soft delete. Do not add it proactively.

## Anti-Patterns

```java
// BAD: Duplicating auditing/ID fields in each entity instead of using BaseDoc
@Document(collection = "users")
public class UserDoc {
    @Id
    private Long id;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String createdBy;
    private String updatedBy;
    // ... business fields
}

// BAD: Document class without Doc suffix
@Document(collection = "users")
public class User extends BaseDoc { ... }

// BAD: Using Entity / Model suffix (JPA / ORM convention)
@Document(collection = "users")
public class UserEntity extends BaseDoc { ... }

// BAD: Using Document suffix (too verbose)
@Document(collection = "users")
public class UserDocument extends BaseDoc { ... }

// BAD: Overriding @PrePersist without calling super
@PrePersist
public void initDefaults() {
    // missing super.prePersist() — Snowflake ID not generated!
    this.someField = "default";
}

// BAD: Using @Autowired in entity class
@Autowired
private SnowflakeIdGenerator generator; // entities are not Spring beans!

// BAD: Re-declaring BaseDoc fields in subclass
public class UserDoc extends BaseDoc {
    private Long id; // already in BaseDoc!
    private LocalDateTime createdAt; // already in BaseDoc!
}

// BAD: Adding @Version on documents that are never updated (e.g., log documents)
@Document(collection = "access_logs")
public class AccessLogDoc extends BaseDoc {
    @Version
    private Long version; // logs are append-only, no concurrent updates
}

// BAD: Adding deleted on documents that are never soft-deleted
@Document(collection = "system_configs")
public class SystemConfigDoc extends BaseDoc {
    @Field("deleted")
    private Boolean deleted = false; // configs are never logically deleted
}
```

## Corrected Patterns

```java
// OK: Extend BaseDoc with Doc suffix — no field duplication
@Document(collection = "users")
public class UserDoc extends BaseDoc {
    @Field("name")
    private String name;

    @Field("email")
    private String email;

    @Field("deleted")
    private Boolean deleted = false;
}

// OK: Order document with @Version (concurrent updates expected)
@Document(collection = "orders")
public class OrderDoc extends BaseDoc {
    @Field("totalAmount")
    private BigDecimal totalAmount;

    @Version
    @Field("version")
    private Long version;
}

// OK: Log document — no @Version, no deleted (append-only)
@Document(collection = "access_logs")
public class AccessLogDoc extends BaseDoc {
    @Field("userId")
    private Long userId;

    @Field("action")
    private String action;
}

// OK: Override @PrePersist with super call
@PrePersist
public void initDefaults() {
    super.prePersist(); // ensures ID generation
    if (this.deleted == null) {
        this.deleted = false;
    }
}
```