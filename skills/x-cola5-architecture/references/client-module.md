# Client Module

Client 模块规约。Client 模块是服务间调用的 API 契约模块，存放接口定义和 DTO，供消费方依赖引用。

## 定位

Client 模块是 COLA 5 架构中的 **API 契约发布模块**，独立于 adapter / app / domain / infrastructure 四层之外。它的核心职责是向外部微服务暴露本服务的调用契约。

```
project-name
├── project-name-client         # API 契约模块（接口 + DTO）
├── project-name-adapter        # 适配层（实现 client 定义的接口）
├── project-name-app            # 应用层
├── project-name-domain         # 领域层
├── project-name-infrastructure # 基础设施层
└── project-name-start          # 启动模块
```

## 目录结构

```
client
└── src/main/java/com/{company}/{project}/client
    ├── api                     # 服务间调用接口定义
    └── dto                     # 数据传输对象
```

## api 包

### 命名规约

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| 服务接口 | `{Resource}Api` | `OrderApi`、`ProductApi` |

### 职责边界

- 定义服务间调用的接口契约（方法签名 + 入参 + 出参）
- 一个 `{Resource}Api` 对应一个领域资源的服务间调用能力
- 接口方法命名使用业务语义，不暴露传输协议细节

### 代码示例

```java
public interface OrderApi {

    OrderDTO getOrder(Long orderId);

    Long createOrder(OrderCreateDTO createDTO);

    void cancelOrder(Long orderId);

    PageResult<OrderDTO> listOrders(OrderQueryDTO queryDTO);
}
```

## dto 包

### 命名规约

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| 写入参 | `{Resource}{Action}DTO` | `OrderCreateDTO`、`OrderUpdateDTO` |
| 读入参 | `{Resource}QueryDTO` | `OrderQueryDTO` |
| 响应 | `{Resource}DTO` | `OrderDTO` |

### 职责边界

- DTO 是服务契约的一部分，面向消费方，不是内部传输细节
- DTO 字段代表服务承诺暴露的数据结构，消费方直接依赖这些类
- **禁止**在 DTO 中包含领域内部实现细节

### Serializable 规约

项目服务间通讯使用 **Dubbo3 + Triple + Fastjson2**，DTO **不实现** `Serializable` 接口，不声明 `serialVersionUID`。

Fastjson2 是 JSON 序列化，不检查 `Serializable` 接口。DTO 作为服务契约应只关心数据结构，不耦合 Java 序列化机制。

> 如需跨语言调用（Go / Python / Rust），使用 Triple REST 模式发布 HTTP + JSON 端点，DTO 仍为 POJO，无需改动。

### 代码示例

```java
@Data
public class OrderDTO {

    private Long orderId;
    private String orderNo;
    private String status;
    private BigDecimal totalAmount;
    private List<OrderItemDTO> items;
    private LocalDateTime createdAt;
}
```

```java
@Data
public class OrderCreateDTO {

    private Long customerId;
    private List<OrderItemCreateDTO> items;
}
```

```java
@Data
public class OrderQueryDTO {

    private String status;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private Integer pageNum;
    private Integer pageSize;
}
```

## Maven 依赖关系

```
start → adapter → app → domain ← infrastructure
           ↑
           └── 依赖 client（实现 client 定义的接口）

consumer-service ──→ client（仅依赖 client jar，不依赖服务实现）
```

| 模块 | 与 client 的关系 |
|------|-----------------|
| client | 独立模块，不依赖 adapter / app / domain / infrastructure |
| adapter | 依赖 client，实现 client 中定义的 `{Resource}Api` 接口 |
| app | 不依赖 client |
| domain | 不依赖 client |
| infrastructure | 不依赖 client |
| consumer | 仅依赖 client jar，通过接口 + DTO 调用服务 |

## client 与 adapter.api 的关系

adapter 层的 `api` 包（`adapter.api.http` / `adapter.api.rpc`）实现 client 模块定义的 `{Resource}Api` 接口：

