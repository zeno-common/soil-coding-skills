# Client Module

Client 模块是服务间调用的 API 契约模块，存放接口定义和 DTO，供消费方依赖引用。**独立于四层之外，不依赖任何业务模块。**

## 目录结构

```
client/src/main/java/com/{company}/{project}/client
├── api     # 服务间调用接口定义
└── dto     # 数据传输对象
```

## 命名规约

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| 服务接口 | `{Resource}Api` | `OrderApi` |
| 写入参 | `{Resource}{Action}DTO` | `OrderCreateDTO` |
| 读入参 | `{Resource}QueryDTO` | `OrderQueryDTO` |
| 响应 | `{Resource}DTO` | `OrderDTO` |

## 代码示例

```java
public interface OrderApi {
    OrderDTO getOrder(Long orderId);
    Long createOrder(OrderCreateDTO dto);
    PageResult<OrderDTO> listOrders(OrderQueryDTO qry);
}

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class OrderDTO {
    private Long orderId;
    private String orderNo;
    private BigDecimal totalAmount;
}
```

## DTO 规约

- **禁止实现 Serializable**（Dubbo3+Triple+Fastjson2 为 JSON 序列化，不检查 Serializable）
- 字段使用包装类型（`Long` 非 `long`），避免 NPE
- 日期字段用 `OffsetDateTime` / `LocalDate`
- **禁止包含领域内部实现细节**

## client ↔ adapter.api 关系

```
client/                          # 契约定义
├── api/OrderApi.java
└── dto/OrderDTO.java
adapter/api/
├── http/OrderHttpApi.java       # @RestController implements OrderApi
└── rpc/OrderRpcApi.java         # @DubboService implements OrderApi
```

- client 定义契约，adapter 实现契约（HTTP/RPC 两种传输方式）
- http 与 rpc 共享同一套 DTO，**禁止各自定义独立 DTO**

## 何时需要 client

| 场景 | 需要 client | 需要 adapter.api |
|------|:-----------:|:---------------:|
| 被其他微服务调用 | ✅ | ✅ |
| 仅前端/移动端调用 | ❌ | ❌ |
| 同时被前端和微服务调用 | ✅ | ✅ |

> 有 client → 有 adapter.api；无 client → 无 adapter.api

## Mandatory 规则

1. Client **禁止依赖** adapter/app/domain/infrastructure
2. DTO **禁止实现 Serializable**，不声明 serialVersionUID
3. http 与 rpc **禁止各自定义独立 DTO**，**必须共享 client 同一套 DTO
4. Client **禁止包含任何业务逻辑或转换逻辑**
5. Api 方法命名**必须使用业务语义**，**禁止 CRUD 风格**

## Recommended 规则

1. Client 仅含 api 和 dto 两个包
2. pom.xml 仅依赖通用工具包，不依赖 Spring
3. 版本化：Dubbo 用 `version` 属性，HTTP 用 URI `/api/v1/`
4. 跨语言调用用 Triple REST 模式，DTO 仍为 POJO