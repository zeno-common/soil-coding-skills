# Spring Data MongoDB Rules

## 1. Entity Mapping

- Always annotate Document classes with `@Document(collection = "collection_name")`. Never rely on class name defaulting.
- Document class names use `Doc` suffix (e.g., `UserDoc`, `OrderDoc`). See `references/document-design.md` for naming rules.
- All entities must extend `BaseDoc<ID>` (see `references/base-document.md`). Do not re-declare ID or auditing fields.
  ```java
  @Document(collection = "users")
  public class UserDoc extends BaseDoc<Long> { ... }
  ```
- Always specify the concrete ID type parameter. Do not use raw type `BaseDoc`.
  - OK: `extends BaseDoc<Long>` (distributed ID)
  - OK: `extends BaseDoc<String>` (business key)
  - BAD: `extends BaseDoc` (raw type, no type safety)
- Use `@Field("fieldName")` when Java field name differs from MongoDB field name, or to explicitly declare the mapping.
  ```java
  @Field("createdAt")
  private LocalDateTime createdAt;
  ```
- Use `@BsonRepresentation(BsonType.DECIMAL128)` for `BigDecimal` fields to ensure exact precision.
  ```java
  @BsonRepresentation(BsonType.DECIMAL128)
  private BigDecimal amount;
  ```
- Do not use `@DBRef` unless absolutely necessary. It creates a separate query (N+1 problem). Prefer manual references (storing the ID as a `Long` field).
  - BAD: `@DBRef private List<OrderDoc> orders;`
  - OK: `@Field private List<Long> orderIds;`

## 2. Repository Design

- Extend `MongoRepository<DocClass, ID>` for standard CRUD operations. The ID type must match the `BaseDoc<ID>` type parameter.
  ```java
  public interface UserRepository extends MongoRepository<UserDoc, Long> { ... }
  public interface ConfigRepository extends MongoRepository<ConfigDoc, String> { ... }
  ```
- Define derived query methods with clear naming conventions:
  ```java
  List<UserDoc> findByEmailAndStatus(String email, String status);
  Page<UserDoc> findByStatus(String status, Pageable pageable);
  ```
- For complex queries, use `@Query` annotation instead of extremely long method names:
  ```java
  @Query("{ 'status': ?0, 'createdAt': { $gte: ?1 } }")
  List<UserDoc> findActiveUsersSince(String status, LocalDateTime since);
  ```
- Avoid derived query methods with more than 3 conditions. Use `@Query` or `MongoTemplate` instead.
  - BAD: `findByStatusAndRoleAndDepartmentAndCreatedAtBetween(...)` -- too long, hard to read
  - OK: Use `@Query` or `MongoTemplate` with `Criteria`

## 3. MongoTemplate Usage

- Use `MongoTemplate` for:
  - Dynamic queries with conditional criteria
  - Aggregation pipelines
  - Bulk operations
  - Update operations with `$set`, `$inc`, `$push`, `$pull`
  - Upsert operations
- Always use `Criteria` API for type-safe query construction:
  ```java
  Query query = new Query();
  query.addCriteria(Criteria.where("status").is("active")
      .and("createdAt").gte(since));
  query.with(Sort.by(Sort.Direction.DESC, "createdAt"));
  query.with(PageRequest.of(0, 20));
  List<UserDoc> users = mongoTemplate.find(query, UserDoc.class);
  ```
- Use `Aggregation` API for aggregation pipelines:
  ```java
  Aggregation aggregation = Aggregation.newAggregation(
      Aggregation.match(Criteria.where("status").is("active")),
      Aggregation.group("department").count().as("total"),
      Aggregation.sort(Sort.Direction.DESC, "total")
  );
  AggregationResults<DeptStats> results = mongoTemplate.aggregate(
      aggregation, "users", DeptStats.class
  );
  ```

## 4. Update Operations

- Always use `Update` class with operators (`$set`, `$inc`, etc.) for partial updates. Never do full document replacement for partial changes.
  ```java
  Update update = new Update();
  update.set("name", "New Name");
  update.set("updatedAt", LocalDateTime.now());
  mongoTemplate.updateFirst(query, update, UserDoc.class);
  ```
- Use `updateMulti` for bulk updates matching a query.
- Use `upsert` when you want to insert if not exists:
  ```java
  mongoTemplate.upsert(query, update, UserDoc.class);
  ```

## 5. Auditing

- Enable MongoDB auditing with `@EnableMongoAuditing` on configuration class.
- Auditing fields (`createdAt`, `updatedAt`, `createdBy`, `updatedBy`) are defined in `BaseDoc<ID>` with `@CreatedDate`, `@LastModifiedDate`, `@CreatedBy`, `@LastModifiedBy`. See `references/base-document.md` for full design.
- `AuditorAware<String>` is provided by the project's dependency library. Do not implement it manually.

