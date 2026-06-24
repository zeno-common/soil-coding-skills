# Infrastructure Layer

基础设施层目录规约。Infrastructure 实现领域层定义的 Gateway 接口，对接数据库、缓存、消息队列等外部系统。

## 目录结构

```
infrastructure
└── src/main/java/com/{company}/{project}/infrastructure
    ├── gateway
    │   └── impl            # Gateway 接口实现
    ├── mapper              # MyBatis Mapper 接口
    ├── dataobject          # 数据库映射对象（DO）
    ├── client              # 外部服务客户端（RPC、HTTP）
    ├── config              # 基础设施配置
    └── common              # 基础设施通用工具
```

## gateway/impl 包

### 命名规约

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| Gateway 实现 | `{DomainConcept}GatewayImpl` | `OrderGatewayImpl` |

### 职责边界

- 实现 domain 模块中定义的 Gateway 接口
- 负责领域对象与数据对象之间的转换
- 调用 Mapper 或 Client 完成数据操作
- **禁止**包含业务逻辑

### 代码示例

```java
@Component
public class OrderGatewayImpl implements OrderGateway {

    @Resource
    private OrderMapper orderMapper;
    @Resource
    private OrderItemMapper orderItemMapper;

    @Override
    public Order findById(String orderId) {
        OrderDO orderDO = orderMapper.selectById(orderId);
        if (orderDO == null) {
            return null;
        }
        List<OrderItemDO> itemDOs = orderItemMapper.selectByOrderId(orderId);
        return OrderConverter.toEntity(orderDO, itemDOs);
    }

    @Override
    public void save(Order order) {
        OrderDO orderDO = OrderConverter.toDO(order);
        orderMapper.insertOrUpdate(orderDO);
    }
}
```

## mapper 包

### 命名规约

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| Mapper 接口 | `{TableConcept}Mapper` | `OrderMapper`, `OrderItemMapper` |

### 职责边界

- 定义数据库操作方法
- 对应 XML 或注解 SQL
- **禁止**被 domain 或 app 层直接引用

## dataobject 包

### 命名规约

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| 数据对象 | `{TableConcept}DO` | `OrderDO`, `OrderItemDO` |

### 职责边界

- 与数据库表一一对应
- 仅包含字段和 getter/setter
- **禁止**包含业务逻辑
- **禁止**泄露到 domain 或 app 层

## client 包

### 命名规约

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| 外部服务客户端 | `{ExternalSystem}Client` | `PaymentClient`, `InventoryClient` |
| 外部服务响应 | `{ExternalSystem}Response` | `PaymentResponse` |

### 职责边界

- 封装对外部系统（RPC / HTTP）的调用
- 处理序列化/反序列化
- 处理外部系统异常并转换为内部异常
- **禁止**将外部系统的数据结构泄露到 domain 层

## config 包

### 职责边界

- 数据源配置
- Redis 配置
- MQ 配置
- 其他中间件配置
- **仅限**基础设施相关配置，业务配置放在 start 模块

## 对象转换规约

| 转换方向 | 转换器位置 | 方法命名 |
|---------|-----------|---------|
| Entity → DO | `GatewayImpl` 内部或 `Converter` 工具类 | `toDO(entity)` |
| DO → Entity | `GatewayImpl` 内部或 `Converter` 工具类 | `toEntity(do)` |
| External Response → Entity | `Client` 内部 | `toEntity(response)` |

## Mandatory 规则

1. Gateway 实现类命名必须以 `GatewayImpl` 结尾
2. GatewayImpl 必须实现 domain 模块中定义的 Gateway 接口
3. DO 对象**禁止**泄露到 domain 或 app 层
4. Mapper 接口**禁止**被 domain 或 app 层直接引用，必须通过 GatewayImpl 间接使用
5. 外部系统的数据结构**禁止**泄露到 domain 层，必须在 client 或 GatewayImpl 中转换
6. 基础设施配置类**禁止**包含业务逻辑

## Recommended 规则

1. 一个 GatewayImpl 对应一个 Gateway 接口，不要合并实现
2. 对象转换逻辑抽取为独立的 Converter 类，保持 GatewayImpl 简洁
3. DO 类字段使用基本类型包装类（`Long` 而非 `long`），避免 NPE
4. Client 类中统一处理外部系统异常，转换为 `BizException`
5. 使用 MapStruct 等工具简化 Entity 与 DO 之间的转换