# Client Module

服务间调用 API 契约模块。**独立于四层之外，不依赖任何业务模块。**

## Structure

```
client/src/main/java/{basePackage}/client
├── api     # 接口定义（含 HTTP 路径注解）
└── dto     # 数据传输对象
```

## Naming

| Type | Pattern | Example |
|------|---------|---------|
| Api interface | `{Resource}Api` | `OrderApi` |
| Write input | `{Resource}{Action}DTO` | `OrderCreateDTO` |
| Query input | `{Resource}QueryDTO` | `OrderQueryDTO` |
| Response | `{Resource}DTO` | `OrderDTO` |

> client `{Resource}Api` → adapter `{Resource}Http`(HTTP) / `{Resource}Rpc`(RPC). Implementation class MUST NOT share name with interface.

## HTTP Path Pre-definition

Api 接口 MUST 预定义完整 HTTP 路径注解，adapter 实现类和 Feign 消费方直接继承。

### Annotations

| Level | Required | Pattern |
|-------|----------|---------|
| Class | `@RequestMapping("/api/v1/{resource}")` | `@RequestMapping("/api/v1/orders")` |
| Method - simple query | `@GetMapping("/{id}")` or `@GetMapping` | `@GetMapping("/{orderId}")` |
| Method - complex query | `@PostMapping("/query")` | `@PostMapping("/query")` |
| Method - create | `@PostMapping` | `@PostMapping` |
| Method - update | `@PutMapping("/{id}")` | `@PutMapping("/{orderId}")` |
| Method - partial update | `@PatchMapping("/{id}/{action}")` | `@PatchMapping("/{orderId}/status")` |
| Method - delete | `@DeleteMapping("/{id}")` | `@DeleteMapping("/{orderId}")` |
| Param - path | `@PathVariable("name")` | `@PathVariable("orderId") Long orderId` |
| Param - query | `@RequestParam("name")` | `@RequestParam("orderNo") String orderNo` |
| Param - body | `@RequestBody` | `@RequestBody OrderCreateDTO dto` |
| Status - create | `@ResponseStatus(HttpStatus.CREATED)` | on create method |
| Status - no content | `@ResponseStatus(HttpStatus.NO_CONTENT)` | on update/delete returning void |

### Query Convention

| Query Type | Method | Path | Param | Use Case |
|-----------|--------|------|-------|----------|
| Simple | GET | `/{id}` or `?key=value` | `@PathVariable` / `@RequestParam` | 单 ID、单键查询 |
| Complex | POST | `/query` | `@RequestBody` | 多条件筛选、分页、排序 |

> MUST NOT use `@SpringQueryMap` — requires `spring-cloud-starter-openfeign` dependency, inconsistent behavior.

## Code Example

```java
@RequestMapping("/api/v1/orders")
public interface OrderApi {
    @GetMapping("/{orderId}")
    OrderDTO getOrder(@PathVariable("orderId") Long orderId);

    @GetMapping
    OrderDTO getByOrderNo(@RequestParam("orderNo") String orderNo);

    @PostMapping("/query")
    PagedResult<OrderDTO> listOrders(@RequestBody OrderQueryDTO qry);

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    Long createOrder(@RequestBody OrderCreateDTO dto);

    @PutMapping("/{orderId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void updateOrder(@PathVariable("orderId") Long orderId, @RequestBody OrderUpdateDTO dto);

    @DeleteMapping("/{orderId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void deleteOrder(@PathVariable("orderId") Long orderId);
}
```

## Adapter Implementation

```java
@RestController @RequiredArgsConstructor
public class OrderHttp implements OrderApi {
    private final OrderApplicationService orderService;
    @Override public OrderDTO getOrder(Long orderId) { return orderService.findById(orderId); }
    @Override public PagedResult<OrderDTO> listOrders(OrderQueryDTO qry) { return orderService.listOrders(qry); }
    @Override public Long createOrder(OrderCreateDTO dto) { return orderService.createOrder(dto); }
}
```

> Implementation MUST NOT redeclare path annotations — inherited from interface.

## Feign Consumer

```java
@FeignClient(name = "order-service", url = "${order-service.url}")
public interface OrderFeignClient extends OrderApi {}
```

## DTO Rules

- MUST NOT implement Serializable / declare serialVersionUID
- Use wrapper types (`Long` not `long`)
- Date fields: `OffsetDateTime` / `LocalDate`
- MUST NOT include domain implementation details

## client ↔ adapter.api

```
client/api/OrderApi.java        → @RequestMapping + HTTP Method + param annotations
client/dto/OrderDTO.java        → shared DTO
adapter/api/http/OrderHttp.java → @RestController implements OrderApi (path inherited)
adapter/api/rpc/OrderRpc.java   → @DubboService implements OrderApi (no HTTP annotations)
```

- HTTP impl inherits path annotations; RPC impl does not use HTTP annotations
- http and rpc MUST share same DTO set from client

## When Client Exists

| Scenario | client | adapter.api |
|----------|:------:|:-----------:|
| Called by other services | ✅ | ✅ |
| Frontend/mobile only | ❌ | ❌ |
| Both frontend and services | ✅ | ✅ |

## Dependency

```xml
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-web</artifactId>
</dependency>
```

Provides `@RequestMapping`, `@GetMapping`, `@PathVariable`, `@RequestBody` etc. No `spring-boot-starter-web`.

## Mandatory

1. Client MUST NOT depend on adapter/app/domain/infrastructure
2. DTO MUST NOT implement Serializable
3. http and rpc MUST share client DTO — MUST NOT define independent DTOs
4. Client MUST NOT contain business logic or conversion logic
5. Api method naming MUST use business semantics — MUST NOT use CRUD style
6. Api MUST predefine `@RequestMapping` (class) + HTTP Method annotations (method)
7. Api params MUST declare `@PathVariable` / `@RequestParam` / `@RequestBody`
8. Write operations MUST declare `@ResponseStatus` (CREATED / NO_CONTENT)
9. Adapter impl MUST NOT redeclare interface path annotations
10. Complex query MUST use `@PostMapping("/query")` + `@RequestBody` — MUST NOT use `@SpringQueryMap`
11. Simple query uses `@GetMapping` + `@PathVariable` / `@RequestParam`