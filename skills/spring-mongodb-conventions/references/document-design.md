# Document Design Rules

## 1. Collection and Field Naming

- Collection names use lowercase letters, plural form, separated by underscores.
  - OK: `user_profiles` / `order_items`
  - BAD: `UserProfile` / `userProfile` / `ORDER_ITEMS`
- Java Document class names use PascalCase with `Doc` suffix to distinguish from DTO / VO / Entity in other layers.
  - OK: `UserDoc` / `OrderDoc` / `ProductDoc`
  - BAD: `User` / `Order` / `Product` (ambiguous with DTO / Service model)
  - BAD: `UserDocument` / `OrderDocument` (too verbose)
  - BAD: `UserEntity` / `UserModel` (reserved for JPA / ORM conventions)
- The `@Document(collection = "...")` annotation must explicitly declare the collection name. Do not rely on class name defaulting.
  - OK: `@Document(collection = "users") public class UserDoc`
  - BAD: `@Document public class UserDoc` (collection name defaults to `userDoc`, not `users`)
- Field names use camelCase, matching Java field naming conventions.
  - OK: `firstName` / `createdAt` / `orderTotal`
  - BAD: `first_name` / `FirstName` / `CREATED_AT`
- Collection names must not start with a number or contain system prefix `system.`.
  - BAD: `1_user_profiles` / `system.users`
- Avoid MongoDB reserved field names as top-level keys: `_id`, `_class`, `__v`.

## 2. Primary Key

- Every document must have an `_id` field. Use **Snowflake ID** (distributed unique ID) as the primary key strategy.
- Store Snowflake ID as `Long` (int64) type in `_id`. Do not use MongoDB auto-generated `ObjectId`.
  - OK: `{ _id: NumberLong(1867452390812348416) }` (Snowflake ID as int64)
  - BAD: `{ _id: ObjectId("6621a8f9e4b0c71a23d5e123") }` (auto-generated ObjectId)
  - BAD: `{ _id: "1867452390812348416" }` (String type, wastes storage and index memory)
- Snowflake ID advantages over ObjectId:
  - Time-sortable: IDs are chronologically ordered, friendly to B-tree index and range queries
  - Distributed: No coordination needed between instances, suitable for microservice architecture
  - Decodeable: Timestamp, worker ID, and sequence can be extracted from the ID
  - Compact: 8 bytes (int64) vs 12 bytes (ObjectId) vs ~19 bytes (String), optimal for storage and index
- Why Long over String for Snowflake ID:
  - Storage: `Long` is 8 bytes, `String` is ~19 bytes — 2.4x smaller per document
  - Index: Smaller index footprint, more index entries fit in memory, faster range scans
  - Comparison: Integer comparison is faster than string comparison
  - Consistency: Snowflake ID is inherently a 64-bit integer; storing as String is a type mismatch
- **CAUTION**: Snowflake IDs exceed JavaScript `Number.MAX_SAFE_INTEGER` (2^53-1). When exposing IDs via REST API, serialize as String in JSON to prevent precision loss on JS clients. Use Jackson `@JsonSerialize(using = ToStringSerializer.class)` on the `id` field.
- When using a natural business key as `_id`, ensure it is immutable and globally unique.
  - OK: Use Snowflake ID as default surrogate key
  - OK: Use business identifier (e.g., `orderId`) as `_id` only when guaranteed unique and immutable
  - BAD: Use mutable fields like `email` as `_id` (email can change)
- In Spring Data MongoDB entity mapping:
  ```java
  @Id
  @JsonSerialize(using = ToStringSerializer.class)
  private Long id; // Snowflake ID stored as Long (int64 in MongoDB)
  ```
- Generate Snowflake ID before insertion (in application layer), not via MongoDB auto-generation:
  ```java
  @PrePersist
  public void prePersist() {
      if (this.id == null) {
          this.id = snowflakeIdGenerator.nextId();
      }
  }
  ```

## 3. Embedding vs Referencing

- **Embed** when:
  - The sub-document is always read with the parent (strong consistency requirement)
  - The sub-document has a 1:few relationship (<= 100 items)
  - The sub-document rarely changes independently
  - OK: Embed `address` in `user` document
  - OK: Embed `orderItem` list in `order` document (bounded array)
- **Reference** when:
  - The related document is large or unbounded
  - The related document is accessed independently
  - The related document is shared across multiple parents
  - The array could grow beyond the 16MB document limit
  - OK: Reference `productId` in `orderItem` instead of embedding full product
  - OK: Reference `userId` in `comment` instead of embedding full user
- **Hybrid**: Embed frequently accessed summary fields, reference for full data.
  - OK: Embed `productName` and `productImage` in `orderItem`, reference `productId` for full product details

## 4. Document Size and Array Limits