## 6. EntityCallback API

- Spring Data MongoDB recommends **EntityCallback API** for lifecycle hooks, NOT JPA annotations (`@PrePersist` / `@PostPersist` / `@PreUpdate` / `@PostUpdate`).
- `@PrePersist` and related annotations belong to `javax.persistence` (JPA), not Spring Data MongoDB. Do NOT use them in MongoDB entity classes.
- Available EntityCallback interfaces:

| Callback | Timing | Use Case |
|----------|--------|----------|
| `BeforeConvertCallback` | Before entity is converted to BSON | ID generation, field defaults |
| `BeforeSaveCallback` | Before document is saved to MongoDB | Last-minute modifications |
| `AfterSaveCallback` | After document is saved | Post-save side effects |
| `AfterConvertCallback` | After BSON is converted to entity | Post-load initialization |

- ID generation is handled by `MongoDocIdCallback` (see `references/base-document.md` Section 5):
  ```java
  @Component
  public class MongoDocIdCallback implements BeforeConvertCallback<BaseDoc<Long>>, Ordered {

      @Override
      public BaseDoc<Long> onBeforeConvert(BaseDoc<Long> entity, String collection) {
          if (entity.getId() == null) {
              entity.setId(LeafId.next());
          }
          return entity;
      }

      @Override
      public int getOrder() {
          return 100; // Before AuditingEntityCallback (order 1000)
      }
  }
  ```
- `MongoDocIdCallback` only handles `BaseDoc<Long>`. Entities using `BaseDoc<String>` are not affected.
- `LeafId.next()` generates a distributed unique ID (Long). Provided by the project's dependency library.
- Use `Ordered` interface to control execution order. AuditingEntityCallback runs at order 1000 by default.
- For reactive applications, use `ReactiveBeforeConvertCallback` / `ReactiveAfterSaveCallback` etc.
- Do not perform database operations inside EntityCallback (risk of infinite loops).

## 7. Optimistic Locking

- Add `@Version` field only when concurrent updates are expected. Not all documents need this.
  ```java
  @Document(collection = "orders")
  public class OrderDoc extends BaseDoc<Long> {
      @Version
      @Field("version")
      private Long version;
  }
  ```
- Spring Data MongoDB automatically increments `version` on each update.
- On conflict, throws `OptimisticLockingFailureException`. Handle with retry logic in the service layer.

## 8. Transactions

- Use `@Transactional` for multi-document operations that require atomicity.
- Single document operations are already atomic — do not wrap them in transactions unnecessarily.
- Transactions require a `MongoTransactionManager` bean and a Replica Set (not supported on standalone MongoDB).
  ```java
  @Transactional
  public void createOrder(OrderDoc order, List<OrderItemDoc> items) {
      orderRepository.save(order);
      orderItemRepository.saveAll(items);
  }
  ```
- Keep transactions short — long-running transactions hold locks and can cause performance issues.
- Do not use transactions for read-only operations.

## 9. Configuration

- Connection string format:
  ```yaml
  spring:
    data:
      mongodb:
        uri: mongodb://user:pass@host1:27017,host2:27017/dbname?replicaSet=rs0&connectTimeoutMS=60000
  ```
- Enable auto-index creation only in development, not production:
  ```yaml
  spring:
    data:
      mongodb:
        auto-index-creation: false
  ```
- Use `@CompoundIndex` and `@CompoundIndexes` on entity classes for index definitions (development only):
  ```java
  @CompoundIndexes({
      @CompoundIndex(name = "idx_status_createdAt",
                     def = "{'status': 1, 'createdAt': -1}")
  })
  @Document(collection = "orders")
  public class OrderDoc extends BaseDoc<Long> { ... }
  ```
- In production, manage indexes via migration scripts (Mongock, etc.), not auto-index-creation.
- Configure Jackson to handle Long ID serialization globally (recommended for `BaseDoc<Long>` entities):
  ```java
  @Configuration
  public class JacksonConfig {
      @Bean
      public ObjectMapper objectMapper() {
          ObjectMapper mapper = new ObjectMapper();
          SimpleModule module = new SimpleModule();
          module.addSerializer(Long.class, ToStringSerializer.instance);
          module.addSerializer(Long.TYPE, ToStringSerializer.instance);
          mapper.registerModule(module);
          return mapper;
      }
  }
  ```
  - Since `BaseDoc<ID>` uses a generic type parameter, `@JsonSerialize(using = ToStringSerializer.class)` cannot be placed on the `id` field in the base class. Use global Jackson Long-to-String serialization instead.
  - Note: Global Long-to-string serialization affects all Long fields. If only ID fields need this, use per-field `@JsonSerialize` in each derived class that uses `BaseDoc<Long>`.

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
// Use BeforeConvertCallback instead. See references/base-document.md Section 5.

