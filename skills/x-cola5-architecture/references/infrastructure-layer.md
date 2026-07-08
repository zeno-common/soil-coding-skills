# Infrastructure Layer

实现 domain Gateway 接口，对接外部系统。**按领域聚合组织目录。**

## Structure

```
infrastructure/src/main/java/{basePackage}/infrastructure
├── {domain1}/
│   ├── gateway/impl/         # Gateway 实现
│   ├── mapper/               # MyBatis Mapper
│   └── dataobject/           # DO
├── {domain2}/
└── common/
    ├── client/               # 外部服务客户端
    ├── event/                # 事件发布实现
    ├── config/               # 基础设施配置
    └── util/                 # 通用工具
```

## Naming & Responsibilities

| Package | Pattern | Example | Responsibility |
|---------|---------|---------|---------------|
| gateway/impl | `{Concept}GatewayImpl` | `OrderGatewayImpl` | Implement domain Gateway, Entity↔DO conversion |
| mapper | `{Table}Mapper` | `OrderMapper` | DB operations — MUST NOT be referenced by domain/app |
| dataobject | `{Table}DO` | `OrderDO` | DB mapping — MUST NOT leak to domain/app |
| client | `{System}Client` | `PaymentClient` | Wrap external calls, convert to internal exceptions |
| event | `DomainEventPublisher` | — | Publish events to MQ, serialization and retry |
| config | — | — | DataSource/Redis/MQ config — MUST NOT contain business logic |

```java
@Component @RequiredArgsConstructor
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

## Conversion

| Direction | Location | Method |
|-----------|----------|--------|
| Entity ↔ DO | Converter / GatewayImpl | `toDO()` / `toEntity()` |
| Response → Entity | Client | `toEntity(response)` |

See `references/object-isolation.md` for full conversion rules.

## Mandatory

1. MUST organize by domain aggregate — MUST NOT flat-layout by technical concern
2. GatewayImpl suffix `GatewayImpl`, must implement domain Gateway interface
3. DO MUST NOT leak to domain or app
4. Mapper MUST NOT be referenced by domain or app directly
5. External data structures MUST NOT leak to domain — convert in Client or GatewayImpl
6. config MUST NOT contain business logic

## Recommended

1. One GatewayImpl per Gateway interface
2. Extract conversion to Converter class, keep GatewayImpl clean
3. DO fields use wrapper types (`Long` not `long`)
4. Client converts external exceptions to `BaseException`
5. Use MapStruct for Entity↔DO conversion