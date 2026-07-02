# Lombok Usage

COLA 5 各层 Lombok 注解使用规约。

## 注解速查表

| 层 | 对象类型 | 推荐 | 禁止 | 原因 |
|----|---------|------|------|------|
| domain | Entity | `@Getter` | `@Data` `@Setter` `@Builder` | 保护内部一致性 |
| domain | ValueObject(V) | `@Getter @EqualsAndHashCode` | `@Data` `@Setter` | 不可变 |
| domain | Event | `@Getter @EqualsAndHashCode` | `@Data` `@Setter` | 不可变 |
| domain | DomainService | `@RequiredArgsConstructor` | — | 构造器注入 |
| app | Cmd / Qry / VO | `@Data @Builder` | — | 纯数据载体 |
| app | Service / Executor | `@RequiredArgsConstructor` | — | 构造器注入 |
| infra | DO | `@Data @Builder @NoArgsConstructor @AllArgsConstructor` | — | ORM 需无参构造器 |
| infra | GatewayImpl / Client | `@RequiredArgsConstructor` | — | 构造器注入 |
| client | DTO | `@Data @Builder @NoArgsConstructor @AllArgsConstructor` | — | 反序列化需无参构造器 |
| adapter | Controller / HttpApi / RpcApi | `@RequiredArgsConstructor` | — | 构造器注入 |

## 关键代码片段

### 领域实体（仅 Getter）

```java
@Getter
public class Order extends AggregateRoot {
    private String orderId;
    private OrderStatus status;
    // 状态变更通过业务方法，禁止 @Data/@Setter
}
```

### 不可变值对象/事件

```java
@Getter @EqualsAndHashCode
public class MoneyV {
    private final BigDecimal amount;      // 字段必须 final
    private final String currency;
}
```

### 纯数据载体（Cmd/Qry/VO）

```java
@Data @Builder
public class OrderCreateCmd { ... }       // 无需 NoArgs/AllArgs
```

### 需反序列化的载体（DTO/DO）

```java
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class OrderDTO { ... }             // Fastjson2/ORM 需无参构造器
```

### 依赖注入的服务类

```java
@Service @RequiredArgsConstructor         // 统一构造器注入，不用 @Autowired
@Slf4j                                     // domain/client 禁止 @Slf4j
public class OrderService { ... }
```

## @Slf4j 使用规约

| 层 | 允许 | 说明 |
|----|:---:|------|
| domain | ❌ | 不记录日志 |
| client | ❌ | 不记录日志 |
| app | ✅ | 用例级日志 |
| infrastructure | ✅ | 外部调用日志 |
| adapter | ✅ | 请求日志 |

## @Builder 使用规约

| 对象类型 | @Builder | 原因 |
|---------|:-------:|------|
| Cmd / Qry / VO / DTO / DO | ✅ | 纯数据载体 |
| Entity | ❌ | 绕过业务规则构造不合法对象 |
| ValueObject / Event | ❌ | 应通过显式构造器确保不变性 |

## @EqualsAndHashCode 使用规约

| 对象类型 | 需要 | 说明 |
|---------|:-----:|------|
| ValueObject | ✅ | 按属性判等 |
| DomainEvent | ✅ | 按属性判等 |
| Entity | ❌ | 按 ID 判等，属性判等语义错误 |
| DTO/Cmd/Qry/VO/DO | — | @Data 已包含 |

## Mandatory 规则

1. Entity **禁止** `@Data` / `@Setter` / `@Builder`
2. ValueObject **禁止** `@Setter`，字段必须 `final`
3. domain / client **禁止** `@Slf4j`
4. DTO / DO 用 `@Data @Builder` 时**必须**加 `@NoArgsConstructor @AllArgsConstructor`

## Recommended 规则

1. Service 类统一 `@RequiredArgsConstructor`，不用 `@Autowired`
2. ValueObject/Event 用 `@Getter @EqualsAndHashCode`，不用 `@Value`
3. `@ToString` 避免包含懒加载/循环引用字段