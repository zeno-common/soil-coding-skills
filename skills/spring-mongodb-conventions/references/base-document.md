# Base Document Class

## 1. Overview

- All Document classes must extend a common `BaseMongoDoc<ID>` abstract class that encapsulates ID and auditing. Do not duplicate these fields in each entity.
- `BaseMongoDoc<ID>` uses a generic type parameter for the ID field — the concrete ID type is defined by each derived class (e.g., `UserDoc extends BaseMongoDoc<Long>`).
- `BaseMongoDoc` consolidates cross-cutting concerns that every document shares, ensuring consistency and reducing boilerplate.
- Document class names use `Doc` suffix (e.g., `UserDoc`, `OrderDoc`). See `references/document-design.md` for naming rules.
- `BaseMongoDoc` only includes universally required fields: `id` (generic type) and auditing fields. `version` (optimistic locking) and `deleted` (logical deletion) are NOT included — they are optional concerns that subclasses add as needed.
- ID generation is handled by `MongoDocIdCallback` (BeforeConvertCallback EntityCallback API), NOT by `@PrePersist`. See Section 5 for details.
- `AuditorAware` is provided by the project's dependency library. Do not implement it manually.

## 2. BaseMongoDoc Design

```java
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public abstract class BaseMongoDoc<ID> {

    @Id
    private ID id;

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
}
```

- `BaseMongoDoc<ID>` is a pure POJO — no lifecycle methods, no framework callbacks.
- The ID type is a generic parameter. Each derived class specifies the concrete type (e.g., `BaseMongoDoc<Long>` for distributed ID, `BaseMongoDoc<String>` for business key).
- ID generation is decoupled from the entity class via `MongoDocIdCallback` (see Section 5).
- **CAUTION**: When using `Long` as ID type, distributed IDs exceed JavaScript `Number.MAX_SAFE_INTEGER` (2^53-1). Use Jackson global Long-to-String serialization to prevent precision loss on JS clients. See `references/spring-data-rules.md` Section 9 for Jackson configuration.

### Why Generic ID Type

- **Flexibility**: Not all documents use `Long` ID. Some may use `String` business keys (e.g., `orderId` as `_id`).
- **Type safety**: `BaseMongoDoc<Long>` ensures `getId()` returns `Long`, `BaseMongoDoc<String>` returns `String` — no casting needed.
- **Repository compatibility**: `MongoRepository<UserDoc, Long>` and `MongoRepository<ConfigDoc, String>` both work correctly with their respective ID types.

## 3. Field Design Decisions

| Field | Type | Annotation | Purpose |
|-------|------|-----------|---------|
| `id` | `ID` (generic) | `@Id` | Primary key, concrete type defined by derived class |
| `createdAt` | `LocalDateTime` | `@CreatedDate` + `@Field("createdAt")` | Auto-filled on insert by Spring Data auditing |
| `updatedAt` | `LocalDateTime` | `@LastModifiedDate` + `@Field("updatedAt")` | Auto-filled on insert and update by Spring Data auditing |
| `createdBy` | `String` | `@CreatedBy` + `@Field("createdBy")` | Auto-filled with current auditor on insert |
| `updatedBy` | `String` | `@LastModifiedBy` + `@Field("updatedBy")` | Auto-filled with current auditor on insert and update |

### Why `version` and `deleted` are NOT in BaseMongoDoc

- **`version`** (optimistic locking): Not all documents face concurrent updates. For example, log documents are append-only and never updated. Forcing `@Version` on all documents adds unnecessary overhead and confusion.
- **`deleted`** (logical deletion): Not all documents require soft delete. For example, system config documents are never logically deleted. Forcing a `deleted` flag on all documents wastes storage and complicates queries.
- Subclasses add these fields when the business scenario requires them.

## 4. Optional Fields: version and deleted

### Adding `@Version` for Optimistic Locking

Add `@Version` only when the document may be concurrently updated by multiple threads or processes.

