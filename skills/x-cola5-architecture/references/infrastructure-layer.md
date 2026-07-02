# Infrastructure Layer

基础设施层目录规约。Infrastructure 实现领域层定义的 Gateway 接口，对接外部系统。**按领域聚合组织目录。**

## 目录结构

```
infrastructure/src/main/java/com/{company}/{project}/infrastructure
├── {domain1}/                    # 领域 1（如 order）
│   ├── gateway/impl/             # Gateway 接口实现
│   ├── mapper/                   # MyBatis Mapper
│   └── dataobject/               # DO（数据库映射对象）
├── {domain2}/                    # 领域 2
└── common/                       # 跨领域共享
    ├── client/                   # 外部服务客户端
    ├── event/                    # 事件发布实现
    ├── config/                   # 基础设施配置
    └── util/                     # 通用工具
```

## 各包命名与职责

| 包 | 命名格式 | 示例 | 职责 |
|----|---------|------|------|
| gateway/impl | `{Concept}GatewayImpl` | `OrderGatewayImpl` | 实现 domain 的 Gateway 接口，Entity↔DO 转换 |
| mapper | `{Table}Mapper` | `OrderMapper` | 数据库操作，**禁止被 domain/app 引用** |
| dataobject | `{Table}DO` | `OrderDO` | 数据库映射，**禁止泄露到 domain/app** |
| client | `{System}Client` | `PaymentClient` | 封装外部系统调用，转内部异常 |
| event | `DomainEventPublisher` | — | 发送事件到 MQ，处理序列化和重试 |
| config | — | — | 数据源/Redis/MQ 配置，**禁止含业务逻辑** |

```java
@Component
@RequiredArgsConstructor
public class OrderGatewayImpl implements OrderGateway {
    private final OrderMapper orderMapper;

    public Order findById(String orderId) {
        OrderDO orderDO = orderMapper.selectById(orderId);
        return orderDO == null ? null : OrderConverter.toEntity(orderDO);
    }

    public void save(Order order) {
        orderMapper.insertOrUpdate(OrderConverter.toDO(order));
    }
}
```

## 对象转换

详见 `references/object-isolation.md`。

| 转换方向 | 位置 | 方法命名 |
|---------|------|---------|
| Entity ↔ DO | Converter / GatewayImpl 内部 | `toDO()` / `toEntity()` |
| Response → Entity | Client 内部 | `toEntity(response)` |

## Mandatory 规则

1. **必须按领域聚合组织**，**禁止按技术职责平铺**
2. GatewayImpl 必须以 `GatewayImpl` 结尾，必须实现 domain 的 Gateway 接口
3. DO **禁止泄露到 domain 或 app**
4. Mapper **禁止被 domain 或 app 直接引用**
5. 外部数据结构**禁止泄露到 domain**，必须在 Client 或 GatewayImpl 中转换
6. config **禁止包含业务逻辑**

## Recommended 规则

1. 一个 GatewayImpl 对应一个 Gateway 接口
2. 转换逻辑抽取为 Converter 类，保持 GatewayImpl 简洁
3. DO 字段用包装类（`Long` 非 `long`），避免 NPE
4. Client 统一处理外部异常转为 `BizException`
5. 用 MapStruct 简化 Entity↔DO 转换