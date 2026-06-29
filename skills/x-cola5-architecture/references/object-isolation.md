# Object Isolation

对象类型隔离规约。定义各层对象类型的归属、跨层流转规则和转换规约，确保层间依赖方向正确、对象不越界泄露。

## 对象类型总览

| 对象类型 | 后缀 | 归属层 | 用途 |
|---------|------|--------|------|
| Command | `Cmd` | app | 写操作入参（`OrderCreateCmd`） |
| Query | `Qry` | app | 读操作入参（`OrderListQry`） |
| View Object | `VO` | app | 面向前端的出参（`OrderVO`） |
| DTO | `DTO` | adapter.api | 服务间调用入参/出参（`OrderDTO`、`OrderCreateDTO`、`OrderQueryDTO`） |
| Entity | 无后缀 | domain | 领域实体 / 聚合根（`Order`、`OrderItem`） |
| Value Object | `V` | domain | 值对象（`MoneyV`、`AddressV`） |
| Domain Event | `Event` | domain | 领域事件（`OrderSubmittedEvent`） |
| Data Object | `DO` | infrastructure | 数据库映射对象（`OrderDO`） |
| External Response | `Response` | infrastructure | 外部服务响应（`PaymentResponse`） |

## 跨层流转矩阵

| 对象类型 | adapter | app | domain | infrastructure |
|---------|---------|-----|--------|----------------|
| Cmd / Qry / VO | ✅ 使用 | ✅ 定义 | ❌ | ❌ |
| DTO（服务间） | ✅ 定义 | ❌ | ❌ | ❌ |
| Entity / V / Event | ❌ | ✅ 使用 | ✅ 定义 | ✅ 使用 |
| DO / Response | ❌ | ❌ | ❌ | ✅ 定义 |

> ✅ 定义 = 归属层，负责创建和维护　✅ 使用 = 可以引用　❌ = 禁止引用

## 依赖方向与对象归属

```
adapter ──→ app ──→ domain ←── infrastructure
  │           │          │            │
  ▼           ▼          ▼            ▼
 定义 DTO   定义 Cmd   定义 Entity   定义 DO
 使用 Cmd   使用 Entity (无外部依赖) 使用 Entity
 /Qry/VO    /V/Event                 /V/Event
```

- **adapter 依赖 app** → 可使用 app 定义的 Cmd / Qry / VO
- **app 依赖 domain** → 可使用 domain 定义的 Entity / V / Event
- **infrastructure 依赖 domain** → 可使用 domain 定义的 Entity / V / Event
- **app 禁止依赖 adapter** → 无法访问 adapter 定义的 DTO
- **domain 不依赖任何模块** → 无法访问任何其他层的对象类型

## 对象转换规约

### 完整转换链

```
Cmd/Qry ──[Cmd/Qry]──→ Entity ──[GatewayImpl]──→ DO
   (app 层)                 (domain 层)              (infrastructure 层)

VO ←──[Cmd/Qry]── Entity ←──[GatewayImpl]── DO
(app 层)                (domain 层)              (infrastructure 层)

DTO ←──[HttpApi/RpcApi]── Entity          Response ──[Client]──→ Entity
(adapter 层)              (通过 app 层)    (infrastructure 层)
```

### 转换规则明细

| 转换方向 | 转换器位置 | 方法命名 | 示例 |
|---------|--------|---------|------|
| Cmd → Entity | `Cmd` | `toEntity(cmd)` | `OrderCreateCmd.toEntity(cmd)` |
| Entity → VO | `Qry` | `toVO(entity)` | `OrderListQry.toVO(order)` |
| Entity ↔ DO | `Converter` / `GatewayImpl` | `toDO` / `toEntity` | `OrderConverter.toDO(order)` |
| Entity → DTO | `ApiConverter` | `toDTO(entity)` | `OrderApiConverter.toDTO(order)` |
| Response → Entity | `Client` | `toEntity(response)` | `PaymentClient.toEntity(resp)` |

### 转换器归属

| 转换器 | 归属层 | 命名格式 |
|--------|--------|---------|
| Cmd（Cmd→Entity / Entity→VO） | app | `{Resource}{Action}Cmd` |
| Qry（Entity→VO） | app | `{Resource}{Action}Qry` |
| Converter（Entity↔DO） | infrastructure | `{Resource}Converter` |
| ApiConverter（Entity→DTO） | adapter.api | `{Resource}ApiConverter` |

## Mandatory 规则

1. Cmd / Qry / VO **必须**定义在 app 模块，adapter 通过依赖 app 使用
2. DTO **必须**定义在 adapter.api 模块或独立 API jar，**禁止**泄露到 app 或 domain
3. DO **禁止**泄露到 domain 或 app 层
4. External Response **禁止**泄露到 domain 层，必须在 Client 或 GatewayImpl 中转换
5. 对象转换逻辑**禁止**散落在业务代码中，必须抽取到对应的转换器
6. **禁止**跨层直接传递非归属对象（如 Controller 直接返回 Entity）

## Recommended 规则

1. 使用 MapStruct 等工具简化 Entity 与 DO 之间的转换
2. 简单转换（1-2 个字段）可直接在 Cmd / GatewayImpl 中完成，不必强制抽取 Converter
3. DTO 与 VO 字段可能重叠，但应独立定义，不要复用——演进节奏不同
4. 聚合根不要暴露 getter 让外部转换器直接读取内部状态，应提供 `toVO()` / `toDTO()` 等方法