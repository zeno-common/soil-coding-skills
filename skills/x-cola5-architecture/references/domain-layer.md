# Domain Layer

领域层目录规约。Domain 是核心业务层，包含领域模型、领域服务和网关接口定义，不依赖任何其他业务模块。

## 目录结构

```
domain
└── src/main/java/com/{company}/{project}/domain
    ├── entity              # 领域实体（聚合根、实体、值对象）
    ├── service             # 领域服务
    ├── gateway             # 网关接口（防腐层接口）
    └── event               # 领域事件（可选）
```

## entity 包

### 目录划分

```
entity
├── {AggregateRoot}.java    # 聚合根
├── {Entity}.java           # 实体
└── {ValueObject}V.java     # 值对象
```

### 命名规约

| 类别 | 命名格式 | 示例 | 区分方式 |
|------|---------|------|---------|
| 聚合根 | `{BusinessConcept}` | `Order` | 继承 `AggregateRoot`，有独立 Gateway |
| 实体 | `{BusinessConcept}` | `OrderItem` | 被聚合根持有，有标识 |
| 值对象 | `{BusinessConcept}V` | `MoneyV`, `AddressV` | 不可变，无标识，按属性判等 |

### 职责边界

- 封装业务规则和业务逻辑，聚合根保护内部一致性
- 值对象不可变（无 setter，所有字段 final）
- **禁止**依赖 Spring 框架注解 / 任何基础设施（数据库、缓存、MQ）

### 代码示例

```java
public class Order extends AggregateRoot {
    private String orderId;
    private List<OrderItem> items;
    private OrderStatus status;

    public void addItem(Product product, int quantity) {
        if (this.status != OrderStatus.DRAFT) {
            throw new BizException("ORDER_NOT_DRAFT", "只有草稿订单可添加商品");
        }
        this.items.add(new OrderItem(product, quantity));
        this.recalculateTotalAmount();
    }

    public void submit() {
        if (this.items.isEmpty()) {
            throw new BizException("ORDER_EMPTY", "订单不能为空");
        }
        this.status = OrderStatus.SUBMITTED;
        this.registerEvent(new OrderSubmittedEvent(this.orderId));
    }
}
```

## service 包

### 命名规约

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| 领域服务 | `{DomainConcept}DomainService` | `OrderDomainService` |

### 职责边界

- 跨聚合业务逻辑、协调多个聚合根、调用 Gateway 获取外部数据
- 封装实体的创建和初始化逻辑（工厂方法），App 层必须通过领域服务创建实体，**禁止**在 App 层直接 `new` 实体
- **禁止**包含用例编排逻辑（属于 app 层）

### 代码示例

```java
public class OrderDomainService {
    private final OrderGateway orderGateway;
    private final ProductGateway productGateway;

    public Order createOrder(String customerId, List<String> productIds) {
        List<Product> products = productGateway.findByIds(productIds);
        Order order = new Order(customerId);
        products.forEach(p -> order.addItem(p, 1));
        return order;
    }
}
```

## gateway 包

### 命名规约

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| 网关接口 | `{DomainConcept}Gateway` | `OrderGateway` |

### 职责边界

- 定义领域层需要的外部操作接口（防腐层），由 infrastructure 层实现
- 接口方法以领域语言命名，不暴露存储细节

### 代码示例

```java
public interface OrderGateway {
    Order findById(String orderId);
    void save(Order order);
    void remove(String orderId);
}
```

❌ 禁止：`OrderMapper` / `OrderRepository`（暴露存储细节）、`insert` / `update` / `delete`（CRUD 命名）
✅ 正确：`save` / `remove` / `findById`（领域语言）

## event 包（可选）

### 命名规约

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| 领域事件 | `{PastTenseAction}Event` | `OrderSubmittedEvent` |

### 职责边界

- 表示领域中已发生的事实，事件名称使用过去时态，事件对象为不可变值对象

### 事件生命周期

```
registerEvent()         save()                  publish()
     │                    │                       │
     ▼                    ▼                       ▼
 存入聚合根             持久化聚合根             发布到 MQ
 内存列表               （DB 事务提交）          （事务提交后）
```

- `registerEvent`：聚合根业务方法中调用，仅存入内存列表，**不立即发布**
- `save`：GatewayImpl 持久化聚合根
- `publish`：Application Service 在持久化成功后，从聚合根取出事件并发布

## Mandatory 规则

1. Domain 模块**禁止**依赖 app、adapter、infrastructure 模块
2. Domain 模块**禁止**依赖 Spring 框架（`@Service`、`@Component` 等）
3. 聚合根必须保护内部一致性，外部不能直接修改内部状态
4. Gateway 接口方法命名必须使用领域语言，禁止 CRUD 风格命名
5. 值对象（`V` 后缀）必须不可变（无 setter，所有字段 final）
6. 领域事件命名必须使用过去时态
7. 当领域服务（`XxxDomainService`）已存在时，App 层**必须**注入并使用它，**禁止**在 App 层重新实现相同逻辑
8. App 层**必须**通过领域服务的工厂方法创建实体，**禁止**在 App 层直接 `new` 领域实体

## Recommended 规则

1. 聚合根继承 `AggregateRoot` 基类（提供事件注册能力）
2. 实体使用 ID 标识，值对象（`V` 后缀）通过属性判等
3. 跨聚合逻辑放在 DomainService 中，不要放在实体内
4. Gateway 接口方法数量尽量精简，按需定义
5. 领域事件放在 entity 同级的 event 包中，不要散落在各处