```java
@Document(collection = "orders")
public class OrderDoc extends BaseMongoDoc<Long> {

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
public class UserDoc extends BaseMongoDoc<Long> {

    @Field("name")
    private String name;

    @Field("email")
    private String email;

    @Field("deleted")
    private Boolean deleted = false;
}
```

- Use field default value `= false` for initialization. Do NOT use `@PrePersist` for setting defaults.
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
public class ProductDoc extends BaseMongoDoc<Long> {

    @Field("name")
    private String name;

    @Field("price")
    private BigDecimal price;

    @Field("deleted")
    private Boolean deleted = false;

    @Version
    @Field("version")
    private Long version;
}
```

### Using String ID Type

When a document uses a business key as `_id` instead of distributed ID:

```java
@Document(collection = "system_configs")
public class ConfigDoc extends BaseMongoDoc<String> {

    @Field("value")
    private String value;

    @Field("description")
    private String description;
}
```

- `ConfigDoc` uses `String` as ID type — no ID generation needed.
- `MongoDocIdCallback` only handles `BaseMongoDoc<Long>` and will not interfere with `BaseMongoDoc<String>`.

## 5. ID Generation via MongoDocIdCallback

### Why NOT @PrePersist

- `@PrePersist` / `@PostPersist` / `@PreUpdate` / `@PostUpdate` are **JPA annotations** (`javax.persistence`), NOT Spring Data MongoDB annotations. They belong to `spring-boot-starter-data-jpa`.
- Spring Data MongoDB historically supported them through cross-store compatibility, but this is not guaranteed and not recommended.
- Entity classes are NOT Spring-managed beans — `@Autowired` does not work, requiring hacks like `SpringContextHolder`.
- Spring Data MongoDB officially recommends the **EntityCallback API** since Spring Data Commons 2.2.

### Why BeforeConvertCallback

| Feature | @PrePersist (JPA) | BeforeConvertCallback (EntityCallback) |
|---------|-------------------|----------------------------------------|
| Belongs to | JPA specification | Spring Data MongoDB |
| Dependency injection | ❌ Not available (entity is not a Spring bean) | ✅ Constructor / `@Autowired` (callback is a Spring bean) |
| SpringContextHolder hack | ❌ Required | ✅ Not needed |
| Execution ordering | ❌ No control | ✅ `Ordered` interface |
| Reactive support | ❌ No | ✅ `ReactiveBeforeConvertCallback` |
| Return modified entity | ❌ Void method | ✅ Returns entity |
| Official recommendation | ❌ Legacy / JPA only | ✅ Recommended by Spring Data |

### MongoDocIdCallback Implementation

```java
@Component
public class MongoDocIdCallback implements BeforeConvertCallback<BaseMongoDoc<Long>>, Ordered {

    @Override
    public BaseMongoDoc<Long> onBeforeConvert(BaseMongoDoc<Long> entity, String collection) {
        if (entity.getId() == null) {
            entity.setId(LeafId.next());
        }
        return entity;
    }

    @Override
    public int getOrder() {
        return 100; // Execute before AuditingEntityCallback (order 1000)
    }
}
```

- `BeforeConvertCallback<BaseMongoDoc<Long>>`: Only intercepts entities extending `BaseMongoDoc<Long>`. Entities using `BaseMongoDoc<String>` are not affected.
- `LeafId.next()`: Generates a distributed unique ID (Long). Provided by the project's dependency library.
- `getOrder()`: Controls execution order. AuditingEntityCallback runs at order 1000 by default. ID generation should run before auditing, so use a lower order value (e.g., 100).

### EntityCallback Execution Flow

```
Application calls repository.save(entity)
  │
  ├─ 1. MongoDocIdCallback.onBeforeConvert()    (order 100) — generates ID if null
  ├─ 2. AuditingEntityCallback.onBeforeConvert() (order 1000) — sets auditing fields
  ├─ 3. MongoDB driver converts entity to BSON
  └─ 4. Document inserted into collection
