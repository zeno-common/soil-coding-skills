# Spring Data MongoDB Rules

## 1. Entity Mapping

- Always annotate Document classes with `@Document(collection = "collection_name")`. Never rely on class name defaulting.
- Document class names use `Doc` suffix (e.g., `UserDoc`, `OrderDoc`). See `references/document-design.md` for naming rules.
- All entities must extend `BaseDoc` (see `references/base-document.md`). Do not re-declare ID or auditing fields.
  ```java
  @Document(collection = "users")
  public class UserDoc extends BaseDoc { ... }
  ```
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
- Do not use `@DBRef` unless absolutely necessary. It creates a separate query (N+1 problem). Prefer manual references (storing the Snowflake ID as a `Long` field).
  - BAD: `@DBRef private List<OrderDoc> orders;`
  - OK: `@Field private List<Long> orderIds;`

## 2. Repository Design

- Extend `MongoRepository<DocClass, Long>` for standard CRUD operations.
  ```java
  public interface UserRepository extends MongoRepository<UserDoc, Long> { ... }
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
- Auditing fields (`createdAt`, `updatedAt`, `createdBy`, `updatedBy`) are defined in `BaseDoc` with `@CreatedDate`, `@LastModifiedDate`, `@CreatedBy`, `@LastModifiedBy`. See `references/base-document.md` for full design.
- Implement `AuditorAware<String>` to provide the current user:
  ```java
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

## 6. Lifecycle Events

- Use `@PrePersist` / `@PostPersist` / `@PreUpdate` / `@PostUpdate` for lifecycle hooks.
- ID generation is handled in `BaseDoc.prePersist()`. Subclasses should only override for entity-specific logic and must call `super.prePersist()` first.
  ```java
  @PrePersist
  public void initDefaults() {
      super.prePersist(); // MUST call super first
      // entity-specific logic here
  }
  ```
- Do not perform database operations inside lifecycle callbacks (risk of infinite loops).

## 7. Optimistic Locking

- Add `@Version` only when the document faces concurrent updates. It is NOT included in `BaseDoc` — add it per entity as needed.
  ```java
  @Document(collection = "orders")
  public class OrderDoc extends BaseDoc {
      @Version
      @Field("version")
      private Long version;
  }
  ```
- Spring Data MongoDB automatically increments the version on each update and throws `OptimisticLockingFailureException` on conflict.
- Handle `OptimisticLockingFailureException` with retry logic in the service layer.
- Do not add `@Version` on append-only documents (e.g., log documents).

## 8. Transaction Management

- Configure `MongoTransactionManager` bean to enable `@Transactional`:
  ```java
  @Bean
  public MongoTransactionManager transactionManager(MongoDatabaseFactory dbFactory) {
      return new MongoTransactionManager(dbFactory);
  }
  ```
- Use `@Transactional(rollbackFor = Exception.class)` for multi-document operations.
- Keep transactions short. Do not include external API calls or long computations inside transactions.
- Transactions require a replica set (not supported on standalone MongoDB).
- Prefer single-document atomicity (embedding) over multi-document transactions.

## 9. Type Mapping and Converters

- Register custom `Converter` implementations for complex type mappings:
  ```java
  @ReadingConverter
  public static class DateToLocalDateTimeConverter
          implements Converter<Date, LocalDateTime> {
      @Override
      public LocalDateTime convert(Date source) {
          return source.toInstant()
              .atZone(ZoneId.systemDefault())
              .toLocalDateTime();
      }
  }
  ```
- Register converters via `MongoCustomConversions`:
  ```java
  @Bean
  public MongoCustomConversions customConversions() {
      return new MongoCustomConversions(List.of(
          new DateToLocalDateTimeConverter(),
          new LocalDateTimeToDateConverter()
      ));
  }
  ```
- Prefer `LocalDateTime` / `Instant` over `java.util.Date` in entity classes.

## 10. Batch Operations

- Use `mongoTemplate.bulkOps()` for efficient batch writes:
  ```java
  BulkOperations bulkOps = mongoTemplate.bulkOps(
      BulkOperations.BulkMode.UNORDERED, UserDoc.class
  );
  for (UserDoc user : users) {
      bulkOps.insert(user);
  }
  bulkOps.execute();
  ```
- Use `BulkMode.UNORDERED` for independent operations (parallel execution, faster).
- Use `BulkMode.ORDERED` when operations have dependencies (stops on first error).
- For `saveAll()` on `MongoRepository`, be aware it performs individual `save` calls. Use `bulkOps` for large batches.
- Pre-generate Snowflake IDs for all documents before batch insert to ensure consistency.

## 11. Configuration Best Practices

- Configure connection pooling appropriately:
  ```yaml
  spring:
    data:
      mongodb:
        uri: mongodb://host:port/db?maxPoolSize=50&minPoolSize=10&maxIdleTimeMS=60000
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
  public class OrderDoc extends BaseDoc { ... }
  ```
- In production, manage indexes via migration scripts (Mongock, etc.), not auto-index-creation.
- Configure Snowflake ID generator as a Spring bean:
  ```java
  @Configuration
  public class SnowflakeConfig {
      @Bean
      public SnowflakeIdGenerator snowflakeIdGenerator(
              @Value("${snowflake.worker-id}") long workerId,
              @Value("${snowflake.datacenter-id}") long datacenterId) {
          return new SnowflakeIdGenerator(workerId, datacenterId);
      }
  }
  ```
- Configure Jackson to handle Long ID serialization globally (alternative to per-field `@JsonSerialize`):
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
  - Note: Global Long-to-String serialization affects all Long fields. If only ID fields need this, prefer per-field `@JsonSerialize` in `BaseDoc`.

## Anti-Patterns

```java
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

// BAD: Performing DB operations in lifecycle callback
@PrePersist
public void initDefaults() {
    auditLogRepository.save(new AuditLog(...)); // risk of infinite loop
}

// BAD: Relying on MongoDB auto-generated ObjectId
// Let MongoDB generate _id as ObjectId instead of using Snowflake ID

// BAD: Document class without Doc suffix
@Document(collection = "users")
public class User extends BaseDoc { ... }

// BAD: Using Entity / Model suffix (JPA / ORM convention)
@Document(collection = "users")
public class UserEntity extends BaseDoc { ... }

// BAD: Using Document suffix (too verbose)
@Document(collection = "users")
public class UserDocument extends BaseDoc { ... }

// BAD: Duplicating auditing/ID fields in each entity instead of using BaseDoc
// See references/base-document.md for the correct BaseDoc design

// BAD: Overriding @PrePersist without calling super
@PrePersist
public void initDefaults() {
    // missing super.prePersist() — Snowflake ID not generated!
    this.someField = "default";
}

// BAD: Adding @Version on documents that are never updated
@Document(collection = "access_logs")
public class AccessLogDoc extends BaseDoc {
    @Version
    private Long version; // logs are append-only, no concurrent updates
}
```

## Corrected Patterns

```java
// OK: Manual reference instead of @DBRef (using Snowflake ID as Long)
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

// OK: Extend BaseDoc with Doc suffix — no field duplication
@Document(collection = "users")
public class UserDoc extends BaseDoc {
    @Field("name")
    private String name;

    @Field("email")
    private String email;
}

// OK: Add @Version only when concurrent updates are expected
@Document(collection = "orders")
public class OrderDoc extends BaseDoc {
    @Field("totalAmount")
    private BigDecimal totalAmount;

    @Version
    @Field("version")
    private Long version;
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