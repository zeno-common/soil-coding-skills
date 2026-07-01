# Domain Layer

领域层目录规约。Domain 是核心业务层，包含领域模型、领域服务和网关接口定义，不依赖任何其他业务模块。

## 目录结构

Domain 层按领域聚合组织目录，每个领域独立子包，保护聚合边界。

```
domain
└── src/main/java/com/{company}/{project}/domain
    ├── {domain1}/                   # 领域 1（如 order）
    │   ├── entity/                  # 领域实体（聚合根、实体、值对象）
    │   ├── service/                 # 领域服务
    │   ├── gateway/                 # 网关接口（防腐层接口）
    │   └── event/                   # 领域事件（可选）
    ├── {domain2}/                   # 领域 2（如 inventory）
    │   ├── entity/
    │   ├── service/
    │   └── gateway/
    └── shared/                      # 跨领域共享（可选）
        └── event/                   # 跨领域共享事件
```

> 按领域聚合划分目录，而非按技术职责（entity/service/gateway）平铺。新增领域只需新增子包，不修改现有代码。

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
- 允许使用 Spring 通用编程能力（IoC/DI）：领域服务使用 `@Service` 注解，通过构造器注入 Gateway 接口。domain 模块仅依赖 `spring-context`，不依赖 `spring-boot-starter-*` 等基础设施 starter。**禁止**使用基础设施能力（`@Repository` / `@Transactional` / `@Cacheable` / `@Scheduled` / 数据库 / 缓存 / MQ 等）

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
@Service
@RequiredArgsConstructor
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

领域事件有两种消费路径：**进程内**（同 JVM）和**分布式**（跨服务 MQ）。

#### 进程内事件（同 JVM）

```
registerEvent()         save()                  publish()               handle()
     │                    │                       │                       │
     ▼                    ▼                       ▼                       ▼
 domain 层              infrastructure 层       app 层控制              app 层 eventhandler
 存入聚合根             持久化聚合根            ApplicationEvent        @EventListener
 内存列表               （DB 事务提交）         Publisher 分发          同一事务内编排领域服务
```

#### 分布式事件（跨服务 MQ）

```
registerEvent()         save()                  publish()               handle()
     │                    │                       │                       │
     ▼                    ▼                       ▼                       ▼
 domain 层              infrastructure 层       app 层控制              app 层 eventhandler
 存入聚合根             持久化聚合根            发布到 MQ               adapter listener 调用
 内存列表               （DB 事务提交）         （事务提交后）           独立事务编排领域服务
```

- `registerEvent`：聚合根业务方法中调用，仅存入内存列表，**不立即发布**
- `save`：GatewayImpl 持久化聚合根
- `publish`：Application Service 在持久化成功后，从聚合根取出事件并发布（进程内用 `ApplicationEventPublisher`，分布式用 `DomainEventPublisher` 发送到 MQ）
- `handle`：
  - **进程内**：Spring 事件总线分发 → `@EventListener` → 同一事务内编排领域服务
  - **分布式**：adapter listener 接收 MQ 消息 → 调用 `EventHandler.onXxx()` → 独立事务编排领域服务

### 事件处理分层职责

| 阶段 | 所在层 | 位置 | 职责 |
|------|--------|------|------|
| 定义事件 | domain | `domain/event` | 不可变值对象，过去时态命名 |
| 注册事件 | domain | `domain/entity` | 聚合根内 `registerEvent()`，仅存内存 |
| 控制发布时机 | app | `app/service` | Application Service 在 `save()` 后发布，`clearEvents()` 避免重复 |
| 实现发布（进程内） | app | `app/service` | `ApplicationEventPublisher.publishEvent()`，Spring 事件总线分发 |
| 实现发布（分布式） | infrastructure | `infrastructure/event` | `DomainEventPublisher` 对接 MQ，处理序列化和发送失败重试 |
| 消费事件（进程内） | app | `app/eventhandler` | `@EventListener` 监听，与发布者同一事务 |
| 消费事件（分布式） | adapter | `adapter/listener` | MQ Consumer 反序列化，调用 app 层 EventHandler |
| 处理事件 | app | `app/eventhandler` | 按领域聚合组织 EventHandler，编排领域服务完成跨聚合协作，**禁止**包含业务规则 |

## Mandatory 规则

1. Domain 模块**禁止**依赖 app、adapter、infrastructure 模块
2. Domain 层**必须**按领域聚合组织目录，每个领域一个独立子包，**禁止**按技术职责（entity/service/gateway）平铺
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