```

### Prohibitions

- Do NOT use `@PrePersist` / `@PostPersist` / `@PreUpdate` / `@PostUpdate` in entity classes — these are JPA annotations.
- Do NOT use `SpringContextHolder` or static field injection to obtain Spring beans in entity classes.
- Do NOT perform database operations inside EntityCallback (risk of infinite loops).
- Do NOT add business logic in EntityCallback — it should only handle cross-cutting concerns (ID generation, auditing).

## 6. Prerequisites Configuration

`BaseMongoDoc` relies on the following Spring configurations. All must be present:

```java
@Configuration
@EnableMongoAuditing
public class MongoConfig {

    @Bean
    public MongoTransactionManager transactionManager(MongoDatabaseFactory dbFactory) {
        return new MongoTransactionManager(dbFactory);
    }
}
```

- `@EnableMongoAuditing`: Activates `@CreatedDate`, `@LastModifiedDate`, `@CreatedBy`, `@LastModifiedBy`.
- `AuditorAware<String>` bean: Provided by the project's dependency library. Do not implement it manually.
- `MongoTransactionManager`: Required if using `@Transactional` (optional if no multi-doc transactions).
- `LeafId`: Provided by the project's dependency library. No additional configuration needed.
- `MongoDocIdCallback` is auto-detected via `@Component` — no additional configuration needed.

## 7. Entity Class Example

```java
@Document(collection = "users")
@CompoundIndexes({
    @CompoundIndex(name = "idx_status_createdAt", def = "{'status': 1, 'createdAt': -1}")
})
public class UserDoc extends BaseMongoDoc<Long> {

    @Field("name")
    private String name;

    @Field("email")
    private String email;

    @Field("status")
    private String status;

    @Field("deleted")
    private Boolean deleted = false;
}
```

- No lifecycle methods needed — ID generation is handled by `MongoDocIdCallback`, auditing by Spring Data auditing.
- Field defaults (e.g., `deleted = false`) are set via Java field initializers, not `@PrePersist`.

## 8. Rules for Extending BaseMongoDoc

- Document class names must use `Doc` suffix (e.g., `UserDoc`, `OrderDoc`, `ProductDoc`).
- All derived classes must specify the concrete ID type parameter (e.g., `extends BaseMongoDoc<Long>` or `extends BaseMongoDoc<String>`).
- Never re-declare `id`, `createdAt`, `updatedAt`, `createdBy`, `updatedBy` in subclasses.
- Subclasses must use `@Document(collection = "...")` annotation explicitly with the collection name.
- Do NOT use `@PrePersist` / `@PreUpdate` / `@PostPersist` / `@PostUpdate` in entity classes — these are JPA annotations, not Spring Data MongoDB annotations.
- Use Java field initializers for default values (e.g., `deleted = false`), not lifecycle callbacks.
- If entity-specific cross-cutting logic is needed, create a dedicated `BeforeConvertCallback` or `BeforeSaveCallback` bean.
- Do not add `@PreUpdate` in subclasses for audit fields — `@LastModifiedDate` / `@LastModifiedBy` are handled by Spring Data auditing automatically.
- Add `@Version` only when the document faces concurrent updates. Do not add it proactively.
- Add `deleted` only when the document requires soft delete. Do not add it proactively.

## Anti-Patterns

```java
// BAD: Using @PrePersist (JPA annotation) in Spring Data MongoDB entity
@PrePersist
public void prePersist() {
    if (this.id == null) {
        this.id = someIdGenerator.nextId();
    }
}
// @PrePersist belongs to javax.persistence (JPA), not Spring Data MongoDB.
// Use BeforeConvertCallback instead. See Section 5.

// BAD: Using SpringContextHolder to obtain Spring beans in entity class
this.id = SpringContextHolder.getBean(SomeGenerator.class).nextId();
// Entity classes are not Spring-managed beans. Use EntityCallback for DI.