```
client/                          # 契约定义
├── api/OrderApi.java            # 接口
└── dto/OrderDTO.java            # DTO

adapter/                         # 契约实现
└── api/
    ├── http/OrderHttpApi.java   # @RestController implements OrderApi
    └── rpc/OrderRpcApi.java     # @DubboService implements OrderApi
```

- **client 定义契约**（接口 + DTO），**adapter 实现契约**（HTTP / RPC 两种传输方式）
- HTTP 和 RPC 共享 client 中的同一套 DTO，**禁止**各自定义独立的 DTO
- adapter.api 中的 `HttpApi` / `RpcApi` 实现类中**禁止**重新定义 DTO

## DTO 与其他对象类型的关系

| 对象类型 | 后缀 | 归属模块 | 用途 | 消费方 |
|---------|------|---------|------|--------|
| DTO | `DTO` | client | 服务间调用入参/出参 | 其他微服务 |
| Cmd | `Cmd` | app | 写操作入参 | 前端（通过 adapter.controller） |
| Qry | `Qry` | app | 读操作入参 | 前端（通过 adapter.controller） |
| VO | `VO` | app | 面向前端的出参 | 前端 |
| DO | `DO` | infrastructure | 数据库映射对象 | 内部 |

> DTO 面向服务间调用，Cmd/Qry/VO 面向前端。两者字段可能重叠但必须独立定义——演进节奏和消费方不同。

## 对象转换

| 转换方向 | 转换器位置 | 方法命名 | 示例 |
|---------|-----------|---------|------|
| Entity → DTO | adapter.api | `toDTO(entity)` | `OrderApiConverter.toDTO(order)` |
| DTO → Cmd | adapter.api | `toCmd(dto)` | `OrderApiConverter.toCmd(createDTO)` |
| DTO → Qry | adapter.api | `toQry(dto)` | `OrderApiConverter.toQry(queryDTO)` |

- 转换器定义在 adapter.api 层，因为 adapter 依赖 client 和 app，可以同时访问 DTO 和 Cmd/Qry/Entity
- **禁止**在 client 模块中定义转换逻辑（client 不依赖 app 和 domain）

## 何时需要 client 模块

| 场景 | 是否需要 client | 是否需要 adapter.api |
|------|---------------|-------------------|
| 服务被其他微服务通过 Feign / Dubbo 调用 | ✅ 必须 | ✅ 必须 |
| 服务仅被前端 / 移动端调用（无服务间调用） | ❌ 不需要 | ❌ 不需要 |
| 服务同时被前端和其他微服务调用 | ✅ 必须 | ✅ 必须 |

> adapter.api 与 client 模块共生：有 client → 有 adapter.api；无 client → 无 adapter.api。不存在有 api 包但无 client 模块的情况。

## Mandatory 规则

1. Client 模块**禁止**依赖 adapter、app、domain、infrastructure 模块
2. DTO **禁止**实现 `Serializable` 接口，不声明 `serialVersionUID`
3. HTTP 和 RPC 实现**禁止**各自定义独立的 DTO，**必须**共享 client 中的同一套 DTO
4. Client 模块**禁止**包含任何业务逻辑或转换逻辑
5. `{Resource}Api` 接口方法命名**必须**使用业务语义，**禁止** CRUD 风格命名

## Recommended 规则

1. Client 模块仅包含 `api` 和 `dto` 两个包，不要放入其他内容
2. 一个 `{Resource}Api` 对应一个领域资源的服务间调用能力
3. DTO 字段使用包装类型（`Long` 而非 `long`），避免消费方反序列化 NPE
4. DTO 中日期字段使用 `LocalDateTime` / `LocalDate`，配合 Fastjson2 序列化
5. 当服务无服务间调用需求时，不必创建 client 模块，也不需要 adapter.api 包
6. Client 模块的 `pom.xml` 仅依赖通用工具包（如 commons-lang3、guava），不依赖 Spring 等框架
7. 接口版本化：Dubbo 通过 `version` 属性，HTTP 通过 URI 路径版本 `/api/v1/`
8. 如需跨语言调用，使用 Triple REST 模式（加 Spring Web 注解），DTO 仍为 POJO，无需实现 Serializable