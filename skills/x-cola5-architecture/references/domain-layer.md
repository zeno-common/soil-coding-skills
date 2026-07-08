# Domain Layer

核心业务层。**不依赖任何其他业务模块。按领域聚合组织目录。**

## Structure

```
domain/src/main/java/{basePackage}/domain
├── {domain1}/
│   ├── entity/               # 聚合根 / 实体 / 值对象
│   ├── service/              # 领域服务
│   ├── gateway/              # 网关接口（防腐层）
│   └── event/                # 领域事件（可选）
├── {domain2}/
└── shared/event/             # 跨领域共享事件（可选）
```

## entity

| Type | Pattern | Example | Identity |
|------|---------|---------|----------|
| AggregateRoot | `{Concept}` | `Order` | extends AggregateRoot |
| Entity | `{Concept}` | `OrderItem` | held by aggregate root |
| ValueObject | `{Concept}V` | `MoneyV` | V suffix, immutable, equality by attributes |

Encapsulate business rules. Aggregate root protects internal consistency. ValueObject: fields final, no setter.
Allow IoC/DI (`@Service` + constructor inject Gateway), depend on `spring-context` only.
MUST NOT use infra capabilities (`@Repository`/`@Transactional`/`@Cacheable`/DB/cache/MQ).

```java
@Getter
public class Order extends AggregateRoot {
    private String orderId;
    private List<OrderItem> items;
    private OrderStatus status;

    public void addItem(Product product, int quantity) {
        if (this.status != OrderStatus.DRAFT) throw new BaseException("ORDER_NOT_DRAFT", "只有草稿订单可添加商品");
        this.items.add(new OrderItem(product, quantity));
        this.recalculateTotalAmount();
    }

    public void submit() {
        if (this.items.isEmpty()) throw new BaseException("ORDER_EMPTY", "订单不能为空");
        this.status = OrderStatus.SUBMITTED;
        this.registerEvent(new OrderSubmittedEvent(this.orderId));
    }
}
```

## service

| Type | Pattern | Example |
|------|---------|---------|
| DomainService | `{Concept}DomainService` | `OrderDomainService` |

Cross-aggregate logic, coordinate multiple aggregates, call Gateway, entity factory methods.
MUST NOT contain use-case orchestration (belongs in app).

## gateway

| Type | Pattern | Example |
|------|---------|---------|
| Gateway interface | `{Concept}Gateway` | `OrderGateway` |

Anti-corruption layer, implemented by infrastructure. Methods in domain language, MUST NOT use CRUD naming.

```java
public interface OrderGateway {
    Order findById(String orderId);
    void save(Order order);
    void remove(String orderId);
}
```

## event

| Type | Pattern | Example |
|------|---------|---------|
| Domain Event | `{PastTenseAction}Event` | `OrderSubmittedEvent` |

Immutable value object, past tense naming.

### Event Lifecycle

| Phase | Layer | Action |
|-------|-------|--------|
| Register | domain entity | `registerEvent()` — memory only |
| Persist | infrastructure | GatewayImpl `save()` |
| Publish control | app service | Publish after `save()`, `clearEvents()` to prevent duplicate |
| Publish (in-process) | app service | `ApplicationEventPublisher.publishEvent()` |
| Publish (distributed) | infra event | `DomainEventPublisher` → MQ |
| Consume (in-process) | app eventhandler | `@EventListener`, same transaction |
| Consume (distributed) | adapter listener | MQ Consumer → call EventHandler, independent transaction |

## Mandatory

1. Domain MUST NOT depend on app/adapter/infrastructure
2. MUST organize by domain aggregate — MUST NOT flat-layout by technical concern
3. Aggregate root protects internal consistency — external code MUST NOT directly modify state
4. Gateway methods MUST use domain language — MUST NOT use CRUD naming
5. ValueObject (V suffix) MUST be immutable — no setter, fields final
6. Domain events MUST use past tense
7. App layer MUST create entities via DomainService factory methods — MUST NOT directly `new`
8. When DomainService exists, App layer MUST inject and use it — MUST NOT re-implement

## Recommended

1. AggregateRoot extends base class
2. Cross-aggregate logic in DomainService, not in entity
3. Keep Gateway interfaces minimal, define as needed