// BAD: Using @Autowired in entity class
@Autowired
private SomeGenerator generator; // entities are not Spring beans!

// BAD: Not specifying ID type parameter (raw type)
public class UserDoc extends BaseMongoDoc { ... }
// Always specify: BaseMongoDoc<Long> or BaseMongoDoc<String>

// BAD: Duplicating auditing/ID fields in each entity instead of using BaseMongoDoc
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
public class User extends BaseMongoDoc<Long> { ... }

// BAD: Using Entity / Model suffix (JPA / ORM convention)
@Document(collection = "users")
public class UserEntity extends BaseMongoDoc<Long> { ... }

// BAD: Using Document suffix (too verbose)
@Document(collection = "users")
public class UserDocument extends BaseMongoDoc<Long> { ... }

// BAD: Re-declaring BaseMongoDoc fields in subclass
public class UserDoc extends BaseMongoDoc<Long> {
    private Long id; // already in BaseMongoDoc!
    private LocalDateTime createdAt; // already in BaseMongoDoc!
}

// BAD: Adding @Version on documents that are never updated (e.g., log documents)
@Document(collection = "access_logs")
public class AccessLogDoc extends BaseMongoDoc<Long> {
    @Version
    private Long version; // logs are append-only, no concurrent updates
}

// BAD: Adding deleted on documents that are never soft-deleted
@Document(collection = "system_configs")
public class SystemConfigDoc extends BaseMongoDoc<String> {
    @Field("deleted")
    private Boolean deleted = false; // configs are never logically deleted
}

// BAD: Implementing AuditorAware manually when provided by dependency library
@Component
public class SpringSecurityAuditorAware implements AuditorAware<String> { ... }
// AuditorAware is provided by the dependency library. Do not re-implement.

// BAD: Performing DB operations inside EntityCallback
@Component
public class BadCallback implements BeforeConvertCallback<BaseMongoDoc<Long>> {
    @Override
    public BaseMongoDoc<Long> onBeforeConvert(BaseMongoDoc<Long> entity, String collection) {
        auditLogRepository.save(new AuditLog(...)); // risk of infinite loop!
        return entity;
    }
}
```

## Corrected Patterns

```java
// OK: Extend BaseMongoDoc<Long> with Doc suffix — no field duplication, no lifecycle methods
@Document(collection = "users")
public class UserDoc extends BaseMongoDoc<Long> {
    @Field("name")
    private String name;

    @Field("email")
    private String email;

    @Field("deleted")
    private Boolean deleted = false;
}

// OK: Order document with @Version (concurrent updates expected)
@Document(collection = "orders")
public class OrderDoc extends BaseMongoDoc<Long> {
    @Field("totalAmount")
    private BigDecimal totalAmount;

    @Version
    @Field("version")
    private Long version;
}

// OK: Log document — no @Version, no deleted (append-only)
@Document(collection = "access_logs")
public class AccessLogDoc extends BaseMongoDoc<Long> {
    @Field("userId")
    private Long userId;

    @Field("action")
    private String action;
}

// OK: Config document using String ID (business key)
@Document(collection = "system_configs")
public class ConfigDoc extends BaseMongoDoc<String> {
    @Field("value")
    private String value;

    @Field("description")
    private String description;
}

// OK: ID generation via MongoDocIdCallback (BeforeConvertCallback)
@Component
public class MongoDocIdCallback implements BeforeConvertCallback<BaseMongoDoc<Long>>, Ordered {

    @Override
    public BaseMongoDoc<Long> onBeforeConvert(BaseMongoDoc<Long> entity, String collection) {
        if (entity.getId() == null) {
            entity.setId(LeafId.next());
        }
        return entity;
    }

    @Override
    public int getOrder() {
        return 100;
    }
}

// OK: Field default values via Java initializer (not @PrePersist)
@Field("deleted")
private Boolean deleted = false;
```