- Maximum document size is 16MB. Design schemas to stay well under this limit.
- Unbounded arrays are an anti-pattern. If an array can grow indefinitely, use a separate collection.
  - BAD: Embedding all comments in a `post` document (unbounded)
  - OK: Store comments in a separate `comments` collection with `postId` reference
- For large arrays that are frequently accessed in bulk, consider bucket pattern:
  - OK: Group time-series data into hourly/daily buckets instead of one document per data point

## 5. Common Fields

- Every document should include audit fields: `createdAt`, `updatedAt`, `createdBy`, `updatedBy`. These are provided by `BaseDoc` (see `references/base-document.md`).
- Use `Date` type (ISODate) for time fields, never store timestamps as strings.
  - OK: `createdAt: ISODate("2024-01-15T10:30:00Z")`
  - BAD: `createdAt: "2024-01-15 10:30:00"`
- Include logical deletion field `deleted` with default `false` only when the document requires soft delete. Not all documents need this.
  - OK: `deleted: false` (Boolean type, not integer)
- Include `version` field for optimistic locking only when concurrent updates are expected. Not all documents need this.

## 6. BSON Type Selection

- Use `Long` (int64) type for Snowflake ID identifiers, not `ObjectId` or `String`.
  - OK: `_id: NumberLong(1867452390812348416)` (8 bytes, compact and fast)
  - BAD: `_id: "1867452390812348416"` (19 bytes, wasteful)
  - BAD: `_id: ObjectId("6621a8f9e4b0c71a23d5e123")` (12 bytes, not time-sortable)
- Use `Date` for timestamps, not numbers or strings.
- Use `NumberLong` / `NumberInt` explicitly for 64-bit / 32-bit integers to avoid floating-point precision loss.
  - OK: `amount: NumberLong(10000)` for monetary values
  - BAD: `amount: 10000` (may be stored as double)
- Use `Decimal128` (`BigDecimal` in Java) for financial calculations requiring exact precision.
  - OK: Map `BigDecimal` with `@BsonRepresentation(BsonType.DECIMAL128)`
- Use `Boolean` for flags, not integers (`0`/`1`).
  - OK: `active: true`
  - BAD: `active: 1`
- Store binary data (images, files) in GridFS, not directly in documents.

## 7. Schema Validation

- Use MongoDB JSON Schema validation for critical collections to enforce field types and required fields.
  ```javascript
  db.createCollection("users", {
    validator: {
      $jsonSchema: {
        required: ["email", "name"],
        properties: {
          _id: { bsonType: "long" },
          email: { bsonType: "string" },
          name: { bsonType: "string" },
          age: { bsonType: "int", minimum: 0 }
        }
      }
    }
  })
  ```

## Anti-Patterns

```javascript
// BAD: Using ObjectId as _id (not time-sortable, not distributed-friendly)
{ _id: ObjectId("6621a8f9e4b0c71a23d5e123") }

// BAD: Using String for Snowflake ID (wastes storage and index memory)
{ _id: "1867452390812348416" }

// BAD: Unbounded array embedding
{
  _id: NumberLong(1867452390812348416),
  title: "Popular Post",
  comments: [/* 10000+ comments */]
}

// BAD: String timestamp
{ createdAt: "2024-01-15T10:30:00Z" }

// BAD: Mutable field as _id
{ _id: "user@example.com" }

// BAD: Integer for boolean
{ active: 1 }
```

```java
// BAD: Document class without Doc suffix (ambiguous with DTO / VO)
@Document(collection = "users")
public class User extends BaseDoc { ... }

// BAD: Using Entity / Model suffix (JPA / ORM convention, not MongoDB)
@Document(collection = "users")
public class UserEntity extends BaseDoc { ... }

// BAD: Using Document suffix (too verbose)
@Document(collection = "users")
public class UserDocument extends BaseDoc { ... }

// BAD: Missing explicit collection name (defaults to class name in camelCase)
@Document
public class UserDoc extends BaseDoc { ... }
```

## Corrected Patterns

```javascript
// OK: Snowflake ID as Long (time-sortable, distributed, compact)
{ _id: NumberLong(1867452390812348416), email: "user@example.com" }

// OK: Separate collection for unbounded data
// posts collection
{ _id: NumberLong(1867452390812348416), title: "Popular Post" }
// comments collection
{ _id: NumberLong(1867452390812348417), postId: NumberLong(1867452390812348416), content: "..." }

// OK: Proper Date type
{ createdAt: ISODate("2024-01-15T10:30:00Z") }

// OK: Boolean for flags
{ active: true }
```

```java
// OK: Doc suffix + explicit collection name
@Document(collection = "users")
public class UserDoc extends BaseDoc { ... }

// OK: Order document
@Document(collection = "orders")
public class OrderDoc extends BaseDoc { ... }
```