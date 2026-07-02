# Object Isolation

对象类型隔离规约。定义各层对象归属、跨层流转规则和转换规约。

## 对象类型总览

| 类型 | 后缀 | 归属层 | 用途 |
|------|------|--------|------|
| Command | `Cmd` | app | 写操作入参 |
| Query | `Qry` | app | 读操作入参 |
| View Object | `VO` | app | 面向前端的出参 |
| DTO | `DTO` | client | 服务间调用入参/出参 |
| Entity | — | domain | 领域实体/聚合根 |
| Value Object | `V` | domain | 值对象 |
| Domain Event | `Event` | domain | 领域事件 |
| Data Object | `DO` | infrastructure | 数据库映射 |
| External Response | `Response` | infrastructure | 外部服务响应 |

## 跨层流转矩阵

| 对象类型 | adapter | app | domain | infrastructure |
|---------|:-------:|:---:|:------:|:--------------:|
| Cmd / Qry / VO | ✅ 用 | ✅ 定义 | ❌ | ❌ |
| DTO | ✅ 用(client) | ❌ | ❌ | ❌ |
| Entity / V / Event | ❌ | ✅ 用 | ✅ 定义 | ✅ 用 |
| DO / Response | ❌ | ❌ | ❌ | ✅ 定义 |

## 依赖方向与对象归属

```
adapter ──→ app ──→ domain ←── infrastructure
  │           │          │            │
  ▼           ▼          ▼            ▼
 Cmd/Qry/VO  Cmd/Qry/VO  Entity/V/Event  DO/Response
 DTO(client)
```

## 转换规约

| 转换方向 | 转换器位置 | 方法命名 |
|---------|-----------|---------|
| Cmd → Entity | Cmd 自身 | `toEntity()` |
| Entity → VO | Qry / Cmd | `toVO()` |
| Entity ↔ DO | Converter / GatewayImpl | `toDO()` / `toEntity()` |
| Entity → DTO | ApiConverter (adapter.api) | `toDTO()` |
| Response → Entity | Client (infra) | `toEntity()` |

## Mandatory 规则

1. Cmd/Qry/VO **必须定义在 app 模块**
2. DTO **必须定义在 client 模块**，**禁止泄露到 app/domain**
3. DO **禁止泄露到 domain/app**
4. External Response **禁止泄露到 domain**
5. 转换逻辑**禁止散落在业务代码中**，必须抽取到转换器
6. **禁止跨层传递非归属对象**（如 Controller 直接返回 Entity）

## Recommended 规则

1. 用 MapStruct 简化 Entity↔DO 转换
2. 简单转换（1-2 字段）可直接在 Cmd/GatewayImpl 完成
3. DTO 与 VO 字段可能重叠但应独立定义——演进节奏不同
4. 聚合根提供 `toVO()`/`toDTO()` 方法，避免 getter 暴露内部状态