# Domain Layer

领域层目录规约。Domain 是核心业务层，包含领域模型、领域服务和网关接口定义。**不依赖任何其他业务模块。按领域聚合组织目录。**

## 目录结构

```
domain/src/main/java/com/{company}/{project}/domain
├── {domain1}/                    # 领域 1（如 order）
│   ├── entity/                   # 聚合根 / 实体 / 值对象
│   ├── service/                  # 领域服务
│   ├── gateway/                  # 网关接口（防腐层）
│   └── event/                    # 领域事件（可选）
├── {domain2}/                    # 领域 2
└── shared/event/                 # 跨领域共享事件（可选）
```

## entity 包

### 命名规约

| 类别 | 命名格式 | 示例 | 区分方式 |
|------|---------|------|---------|
| 聚合根 | `{BusinessConcept}` | `Order` | 继承 AggregateRoot |
| 实体 | `{BusinessConcept}` | `OrderItem` | 被聚合根持有 |
| 值对象 | `{BusinessConcept}V` | `MoneyV` | V 后缀，不可变，按属性判等 |

### 职责边界

封装业务规则，聚合根保护内部一致性。值对象不可变（字段 final，无 setter）。
允许 IoC/DI（`@Service` + 构造器注入 Gateway），仅依赖 `spring-context`。
**禁止**使用基础设施能力（`@Repository`/`@Transactional`/`@Cacheable`/数据库/缓存/MQ 等）

```java
@Getter
public class Order extends AggregateRoot {
    private String orderId;
    private List<OrderItem> items;
    private OrderStatus status;

    public void addItem(Product product, int quantity) {
        if (this.status != OrderStatus.DRAFT) throw new BizException("ORDER_NOT_DRAFT", "只有草稿订单可添加商品");
        this.items.add(new OrderItem(product, quantity));
        this.recalculateTotalAmount();
    }

    public void submit() {
        if (this.items.isEmpty()) throw new BizException("ORDER_EMPTY", "订单不能为空");
        this.status = OrderStatus.SUBMITTED;
        this.registerEvent(new OrderSubmittedEvent(this.orderId));
    }
}
```

## service 包

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| 领域服务 | `{DomainConcept}DomainService` | `OrderDomainService` |

职责：跨聚合逻辑、协调多个聚合根、调 Gateway 获取外部数据、实体工厂方法。
**禁止**包含用例编排逻辑（属于 app 层）。

## gateway 包

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| 网关接口 | `{DomainConcept}Gateway` | `OrderGateway` |

防腐层接口，由 infrastructure 实现。方法以领域语言命名，**禁止 CRUD 风格**（如 insert/delete）。

```java
public interface OrderGateway {
    Order findById(String orderId);
    void save(Order order);
    void remove(String orderId);
}
```

## event 包

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| 领域事件 | `{PastTenseAction}Event` | `OrderSubmittedEvent` |

不可变值对象，过去时态命名。

### 事件生命周期

| 阶段 | 所在层 | 操作 |
|------|--------|------|
| 注册 | domain entity | `registerEvent()` 仅存内存，**不立即发布** |
| 持久化 | infrastructure | GatewayImpl `save()` |
| 发布控制 | app service | `save()` 后发布，`clearEvents()` 防重复 |
| 发布实现（进程内） | app service | `ApplicationEventPublisher.publishEvent()` |
| 发布实现（分布式） | infra event | `DomainEventPublisher` 发送到 MQ |
| 消费（进程内） | app eventhandler | `@EventListener`，同事务内 |
| 消费（分布式） | adapter listener | MQ Consumer 反序列化 → 调 EventHandler，独立事务 |

## Mandatory 规则

1. Domain **禁止依赖** app/adapter/infrastructure
2. **必须按领域聚合组织**，**禁止按技术职责平铺**
3. 聚合根保护内部一致性，外部不能直接修改状态
4. Gateway 方法**必须使用领域语言**，**禁止 CRUD 命名**
5. 值对象（V 后缀）**必须不可变**（无 setter，字段 final）
6. 领域事件**必须使用过去时态**
7. App 层**必须通过 DomainService 工厂方法创建实体**，**禁止直接 new**
8. 当 DomainService 已存在时，App 层**必须注入并使用它**，**禁止重新实现相同逻辑**

## Recommended 规则

1. 聚合根继承 AggregateRoot 基类
2. 跨聚合逻辑放 DomainService，不放实体内
3. Gateway 接口数量精简，按需定义