// BAD: Using SpringContextHolder to obtain Spring beans in entity class
this.id = SpringContextHolder.getBean(SomeGenerator.class).nextId();
// Entity classes are not Spring-managed beans. Use EntityCallback for DI.

// BAD: Using raw type BaseDoc without ID type parameter
public class UserDoc extends BaseDoc { ... }
// Always specify: BaseDoc<Long> or BaseDoc<String>

// BAD: Implementing AuditorAware manually when provided by dependency library
@Component
public class SpringSecurityAuditorAware implements AuditorAware<String> { ... }
// AuditorAware is provided by the dependency library. Do not re-implement.

// BAD: @DBRef causing N+1 queries
@DBRef
private List<OrderDoc> orders;

// BAD: Overly long derived query method
List<UserDoc> findByStatusAndRoleAndDepartmentAndCreatedAtBetween(
    String status, String role, String dept, LocalDateTime from, LocalDateTime to);

// BAD: Full document replacement for partial update
UserDoc user = repository.findById(id).get();
user.setName("New Name");
repository.save(user); // replaces entire document

// BAD: Auto-index-creation in production
// spring.data.mongodb.auto-index-creation=true

// BAD: Performing DB operations inside EntityCallback
@Component
public class BadCallback implements BeforeConvertCallback<BaseDoc<Long>> {
    @Override
    public BaseDoc<Long> onBeforeConvert(BaseDoc<Long> entity, String collection) {
        auditLogRepository.save(new AuditLog(...)); // risk of infinite loop!
        return entity;
    }
}

// BAD: Relying on MongoDB auto-generated ObjectId
// Let MongoDB generate _id as ObjectId instead of using distributed ID

// BAD: Document class without Doc suffix
@Document(collection = "users")
public class User extends BaseDoc<Long> { ... }

// BAD: Using Entity / Model suffix (JPA / ORM convention)
@Document(collection = "users")
public class UserEntity extends BaseDoc<Long> { ... }

// BAD: Using Document suffix (too verbose)
@Document(collection = "users")
public class UserDocument extends BaseDoc<Long> { ... }

// BAD: Duplicating auditing/ID fields in each entity instead of using BaseDoc
// See references/base-document.md for the correct BaseDoc design

// BAD: Adding @Version on documents that are never updated
@Document(collection = "access_logs")
public class AccessLogDoc extends BaseDoc<Long> {
    @Version
    private Long version; // logs are append-only, no concurrent updates
}
```

## Corrected Patterns

```java
// OK: ID generation via MongoDocIdCallback (BeforeConvertCallback)
@Component
public class MongoDocIdCallback implements BeforeConvertCallback<BaseDoc<Long>>, Ordered {

    @Override
    public BaseDoc<Long> onBeforeConvert(BaseDoc<Long> entity, String collection) {
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

// OK: Manual reference instead of @DBRef (using Long ID)
@Field
private List<Long> orderIds;

// OK: Use @Query or MongoTemplate for complex queries
@Query("{ 'status': ?0, 'role': ?1, 'department': ?2, 'createdAt': { $gte: ?3, $lte: ?4 } }")
List<UserDoc> findUsersByConditions(String status, String role, String dept,
    LocalDateTime from, LocalDateTime to);

// OK: Partial update with $set
Update update = new Update()
    .set("name", "New Name")
    .set("updatedAt", LocalDateTime.now());
mongoTemplate.updateFirst(
    Query.query(Criteria.where("_id").is(id)), update, UserDoc.class
);

// OK: Manage indexes via migration scripts in production
// Use Mongock or custom migration scripts

// OK: Extend BaseDoc<Long> with Doc suffix — no field duplication
@Document(collection = "users")
public class UserDoc extends BaseDoc<Long> {
    @Field("name")
    private String name;

    @Field("email")
    private String email;
}

// OK: Extend BaseDoc<String> for business key ID
@Document(collection = "system_configs")
public class ConfigDoc extends BaseDoc<String> {
    @Field("value")
    private String value;
}

// OK: Add @Version only when concurrent updates are expected
@Document(collection = "orders")
public class OrderDoc extends BaseDoc<Long> {
    @Field("totalAmount")
    private BigDecimal totalAmount;

    @Version
    @Field("version")
    private Long version;
}
```